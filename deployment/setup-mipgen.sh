#!/bin/bash
# setup-mipgen.sh - A script to install dependencies, clone and build upstream MIPGEN,
# install FLUMIP's helper scripts, set up data directories, and optionally
# download required reference files for selected genomes.
# Supported genomes: hg18, hg19, hg38, hs1.
#
# Ownership, and why it is split: the service user may write only the data
# (data/ and projects/). /opt/flumip itself and tools/ belong to root and
# MIPGEN/ to you, writable by nobody else, because you and root run what is in
# them later (git, make, this script), and a file the service could change there
# would be a way from a bug in the server to your account.
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
#   --service-user USER          Service user that writes the data (default: www-data).
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
# The pin lives in mipgen.pin, shared with the Docker image's MIPGEN build.
# shellcheck source=mipgen.pin
. "$SCRIPT_DIR/mipgen.pin"

# The hash bigGenePredToGenePred has to have. ucsc-tools.pin explains why it is
# pinned and what to do when UCSC replaces the file. BIGGENEPRED_SHA256 in the
# environment overrides the pin for one run, so it is saved before the pin is
# sourced over it.
BIGGENEPRED_SHA256_GIVEN="${BIGGENEPRED_SHA256:-}"
# shellcheck source=ucsc-tools.pin
. "$SCRIPT_DIR/ucsc-tools.pin"
BIGGENEPRED_SHA256="${BIGGENEPRED_SHA256_GIVEN:-$BIGGENEPRED_SHA256}"

# Where everything goes. setup-flumip.sh and uninstall-flumip.sh must agree.
FLUMIP_ROOT=/opt/flumip
MIPGEN_DIR="$FLUMIP_ROOT/MIPGEN"
TOOLS_DIR="$FLUMIP_ROOT/tools"

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

# Checked before anything is installed. This used to be checked at the very
# end, after the packages, the build and hours of genome downloads.
if ! id "$SERVICE_USER" &>/dev/null; then
  echo -e "${RED}User ${SERVICE_USER} does not exist. Create it first, or pass --service-user.${NC}\n"
  exit 1
fi

# Update system package repository.
echo -e "\n${GREEN}Updating system packages...${NC}\n"
sudo apt update

# Install required packages.
echo -e "\n${GREEN}Installing required packages: build-essential, git, tabix, samtools, bwa, trf, acl, wget, curl...${NC}\n"
sudo apt install build-essential git tabix samtools bwa trf acl wget curl -y

# --- /opt/flumip itself -----------------------------------------------------

# Root's, and writable by root alone. Earlier installs gave it to the installing
# user with the service user's group, group-writable and setgid, so the service
# could rename MIPGEN/ or tools/ out of the way and put its own in their place.
# Not -R: what is below is sorted out piece by piece further down.
# ⚠️ chmod 755 alone keeps a directory's setgid bit (GNU chmod never clears it
# from a numeric mode), hence the separate g-s, here and below.
echo -e "\n${GREEN}Setting up '${FLUMIP_ROOT}'...${NC}\n"
sudo mkdir -p "$FLUMIP_ROOT"
sudo chown root:root "$FLUMIP_ROOT"
sudo chmod 755 "$FLUMIP_ROOT"
sudo chmod g-s "$FLUMIP_ROOT"

# --- MIPGEN -----------------------------------------------------------------

# Git with nothing from the repository's own configuration that runs a program:
# no hooks, no fsmonitor. Only matters for a tree someone else could write, which
# mipgen_tree_trusted below refuses anyway; this is the second line.
mgit() {
  git -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"
}

# Whether everything in MIPGEN/ belongs to you or root and nobody else can
# write it. Symlinks always show mode 777, so only their owner counts.
mipgen_tree_trusted() {
  [ -z "$(sudo find "$MIPGEN_DIR" \( ! -user "$USER" ! -user root \) -print -quit)" ] \
    && [ -z "$(sudo find "$MIPGEN_DIR" ! -type l -perm /022 -print -quit)" ]
}

# A tree the service user could write is never built on: a planted hook,
# filter, makefile or object file would run as you, at the git checkout or
# `make` below. Every install made before this check has such a tree (group
# www-data, 775, setgid), so this is what an upgrade of one does, once. Nothing
# in the old tree is run, not even git; it is moved aside, cloned afresh, and
# deleted once the new one is built, so a design that is running when this
# happens keeps its files.
MIPGEN_OLD=""
if [ -e "$MIPGEN_DIR" ] && ! mipgen_tree_trusted; then
  MIPGEN_OLD="$MIPGEN_DIR.untrusted.$(date +%Y%m%d%H%M%S)"
  echo -e "${YELLOW}${MIPGEN_DIR} could be written by someone other than you (${USER}) or root,"
  echo -e "as every install before this version left it. Cloning it afresh instead of"
  echo -e "building on it; the old tree is deleted afterwards.${NC}"
  sudo mv "$MIPGEN_DIR" "$MIPGEN_OLD"
fi

echo -e "\n${GREEN}Cloning MIPGEN into ${MIPGEN_DIR}...${NC}\n"
if [ ! -d "$MIPGEN_DIR" ]; then
  # Made by root inside the root-owned /opt/flumip, then handed to you: git and
  # make run as you, never as root, and never as the service user.
  sudo install -d -o "$USER" -g "$(id -gn)" -m 755 "$MIPGEN_DIR"
  git clone -q "$MIPGEN_REPO" "$MIPGEN_DIR"
fi
cd "$MIPGEN_DIR"

# Earlier installs cloned a modified fork. Refuse to build on top of one rather
# than quietly running something other than upstream MIPGEN.
MIPGEN_ORIGIN="$(mgit remote get-url origin 2>/dev/null || true)"
if [ "$MIPGEN_ORIGIN" != "$MIPGEN_REPO" ]; then
  echo -e "${RED}${MIPGEN_DIR} was cloned from ${MIPGEN_ORIGIN:-an unknown source}, not ${MIPGEN_REPO}.${NC}"
  echo -e "${RED}Remove it (sudo rm -rf ${MIPGEN_DIR}) and run this script again.${NC}"
  exit 1
fi

# A clone made before the pin moved may not have the commit yet.
if ! mgit cat-file -e "${MIPGEN_COMMIT}^{commit}" 2>/dev/null; then
  mgit fetch -q origin
fi
mgit -c advice.detachedHead=false checkout -q "$MIPGEN_COMMIT"

# The commit really checked out, in full. mipgen.pin holds the whole id, and
# this makes sure nothing (an abbreviation, a branch or tag of the same name)
# resolved to anything else.
MIPGEN_HEAD="$(mgit rev-parse HEAD)"
if [ "$MIPGEN_HEAD" != "$MIPGEN_COMMIT" ]; then
  echo -e "${RED}MIPGEN is at ${MIPGEN_HEAD} after checking out ${MIPGEN_COMMIT}; not building it.${NC}"
  exit 1
fi
# And every tracked file exactly as committed: MIPGEN is used unmodified, and
# the makefile run below is one of those files.
if [ -n "$(mgit status --porcelain --untracked-files=no)" ]; then
  echo -e "${RED}Files in ${MIPGEN_DIR} differ from MIPGEN ${MIPGEN_COMMIT}:${NC}"
  mgit status --short --untracked-files=no
  echo -e "${RED}Remove it (sudo rm -rf ${MIPGEN_DIR}) and run this script again.${NC}"
  exit 1
fi

echo -e "\n${GREEN}Building MIPGEN...${NC}\n"
# -f makefile, the tracked one: make would prefer an untracked GNUmakefile.
make -f makefile

echo -e "\n${GREEN}Setting execute permissions for MIPGEN tools...${NC}\n"
chmod +x mipgen
chmod +x tools/extract_coding_gene_exons.sh
# Your umask may leave files group-writable (Ubuntu's 002 does). Writable by
# you alone, so that the next run trusts the tree; the service reads and runs it.
chmod -R go-w "$MIPGEN_DIR"
cd "$FLUMIP_ROOT"

if [ -n "$MIPGEN_OLD" ]; then
  sudo rm -rf "$MIPGEN_OLD"
fi

# --- tools/ -----------------------------------------------------------------

# Root's, like /opt/flumip: the service runs these, and fetch-genome.sh runs
# bigGenePredToGenePred.
echo -e "\n${GREEN}Installing FLUMIP helper scripts...${NC}\n"
sudo mkdir -p "$TOOLS_DIR"
sudo chown -R root:root "$TOOLS_DIR"
sudo chmod -R go-w "$TOOLS_DIR"
sudo chmod 755 "$TOOLS_DIR"
sudo chmod -R g-s "$TOOLS_DIR"
sudo install -o root -g root -m 755 "$SCRIPT_DIR/mipgen-trf" "$TOOLS_DIR/mipgen-trf"
# Earlier installs put a Python helper here; its job is now done inline, in awk.
sudo rm -f "$TOOLS_DIR/add_bins_to_refgene.py"

# bigGenePredToGenePred, needed for hs1 only. Installed only if it matches the
# hash in ucsc-tools.pin; that file says why. When it does not (UCSC replaced it,
# or the pin is empty), the rest of the install goes ahead without it, and a
# copy an earlier run installed is left where it is.
BIGGENEPRED_DEST="$TOOLS_DIR/bigGenePredToGenePred"
install_biggenepred() {
  local tmp got
  if [ -n "$BIGGENEPRED_SHA256" ] && [ -f "$BIGGENEPRED_DEST" ] \
      && [ "$(sha256sum < "$BIGGENEPRED_DEST" | cut -d' ' -f1)" = "$BIGGENEPRED_SHA256" ]; then
    echo -e "${GREEN}bigGenePredToGenePred is installed and matches the pinned hash.${NC}"
    return 0
  fi
  tmp="$(mktemp -d)"
  # https only, also after a redirect.
  if ! curl -fsSL --proto '=https' --proto-redir '=https' --tlsv1.2 --retry 3 \
      -o "$tmp/bigGenePredToGenePred" "$BIGGENEPRED_URL"; then
    rm -rf "$tmp"
    echo -e "${YELLOW}⚠️  Could not download bigGenePredToGenePred from ${BIGGENEPRED_URL}.${NC}"
    return 1
  fi
  got="$(sha256sum < "$tmp/bigGenePredToGenePred" | cut -d' ' -f1)"
  if [ -n "$BIGGENEPRED_SHA256" ] && [ "$got" = "$BIGGENEPRED_SHA256" ]; then
    sudo install -o root -g root -m 755 "$tmp/bigGenePredToGenePred" "$BIGGENEPRED_DEST"
    rm -rf "$tmp"
    echo -e "${GREEN}Installed bigGenePredToGenePred (sha256 ${got}).${NC}"
    return 0
  fi
  rm -rf "$tmp"
  if [ -z "$BIGGENEPRED_SHA256" ]; then
    echo -e "${YELLOW}⚠️  ucsc-tools.pin has no hash for bigGenePredToGenePred, so the download"
    echo -e "   cannot be checked and is not installed.${NC}"
  else
    echo -e "${YELLOW}⚠️  The bigGenePredToGenePred UCSC serves now does not match ucsc-tools.pin."
    echo -e "   UCSC replaces it with each release, so this is most likely a new version,"
    echo -e "   but it is not installed unchecked.${NC}"
  fi
  echo -e "${YELLOW}   Downloaded file: sha256 ${got}"
  echo -e "   Only hs1 needs it. If you have checked that file, install it with:"
  echo -e "     BIGGENEPRED_SHA256=${got} $0${NC}"
  return 1
}

echo -e "\n${GREEN}Installing bigGenePredToGenePred...${NC}\n"
if ! install_biggenepred; then
  if [ -f "$BIGGENEPRED_DEST" ]; then
    echo -e "${YELLOW}   Keeping the copy an earlier run installed at ${BIGGENEPRED_DEST}.${NC}"
  elif [[ " ${GENOMES[*]} " == *" hs1 "* ]]; then
    echo -e "${RED}hs1 was asked for, and cannot be set up without bigGenePredToGenePred.${NC}"
    exit 1
  fi
fi

# --- data/ and projects/ ----------------------------------------------------

# The service user's to write, and the only part of /opt/flumip that is. Group
# ${SERVICE_USER}, group-writable and setgid, as before, so that you (added to
# the group below) can still put a genome of your own there.
echo -e "\n${GREEN}Setting up the data directories for ${SERVICE_USER}...${NC}\n"
for dir in "$FLUMIP_ROOT/data" "$FLUMIP_ROOT/data/genomes" "$FLUMIP_ROOT/projects" \
    "$FLUMIP_ROOT/data/custom_snp" "$FLUMIP_ROOT/data/custom_snp/common" \
    "$FLUMIP_ROOT/data/custom_snp/private"; do
  if ! sudo test -d "$dir"; then
    sudo install -d -o "$SERVICE_USER" -g "$SERVICE_USER" -m 2775 "$dir"
  fi
done

# Group write for the service on everything in them. g+rwX rather than the 775
# earlier installs set: that made every genome and result file executable.
fix_data_permissions() {
  local dir
  for dir in "$FLUMIP_ROOT/data" "$FLUMIP_ROOT/projects"; do
    sudo chgrp -R "$SERVICE_USER" "$dir"
    sudo chmod -R g+rwX "$dir"
    sudo find "$dir" -type d -exec chmod g+s {} +
  done
}
fix_data_permissions

# Download genomes if the download flag is set. The downloads themselves live in
# fetch-genome.sh, which the Docker image runs too.
#
# As the service user, as in the Docker image, not as you: these directories
# are the service's to write, so a symlink it had planted there would otherwise
# turn a download of yours into a write anywhere you can write. The script is fed
# on stdin, because your home directory, where it was unpacked, is often closed
# to other users; -H gives wget the service user's home rather than yours.
if $DOWNLOAD; then
  (cd / && sudo -H -u "$SERVICE_USER" bash -s -- --root "$FLUMIP_ROOT" "${GENOMES[@]}") \
    < "$SCRIPT_DIR/fetch-genome.sh"
  fix_data_permissions
fi

# You keep group access to the data, for genomes of your own.
sudo usermod -a -G "$SERVICE_USER" "$USER"
echo -e "${GREEN}${SERVICE_USER} can write ${FLUMIP_ROOT}/data and ${FLUMIP_ROOT}/projects;"
echo -e "MIPGEN and tools/ are read-only to it.${NC}"
echo -e "${GREEN}Current user ${USER} is in the ${SERVICE_USER} group${NC}"
echo -e "${GREEN}You may need to log out and back in for group changes to take effect${NC}\n"

if $DOWNLOAD; then
  echo -e "\n${GREEN}Setup completed successfully. Reference data is in place for: ${GENOMES[*]}.${NC}\n"
else
  echo -e "\n${GREEN}Setup completed successfully. No reference data was downloaded.${NC}"
  echo -e "Run '${0} --download hg38' (or hg19, hg18, hs1) to fetch a genome, or put"
  echo -e "your own under /opt/flumip/data/genomes/<category>/<name>/ and scan for it in the app.\n"
fi
