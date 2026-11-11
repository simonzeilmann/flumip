#!/bin/bash
# setup-flumip.sh - Install and run a FLUMIP server on this machine.
#
# Run this AFTER setup-mipgen.sh, which installs MIPGEN, the reference data and
# the /opt/flumip directory tree. This script covers everything else needed to
# get the app serving:
#
#   1. checks prerequisites (and that setup-mipgen.sh has run)
#   2. downloads a release build (or uses a local tarball) and checks it
#      against the SHA256SUMS published with it
#   3. provisions a PostgreSQL container, with an ordinary role for FLUMIP
#   4. generates config/production.yaml and a passwords.yaml with random secrets,
#      and on a new install a random first settings password
#   5. applies the database migrations
#   6. keeps the internal API and Insights ports to this machine (nftables)
#   7. installs and starts the flumip systemd unit, sandboxed so that it can
#      write only its data directories
#   8. with --pocket-id, installs Pocket ID as this server's own single sign-on
#
# Re-running is safe: an existing database and its generated passwords are
# reused, and the choices made on the first run (hostname, database, service
# user, Pocket ID, firewall, extra writable directories) are remembered in /etc/flumip/setup.conf, so it doubles as an
# updater.
# Any switch given on a re-run replaces the remembered value.
#
# The script has two modes, like setup-mipgen.sh:
#   * Interactive      - run with no switches on a terminal and you are prompted
#                        for the hostname, service user and database setup.
#   * Non-interactive  - pass any switch below (or --yes) to script the run.
#
# Usage:
#   ./setup-flumip.sh [options]
#
# Options:
#   --host HOST             Public hostname clients reach this server on
#                           (default: the previous run's, else localhost).
#   --url URL               Download the build tarball from URL.
#   --file FILE             Use a local build tarball.
#   --release TAG           Install a specific release tag (default: latest).
#   --db docker|existing    Provision a PostgreSQL container, or connect to a
#                           database that already exists (default: docker).
#   --db-host HOST          Database host for --db existing (default: localhost).
#   --db-port PORT          Database port (default: 5432).
#   --db-name NAME          Database name (default: flumip).
#   --db-user USER          Database user (default: flumip; an install made
#                           before this default keeps its postgres).
#   --service-user USER     User the service runs as (default: www-data). It
#                           can read the install dir but not change it.
#   --skip-checksum         Install a build that cannot be checked against a
#                           SHA256SUMS (or .sha256) published with it. Needed
#                           only for a --url without one; see "Build" below.
#   --firewall              Keep the API (9080) and Insights (9081) ports to this
#                           machine with an nftables rule of FLUMIP's own (the
#                           default; needs nft).
#   --no-firewall           Do not, and remove that rule if an earlier run added
#                           it.
#   --writable-dir DIR      Another directory the service may write, for a path
#                           moved away from /opt/flumip in Settings → Storage.
#                           Repeatable; remembered. The service is sandboxed and
#                           can write nowhere else.
#   --pocket-id URL         Also install Pocket ID, a self-hosted single sign-on
#                           provider, reached at URL (e.g. https://id.example.org).
#                           Only for a server with no institutional provider to
#                           sign in with, such as a public instance. See
#                           docs/pocket-id.md.
#   --no-pocket-id          Remove a Pocket ID installed by an earlier run. Its
#                           users and keys stay; uninstall-flumip.sh removes them.
#   --no-migrations         Do not apply database migrations.
#   --no-restart            Install files/unit but do not (re)start the service.
#   -i, --interactive       Force interactive prompts even if switches are given.
#   -y, --yes               Never prompt; use defaults/switches (for automation).
#   -h, --help              Show this help and exit.
#
# With --db existing, the database password is prompted for on a terminal, or
# read from the FLUMIP_DB_PASSWORD environment variable with --yes. It is kept
# off the command line so it never shows up in `ps` or the shell history.
#
# Examples:
#   ./setup-flumip.sh                                  # interactive install
#   ./setup-flumip.sh --yes --host mips.example.org     # scripted install
#   ./setup-flumip.sh --file ./flumip-build.tar.gz      # update from a tarball
#   FLUMIP_DB_PASSWORD=... ./setup-flumip.sh --db existing --db-host 10.0.0.5 --yes
#
# TLS is out of scope: the server listens on plain HTTP and the script prints
# reverse-proxy instructions at the end.

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Release builds are published as flumip-build.tar.gz by the CI release job.
REPO_SLUG="simonzeilmann/flumip"

# PostgreSQL image. Must match the version used elsewhere (dev, test, CI): a
# data volume initialised by one major version is unreadable by another.
POSTGRES_IMAGE="postgres:18"

# The generated passwords file is kept outside the install directory so it
# survives a redeploy that replaces /var/www/flumip wholesale.
SECRETS_DIR="/etc/flumip"

# Serverpod's run mode: it picks config/production.yaml and the production:
# block of passwords.yaml. A Serverpod name, not part of the install's.
MODE="production"

PUBLIC_HOST=""
BUILD_URL=""
BUILD_FILE=""
RELEASE_TAG="latest"
# Left empty here so that a re-run can tell a switch from a default and fill
# the gap from the previous run's choices; the defaults are applied below.
DB_MODE=""
DB_HOST=""
DB_PORT=""
DB_NAME=""
DB_USER=""
SERVICE_USER=""
# "none" for --no-pocket-id, so that it is not mistaken for "not given" and
# filled in again from the previous run's choice.
POCKET_ID_URL=""
MIGRATIONS=true
RESTART=true
SKIP_CHECKSUM=false
# yes|no, empty for "not given" like the database switches above.
FIREWALL=""
# --writable-dir, each given on this run; joined with the remembered ones below.
WRITABLE_DIRS_GIVEN=()
WRITABLE_DIRS=""

# Pocket ID's layout on a bare-metal install. uninstall-flumip.sh must agree.
# The env file sits in $SECRETS_DIR so that backing that up (step 5 of the next
# steps) also covers the key without which Pocket ID's database is unreadable.
POCKET_ID_BIN="/opt/pocket-id/pocket-id"
POCKET_ID_USER="pocket-id"
POCKET_ID_DATA="/var/lib/pocket-id"
POCKET_ID_PORT=1411

INTERACTIVE="auto"
SWITCHES_GIVEN=false

# Temp directories for a downloaded build and Pocket ID; removed on exit.
TMP_DL=""
POCKET_ID_TMP=""
cleanup() {
  local dir
  for dir in "$TMP_DL" "$POCKET_ID_TMP"; do
    if [[ -n "$dir" && -d "$dir" ]]; then
      rm -rf "$dir"
    fi
  done
  return 0
}
trap cleanup EXIT

# Directory this script lives in, so the .service file next to it is found
# regardless of the working directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  # Print the comment header (usage block) without the leading '# ',
  # stopping at the first blank/non-comment line after the shebang.
  awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "$0"
}

die() {
  echo -e "${RED}$1${NC}" >&2
  exit 1
}

# Requires a value for the current option; $1 = option name, $2 = value.
require_value() {
  [[ -n "${2:-}" ]] || die "$1 requires a value"
}

# --- Argument parsing --------------------------------------------------------

while [[ $# -gt 0 ]]; do
  case $1 in
    # Accepted so scripts written for the two-environment installer still run;
    # production is now the only kind of install there is.
    --prod|--production) SWITCHES_GIVEN=true ;;
    --staging)
      die "--staging is no longer supported: the installer sets up a single FLUMIP
install. Staging is deployed by the project's own CI, not by this script." ;;
    --host)
      require_value "$1" "${2:-}"; PUBLIC_HOST="$2"; SWITCHES_GIVEN=true; shift ;;
    --url)
      require_value "$1" "${2:-}"; BUILD_URL="$2"; SWITCHES_GIVEN=true; shift ;;
    --file)
      require_value "$1" "${2:-}"; BUILD_FILE="$2"; SWITCHES_GIVEN=true; shift ;;
    --release)
      require_value "$1" "${2:-}"; RELEASE_TAG="$2"; SWITCHES_GIVEN=true; shift ;;
    --db)
      require_value "$1" "${2:-}"
      case "$2" in
        docker|existing) DB_MODE="$2" ;;
        *) die "--db must be 'docker' or 'existing'" ;;
      esac
      SWITCHES_GIVEN=true; shift ;;
    --db-host)
      require_value "$1" "${2:-}"; DB_HOST="$2"; SWITCHES_GIVEN=true; shift ;;
    --db-port)
      require_value "$1" "${2:-}"; DB_PORT="$2"; SWITCHES_GIVEN=true; shift ;;
    --db-name)
      require_value "$1" "${2:-}"; DB_NAME="$2"; SWITCHES_GIVEN=true; shift ;;
    --db-user)
      require_value "$1" "${2:-}"; DB_USER="$2"; SWITCHES_GIVEN=true; shift ;;
    --service-user)
      require_value "$1" "${2:-}"; SERVICE_USER="$2"; SWITCHES_GIVEN=true; shift ;;
    --pocket-id)
      require_value "$1" "${2:-}"; POCKET_ID_URL="$2"; SWITCHES_GIVEN=true; shift ;;
    --no-pocket-id) POCKET_ID_URL="none"; SWITCHES_GIVEN=true ;;
    --skip-checksum) SKIP_CHECKSUM=true; SWITCHES_GIVEN=true ;;
    --firewall) FIREWALL="yes"; SWITCHES_GIVEN=true ;;
    --no-firewall) FIREWALL="no"; SWITCHES_GIVEN=true ;;
    --writable-dir)
      require_value "$1" "${2:-}"
      [[ "$2" == /* ]] || die "--writable-dir needs an absolute path: $2"
      # Kept colon-separated in setup.conf and space-separated in the unit.
      [[ "$2" =~ ^[A-Za-z0-9._/@+-]+$ ]] \
        || die "--writable-dir: only letters, digits and . _ / @ + - are supported: $2"
      WRITABLE_DIRS_GIVEN+=("${2%/}"); SWITCHES_GIVEN=true; shift ;;
    --no-migrations) MIGRATIONS=false; SWITCHES_GIVEN=true ;;
    --no-restart) RESTART=false; SWITCHES_GIVEN=true ;;
    -i|--interactive) INTERACTIVE="yes" ;;
    -y|--yes|--non-interactive) INTERACTIVE="no" ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}" >&2
      echo "Run '$0 --help' for usage." >&2
      exit 1 ;;
  esac
  shift
done

[[ -n "$BUILD_URL" && -n "$BUILD_FILE" ]] && die "--url and --file are mutually exclusive"

# Decide whether to run interactively. Explicit -i/-y always win; otherwise
# prompt only when no switches were given and we have a terminal.
if [[ "$INTERACTIVE" == "auto" ]]; then
  if $SWITCHES_GIVEN; then
    INTERACTIVE="no"
  elif [[ -t 0 ]]; then
    INTERACTIVE="yes"
  else
    INTERACTIVE="no"
  fi
fi

if [[ "$INTERACTIVE" == "yes" && ! -t 0 ]]; then
  echo -e "${YELLOW}No terminal available for interactive prompts; continuing non-interactively.${NC}"
  INTERACTIVE="no"
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

# Read a value with a default. $1 = prompt, $2 = default. Echoes the answer.
prompt_value() {
  local prompt="$1" default="$2" reply
  read -r -p "$(echo -e "${CYAN}${prompt}${NC} [${default}]: ")" reply || reply=""
  echo "${reply:-$default}"
}

# --- Interactive flow -------------------------------------------------------

if [[ "$INTERACTIVE" == "yes" ]]; then
  echo -e "${GREEN}=== FLUMIP server interactive setup ===${NC}"
  echo -e "Press Enter to accept the [default] shown in each prompt.\n"
fi

SECRETS_FILE="$SECRETS_DIR/passwords.yaml"
CHOICES_FILE="$SECRETS_DIR/setup.conf"
ENV_FILE="$SECRETS_DIR/flumip.env"
INITIAL_PASSWORD_FILE="$SECRETS_DIR/initial-settings-password.env"
# Generated by this script for a sandboxed service; see "systemd" below.
FIREWALL_RULES="$SECRETS_DIR/flumip.nft"
FIREWALL_UNIT="flumip-firewall.service"

# --- Older installs ---------------------------------------------------------

# Installers before the single-install layout named everything flumip_production
# (service, /var/www dir, container, /etc/flumip files). There is no migration:
# such an install holds the same ports and would make this one fail halfway, so
# stop before anything is touched. The project's CI hosts use those names too.
# $SECRETS_DIR is only traversable by root and the service user, hence sudo.
if [[ -f /etc/systemd/system/flumip_production.service ]] \
    || sudo test -f "$SECRETS_DIR/setup_production.conf"; then
  die "This machine has a FLUMIP install from an older installer (flumip_production).
It uses the same ports, and this version does not migrate it. Remove it first
with the uninstall-flumip.sh that came with that release, then re-run this
script. Back up /etc/flumip and the database first if you want to keep them."
fi

# --- Remembered choices -----------------------------------------------------

# A re-run without switches must not quietly reset the install: the generated
# config is rewritten every time, so a forgotten --host would put localhost
# into the redirect URI single sign-on depends on, and a forgotten --db
# existing would start a container next to the real database. Each value the
# previous run settled on fills in whatever this run was not told.
# $SECRETS_DIR is only traversable by root and the service user, hence sudo.
if sudo test -f "$CHOICES_FILE"; then
  echo -e "${GREEN}Using the choices remembered in $CHOICES_FILE${NC}"
  while IFS='=' read -r key value; do
    case "$key" in
      PUBLIC_HOST|DB_MODE|DB_HOST|DB_PORT|DB_NAME|DB_USER|SERVICE_USER|POCKET_ID_URL|FIREWALL)
        [[ -n "${!key}" ]] || printf -v "$key" '%s' "$value" ;;
      # Added to, not replaced: --writable-dir on a re-run adds one more.
      WRITABLE_DIRS) WRITABLE_DIRS="$value" ;;
    esac
  done < <(sudo cat "$CHOICES_FILE")
fi
# Colon-separated in setup.conf; a path with a colon is refused below.
for dir in "${WRITABLE_DIRS_GIVEN[@]}"; do
  [[ ":$WRITABLE_DIRS:" == *":$dir:"* ]] || WRITABLE_DIRS="${WRITABLE_DIRS:+$WRITABLE_DIRS:}$dir"
done

if [[ "$INTERACTIVE" == "yes" ]]; then
  PUBLIC_HOST="$(prompt_value "Public hostname clients will use" "${PUBLIC_HOST:-localhost}")"
  SERVICE_USER="$(prompt_value "Service user" "${SERVICE_USER:-www-data}")"

  if prompt_yes_no "Provision a PostgreSQL container with Docker?" \
      "$([[ "$DB_MODE" == "existing" ]] && echo n || echo y)"; then
    DB_MODE="docker"
  else
    DB_MODE="existing"
    DB_HOST="$(prompt_value "Database host" "${DB_HOST:-localhost}")"
    DB_PORT="$(prompt_value "Database port" "${DB_PORT:-5432}")"
    DB_NAME="$(prompt_value "Database name" "${DB_NAME:-flumip}")"
    DB_USER="$(prompt_value "Database user" "${DB_USER:-flumip}")"
  fi

  if prompt_yes_no "Install Pocket ID as this server's own single sign-on? Only for a
  public instance with no institutional provider to sign in with." \
      "$([[ -n "$POCKET_ID_URL" && "$POCKET_ID_URL" != "none" ]] && echo y || echo n)"; then
    POCKET_ID_URL="$(prompt_value "Address Pocket ID will be reached at" \
      "$([[ "$POCKET_ID_URL" == "none" ]] && echo "" || echo "${POCKET_ID_URL:-https://id.${PUBLIC_HOST}}")")"
  elif [[ -n "$POCKET_ID_URL" ]]; then
    # Declining an earlier choice removes it, as --no-pocket-id does; declining
    # one never made leaves nothing to remove.
    POCKET_ID_URL="none"
  fi

  if prompt_yes_no "Keep the internal API (9080) and Insights (9081) ports to this machine
  with a firewall rule? Only these two ports are touched." \
      "$([[ "$FIREWALL" == "no" ]] && echo n || echo y)"; then
    FIREWALL="yes"
  else
    FIREWALL="no"
  fi
fi

# --- Defaults ---------------------------------------------------------------

PUBLIC_HOST="${PUBLIC_HOST:-localhost}"
SERVICE_USER="${SERVICE_USER:-www-data}"
DB_MODE="${DB_MODE:-docker}"
DB_HOST="${DB_HOST:-localhost}"
DB_NAME="${DB_NAME:-flumip}"
DB_PORT="${DB_PORT:-5432}"
FIREWALL="${FIREWALL:-yes}"
# A new install connects as an ordinary role that owns its database, not as a
# superuser; for --db docker this script creates it (see "Database" below).
# An install that already has its passwords connects as before: every one made
# before this default is postgres, and setup.conf remembers that, but one so old
# that setup.conf has no DB_USER must not be switched over by a missing line.
if [[ -z "$DB_USER" ]] && sudo test -f "$SECRETS_DIR/passwords.yaml"; then
  DB_USER="postgres"
fi
DB_USER="${DB_USER:-flumip}"

# Pocket ID: POCKET_ID_URL set means install or update it, REMOVE_POCKET_ID
# means take away one an earlier run installed, and neither means leave it be.
REMOVE_POCKET_ID=false
if [[ "$POCKET_ID_URL" == "none" ]]; then
  POCKET_ID_URL=""
  REMOVE_POCKET_ID=true
elif [[ -n "$POCKET_ID_URL" ]]; then
  # Passkeys are bound to this domain for good, so a typo here costs every
  # administrator their passkey later. https, or plain http on localhost for a
  # trial; the bare origin, with no path.
  POCKET_ID_URL="${POCKET_ID_URL%/}"
  [[ "$POCKET_ID_URL" =~ ^https://[^/]+$ || "$POCKET_ID_URL" =~ ^http://localhost(:[0-9]+)?$ ]] \
    || die "--pocket-id must be the bare https:// origin Pocket ID will be reached at,
such as https://id.example.org (plain http only for localhost): $POCKET_ID_URL"
fi

# The ports of config/production.yaml, which the app's own URL logic expects
# (installWebPorts in flumip_flutter/lib/api_config.dart).
API_PORT=9080; INSIGHTS_PORT=9081; WEB_PORT=9082

DB_CONTAINER="flumip_postgres"
DB_VOLUME="flumip_data"

TARGET="/var/www/flumip"
SERVICE="flumip"
UNIT="$SERVICE.service"
UNIT_SRC="$SCRIPT_DIR/$UNIT"

# Fall back to the published release when no build source was given.
if [[ -z "$BUILD_URL" && -z "$BUILD_FILE" ]]; then
  if [[ "$RELEASE_TAG" == "latest" ]]; then
    # "latest" is resolved to its tag once, here, so that the tarball and the
    # checksums below come from the same release: two separate latest/download
    # requests could straddle a new release and fetch one file from each.
    # GitHub answers /releases/latest with a redirect to /releases/tag/<tag>.
    LATEST_URL="$(curl -fsSLI --retry 3 -o /dev/null -w '%{url_effective}' \
      "https://github.com/$REPO_SLUG/releases/latest" 2>/dev/null || true)"
    if [[ "$LATEST_URL" == */releases/tag/* ]]; then
      RELEASE_TAG="${LATEST_URL##*/releases/tag/}"
    fi
  fi
  if [[ "$RELEASE_TAG" == "latest" ]]; then
    BUILD_URL="https://github.com/$REPO_SLUG/releases/latest/download/flumip-build.tar.gz"
  else
    BUILD_URL="https://github.com/$REPO_SLUG/releases/download/$RELEASE_TAG/flumip-build.tar.gz"
  fi
fi

# --- Preflight --------------------------------------------------------------

echo -e "\n${GREEN}Checking prerequisites...${NC}"

for cmd in curl tar sudo systemctl openssl; do
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
done

# Ask for the sudo password now rather than partway through the install.
sudo -v || die "This script needs sudo to write /var/www and manage systemd."

if [[ "$DB_MODE" == "docker" ]]; then
  command -v docker >/dev/null 2>&1 \
    || die "Docker is required for --db docker. Install it, or use --db existing."
  docker info >/dev/null 2>&1 \
    || die "Cannot talk to the Docker daemon. Is it running, and are you in the 'docker' group?"
fi

[[ -f "$UNIT_SRC" ]] || die "Missing systemd unit: $UNIT_SRC"

if [[ -n "$POCKET_ID_URL" ]]; then
  [[ -f "$SCRIPT_DIR/pocket-id.pin" ]] || die "Missing $SCRIPT_DIR/pocket-id.pin"
  [[ -f "$SCRIPT_DIR/pocket-id.service" ]] || die "Missing systemd unit: $SCRIPT_DIR/pocket-id.service"
  command -v sha256sum >/dev/null 2>&1 || die "Required command not found: sha256sum"
  # The pin holds the hash of the amd64 build only, which is all FLUMIP runs on.
  [[ "$(uname -m)" == "x86_64" ]] || die "--pocket-id is only supported on x86_64."
fi

id "$SERVICE_USER" &>/dev/null \
  || die "Service user '$SERVICE_USER' does not exist. Create it first, or pass --service-user."

# FLUMIP shells out to MIPGEN and the aligner tools; without them the server
# starts but every job fails. setup-mipgen.sh installs all of this.
MIPGEN_MISSING=()
[[ -x /opt/flumip/MIPGEN/mipgen ]] || MIPGEN_MISSING+=("/opt/flumip/MIPGEN/mipgen")
[[ -d /opt/flumip/projects ]] || MIPGEN_MISSING+=("/opt/flumip/projects")
[[ -d /opt/flumip/data/genomes ]] || MIPGEN_MISSING+=("/opt/flumip/data/genomes")
for tool in bwa samtools tabix; do
  command -v "$tool" >/dev/null 2>&1 || MIPGEN_MISSING+=("$tool")
done

if [[ ${#MIPGEN_MISSING[@]} -gt 0 ]]; then
  echo -e "${YELLOW}setup-mipgen.sh does not look like it has run — missing:${NC}"
  for item in "${MIPGEN_MISSING[@]}"; do
    echo -e "${YELLOW}  - $item${NC}"
  done
  echo -e "${YELLOW}The server will start, but MIP design jobs will fail.${NC}"
  if [[ "$INTERACTIVE" == "yes" ]]; then
    prompt_yes_no "Continue anyway?" "n" || die "Aborted. Run ./setup-mipgen.sh first."
  fi
fi

# --- Summary / confirmation -------------------------------------------------

echo -e "\n${GREEN}Configuration:${NC}"
echo -e "  Install dir:      ${TARGET}"
echo -e "  Service:          ${SERVICE}"
echo -e "  Public hostname:  ${PUBLIC_HOST}"
echo -e "  Server ports:     web ${WEB_PORT} (public) / api ${API_PORT}, insights ${INSIGHTS_PORT} (internal)"
echo -e "  Service user:     ${SERVICE_USER}"
if [[ -n "$BUILD_FILE" ]]; then
  echo -e "  Build:            ${BUILD_FILE}"
else
  echo -e "  Build:            ${BUILD_URL}"
fi
if [[ "$DB_MODE" == "docker" ]]; then
  echo -e "  Database:         ${POSTGRES_IMAGE} container '${DB_CONTAINER}' on port ${DB_PORT}"
else
  echo -e "  Database:         existing at ${DB_HOST}:${DB_PORT}/${DB_NAME} as ${DB_USER}"
fi
if [[ -n "$POCKET_ID_URL" ]]; then
  echo -e "  Pocket ID:        ${POCKET_ID_URL} (service pocket-id on 127.0.0.1:${POCKET_ID_PORT})"
elif $REMOVE_POCKET_ID; then
  echo -e "  Pocket ID:        remove (its data stays in ${POCKET_ID_DATA})"
fi
if [[ "$FIREWALL" == "yes" ]]; then
  echo -e "  Firewall:         ports ${API_PORT} and ${INSIGHTS_PORT} this machine only (--no-firewall to skip)"
else
  echo -e "  Firewall:         none for ports ${API_PORT} and ${INSIGHTS_PORT}"
fi
if [[ -n "$WRITABLE_DIRS" ]]; then
  echo -e "  Also writable:    ${WRITABLE_DIRS//:/ }"
fi
echo -e "  Apply migrations: ${MIGRATIONS}"
echo -e "  Start service:    ${RESTART}"
echo ""

if [[ "$INTERACTIVE" == "yes" ]]; then
  prompt_yes_no "Proceed with this configuration?" "y" || die "Aborted by user."
fi

# --- Build ------------------------------------------------------------------

# Echoes the SHA-256 that checksum file $1 lists for file name $2, or nothing.
# Standard sha256sum output: "<hash>  <name>", or "<hash> *<name>" in binary
# mode, possibly with a directory in front of the name.
checksum_for() {
  awk -v name="$2" '
    { file = $2; sub(/^\*/, "", file); sub(/^.*\//, "", file) }
    # length() rather than {64}: mawk, Debian'"'"'s awk, may not know intervals.
    file == name && length($1) == 64 && $1 ~ /^[0-9a-fA-F]+$/ { print tolower($1); exit }
  ' "$1"
}

# Checks build tarball $1 (named $2 where it was published) against checksum
# file $3. Dies on a mismatch, and on a checksum file that does not list it.
verify_build() {
  local want got
  want="$(checksum_for "$3" "$2")"
  [[ -n "$want" ]] || die "The checksum file published with the build does not list $2.
Not installing it."
  got="$(sha256sum "$1" | cut -d' ' -f1)"
  if [[ "$got" != "$want" ]]; then
    die "The build does not match its published checksum, so it is not installed:
  expected ${want}
  got      ${got}
A truncated download or a changed file both look like this. Download it again;
if it still differs, do not install it."
  fi
  echo -e "${GREEN}Checksum verified (sha256 ${got}).${NC}" >&2
}

# Downloads (if needed), verifies and echoes the path to a build tarball.
#
# The checksums come from the same place as the build: SHA256SUMS, which
# releases publish from the one that brought this check on, else the
# <tarball>.sha256 that releases before it published (v0.8.0 and earlier). That catches a corrupted or truncated download and a mirror or
# proxy that serves something else. It does not protect against someone who can
# replace the release's files on GitHub itself, who could replace both.
#
# With --file, a SHA256SUMS or flumip-build.tar.gz.sha256 next to the tarball
# is used if there is one; download it with the tarball (see the README).
# Without one the file is installed with a warning: it is yours, and you may
# have built it. A download with no checksum to be found is refused, unless
# --skip-checksum says to install it anyway.
fetch_build() {
  local out name base sums="" candidate
  if [[ -n "$BUILD_FILE" ]]; then
    [[ -f "$BUILD_FILE" ]] || die "Build file not found: $BUILD_FILE"
    out="$BUILD_FILE"
    name="$(basename "$BUILD_FILE")"
    for candidate in "$(dirname "$BUILD_FILE")/SHA256SUMS" "$BUILD_FILE.sha256"; do
      if [[ -f "$candidate" ]]; then sums="$candidate"; break; fi
    done
    if [[ -n "$sums" ]]; then
      echo -e "${GREEN}Checking $name against $sums${NC}" >&2
      # A SHA256SUMS lists the tarball under its published name, which a
      # renamed local copy no longer has.
      if [[ -z "$(checksum_for "$sums" "$name")" && -n "$(checksum_for "$sums" flumip-build.tar.gz)" ]]; then
        name="flumip-build.tar.gz"
      fi
      verify_build "$out" "$name" "$sums"
    else
      echo -e "${YELLOW}⚠️  No SHA256SUMS next to $BUILD_FILE, so it is not checked. Download it
   from the same release as the tarball to have it checked.${NC}" >&2
    fi
  else
    out="$TMP_DL/flumip-build.tar.gz"
    name="${BUILD_URL##*/}"
    base="${BUILD_URL%/*}"
    echo -e "${GREEN}Downloading build from $BUILD_URL${NC}" >&2
    # -f fail on HTTP errors, -sS quiet but still report errors, -L follow redirects.
    if ! curl -fsSL --retry 3 -o "$out" "$BUILD_URL" >&2; then
      echo -e "${RED}Download failed: $BUILD_URL${NC}" >&2
      echo -e "${RED}If no release has been published yet, build a tarball and pass --file.${NC}" >&2
      exit 1
    fi
    for candidate in "$base/SHA256SUMS" "$BUILD_URL.sha256"; do
      if curl -fsSL --retry 3 -o "$TMP_DL/checksums" "$candidate" 2>/dev/null; then
        sums="$TMP_DL/checksums"
        echo -e "${GREEN}Checking it against $candidate${NC}" >&2
        break
      fi
    done
    if [[ -n "$sums" ]]; then
      verify_build "$out" "$name" "$sums"
    elif $SKIP_CHECKSUM; then
      echo -e "${YELLOW}⚠️  ⚠️  NO CHECKSUM: neither $base/SHA256SUMS nor $BUILD_URL.sha256
   could be downloaded, and --skip-checksum was given, so this build is
   installed WITHOUT ANY CHECK that it is the file that was published.${NC}" >&2
    else
      die "Found no checksum for this build: neither $base/SHA256SUMS nor
$BUILD_URL.sha256 could be downloaded, so it cannot be checked and is not
installed. Every FLUMIP release publishes one; check the address, or the
network. To install a build from somewhere that publishes none, at your own
risk, pass --skip-checksum."
    fi
  fi

  # Fail before touching the target if the archive is not a usable build.
  tar -tzf "$out" >/dev/null 2>&1 || die "Not a valid .tar.gz archive: $out"
  # Serverpod 4 builds with `dart build cli`, so the executable is
  # bundle/bin/main with its native libraries next to it in bundle/lib/ —
  # not a single top-level `server` binary as it was up to Serverpod 3.
  # ⚠️ Not `grep -q`: it exits at the first match, tar dies of SIGPIPE while
  # still listing, and pipefail turns the match into a failure. A real build
  # is big enough for that to happen every time.
  tar -tzf "$out" | grep -E '(^|/)bundle/bin/main$' >/dev/null \
    || die "Archive contains no 'bundle/bin/main' executable — is this a FLUMIP build?"

  echo "$out"
}

echo -e "\n${GREEN}=== Installing ${SERVICE} ===${NC}"
# ⚠️ Made here, not in fetch_build: that runs in the subshell of the $(...)
# below, so a directory it made would never reach cleanup, and every download
# used to leave its tarball behind in /tmp.
[[ -n "$BUILD_FILE" ]] || TMP_DL="$(mktemp -d)"
BUILD="$(fetch_build)"

# --- Database ---------------------------------------------------------------

# Reads the database password for this environment out of an existing
# passwords.yaml. Echoes nothing when the file or key is absent.
read_db_password() {
  # $SECRETS_DIR is only traversable by root and the service user, so the test
  # has to run under sudo too or it reports a missing file for any other admin.
  sudo test -f "$SECRETS_FILE" || return 0
  # Generated passwords are bare hex; one typed in for --db existing is written
  # single-quoted with '' for a quote, so that is undone here.
  sudo awk -v env="$MODE" -v q="'" '
    /^[a-zA-Z]/ { in_env = ($0 ~ "^" env ":") ; next }
    in_env && $1 == "database:" {
      sub(/^[^:]*: */, "")
      if (length($0) >= 2 && substr($0, 1, 1) == q && substr($0, length($0), 1) == q) {
        $0 = substr($0, 2, length($0) - 2)
        gsub(q q, q)
      }
      print; exit
    }
  ' "$SECRETS_FILE"
}

DB_PASSWORD="$(read_db_password)"
REUSED_SECRETS=false
if [[ -n "$DB_PASSWORD" ]]; then
  REUSED_SECRETS=true
  echo -e "${GREEN}Reusing existing credentials from $SECRETS_FILE${NC}"
elif [[ "$DB_MODE" == "existing" ]]; then
  # A database that already exists already has a password; making one up here
  # would only fail at the migrations, with an error about logging in.
  DB_PASSWORD="${FLUMIP_DB_PASSWORD:-}"
  if [[ -z "$DB_PASSWORD" && "$INTERACTIVE" == "yes" ]]; then
    read -r -s -p "$(echo -e "${CYAN}Password for ${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}${NC}: ")" DB_PASSWORD || true
    echo
  fi
  [[ -n "$DB_PASSWORD" ]] || die "--db existing needs the database password. Set FLUMIP_DB_PASSWORD, or run
the script on a terminal without --yes to be asked for it."
else
  # base64 would include '/' and '+', which complicate YAML and URLs.
  DB_PASSWORD="$(openssl rand -hex 24)"
fi
SERVICE_SECRET="$(openssl rand -hex 32)"

DB_CONTAINER_CREATED=false

if [[ "$DB_MODE" == "docker" ]]; then
  # >/dev/null rather than grep -q, for the SIGPIPE reason in fetch_build.
  if docker ps -a --format '{{.Names}}' | grep -x "$DB_CONTAINER" >/dev/null; then
    echo -e "${GREEN}Database container $DB_CONTAINER already exists; starting it if stopped.${NC}"
    docker start "$DB_CONTAINER" >/dev/null
    if ! $REUSED_SECRETS; then
      die "$DB_CONTAINER exists but $SECRETS_FILE has no password for it.
Either restore that file, or remove the container and its volume to start over:
  docker rm -f $DB_CONTAINER && docker volume rm $DB_VOLUME"
    fi
  else
    echo -e "${GREEN}Starting $POSTGRES_IMAGE container $DB_CONTAINER on 127.0.0.1:$DB_PORT${NC}"
    # The volume mounts at /var/lib/postgresql, NOT /var/lib/postgresql/data:
    # postgres:18 sets PGDATA=/var/lib/postgresql/18/docker, so mounting the
    # old path would leave the data in the container's writable layer and lose
    # it on the next `docker rm`. Matches flumip_server/docker-compose.yaml.
    # Published on 127.0.0.1 only: Docker's iptables rules bypass ufw, so a
    # bare -p would expose the database on every interface.
    #
    # The image's own user is always the superuser postgres. FLUMIP connects as
    # $DB_USER, an ordinary role created below that owns the database: that is
    # all Serverpod's migrations need, as FLUMIP's create no extensions. The
    # superuser's password is random and kept nowhere. Nothing needs it: on
    # this machine `docker exec $DB_CONTAINER psql -U postgres` comes in over
    # the container's local socket, which the image trusts. Only when
    # --db-user postgres is asked for outright does FLUMIP get the superuser,
    # as every install did before.
    if [[ "$DB_USER" == "postgres" ]]; then
      DB_SUPERUSER_PASSWORD="$DB_PASSWORD"
    else
      # Created with CREATE ROLE below; kept to a plain name so that it reads
      # the same everywhere it is written (passwords.yaml, setup.conf, psql).
      [[ "$DB_USER" =~ ^[a-z_][a-z0-9_]{0,62}$ ]] \
        || die "--db-user must be a plain lower-case name for --db docker: $DB_USER"
      DB_SUPERUSER_PASSWORD="$(openssl rand -hex 24)"
    fi
    docker run -d \
      --name "$DB_CONTAINER" \
      --restart unless-stopped \
      -e POSTGRES_USER=postgres \
      -e POSTGRES_PASSWORD="$DB_SUPERUSER_PASSWORD" \
      -e POSTGRES_DB="$DB_NAME" \
      -v "$DB_VOLUME":/var/lib/postgresql \
      -p "127.0.0.1:$DB_PORT":5432 \
      "$POSTGRES_IMAGE" >/dev/null
    DB_CONTAINER_CREATED=true
  fi
  DB_HOST="127.0.0.1"

  # A fresh container runs initdb on a socket-only server before it listens on
  # TCP, which takes several seconds. The migrations would ride that out with
  # Serverpod's own retry, but only after printing a connection error and a
  # stack trace at a first-time user, so wait for the real server instead.
  echo -e "${GREEN}Waiting for PostgreSQL to accept connections...${NC}"
  for _ in $(seq 1 60); do
    docker exec "$DB_CONTAINER" pg_isready -q -h 127.0.0.1 -U "$DB_USER" && break
    sleep 1
  done

  # Only for a container this run created. One that was already there is left
  # exactly as it is: on an upgrade FLUMIP keeps connecting as the role it
  # always has, and the README says how to move an older install off the
  # superuser by hand.
  if $DB_CONTAINER_CREATED && [[ "$DB_USER" != "postgres" ]]; then
    echo -e "${GREEN}Creating database role $DB_USER, owner of $DB_NAME${NC}"
    # The password reaches psql through the environment (docker exec -e NAME
    # copies it from this one), never on a command line, where ps would show it.
    if ! FLUMIP_DB_ROLE="$DB_USER" FLUMIP_DB_ROLE_PASSWORD="$DB_PASSWORD" FLUMIP_DB_ROLE_DB="$DB_NAME" \
        docker exec -i -e FLUMIP_DB_ROLE -e FLUMIP_DB_ROLE_PASSWORD -e FLUMIP_DB_ROLE_DB \
          "$DB_CONTAINER" psql -q -v ON_ERROR_STOP=1 -U postgres -d "$DB_NAME" >/dev/null <<'SQL'
\getenv role FLUMIP_DB_ROLE
\getenv pw FLUMIP_DB_ROLE_PASSWORD
\getenv db FLUMIP_DB_ROLE_DB
CREATE ROLE :"role" LOGIN PASSWORD :'pw';
ALTER DATABASE :"db" OWNER TO :"role";
SQL
    then
      die "Could not create the database role $DB_USER. Remove the new container and
its volume, then re-run:
  docker rm -f $DB_CONTAINER && docker volume rm $DB_VOLUME"
    fi
  fi
fi

# --- Install files ----------------------------------------------------------

if $RESTART && systemctl is-active --quiet "${SERVICE}"; then
  echo -e "${GREEN}Stopping ${SERVICE} before replacing the build...${NC}"
  sudo systemctl stop "${SERVICE}"
fi

# Extract into a fresh directory and swap it in, rather than over the old
# tree: files a newer build no longer ships (old web assets, an old executable)
# would otherwise pile up, and a failed extraction would leave a half-replaced
# install. Nothing under $TARGET needs keeping: the config is regenerated
# below and the secrets live in $SECRETS_DIR.
echo -e "${GREEN}Extracting build to $TARGET${NC}"
sudo rm -rf "$TARGET.new" "$TARGET.old"
sudo mkdir -p "$TARGET.new"
# Root's, and read-only to everyone else, the service included: it runs this
# program, so it must not be able to change it. Extracted without the archive's
# owners (the release runner's uid) and modes, then normalised.
sudo tar --no-same-owner --no-same-permissions -xzf "$BUILD" -C "$TARGET.new"
sudo chown -R root:root "$TARGET.new"
sudo chmod -R u+rwX,go+rX,go-w "$TARGET.new"
sudo chmod 755 "$TARGET.new/bundle/bin/main"
if sudo test -d "$TARGET"; then
  sudo mv "$TARGET" "$TARGET.old"
fi
sudo mv "$TARGET.new" "$TARGET"
sudo rm -rf "$TARGET.old"

# --- Config -----------------------------------------------------------------

# The config shipped in the build points at the upstream project's domains, so
# it is replaced wholesale with one describing this machine.
echo -e "${GREEN}Writing config/${MODE}.yaml${NC}"
sudo tee "$TARGET/config/${MODE}.yaml" >/dev/null <<EOF
# Generated by setup-flumip.sh for host '${PUBLIC_HOST}'.
# Re-running the script overwrites this file.

# Internal only: the web server answers the API under /api on its own port.
apiServer:
  port: ${API_PORT}
  publicHost: localhost
  publicPort: ${API_PORT}
  publicScheme: http

insightsServer:
  port: ${INSIGHTS_PORT}
  publicHost: ${PUBLIC_HOST}
  publicPort: ${INSIGHTS_PORT}
  publicScheme: http

webServer:
  port: ${WEB_PORT}
  publicHost: ${PUBLIC_HOST}
  publicPort: ${WEB_PORT}
  publicScheme: http

database:
  host: ${DB_HOST}
  port: ${DB_PORT}
  name: ${DB_NAME}
  user: ${DB_USER}
  requireSsl: false

redis:
  enabled: false
  host: localhost
  port: 6379
EOF

# passwords.yaml is gitignored and never shipped in a build, so it is generated
# here and kept in $SECRETS_DIR to survive a redeploy of $TARGET.
if ! $REUSED_SECRETS; then
  echo -e "${GREEN}Generating $SECRETS_FILE${NC}"
  sudo mkdir -p "$SECRETS_DIR"
  sudo chmod 750 "$SECRETS_DIR"
  sudo tee "$SECRETS_FILE" >/dev/null <<EOF
# Generated by setup-flumip.sh. Keep this file secret and back it up: the
# database password below is the only copy.
shared:
  mySharedPassword: $(openssl rand -hex 16)

${MODE}:
  database: '${DB_PASSWORD//\'/\'\'}'
  serviceSecret: ${SERVICE_SECRET}
EOF
  sudo chown root:"$SERVICE_USER" "$SECRETS_FILE"
  sudo chmod 640 "$SECRETS_FILE"
fi

sudo cp "$SECRETS_FILE" "$TARGET/config/passwords.yaml"

# Remembered for the next run; see "Remembered choices" above.
sudo tee "$CHOICES_FILE" >/dev/null <<EOF
PUBLIC_HOST=${PUBLIC_HOST}
DB_MODE=${DB_MODE}
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
SERVICE_USER=${SERVICE_USER}
POCKET_ID_URL=${POCKET_ID_URL}
FIREWALL=${FIREWALL}
WRITABLE_DIRS=${WRITABLE_DIRS}
EOF
sudo chmod 640 "$CHOICES_FILE"

# The example issuer in a new flumip.env: Pocket ID's own address when this run
# installs it, so the line only needs uncommenting.
OIDC_ISSUER_EXAMPLE="${POCKET_ID_URL:-https://login.example.org/realms/staff}"

# Optional runtime configuration, read by the systemd unit's EnvironmentFile.
#
# Lives in $SECRETS_DIR rather than under $TARGET so that redeploying the build
# does not wipe it, and every key ships commented out so the file documents what
# is available without changing any behaviour. Never overwritten: an admin who has
# configured single sign-on here must not lose it on a re-run.
if sudo test -f "$ENV_FILE"; then
  echo -e "${GREEN}Keeping existing $ENV_FILE${NC}"
else
  echo -e "${GREEN}Creating $ENV_FILE${NC}"
  sudo mkdir -p "$SECRETS_DIR"
  sudo chmod 750 "$SECRETS_DIR"
  sudo tee "$ENV_FILE" >/dev/null <<EOF
# Optional runtime settings for ${SERVICE}, read by systemd.
# Generated by setup-flumip.sh; never overwritten on a re-run. Apply changes with
#   sudo systemctl restart ${SERVICE}
#
# Everything here is optional. FLUMIP runs with no authentication at all by
# default, which is the standard deployment — leave this file untouched and
# nothing changes.
#
# Anything set here overrides the equivalent setting in the admin Settings tab,
# and the tab shows such a field as read-only. See docs/authentication.md.

# --- Single sign-on (OpenID Connect) ---------------------------------------
# Turns sign-in on or off regardless of the stored setting, so it also works as
# the way back in if a misconfiguration ever locks you out.
#FLUMIP_AUTH_ENABLED=true

# Without a trailing slash; /.well-known/openid-configuration is appended.
#FLUMIP_OIDC_ISSUER=${OIDC_ISSUER_EXAMPLE}
#FLUMIP_OIDC_CLIENT_ID=flumip
#FLUMIP_OIDC_CLIENT_SECRET=

# Comma-separated. Leave unset to allow every account the provider authenticates.
#FLUMIP_OIDC_ALLOWED_DOMAINS=example.org
# Comma-separated. These accounts can open the Settings tab without the password.
#FLUMIP_OIDC_ADMIN_EMAILS=you@example.org
# The claim carrying group membership, e.g. groups or realm_access.roles. Leave
# unset to not use departments at all. See docs/authorization.md.
#FLUMIP_OIDC_DEPARTMENT_CLAIM=groups

# The address the browser actually uses. Required once a reverse proxy terminates
# TLS in front of this server, because the redirect URI is derived from it and
# must match what is registered with your provider exactly.
#FLUMIP_PUBLIC_URL=https://${PUBLIC_HOST}

# By default an incomplete or unreachable single sign-on configuration is *not*
# enforced, so a half-finished setup cannot lock everyone out. Set this to refuse
# requests instead.
#FLUMIP_AUTH_STRICT=false

# A public instance: anonymous visitors accept a notice and see only their own
# projects, which expire. Overrides the Settings tab in both directions, so
# =false is also the way back in. See docs/public-instance.md.
#FLUMIP_PUBLIC_MODE=true
EOF
  sudo chown root:"$SERVICE_USER" "$ENV_FILE"
  sudo chmod 640 "$ENV_FILE"
fi

# The first settings password of a new install. The server takes it from
# FLUMIP_INITIAL_SETTINGS_PASSWORD only when it creates its settings row, on the
# first start against an empty database, and never again; without it the server
# makes up one of its own and writes it to the journal. Earlier installs started
# with the well-known 'changeme' instead.
#
# Only for a new install (no passwords.yaml yet): an upgrade generates and prints
# nothing. Its own file rather than flumip.env, which the service user can read
# and admins edit: this one is root's alone, and systemd reads it as root. Kept
# after the first start so the password can still be looked up with sudo until
# it has been changed; after that it is inert, and can be deleted.
INITIAL_SETTINGS_PASSWORD=""
if ! $REUSED_SECRETS; then
  if sudo test -f "$INITIAL_PASSWORD_FILE"; then
    # Left by a first run that stopped partway; the database may already hold it.
    INITIAL_SETTINGS_PASSWORD="$(sudo sed -n 's/^FLUMIP_INITIAL_SETTINGS_PASSWORD=//p' "$INITIAL_PASSWORD_FILE")"
  else
    # 12 bytes as hex: 24 characters, typed once and then changed.
    INITIAL_SETTINGS_PASSWORD="$(openssl rand -hex 12)"
    echo -e "${GREEN}Creating $INITIAL_PASSWORD_FILE${NC}"
    (umask 077; sudo tee "$INITIAL_PASSWORD_FILE" >/dev/null) <<EOF
# The first settings password of this FLUMIP install, generated by
# setup-flumip.sh. Read by systemd for the ${SERVICE} service, and used by the
# server only when it creates its settings, on its very first start. Change the
# password in the Settings tab; this file can be deleted after that.
FLUMIP_INITIAL_SETTINGS_PASSWORD=${INITIAL_SETTINGS_PASSWORD}
EOF
    sudo chown root:root "$INITIAL_PASSWORD_FILE"
    sudo chmod 600 "$INITIAL_PASSWORD_FILE"
  fi
fi

# The install stays root's (see "Install files"). Earlier versions gave the whole
# of it to the service user, which let it rewrite its own executable; the fresh
# extraction above already undoes that on an upgrade. The one file the service
# has to read that others must not is its passwords.
sudo chown root:"$SERVICE_USER" "$TARGET/config/passwords.yaml"
sudo chmod 640 "$TARGET/config/passwords.yaml"

# --- Migrations -------------------------------------------------------------

# Serverpod does not apply migrations on a normal start, so a fresh database has
# no tables. The maintenance role applies them and exits, retrying the
# connection a few times in case the container is still starting up.
if $MIGRATIONS; then
  echo -e "${GREEN}Applying database migrations...${NC}"
  # The first settings password goes along, through the environment rather than
  # the command line, in case anything in this run creates the settings row.
  MIGRATE_SUDO=(sudo -u "$SERVICE_USER")
  if [[ -n "$INITIAL_SETTINGS_PASSWORD" ]]; then
    export FLUMIP_INITIAL_SETTINGS_PASSWORD="$INITIAL_SETTINGS_PASSWORD"
    MIGRATE_SUDO=(sudo --preserve-env=FLUMIP_INITIAL_SETTINGS_PASSWORD -u "$SERVICE_USER")
  fi
  if ! "${MIGRATE_SUDO[@]}" sh -c "cd '$TARGET' && ./bundle/bin/main \
      --mode='$MODE' \
      --server-id='$MODE' \
      --role=maintenance \
      --apply-migrations \
      --logging=normal"; then
    die "Applying migrations failed. The service was not started.
Check the database is reachable at ${DB_HOST}:${DB_PORT} and that the password
in $SECRETS_FILE is right, then re-run, or pass --no-migrations to skip this step."
  fi
  unset FLUMIP_INITIAL_SETTINGS_PASSWORD
fi

# --- Where the service may write --------------------------------------------

# The unit sandboxes the service (see flumip.service): the whole file system is
# read-only to it except for the directories listed in its ReadWritePaths=, so
# these have to be exactly the ones it writes. From the server's code those are
# the three Storage settings: the projects (each design's files), the genomes
# (bwa and samtools write their indexes next to each FASTA, and the index build
# its log) and the custom SNP sets (uploads, imports, tabix indexes). Temporary
# files go to its own private /tmp. Nothing else, in particular not the install
# directory or its own configuration.
#
# The settings live in the database and can be changed in Settings → Storage,
# so they are read from there when that is possible, and --writable-dir adds any
# the script cannot see. A missing directory does not stop the service
# starting (the leading - in the unit), but it cannot be created later either:
# after moving a directory in the Settings tab, re-run this script.
STORAGE_DEFAULTS=("/opt/flumip/projects" "/opt/flumip/data/genomes" "/opt/flumip/data/custom_snp")

# Prints the stored settings row's paths: projects, genomes, custom SNPs,
# tools, then the three executables, separated by the ASCII unit separator
# (a tab would collapse an empty field when read back). Nothing when it cannot be read,
# which on a new install, before the server's first start, is always.
stored_settings_paths() {
  local sql='SELECT "projectDir", "genomeDir", "customSnpDir", "toolsDir", "mipgenExecutable", "exonExtractScript", "bigGenePredToGenePredExecutable" FROM settings ORDER BY id LIMIT 1'
  if [[ "$DB_MODE" == "docker" ]]; then
    docker exec "$DB_CONTAINER" psql -X -q -t -A -F $'\x1f' -U "$DB_USER" -d "$DB_NAME" \
      -c "$sql" 2>/dev/null || true
  elif command -v psql >/dev/null 2>&1; then
    PGPASSWORD="$DB_PASSWORD" PGCONNECT_TIMEOUT=10 psql -X -q -t -A -F $'\x1f' \
      -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$sql" 2>/dev/null || true
  fi
}

STORED_PATHS="$(stored_settings_paths | head -n 1)"
WRITE_CANDIDATES=("${STORAGE_DEFAULTS[@]}")
OTHER_PATHS=()
if [[ -n "$STORED_PATHS" ]]; then
  IFS=$'\x1f' read -r s_projects s_genomes s_custom s_tools s_mipgen s_exon s_bgp <<<"$STORED_PATHS"
  WRITE_CANDIDATES+=("$s_projects" "$s_genomes" "$s_custom")
  OTHER_PATHS+=("$s_tools" "$s_mipgen" "$s_exon" "$s_bgp")
elif [[ "$DB_MODE" == "existing" ]] && ! command -v psql >/dev/null 2>&1 && $REUSED_SECRETS; then
  echo -e "${YELLOW}psql is not installed, so the Storage paths in the database cannot be read.
If you moved any away from /opt/flumip in the Settings tab, pass --writable-dir
for each, or the service will not be able to write there.${NC}"
fi
if [[ -n "$WRITABLE_DIRS" ]]; then
  IFS=':' read -r -a extra_dirs <<<"$WRITABLE_DIRS"
  WRITE_CANDIDATES+=("${extra_dirs[@]}")
fi

# A data directory may lead elsewhere through a symlink (a genome on a bigger
# disk, say), and the sandbox would keep that place read-only. The links in the
# top few levels are followed, which covers <category>/<genome>/fa.
for dir in "${WRITE_CANDIDATES[@]}"; do
  if [[ -z "$dir" ]] || ! sudo test -d "$dir"; then continue; fi
  WRITE_CANDIDATES+=("$(sudo readlink -f "$dir")")
  while IFS= read -r -d '' link; do
    target="$(sudo readlink -f "$link" || true)"
    if [[ -n "$target" ]] && sudo test -d "$target"; then
      WRITE_CANDIDATES+=("$target")
    fi
  done < <(sudo find "$dir" -maxdepth 3 -type l -print0 2>/dev/null)
done

# Deduplicated, and kept to paths that are safe to write into a unit file. The
# whole of a system directory is never made writable: that would undo the
# sandbox.
WRITE_PATHS=()
for dir in "${WRITE_CANDIDATES[@]}"; do
  dir="${dir%/}"
  [[ -n "$dir" ]] || continue
  if [[ ! "$dir" =~ ^/[A-Za-z0-9._/@+-]*$ ]]; then
    echo -e "${YELLOW}⚠️  Not making '$dir' writable for the service: it has characters the unit
   file cannot hold. Move it to a plain path.${NC}"
    continue
  fi
  case "$dir" in
    ""|/usr|/usr/*|/etc|/etc/*|/boot|/boot/*|/bin|/sbin|/lib|/lib64|/var|/opt|/home|/root|/proc|/sys|/dev|/run)
      echo -e "${YELLOW}⚠️  Not making '${dir:-/}' writable for the service: a system directory.${NC}"
      continue ;;
  esac
  [[ " ${WRITE_PATHS[*]} " == *" $dir "* ]] || WRITE_PATHS+=("$dir")
done

# ProtectHome=yes hides /home, /root and /run/user from the service entirely.
# Should anything it uses be in there, they become read-only instead, which
# ReadWritePaths= can then open up where needed.
PROTECT_HOME="yes"
for path in "${WRITE_PATHS[@]}" "${OTHER_PATHS[@]}"; do
  case "$path" in
    /home/*|/root/*|/run/user/*) PROTECT_HOME="read-only" ;;
  esac
done

READ_WRITE_LINE="ReadWritePaths="
for dir in "${WRITE_PATHS[@]}"; do
  READ_WRITE_LINE+="-${dir} "
done
READ_WRITE_LINE="${READ_WRITE_LINE% }"

# --- Firewall (optional) ----------------------------------------------------

# Serverpod 4.1.1 binds all three of its servers to every address, with no
# setting to change that (InternetAddress.anyIPv6 in its server.dart and
# web_server.dart), and systemd's IPAddressDeny= applies to all of a unit's
# traffic, not to one port. So the internal API and Insights ports are kept to
# this machine by a firewall rule. Insights in particular is Serverpod's
# administration interface.
#
# Lockout-safe by construction: the rules sit in a table of FLUMIP's own
# (inet flumip) and do one thing, reject TCP to these two ports unless it comes
# from this machine. They never accept anything, so they cannot open what
# another firewall closes, and they never touch any other port, SSH included.
# A separate unit applies them, ordered after the distribution's firewall so a
# reload of that does not leave FLUMIP's out, and before flumip itself.
# `sudo systemctl stop flumip-firewall` takes them away at once; --no-firewall
# removes them for good.
NFT=""
for candidate in /usr/sbin/nft /sbin/nft /usr/bin/nft; do
  if [[ -x "$candidate" ]]; then NFT="$candidate"; break; fi
done

if [[ "$FIREWALL" == "yes" ]]; then
  if [[ -z "$NFT" ]]; then
    echo -e "${YELLOW}⚠️  nft is not installed, so ports ${API_PORT} and ${INSIGHTS_PORT} are not firewalled.
   Install the nftables package (without enabling nftables.service, whose
   default ruleset flushes every other firewall) and re-run, or firewall
   them yourself, or pass --no-firewall to stop this warning.${NC}"
  else
    echo -e "${GREEN}Keeping ports ${API_PORT} and ${INSIGHTS_PORT} to this machine (${FIREWALL_UNIT})${NC}"
    sudo mkdir -p "$SECRETS_DIR"
    sudo tee "$FIREWALL_RULES" >/dev/null <<EOF
#!${NFT} -f
# Generated by setup-flumip.sh, applied by ${FIREWALL_UNIT}. Re-running the
# script overwrites this file; --no-firewall removes it.
#
# FLUMIP's internal API (${API_PORT}) and Insights (${INSIGHTS_PORT}) ports
# answer this machine only. Nothing else is matched, and nothing is accepted:
# whatever other firewall runs here still decides everything else.

# Replaces the table as a whole, so applying the file twice leaves one copy.
table inet flumip
delete table inet flumip

table inet flumip {
  chain input {
    type filter hook input priority -10; policy accept;
    iifname "lo" return
    tcp dport { ${API_PORT}, ${INSIGHTS_PORT} } reject with tcp reset
  }
}
EOF
    sudo chmod 644 "$FIREWALL_RULES"
    sudo tee "/etc/systemd/system/$FIREWALL_UNIT" >/dev/null <<EOF
# Generated by setup-flumip.sh; see ${FIREWALL_RULES}.
[Unit]
Description=Firewall for FLUMIP's internal ports (${API_PORT}, ${INSIGHTS_PORT})
# Ordering only: it needs none of these, but must come after any that replace
# the whole ruleset, and before the server opens the ports.
After=nftables.service ufw.service firewalld.service
Before=${UNIT}

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=${NFT} -f ${FIREWALL_RULES}
ExecReload=${NFT} -f ${FIREWALL_RULES}
ExecStop=-${NFT} delete table inet flumip

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable "$FIREWALL_UNIT" >/dev/null 2>&1
    if ! sudo systemctl restart "$FIREWALL_UNIT"; then
      echo -e "${YELLOW}⚠️  ${FIREWALL_UNIT} failed; ports ${API_PORT} and ${INSIGHTS_PORT} are not firewalled.
   See: journalctl -u ${FIREWALL_UNIT}${NC}"
    fi
  fi
elif [[ -f "/etc/systemd/system/$FIREWALL_UNIT" ]] || sudo test -f "$FIREWALL_RULES"; then
  echo -e "${GREEN}Removing ${FIREWALL_UNIT} (--no-firewall)${NC}"
  sudo systemctl disable --now "$FIREWALL_UNIT" 2>/dev/null || true
  sudo rm -f "/etc/systemd/system/$FIREWALL_UNIT" "$FIREWALL_RULES"
  sudo systemctl daemon-reload
fi

# --- systemd ----------------------------------------------------------------

echo -e "${GREEN}Installing systemd unit $UNIT${NC}"
echo -e "  writable for ${SERVICE_USER}: ${WRITE_PATHS[*]}"
# Generated from flumip.service, which ships working as it is for the default
# layout: User= becomes --service-user (it owns nothing here but must read its
# passwords.yaml), and ReadWritePaths= and ProtectHome= the ones worked out
# above. Settings an admin adds with `systemctl edit flumip` live in a drop-in
# next to the unit and survive this.
# (-v is safe here: none of these can hold a backslash, checked above.)
awk -v user="$SERVICE_USER" -v rw="$READ_WRITE_LINE" -v home="$PROTECT_HOME" '
  /^User=/           { print "User=" user; next }
  /^ReadWritePaths=/ { print rw; next }
  /^ProtectHome=/    { print "ProtectHome=" home; next }
  { print }
' "$UNIT_SRC" | sudo tee "/etc/systemd/system/$UNIT" >/dev/null
sudo systemctl daemon-reload
sudo systemctl enable "${SERVICE}"

if $RESTART; then
  echo -e "${GREEN}Starting ${SERVICE}${NC}"
  sudo systemctl restart "${SERVICE}"
else
  echo -e "${YELLOW}--no-restart given; not starting the service.${NC}"
fi

# --- Pocket ID (optional) ---------------------------------------------------

# A self-hosted single sign-on provider for a server that has no institutional
# one, such as a public instance, where signing in is the only way an
# administrator gets in. FLUMIP talks to it like any other OIDC provider; only
# installing it is special. See docs/pocket-id.md.
POCKET_ID_ENV="$SECRETS_DIR/pocket-id.env"
POCKET_ID_UNIT="/etc/systemd/system/pocket-id.service"
POCKET_ID_RECOVERY="sudo systemd-run --pipe --wait --quiet -p User=${POCKET_ID_USER} \\
         -p EnvironmentFile=${POCKET_ID_ENV} -p WorkingDirectory=${POCKET_ID_DATA} \\
         ${POCKET_ID_BIN} one-time-access-token <username or email>"

if [[ -n "$POCKET_ID_URL" ]]; then
  # shellcheck source=pocket-id.pin
  . "$SCRIPT_DIR/pocket-id.pin"
  echo -e "${GREEN}Installing Pocket ID ${POCKET_ID_VERSION}${NC}"

  POCKET_ID_TMP="$(mktemp -d)"
  POCKET_ID_ASSET="pocket-id_linux_amd64"
  POCKET_ID_DL="https://github.com/pocket-id/pocket-id/releases/download/v${POCKET_ID_VERSION}/${POCKET_ID_ASSET}"
  curl -fsSL --retry 3 -o "$POCKET_ID_TMP/$POCKET_ID_ASSET" "$POCKET_ID_DL" \
    || die "Download failed: $POCKET_ID_DL"
  # Against the hash in the pin, not one fetched alongside the binary: a release
  # asset replaced on GitHub would bring its own matching checksum.
  echo "${POCKET_ID_SHA256}  $POCKET_ID_TMP/$POCKET_ID_ASSET" | sha256sum -c --quiet - \
    || die "The Pocket ID download does not match the hash in pocket-id.pin; not installing it."

  if ! id "$POCKET_ID_USER" &>/dev/null; then
    sudo useradd --system --user-group --no-create-home \
      --home-dir "$POCKET_ID_DATA" --shell /usr/sbin/nologin "$POCKET_ID_USER"
  fi

  # Never overwritten, like flumip.env, and for a stronger reason: the key in it
  # is the only way to read Pocket ID's database, and the URL is what every
  # registered passkey is bound to.
  if sudo test -f "$POCKET_ID_ENV"; then
    echo -e "${GREEN}Keeping existing $POCKET_ID_ENV${NC}"
    current_url="$(sudo sed -n 's/^APP_URL=//p' "$POCKET_ID_ENV")"
    if [[ "$current_url" != "$POCKET_ID_URL" ]]; then
      echo -e "${YELLOW}⚠️  $POCKET_ID_ENV still says APP_URL=${current_url}, not ${POCKET_ID_URL}.
   It is left alone: every passkey registered so far is bound to the old address.
   To really move Pocket ID, edit APP_URL there, restart pocket-id, and have each
   administrator register a new passkey with a login code.${NC}"
      # Remember the address in force, not the one asked for, so the next run
      # neither warns again nor prints next steps for an address nothing uses.
      POCKET_ID_URL="$current_url"
      sudo sed -i "s|^POCKET_ID_URL=.*|POCKET_ID_URL=${POCKET_ID_URL}|" "$CHOICES_FILE"
    fi
  else
    echo -e "${GREEN}Creating $POCKET_ID_ENV${NC}"
    sudo mkdir -p "$SECRETS_DIR"
    sudo chmod 750 "$SECRETS_DIR"
    # Read by systemd as root, so nobody else needs to read it at all.
    (umask 077; sudo tee "$POCKET_ID_ENV" >/dev/null) <<EOF
# Pocket ID's configuration, read by systemd for the pocket-id service.
# Generated by setup-flumip.sh; never overwritten on a re-run. Apply changes with
#   sudo systemctl restart pocket-id
# See docs/pocket-id.md.

# The address people reach Pocket ID at. ⚠️ Passkeys are bound to its domain:
# changing it later means every administrator registers theirs again.
APP_URL=${POCKET_ID_URL}

# ⚠️ Encrypts the signing keys in Pocket ID's database under ${POCKET_ID_DATA}.
# Without it that database is useless: back the two up together, and never
# change it.
ENCRYPTION_KEY=$(openssl rand -hex 32)

# Reachable from this machine only; the reverse proxy serves it over HTTPS, and
# its X-Forwarded-For is the visitor's real address.
HOST=127.0.0.1
PORT=${POCKET_ID_PORT}
TRUST_PROXY=127.0.0.1

# Not settable here: whether addresses count as verified, and whether anyone may
# sign up, are Pocket ID settings in its own web UI, and it ignores them in the
# environment. Sign-ups are off by default. ⚠️ Every administrator's address has
# to be marked verified there (Administration → Users → the envelope beside
# Email), the one from /setup included: FLUMIP refuses a sign-in whose address
# the provider calls unverified.

# No daily heartbeat to Pocket ID's instance counter.
ANALYTICS_DISABLED=true
EOF
    sudo chown root:root "$POCKET_ID_ENV"
    sudo chmod 600 "$POCKET_ID_ENV"
  fi

  # Replacing the file under a running service is safe: install unlinks the old
  # binary, which the process keeps until the restart below.
  sudo install -d -m 755 "$(dirname "$POCKET_ID_BIN")"
  sudo install -m 755 "$POCKET_ID_TMP/$POCKET_ID_ASSET" "$POCKET_ID_BIN"
  sudo install -m 644 "$SCRIPT_DIR/pocket-id.service" "$POCKET_ID_UNIT"
  sudo systemctl daemon-reload
  sudo systemctl enable pocket-id
  if $RESTART; then
    echo -e "${GREEN}Starting pocket-id${NC}"
    sudo systemctl restart pocket-id
  fi
elif $REMOVE_POCKET_ID; then
  if [[ -f "$POCKET_ID_UNIT" || -e "$POCKET_ID_BIN" ]]; then
    echo -e "${GREEN}Removing Pocket ID${NC}"
    sudo systemctl disable --now pocket-id 2>/dev/null || true
    sudo rm -f "$POCKET_ID_UNIT"
    sudo systemctl daemon-reload
    sudo rm -rf "$(dirname "$POCKET_ID_BIN")"
  fi
  # Its users, passkeys and keys stay, so --pocket-id again picks them up.
  if sudo test -e "$POCKET_ID_DATA" || sudo test -f "$POCKET_ID_ENV"; then
    echo -e "${YELLOW}Pocket ID's data stays in $POCKET_ID_DATA and $POCKET_ID_ENV.
uninstall-flumip.sh --pocket-id-data removes it.${NC}"
  fi
fi

# --- Next steps -------------------------------------------------------------

# Step 4 is about single sign-on: an organisation's provider in general, or the
# Pocket ID this run installed.
if [[ -n "$POCKET_ID_URL" ]]; then
  POCKET_ID_HOST="${POCKET_ID_URL#*://}"
  POCKET_ID_HOST="${POCKET_ID_HOST%%:*}"
  SSO_STEP="  4. Pocket ID runs on 127.0.0.1:${POCKET_ID_PORT}, as the pocket-id service.
     Before anyone else can reach it:

     a. Give it its own HTTPS server block, like step 3:

          sudo certbot --nginx -d ${POCKET_ID_HOST}
          # proxy_pass http://127.0.0.1:${POCKET_ID_PORT};

     b. Open ${POCKET_ID_URL}/setup AT ONCE. Whoever opens it first
        becomes Pocket ID's administrator. Register a passkey there.
        Then, under Administration → Users, mark your address as verified
        (the envelope beside Email). FLUMIP refuses unverified addresses,
        and Pocket ID creates this first account unverified.

     c. In Pocket ID, create a user group (say flumip-admins) and an OIDC
        client: confidential, callback https://${PUBLIC_HOST}/auth/callback.
        On the client's Access tab allow only that group. Copy the client
        secret: it is shown once.

     d. In ${ENV_FILE} set FLUMIP_OIDC_ISSUER=${POCKET_ID_URL},
        the client id and secret, FLUMIP_OIDC_ADMIN_EMAILS and
        FLUMIP_PUBLIC_URL=https://${PUBLIC_HOST}, then
        'sudo systemctl restart ${SERVICE}'.

     If the last administrator loses their passkey, this prints a one-time
     sign-in link:

       ${POCKET_ID_RECOVERY}

     See docs/pocket-id.md."
  BACKUP_STEP="  5. Back up ${SECRETS_DIR}/ and ${POCKET_ID_DATA}/. ${SECRETS_FILE}
     holds the only copy of the database password, and ${POCKET_ID_ENV}
     the only key to Pocket ID's database."
else
  SSO_STEP="  4. Optional: connect this server to your organisation's single sign-on.
     FLUMIP runs with no authentication by default, which is fine for a trusted
     network — skip this step and nothing changes.

     Register FLUMIP with your identity provider using this redirect URI:

       http://${PUBLIC_HOST}:${WEB_PORT}/auth/callback

     Note the plain http and the port. Most providers refuse a non-HTTPS
     redirect URI for anything other than localhost, so do step 3 first; the URI
     then becomes https://${PUBLIC_HOST}/auth/callback and you must set

       FLUMIP_PUBLIC_URL=https://${PUBLIC_HOST}

     in ${ENV_FILE}, or the public URL
     in the Settings tab. The Settings tab always shows the URI this server
     computes — register exactly that. See docs/authentication.md.

     No provider to use, but need sign-in (a public instance does)? Re-run
     with --pocket-id to host one here; see docs/pocket-id.md."
  BACKUP_STEP="  5. Back up ${SECRETS_DIR}/. ${SECRETS_FILE} holds the only copy of
     the database password."
fi

# Step 2: the settings password. Shown once, on the run that made it; an upgrade
# prints no password, only where to look.
SETTINGS_PW_TAIL="     It gates the settings screen, including the SMTP configuration and the
     paths of the programs FLUMIP runs. It is stored hashed, so the box there
     is write-only: type a new one, or leave it empty to keep the current one."
if [[ -n "$INITIAL_SETTINGS_PASSWORD" ]]; then
  PASSWORD_STEP="  2. The settings password of this new install is:

       $(echo -e "${YELLOW}${INITIAL_SETTINGS_PASSWORD}${NC}")

     Open Settings and change it now. It is shown only this once; until you
     change it, 'sudo cat ${INITIAL_PASSWORD_FILE}' shows it again, and once
     you have, that file can be deleted. (If ${DB_NAME} already had FLUMIP's
     settings, as a database from an earlier install does, it keeps its own
     password and this one does nothing.)
${SETTINGS_PW_TAIL}"
elif sudo test -f "$INITIAL_PASSWORD_FILE"; then
  PASSWORD_STEP="  2. If you have not changed the settings password yet, the first one is in
     ${INITIAL_PASSWORD_FILE} (sudo cat it). Change it in Settings, then
     delete that file.
${SETTINGS_PW_TAIL}"
else
  PASSWORD_STEP="  2. Make sure the settings password is not the 'changeme' installs before
     this version started with. The Settings tab warns while it still is.
${SETTINGS_PW_TAIL}"
fi

if [[ "$FIREWALL" == "yes" && -n "$NFT" ]]; then
  PORTS_NOTE="     ${FIREWALL_UNIT} already keeps those two to this machine. To lift
     that: 'sudo systemctl stop ${FIREWALL_UNIT}', or --no-firewall for good."
else
  PORTS_NOTE="     ⚠️  Nothing keeps those two from the network yet: Serverpod listens on
     every address. Firewall them, or re-run with --firewall."
fi

cat <<EOF

$(echo -e "${GREEN}Setup complete.${NC}")

$(echo -e "${YELLOW}Next steps:${NC}")

  1. Open the app:  http://${PUBLIC_HOST}:${WEB_PORT}
     Check the service with:  systemctl status ${SERVICE}
     Follow the logs with:    journalctl -u ${SERVICE} -f

${PASSWORD_STEP}

  3. Traffic is plain HTTP on port ${WEB_PORT}. To serve it over HTTPS, put a
     reverse proxy in front, for example with nginx and certbot:

       sudo apt install nginx certbot python3-certbot-nginx
       # proxy_pass http://127.0.0.1:${WEB_PORT};  — the only upstream needed:
       # the web port also answers the app's API calls, under /api
       sudo certbot --nginx -d ${PUBLIC_HOST}

     IMPORTANT for uploads and downloads. nginx defaults will break both, and
     the failures look like application bugs rather than proxy limits. In the
     server block that proxies the web app, set:

       client_max_body_size 4G;        # default is 1m: an SNP upload is 100M-1.5G
       proxy_request_buffering off;    # stream the upload through, do not spool it
       proxy_buffering off;            # so a download starts at once
       proxy_read_timeout 3600s;       # a slow gigabyte legitimately takes a while
       proxy_send_timeout 3600s;

     Without client_max_body_size, nginx answers 413 for any real VCF before
     FLUMIP ever sees the request. Without proxy_request_buffering off, nginx
     writes the whole file to its own spool first, so a 1 GB upload costs twice
     the disk and reports no progress until it is finished.

     Then re-run this script with --host set to that domain so the generated
     config advertises the right public URL.

     Only port ${WEB_PORT} needs to be reachable — it serves the app, the API
     (under /api), downloads, uploads and sign-in. Keep ${API_PORT} and
     ${INSIGHTS_PORT} off the proxy.
${PORTS_NOTE}

${SSO_STEP}

     If a sign-in configuration ever locks you out: set
     FLUMIP_AUTH_ENABLED=false in that env file and
     'sudo systemctl restart ${SERVICE}'. While sign-in is enforced the
     admin password does not open the Settings tab; only an admin account does.

${BACKUP_STEP}

  To update later, re-run this script with the new build. The choices
  above are remembered in ${CHOICES_FILE}.

EOF
