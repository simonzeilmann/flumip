#!/bin/bash
# uninstall-flumip.sh - Remove what setup-flumip.sh and setup-mipgen.sh installed.
#
# By default only the software goes, and everything that cannot be downloaded
# again stays where it is:
#
#   removed  - the flumip systemd service, /var/www/flumip, MIPGEN and
#              /opt/flumip/tools
#   kept     - the database, with its password and settings in /etc/flumip,
#              the projects, the genomes and the custom SNP sets
#
# Each kept item has a switch to remove it as well, and --purge removes all of
# them. Reinstalling after a default uninstall picks the kept data up again:
# setup-flumip.sh reconnects to the database with the password it finds in
# /etc/flumip, and setup-mipgen.sh leaves existing genomes alone.
#
# The script has two modes, like the setup scripts:
#   * Interactive      - run with no switches on a terminal and you are asked
#                        which data to remove.
#   * Non-interactive  - pass switches to choose. On a terminal you are still
#                        asked to confirm the summary unless you pass --yes;
#                        without a terminal --yes is required.
#
# Usage:
#   ./uninstall-flumip.sh [options]
#
# Options:
#   --database              Also delete the PostgreSQL container and its volume,
#                           and the install's files in /etc/flumip. A database
#                           given with --db existing is never touched.
#   --projects              Also delete /opt/flumip/projects.
#   --genomes               Also delete /opt/flumip/data/genomes: the reference
#                           data, bwa indexes and built-in SNP sets.
#   --custom-snps           Also delete /opt/flumip/data/custom_snp, the SNP
#                           sets uploaded or imported in the app.
#   --purge                 All four of the above.
#   --packages              Also apt-remove bwa, samtools, tabix and trf.
#                           build-essential, git, wget and acl are left alone:
#                           other software is likely to need them.
#   --keep-mipgen           Keep /opt/flumip/MIPGEN and /opt/flumip/tools.
#   -n, --dry-run           Print what would be removed and change nothing.
#   -i, --interactive       Force interactive prompts even if switches are given.
#   -y, --yes               Never prompt, not even to confirm.
#   -h, --help              Show this help and exit.
#
# Everything under /opt/flumip is shared with any other FLUMIP service on the
# machine (a flumip_<name> unit, such as one from an older installer), so while
# one is there MIPGEN stays and the data switches are refused. Directories
# chosen in Settings → Storage away from /opt/flumip are never touched.
#
# Examples:
#   ./uninstall-flumip.sh                       # interactive
#   ./uninstall-flumip.sh --database            # software and database
#   ./uninstall-flumip.sh --purge --yes         # remove everything, no prompts
#   ./uninstall-flumip.sh --purge --dry-run     # see what that would delete

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Must match setup-flumip.sh and setup-mipgen.sh.
SECRETS_DIR="/etc/flumip"
FLUMIP_ROOT="/opt/flumip"
SERVICE="flumip"
UNIT="$SERVICE.service"
UNIT_FILE="/etc/systemd/system/$UNIT"
TARGET="/var/www/flumip"
SECRETS_FILE="$SECRETS_DIR/passwords.yaml"
CHOICES_FILE="$SECRETS_DIR/setup.conf"
ENV_FILE="$SECRETS_DIR/flumip.env"
DB_CONTAINER="flumip_postgres"
DB_VOLUME="flumip_data"
# Only the tools nothing but FLUMIP is likely to want; see --packages.
PACKAGES=("bwa" "samtools" "tabix" "trf")

REMOVE_DATABASE=false
REMOVE_PROJECTS=false
REMOVE_GENOMES=false
REMOVE_CUSTOM_SNPS=false
REMOVE_PACKAGES=false
KEEP_MIPGEN=false
DRY_RUN=false

INTERACTIVE="auto"
ASSUME_YES=false
SWITCHES_GIVEN=false

usage() {
  # Print the comment header (usage block) without the leading '# ',
  # stopping at the first blank/non-comment line after the shebang.
  awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "$0"
}

die() {
  echo -e "${RED}$1${NC}" >&2
  exit 1
}

# --- Argument parsing --------------------------------------------------------

while [[ $# -gt 0 ]]; do
  case $1 in
    # Accepted so scripts written for the two-environment installer still run.
    --prod|--production) SWITCHES_GIVEN=true ;;
    --staging)
      die "--staging is no longer supported: there is a single FLUMIP install, and
staging is deployed by the project's own CI, not by setup-flumip.sh." ;;
    --database) REMOVE_DATABASE=true; SWITCHES_GIVEN=true ;;
    --projects) REMOVE_PROJECTS=true; SWITCHES_GIVEN=true ;;
    --genomes) REMOVE_GENOMES=true; SWITCHES_GIVEN=true ;;
    --custom-snps) REMOVE_CUSTOM_SNPS=true; SWITCHES_GIVEN=true ;;
    --purge)
      REMOVE_DATABASE=true; REMOVE_PROJECTS=true
      REMOVE_GENOMES=true; REMOVE_CUSTOM_SNPS=true
      SWITCHES_GIVEN=true ;;
    --packages) REMOVE_PACKAGES=true; SWITCHES_GIVEN=true ;;
    --keep-mipgen) KEEP_MIPGEN=true; SWITCHES_GIVEN=true ;;
    -n|--dry-run) DRY_RUN=true ;;
    -i|--interactive) INTERACTIVE="yes" ;;
    -y|--yes|--non-interactive) INTERACTIVE="no"; ASSUME_YES=true ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}" >&2
      echo "Run '$0 --help' for usage." >&2
      exit 1 ;;
  esac
  shift
done

# Decide whether to ask what to remove. Explicit -i/-y always win; otherwise
# ask only when no switches were given and we have a terminal.
if [[ "$INTERACTIVE" == "auto" ]]; then
  if $SWITCHES_GIVEN || [[ ! -t 0 ]]; then
    INTERACTIVE="no"
  else
    INTERACTIVE="yes"
  fi
fi

if [[ "$INTERACTIVE" == "yes" && ! -t 0 ]]; then
  echo -e "${YELLOW}No terminal available for interactive prompts; continuing non-interactively.${NC}"
  INTERACTIVE="no"
fi

# Deleting things is the one place the setup scripts' "no terminal means safe
# defaults" does not carry over: a piped run has to say --yes outright.
if ! $DRY_RUN && ! $ASSUME_YES && [[ ! -t 0 ]]; then
  die "No terminal to confirm on. Pass --yes to uninstall without confirmation, or
--dry-run to see what would be removed."
fi

# --- Interactive helpers ----------------------------------------------------

# Ask a yes/no question. $1 = prompt, $2 = default (y|n). Returns 0 for yes.
prompt_yes_no() {
  local prompt="$1" default="$2" hint reply
  if [[ "$default" == "y" ]]; then hint="[Y/n]"; else hint="[y/N]"; fi
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

# Runs a command, or only prints it with --dry-run.
run() {
  if $DRY_RUN; then
    echo -e "  ${CYAN}would run:${NC} $*"
  else
    "$@"
  fi
}

# --- Preflight --------------------------------------------------------------

command -v sudo >/dev/null 2>&1 || die "Required command not found: sudo"
# $SECRETS_DIR is only traversable by root and the service user, so even
# looking at what is installed needs sudo. Ask for the password now.
sudo -v || die "This script needs sudo to remove the service and its files."

HAVE_DOCKER=false
DOCKER_UNREACHABLE=false
if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    HAVE_DOCKER=true
  else
    DOCKER_UNREACHABLE=true
  fi
fi

# Whether the application is installed: its unit or its install directory.
# Leftover data alone (a kept database) does not count.
app_installed() {
  [[ -f "$UNIT_FILE" ]] || sudo test -d "$TARGET"
}

# Whether anything at all is left, data included, so that a second run can
# still remove a database the first one kept.
install_present() {
  app_installed && return 0
  local file
  for file in "$CHOICES_FILE" "$SECRETS_FILE" "$ENV_FILE"; do
    sudo test -e "$file" && return 0
  done
  if $HAVE_DOCKER; then
    docker ps -a --format '{{.Names}}' | grep -x "$DB_CONTAINER" >/dev/null && return 0
    docker volume ls --format '{{.Name}}' | grep -x "$DB_VOLUME" >/dev/null && return 0
  fi
  return 1
}

# Reads KEY from the remembered choices; echoes nothing if absent.
remembered() {
  sudo test -f "$CHOICES_FILE" || return 0
  sudo awk -F= -v key="$1" '$1 == key { sub(/^[^=]*=/, ""); print; exit }' "$CHOICES_FILE"
}

FOUND=false
install_present && FOUND=true

# Other FLUMIP services on this machine: an install from an older installer
# (flumip_production), or the project's own CI deploys (flumip_staging and
# flumip_production on one host). They use /opt/flumip too, so nothing in it
# may go while there are any. Matched by pattern rather than by name, so this
# script cannot be the one that forgets a kind of install.
OTHER_SERVICES=()
for unit in /etc/systemd/system/flumip_*.service; do
  [[ -f "$unit" ]] || continue
  unit="${unit##*/}"
  OTHER_SERVICES+=("${unit%.service}")
done

# Read now: the file it comes from may be deleted below.
SERVICE_USER="$(remembered SERVICE_USER)"
SERVICE_USER="${SERVICE_USER:-www-data}"

# --- Interactive flow -------------------------------------------------------

if [[ "$INTERACTIVE" == "yes" ]]; then
  echo -e "${GREEN}=== FLUMIP uninstall ===${NC}"
  echo -e "Press Enter to accept the [default] shown in each prompt.\n"

  echo -e "\nThe software is always removed. Data is kept unless you say otherwise."
  prompt_yes_no "Delete the database, its password and its settings?" "n" && REMOVE_DATABASE=true
  prompt_yes_no "Delete the projects in $FLUMIP_ROOT/projects?" "n" && REMOVE_PROJECTS=true
  prompt_yes_no "Delete the genomes in $FLUMIP_ROOT/data/genomes?" "n" && REMOVE_GENOMES=true
  prompt_yes_no "Delete the custom SNP sets in $FLUMIP_ROOT/data/custom_snp?" "n" && REMOVE_CUSTOM_SNPS=true
  prompt_yes_no "apt-remove ${PACKAGES[*]}?" "n" && REMOVE_PACKAGES=true
fi

if [[ ${#OTHER_SERVICES[@]} -gt 0 ]] \
    && { $REMOVE_PROJECTS || $REMOVE_GENOMES || $REMOVE_CUSTOM_SNPS; }; then
  die "${OTHER_SERVICES[*]} is also installed and uses $FLUMIP_ROOT, so its projects,
genomes and SNP sets cannot be deleted. Remove that service first, or leave out
--projects, --genomes, --custom-snps and --purge."
fi

REMOVE_MIPGEN=false
if [[ ${#OTHER_SERVICES[@]} -eq 0 ]] && ! $KEEP_MIPGEN; then
  REMOVE_MIPGEN=true
fi

# --- Summary / confirmation -------------------------------------------------

DB_NOTES=()
echo -e "\n${GREEN}This will remove:${NC}"
if ! $FOUND; then
  echo -e "  FLUMIP is not installed, so there is no service to remove."
else
  echo -e "  service $SERVICE, $TARGET"
  if $REMOVE_DATABASE; then
    if [[ "$(remembered DB_MODE)" == "existing" ]]; then
      DB_NOTES+=("The database at $(remembered DB_HOST):$(remembered DB_PORT)/$(remembered DB_NAME) was not created by setup-flumip.sh and is left alone.")
      echo -e "  $SECRETS_FILE, $CHOICES_FILE, $ENV_FILE (the database itself is external and kept)"
    else
      echo -e "  container $DB_CONTAINER, volume $DB_VOLUME"
      echo -e "  $SECRETS_FILE, $CHOICES_FILE, $ENV_FILE"
    fi
  fi
fi
if $REMOVE_MIPGEN; then
  echo -e "  $FLUMIP_ROOT/MIPGEN and $FLUMIP_ROOT/tools"
fi
$REMOVE_PROJECTS && echo -e "  $FLUMIP_ROOT/projects"
$REMOVE_GENOMES && echo -e "  $FLUMIP_ROOT/data/genomes"
$REMOVE_CUSTOM_SNPS && echo -e "  $FLUMIP_ROOT/data/custom_snp"
$REMOVE_PACKAGES && echo -e "  apt packages: ${PACKAGES[*]}"

echo -e "\n${GREEN}This will keep:${NC}"
KEPT=false
for other in "${OTHER_SERVICES[@]}"; do
  echo -e "  the $other service, which this script does not manage"; KEPT=true
done
if ! $REMOVE_DATABASE && $FOUND; then
  echo -e "  the database, $SECRETS_FILE, $CHOICES_FILE and $ENV_FILE"; KEPT=true
fi
if ! $REMOVE_MIPGEN; then
  echo -e "  $FLUMIP_ROOT/MIPGEN and $FLUMIP_ROOT/tools"; KEPT=true
fi
if ! $REMOVE_PROJECTS; then echo -e "  $FLUMIP_ROOT/projects"; KEPT=true; fi
if ! $REMOVE_GENOMES; then echo -e "  $FLUMIP_ROOT/data/genomes"; KEPT=true; fi
if ! $REMOVE_CUSTOM_SNPS; then echo -e "  $FLUMIP_ROOT/data/custom_snp"; KEPT=true; fi
$KEPT || echo -e "  nothing"
echo ""

for note in "${DB_NOTES[@]}"; do
  echo -e "${YELLOW}${note}${NC}"
done

# Deleting the password while the container it unlocks survives would leave a
# database nobody can log in to, and setup-flumip.sh refuses to reinstall over
# exactly that.
if $REMOVE_DATABASE && $DOCKER_UNREACHABLE; then
  die "Docker is installed but this user cannot reach it, so the database container
cannot be removed. Run as a member of the 'docker' group, or leave out --database
and --purge."
fi

if $DRY_RUN; then
  echo -e "${CYAN}Dry run: nothing below is carried out.${NC}\n"
elif ! $ASSUME_YES; then
  if $REMOVE_DATABASE || $REMOVE_PROJECTS || $REMOVE_GENOMES || $REMOVE_CUSTOM_SNPS; then
    echo -e "${RED}Deleted data cannot be recovered.${NC}"
  fi
  prompt_yes_no "Proceed?" "n" || die "Aborted by user."
fi

# --- Service ----------------------------------------------------------------

if $FOUND; then
  echo -e "\n${GREEN}=== Removing $SERVICE ===${NC}"

  if [[ -f "$UNIT_FILE" ]]; then
    echo -e "${GREEN}Stopping and disabling $UNIT${NC}"
    run sudo systemctl disable --now "$UNIT" || true
    run sudo rm -f "$UNIT_FILE"
    run sudo systemctl daemon-reload
    run sudo systemctl reset-failed "$UNIT" 2>/dev/null || true
  fi

  # .new and .old are what setup-flumip.sh swaps through; an interrupted run
  # can leave either behind.
  for dir in "$TARGET" "$TARGET.new" "$TARGET.old"; do
    if sudo test -e "$dir"; then
      echo -e "${GREEN}Removing $dir${NC}"
      run sudo rm -rf "$dir"
    fi
  done
fi

if $FOUND && $REMOVE_DATABASE; then
  # Only a database setup-flumip.sh created itself. Without the choices file
  # there is no record either way, and a container under this name is the one
  # setup-flumip.sh started.
  if [[ "$(remembered DB_MODE)" != "existing" ]] && $HAVE_DOCKER; then
    if docker ps -a --format '{{.Names}}' | grep -x "$DB_CONTAINER" >/dev/null; then
      echo -e "${GREEN}Removing database container $DB_CONTAINER${NC}"
      run docker rm -f "$DB_CONTAINER"
    fi
    if docker volume ls --format '{{.Name}}' | grep -x "$DB_VOLUME" >/dev/null; then
      echo -e "${GREEN}Removing database volume $DB_VOLUME${NC}"
      run docker volume rm "$DB_VOLUME"
    fi
  fi

  for file in "$SECRETS_FILE" "$CHOICES_FILE" "$ENV_FILE"; do
    if sudo test -e "$file"; then
      echo -e "${GREEN}Removing $file${NC}"
      run sudo rm -f "$file"
    fi
  done
fi

# The directory itself goes once nothing else is left in it.
if sudo test -d "$SECRETS_DIR" && [[ -z "$(sudo ls -A "$SECRETS_DIR")" ]]; then
  run sudo rmdir "$SECRETS_DIR"
fi

# --- /opt/flumip ------------------------------------------------------------

# Projects and SNP sets are written by the service user, so sudo throughout.
remove_dir() {
  if sudo test -e "$1"; then
    echo -e "${GREEN}Removing $1${NC}"
    run sudo rm -rf "$1"
  fi
}

if $REMOVE_MIPGEN; then
  remove_dir "$FLUMIP_ROOT/MIPGEN"
  remove_dir "$FLUMIP_ROOT/tools"
fi
$REMOVE_PROJECTS && remove_dir "$FLUMIP_ROOT/projects"
$REMOVE_GENOMES && remove_dir "$FLUMIP_ROOT/data/genomes"
$REMOVE_CUSTOM_SNPS && remove_dir "$FLUMIP_ROOT/data/custom_snp"

# Then whatever that left empty, deepest first; anything still holding a file
# stays.
for dir in "$FLUMIP_ROOT/data" "$FLUMIP_ROOT"; do
  if sudo test -d "$dir" && [[ -z "$(sudo ls -A "$dir")" ]]; then
    run sudo rmdir "$dir"
  fi
done

# --- Packages ---------------------------------------------------------------

if $REMOVE_PACKAGES; then
  echo -e "\n${GREEN}Removing packages: ${PACKAGES[*]}${NC}\n"
  run sudo apt-get remove -y "${PACKAGES[@]}"
fi

# --- Done -------------------------------------------------------------------

if $DRY_RUN; then
  echo -e "\n${GREEN}Dry run complete. Nothing was changed.${NC}\n"
  exit 0
fi

echo -e "\n${GREEN}Uninstall complete.${NC}\n"

if sudo test -d "$FLUMIP_ROOT"; then
  echo -e "Left in place: $FLUMIP_ROOT"
  sudo ls -A "$FLUMIP_ROOT" | sed 's/^/  /'
  echo ""
fi

# setup-mipgen.sh added the installing user to the service user's group. It
# cannot tell whether they were in it before, so neither can this.
cat <<EOF
setup-mipgen.sh also added your user to the ${SERVICE_USER} group, which this
script leaves alone in case you were a member before. To undo it:

  sudo gpasswd -d ${USER:-$(id -un)} ${SERVICE_USER}

Reverse-proxy and firewall rules you added by hand are not touched either.

EOF
