#!/bin/bash
# setup-mipgen.sh - A script to install dependencies, clone and build upstream MIPGEN,
# install FLUMIP's helper scripts, set up data directories, and optionally
# download required reference files for selected genomes.
# Supported genomes: hg18, hg19, hg38, hs1.
#
# The script has two modes:
#   * Interactive  - run with no selection arguments on a terminal and you will be
#                    prompted to choose whether to download reference data, which
#                    genomes to fetch, and the service user.
#   * Non-interactive (switches) - pass any of the switches below to script the run
#                    for automated deployments or experienced users. Providing a
#                    selection switch (or --yes) disables the prompts.
#
# Usage:
#   ./setup-mipgen.sh [options] [genome ...]
#
# Options:
#   -download, --download        Download reference files for the selected genomes.
#   --service-user USER          Service user to grant access (default: www-data).
#   -i, --interactive            Force interactive prompts even if switches are given.
#   -y, --yes, --non-interactive Never prompt; use defaults/switches (for automation).
#   -h, --help                   Show this help and exit.
#
# Genomes: hg18 hg19 hg38 hs1   (default with --download: hg38). Naming a genome
# without --download is an error, since nothing would be fetched.
#
# Examples:
#   ./setup-mipgen.sh                         # interactive on a terminal
#   ./setup-mipgen.sh -download hg38 hg19     # experienced/scripted, no prompts
#   ./setup-mipgen.sh --yes                   # automation: install only, no download

# Exit immediately if a command exits with a non-zero status.
set -e

# The FLUMIP helpers that ship beside this script (deployment/ in both the
# repository and the release tarball). Resolved now, before any `cd`.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# MIPGEN is installed exactly as its authors publish it, pinned to a known
# commit so every install builds the same thing. Its licence does not allow
# distributing a modified copy, so FLUMIP never patches it: what MIPGEN needs
# adapting for (the TRF check) is handled by the mipgen-trf wrapper instead.
MIPGEN_REPO="https://github.com/shendurelab/MIPGEN.git"
MIPGEN_COMMIT="4d6c342"

# Define colors.
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'  # No Color

# Supported genomes (order defines the interactive menu).
AVAILABLE_GENOMES=("hg38" "hg19" "hg18" "hs1")

# Default flags.
DOWNLOAD=false
GENOMES=()
SERVICE_USER="www-data"

# Mode tracking.
INTERACTIVE="auto"     # auto | yes | no
DOWNLOAD_SET=false     # whether -download was passed explicitly
GENOMES_SET=false      # whether genomes were passed explicitly

usage() {
  # Print the comment header (usage block) without the leading '# ',
  # stopping at the first blank/non-comment line after the shebang.
  awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "$0"
}

# Parse command-line arguments.
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -download|--download)
      DOWNLOAD=true
      DOWNLOAD_SET=true
      ;;
    --service-user)
      if [[ -z "$2" ]]; then
        echo -e "${RED}--service-user requires a value${NC}"
        exit 1
      fi
      SERVICE_USER="$2"
      shift
      ;;
    -i|--interactive)
      INTERACTIVE="yes"
      ;;
    -y|--yes|--non-interactive)
      INTERACTIVE="no"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo -e "${RED}Unknown option: $1${NC}"
      echo -e "Run '${0} --help' for usage."
      exit 1
      ;;
    *)
      # Treat as genome name. Checked here rather than in the download loop,
      # which used to skip a typo and then report success for it anyway.
      if [[ ! " ${AVAILABLE_GENOMES[*]} " == *" $1 "* ]]; then
        echo -e "${RED}Unknown genome: $1. Choose from: ${AVAILABLE_GENOMES[*]}.${NC}"
        exit 1
      fi
      GENOMES+=("$1")
      GENOMES_SET=true
      ;;
  esac
  shift
done

# Decide whether to run interactively.
# - Explicit -i/--interactive or -y/--yes always win.
# - Otherwise: prompt only when no selection switches were given and we have a TTY.
if [ "$INTERACTIVE" == "auto" ]; then
  if $DOWNLOAD_SET || $GENOMES_SET; then
    INTERACTIVE="no"          # experienced/scripted invocation
  elif [ -t 0 ]; then
    INTERACTIVE="yes"
  else
    INTERACTIVE="no"          # piped/CI with no switches -> safe defaults
  fi
fi

# Guard: cannot prompt without a terminal.
if [ "$INTERACTIVE" == "yes" ] && [ ! -t 0 ]; then
  echo -e "${YELLOW}No terminal available for interactive prompts; continuing non-interactively.${NC}"
  INTERACTIVE="no"
fi

# --- Interactive helpers -----------------------------------------------------

# Ask a yes/no question. $1 = prompt, $2 = default (y|n). Returns 0 for yes.
prompt_yes_no() {
  local prompt="$1" default="$2" hint reply
  if [ "$default" == "y" ]; then hint="[Y/n]"; else hint="[y/N]"; fi
  while true; do
    read -r -p "$(echo -e "${CYAN}${prompt}${NC} ${hint} ")" reply || reply=""
    reply="${reply:-$default}"
    case "$reply" in
      [Yy]*) return 0 ;;
      [Nn]*) return 1 ;;
      *) echo -e "${YELLOW}Please answer y or n.${NC}" ;;
    esac
  done
}

# Let the user pick one or more genomes. Sets the global GENOMES array.
select_genomes() {
  local i choice tokens token selected=() valid
  echo -e "\n${CYAN}Select the genome(s) to download:${NC}"
  for i in "${!AVAILABLE_GENOMES[@]}"; do
    printf "  %d) %s\n" "$((i + 1))" "${AVAILABLE_GENOMES[$i]}"
  done
  echo -e "  a) all"
  echo -e "${YELLOW}Enter numbers and/or names separated by spaces (default: hg38).${NC}"

  while true; do
    read -r -p "$(echo -e "${CYAN}Genomes:${NC} ")" -a tokens || tokens=()

    # Default to hg38 when nothing is entered.
    if [ "${#tokens[@]}" -eq 0 ]; then
      selected=("hg38")
      break
    fi

    selected=()
    valid=true
    for token in "${tokens[@]}"; do
      case "$token" in
        a|A|all|ALL)
          selected=("${AVAILABLE_GENOMES[@]}")
          break
          ;;
        [1-9]*)
          if [ "$token" -ge 1 ] 2>/dev/null && [ "$token" -le "${#AVAILABLE_GENOMES[@]}" ] 2>/dev/null; then
            selected+=("${AVAILABLE_GENOMES[$((token - 1))]}")
          else
            echo -e "${RED}Invalid choice: $token${NC}"; valid=false
          fi
          ;;
        hg18|hg19|hg38|hs1)
          selected+=("$token")
          ;;
        *)
          echo -e "${RED}Invalid choice: $token${NC}"; valid=false
          ;;
      esac
    done

    $valid && [ "${#selected[@]}" -gt 0 ] && break
  done

  # De-duplicate while preserving order.
  GENOMES=()
  for token in "${selected[@]}"; do
    if [[ ! " ${GENOMES[*]} " == *" $token "* ]]; then
      GENOMES+=("$token")
    fi
  done
}

# Genome names only mean something with --download. Without it they used to be
# ignored, and the run still reported success "for genomes: hg19" with nothing
# fetched. (-i asks about downloading below, so the names can still be used.)
if $GENOMES_SET && ! $DOWNLOAD && [ "$INTERACTIVE" != "yes" ]; then
  echo -e "${RED}Genomes were named (${GENOMES[*]}) but --download was not given, so nothing would be fetched.${NC}"
  echo -e "Run '${0} --download ${GENOMES[*]}' to download them."
  exit 1
fi

# --- Interactive flow --------------------------------------------------------

if [ "$INTERACTIVE" == "yes" ]; then
  echo -e "${GREEN}=== FLUMIP / MIPGEN interactive setup ===${NC}"
  echo -e "Press Enter to accept the [default] shown in each prompt.\n"

  if prompt_yes_no "Download genome reference files now?" "n"; then
    DOWNLOAD=true
    select_genomes
  else
    DOWNLOAD=false
    echo -e "${YELLOW}Skipping reference downloads (MIPGEN and directories will still be set up).${NC}"
  fi

  read -r -p "$(echo -e "${CYAN}Service user${NC} [${SERVICE_USER}]: ")" _svc || _svc=""
  SERVICE_USER="${_svc:-$SERVICE_USER}"
fi

# Downloading with no genomes named means hg38. Without --download there is no
# genome to default to, so the list stays empty.
if $DOWNLOAD && [ ${#GENOMES[@]} -eq 0 ]; then
  GENOMES=("hg38")
fi

# --- Summary / confirmation --------------------------------------------------

echo -e "\n${GREEN}Configuration:${NC}"
echo -e "  Download reference data: ${DOWNLOAD}"
if $DOWNLOAD; then
  echo -e "  Genomes:                 ${GENOMES[*]}"
fi
echo -e "  Service user:            ${SERVICE_USER}"
echo ""

if [ "$INTERACTIVE" == "yes" ]; then
  if ! prompt_yes_no "Proceed with this configuration?" "y"; then
    echo -e "${RED}Aborted by user.${NC}"
    exit 1
  fi
fi

# Update system package repository.
echo -e "\n${GREEN}Updating system packages...${NC}\n"
sudo apt update

# Install required packages.
echo -e "\n${GREEN}Installing required packages: build-essential, git, tabix, samtools, bwa, trf, acl, wget...${NC}\n"
sudo apt install build-essential git tabix samtools bwa trf acl wget -y

# Create the mipgen directory and clone the MIPGEN repository.
echo -e "\n${GREEN}Creating '/opt/flumip' directory and cloning MIPGEN repository...${NC}\n"
sudo mkdir -p /opt/flumip
sudo chown $USER:$USER /opt/flumip
cd /opt/flumip
if [ ! -d "MIPGEN" ]; then
  git clone "$MIPGEN_REPO" MIPGEN
fi
cd MIPGEN

# Earlier installs cloned a modified fork. Refuse to build on top of one rather
# than quietly running something other than upstream MIPGEN.
MIPGEN_ORIGIN="$(git remote get-url origin 2>/dev/null || true)"
if [ "$MIPGEN_ORIGIN" != "$MIPGEN_REPO" ]; then
  echo -e "${RED}/opt/flumip/MIPGEN was cloned from ${MIPGEN_ORIGIN:-an unknown source}, not ${MIPGEN_REPO}.${NC}"
  echo -e "${RED}Remove it (rm -rf /opt/flumip/MIPGEN) and run this script again.${NC}"
  exit 1
fi
git -c advice.detachedHead=false checkout -q "$MIPGEN_COMMIT"

echo -e "\n${GREEN}Building MIPGEN...${NC}\n"
make

echo -e "\n${GREEN}Setting execute permissions for MIPGEN tools...${NC}\n"
chmod +x mipgen
chmod +x tools/extract_coding_gene_exons.sh
cd ..

# Create the base directory structure.
echo -e "\n${GREEN}Setting up base data directories...${NC}\n"
mkdir -p /opt/flumip/data/genomes/
mkdir -p /opt/flumip/projects
mkdir -p /opt/flumip/tools
mkdir -p /opt/flumip/data/custom_snp/{common,private}

# FLUMIP's own helpers.
echo -e "\n${GREEN}Installing FLUMIP helper scripts...${NC}\n"
install -m 755 "$SCRIPT_DIR/mipgen-trf" /opt/flumip/tools/mipgen-trf
# Earlier installs put a Python helper here; its job is now done inline, in awk.
rm -f /opt/flumip/tools/add_bins_to_refgene.py

# Download and activate bigGenePredToGenePred (needed for hs1).
echo -e "\n${GREEN}Downloading bigGenePredToGenePred...${NC}\n"
cd /opt/flumip/tools
wget -N https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bigGenePredToGenePred
chmod +x bigGenePredToGenePred

# Download genomes if the download flag is set.
if $DOWNLOAD; then
  for GENOME in "${GENOMES[@]}"; do
    echo -e "\n${GREEN}Setting up genome directories for $GENOME...${NC}\n"
    if [ "$GENOME" == "hg38" ]; then
      BASE_DIR="/opt/flumip/data/genomes/human/hg38"
      FA_DIR="$BASE_DIR/fa"
      SNP_DIR="$BASE_DIR/snp/00-common_all"
      FA_FILE="$FA_DIR/hg38.fa"
      REFGENE_FILE="$BASE_DIR/refGene.txt"
      mkdir -p "$BASE_DIR"
      mkdir -p "$FA_DIR"
      mkdir -p "$SNP_DIR"

      # Download refGene for hg38 if not present.
      if [ ! -f "$REFGENE_FILE" ]; then
        echo -e "\n${GREEN}Downloading refGene for hg38...${NC}\n"
        cd "$BASE_DIR"
        wget -N https://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/refGene.txt.gz
        gunzip -f refGene.txt.gz
      fi

      # Download SNP files for hg38 if not present.
      SNP1_FILE="$SNP_DIR/00-common_all.vcf.gz"
      SNP2_FILE="$SNP_DIR/00-common_all.vcf.gz.tbi"
      if [ ! -f "$SNP1_FILE" ] || [ ! -f "$SNP2_FILE" ]; then
        echo -e "\n${GREEN}Downloading SNP files for hg38...${NC}\n"
        cd "$SNP_DIR"
        wget -N https://ftp.ncbi.nih.gov/snp/organisms/human_9606/VCF/00-common_all.vcf.gz
        wget -N https://ftp.ncbi.nih.gov/snp/organisms/human_9606/VCF/00-common_all.vcf.gz.tbi
      fi

      # Download hg38 genome sequence if not present.
      if [ ! -f "$FA_FILE" ]; then
        echo -e "\n${GREEN}Downloading hg38 genome sequence...${NC}\n"
        cd "$FA_DIR"
        wget -N https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/latest/hg38.fa.gz
        gunzip -f hg38.fa.gz
      fi

    elif [ "$GENOME" == "hg18" ]; then
      BASE_DIR="/opt/flumip/data/genomes/human/hg18"
      FA_DIR="$BASE_DIR/fa"
      FA_FILE="$FA_DIR/hg18.fa"
      REFGENE_FILE="$BASE_DIR/refGene.txt"
      mkdir -p "$BASE_DIR"
      mkdir -p "$FA_DIR"

      # Download refGene for hg18 if not present.
      if [ ! -f "$REFGENE_FILE" ]; then
        echo -e "\n${GREEN}Downloading refGene for hg18...${NC}\n"
        cd "$BASE_DIR"
        wget -N https://data.broadinstitute.org/igvdata/annotations/hg18/refGene.txt
      fi

      # Download hg18 genome sequence if not present.
      if [ ! -f "$FA_FILE" ]; then
        echo -e "\n${GREEN}Downloading hg18 genome sequence...${NC}\n"
        cd "$FA_DIR"
        wget -N https://hgdownload.soe.ucsc.edu/goldenPath/hg18/bigZips/hg18.fa.gz
        gunzip -f hg18.fa.gz
      fi

    elif [ "$GENOME" == "hg19" ]; then
      BASE_DIR="/opt/flumip/data/genomes/human/hg19"
      FA_DIR="$BASE_DIR/fa"
      FA_FILE="$FA_DIR/hg19.fa"
      REFGENE_FILE="$BASE_DIR/refGene.txt"
      mkdir -p "$BASE_DIR"
      mkdir -p "$FA_DIR"

      # Download refGene for hg19 if not present.
      if [ ! -f "$REFGENE_FILE" ]; then
        echo -e "\n${GREEN}Downloading refGene for hg19...${NC}\n"
        cd "$BASE_DIR"
        wget -N https://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/refGene.txt.gz
        gunzip -f refGene.txt.gz
      fi

      # Download hg19 genome sequence if not present.
      if [ ! -f "$FA_FILE" ]; then
        echo -e "\n${GREEN}Downloading hg19 genome sequence...${NC}\n"
        cd "$FA_DIR"
        wget -N https://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/hg19.fa.gz
        gunzip -f hg19.fa.gz
      fi

    elif [ "$GENOME" == "hs1" ]; then
      BASE_DIR="/opt/flumip/data/genomes/human/hs1"
      FA_DIR="$BASE_DIR/fa"
      FA_FILE="$FA_DIR/hs1.fa"
      REFGENE_FILE="$BASE_DIR/refGene.txt"
      mkdir -p "$BASE_DIR"
      mkdir -p "$FA_DIR"

      # Download hs1 genome sequence if not present.
      if [ ! -f "$FA_FILE" ]; then
        echo -e "\n${GREEN}Downloading hs1 genome sequence...${NC}\n"
        cd "$FA_DIR"
        wget -N https://hgdownload.soe.ucsc.edu/goldenPath/hs1/bigZips/hs1.fa.gz
        gunzip -f hs1.fa.gz
      fi

      # Generate refGene for hs1 if not present.
      if [ ! -f "$REFGENE_FILE" ]; then
        echo -e "\n${GREEN}Generating refGene for hs1...${NC}\n"
        cd "$BASE_DIR"
        /opt/flumip/tools/bigGenePredToGenePred https://hgdownload.soe.ucsc.edu/gbdb/hs1/ncbiRefSeq/ncbiRefSeq.bb "$BASE_DIR/refWithoutBin.txt"
        # MIPGEN's exon extraction expects refGene.txt's layout, which starts
        # with the UCSC bin column that bigGenePredToGenePred leaves out. Prepend
        # it, computed from txStart/txEnd ($4/$5) by UCSC's binFromRange: the
        # smallest of the 128k, 1M, 8M, 64M or whole-chromosome bins that holds
        # the range. Written beside the target and moved into place, so a
        # failure leaves no refGene.txt for the next run to mistake for done.
        awk -F'\t' -v OFS='\t' '
          function ucsc_bin(start, end,   s, e, i, offsets) {
            split("585 73 9 1 0", offsets, " ")
            s = int(start / 131072); e = int((end - 1) / 131072)
            for (i = 1; i <= 5; i++) {
              if (s == e) return offsets[i] + s
              s = int(s / 8); e = int(e / 8)
            }
            return -1
          }
          /^[[:space:]]*$/ { next }
          {
            if (NF < 5 || $4 !~ /^[0-9]+$/ || $5 !~ /^[0-9]+$/ || (bin = ucsc_bin($4, $5)) < 0) {
              print "refWithoutBin.txt line " NR ": no transcript range to bin" > "/dev/stderr"
              exit 1
            }
            print bin, $0
          }' refWithoutBin.txt > refGene.txt.tmp
        mv refGene.txt.tmp refGene.txt
        rm refWithoutBin.txt
      fi

      # Set up SNP directory for hs1 with the new name and download SNP files.
      SNP_DIR="$BASE_DIR/snp/dbSNPv155"
      mkdir -p "$SNP_DIR"
      SNP1_FILE="$SNP_DIR/chm13v2.0_dbSNPv155.vcf.gz"
      SNP2_FILE="$SNP_DIR/chm13v2.0_dbSNPv155.vcf.gz.tbi"
      if [ ! -f "$SNP1_FILE" ] || [ ! -f "$SNP2_FILE" ]; then
        echo -e "\n${GREEN}Downloading SNP files for hs1...${NC}\n"
        cd "$SNP_DIR"
        wget -N https://hgdownload.soe.ucsc.edu/gbdb/hs1/dbSNP155/chm13v2.0_dbSNPv155.vcf.gz
        wget -N https://hgdownload.soe.ucsc.edu/gbdb/hs1/dbSNP155/chm13v2.0_dbSNPv155.vcf.gz.tbi
      fi

    else
      echo -e "${RED}Invalid genome option: $GENOME. Skipping.${NC}"
    fi
  done
fi

# Set permissions for the service user and maintain current user access
echo -e "\n${GREEN}Setting permissions for service user ${SERVICE_USER}...${NC}\n"
# Check if the service user exists
if id "$SERVICE_USER" &>/dev/null; then
  # Set group to the service user
  sudo chgrp -R "$SERVICE_USER" /opt/flumip
  # Set permissions to allow both owner and group to have full access
  sudo chmod -R 775 /opt/flumip
  # Ensure future files created will inherit the group
  sudo chmod -R g+s /opt/flumip
  # Optionally add the current user to the service user group to ensure continued access
  sudo usermod -a -G "$SERVICE_USER" "$USER"
  echo -e "${GREEN}Full access granted to ${SERVICE_USER} for /opt/flumip${NC}"
  echo -e "${GREEN}Current user ${USER} added to ${SERVICE_USER} group${NC}"
  echo -e "${GREEN}You may need to log out and back in for group changes to take effect${NC}\n"
else
  echo -e "${RED}User ${SERVICE_USER} does not exist. Permissions not changed.${NC}\n"
  exit 1
fi

if $DOWNLOAD; then
  echo -e "\n${GREEN}Setup completed successfully. Reference data is in place for: ${GENOMES[*]}.${NC}\n"
else
  echo -e "\n${GREEN}Setup completed successfully. No reference data was downloaded.${NC}"
  echo -e "Run '${0} --download hg38' (or hg19, hg18, hs1) to fetch a genome, or put"
  echo -e "your own under /opt/flumip/data/genomes/<category>/<name>/ and scan for it in the app.\n"
fi
