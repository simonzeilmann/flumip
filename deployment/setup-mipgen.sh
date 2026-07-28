#!/bin/bash
# setup-mipgen.sh - A script to install dependencies, clone MIPGEN, set up data directories,
# and optionally download required reference files for selected genomes.
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
# Genomes: hg18 hg19 hg38 hs1   (default: hg38)
#
# Examples:
#   ./setup-mipgen.sh                         # interactive on a terminal
#   ./setup-mipgen.sh -download hg38 hg19     # experienced/scripted, no prompts
#   ./setup-mipgen.sh --yes                   # automation: install only, no download

# Exit immediately if a command exits with a non-zero status.
set -e

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
      # Treat as genome name.
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

# If no genomes specified, default to hg38.
if [ ${#GENOMES[@]} -eq 0 ]; then
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
echo -e "\n${GREEN}Installing required packages: build-essential, tabix, samtools, bwa, trf, python-is-python3, acl...${NC}\n"
sudo apt install build-essential tabix samtools bwa trf python-is-python3 acl -y

# Create the mipgen directory and clone the MIPGEN repository.
echo -e "\n${GREEN}Creating '/opt/flumip' directory and cloning MIPGEN repository...${NC}\n"
sudo mkdir -p /opt/flumip
sudo chown $USER:$USER /opt/flumip
cd /opt/flumip
if [ ! -d "MIPGEN" ]; then
  git clone https://github.com/simonzeilmann/MIPGEN.git
fi
cd MIPGEN

echo -e "\n${GREEN}Building MIPGEN...${NC}\n"
make

echo -e "\n${GREEN}Setting execute permissions for MIPGEN tools...${NC}\n"
chmod +x mipgen
chmod +x tools/extract_coding_gene_exons.sh
chmod +x tools/generate_ucsc_track.py
chmod +x tools/add_bins_to_refgene.py
cd ..

# Create the base directory structure.
echo -e "\n${GREEN}Setting up base data directories...${NC}\n"
mkdir -p /opt/flumip/data/genomes/
mkdir -p /opt/flumip/projects
mkdir -p /opt/flumip/tools
mkdir -p /opt/flumip/data/custom_snp/{common,private}

# Download and activate bigGenePredToGenePred (needed for hs1).
echo -e "\n${GREEN}Downloading bigGenePredToGenePred...${NC}\n"
cd /opt/flumip/tools
wget -N http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bigGenePredToGenePred
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
        python /opt/flumip/MIPGEN/tools/add_bins_to_refgene.py refWithoutBin.txt refGene.txt
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

echo -e "\n${GREEN}Setup completed successfully for genomes: ${GENOMES[*]}.${NC}\n"
