#!/bin/bash
# setup-flumip.sh - Install (or update) a FLUMIP server environment: fetch a
# build, unpack it to /var/www/flumip_<env>, and install the systemd unit.
#
# The CI pipelines (.github/workflows/{production,staging}.yml) push-deploy the
# build over scp and restart the unit themselves. This script covers the
# pull-based cases: bootstrapping a new machine, or deploying a build by hand.
#
# A build is the `app` directory produced by the CI "Build server" step
# (server, config/, migrations/, web/, deployment/), packed as a .tar.gz.
# Create one with, from flumip_server after building:
#     tar -czf flumip-build.tar.gz -C app .
#
# Usage:
#   ./setup-flumip.sh [--prod | --staging] [--url URL | --file FILE] [options]
#
# Options:
#   --prod, --staging       Environment to install (default: both).
#   --url URL               Download the build tarball from URL.
#   --file FILE             Use a local build tarball.
#   --service-user USER     Owner of the install dir (default: www-data).
#   --no-restart            Install files/unit but do not (re)start the service.
#   -h, --help              Show this help and exit.
#
# Without --url or --file no build is fetched: the directory and systemd unit
# are set up and the build is left to CI (or a later run of this script).
#
# Examples:
#   ./setup-flumip.sh --prod --url https://example.com/flumip-build.tar.gz
#   ./setup-flumip.sh --staging --file ./flumip-build.tar.gz
#   ./setup-flumip.sh                 # unit + directories only, both envs

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

ENVS=()
BUILD_URL=""
BUILD_FILE=""
SERVICE_USER="www-data"
RESTART=true

# Temp directory for a downloaded build; removed on exit.
TMP_DL=""
cleanup() {
  [[ -n "$TMP_DL" && -d "$TMP_DL" ]] && rm -rf "$TMP_DL"
}
trap cleanup EXIT

# Directory this script lives in, so the .service files next to it are found
# regardless of the working directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "$0"
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --prod|--production) ENVS+=("production") ;;
    --staging) ENVS+=("staging") ;;
    --url)
      [[ -z "${2:-}" ]] && { echo -e "${RED}--url requires a value${NC}"; exit 1; }
      BUILD_URL="$2"; shift ;;
    --file)
      [[ -z "${2:-}" ]] && { echo -e "${RED}--file requires a value${NC}"; exit 1; }
      BUILD_FILE="$2"; shift ;;
    --service-user)
      [[ -z "${2:-}" ]] && { echo -e "${RED}--service-user requires a value${NC}"; exit 1; }
      SERVICE_USER="$2"; shift ;;
    --no-restart) RESTART=false ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Run '$0 --help' for usage."
      exit 1 ;;
  esac
  shift
done

if [[ -n "$BUILD_URL" && -n "$BUILD_FILE" ]]; then
  echo -e "${RED}--url and --file are mutually exclusive${NC}"
  exit 1
fi

# Default to both environments.
if [[ ${#ENVS[@]} -eq 0 ]]; then
  ENVS=("production" "staging")
fi

# Installing the same build into both environments is almost never intended.
if [[ ${#ENVS[@]} -gt 1 && ( -n "$BUILD_URL" || -n "$BUILD_FILE" ) ]]; then
  echo -e "${RED}Refusing to install one build into multiple environments.${NC}"
  echo "Pass --prod or --staging together with --url/--file."
  exit 1
fi

# Downloads (if needed) and echoes the path to a verified build tarball.
# Prints nothing when no build source was given.
fetch_build() {
  if [[ -n "$BUILD_FILE" ]]; then
    if [[ ! -f "$BUILD_FILE" ]]; then
      echo -e "${RED}Build file not found: $BUILD_FILE${NC}" >&2
      exit 1
    fi
    echo "$BUILD_FILE"
    return
  fi

  # Reuse the download across environments; cleaned up by the EXIT trap.
  TMP_DL="${TMP_DL:-$(mktemp -d)}"
  local out="$TMP_DL/flumip-build.tar.gz"
  if [[ ! -s "$out" ]]; then
    echo -e "${GREEN}Downloading build from $BUILD_URL${NC}" >&2
    # -f fail on HTTP errors, -sS quiet but still report errors, -L follow redirects.
    if ! curl -fsSL --retry 3 -o "$out" "$BUILD_URL" >&2; then
      echo -e "${RED}Download failed: $BUILD_URL${NC}" >&2
      exit 1
    fi
  fi
  echo "$out"
}

install_env() {
  local env="$1"
  local target="/var/www/flumip_${env}"
  local unit="flumip_${env}.service"
  local unit_src="$SCRIPT_DIR/$unit"

  if [[ ! -f "$unit_src" ]]; then
    echo -e "${RED}Missing systemd unit: $unit_src${NC}"
    exit 1
  fi

  echo -e "\n${GREEN}=== Installing flumip_${env} ===${NC}"

  local build=""
  if [[ -n "$BUILD_URL" || -n "$BUILD_FILE" ]]; then
    build="$(fetch_build)"
    # Fail before touching the target if the archive is not a valid tarball.
    if ! tar -tzf "$build" >/dev/null 2>&1; then
      echo -e "${RED}Not a valid .tar.gz archive: $build${NC}"
      exit 1
    fi
    # A build must contain the compiled server binary.
    if ! tar -tzf "$build" | grep -qE '(^|/)server$'; then
      echo -e "${RED}Archive does not contain a 'server' binary — is this a FLUMIP build?${NC}"
      exit 1
    fi
  fi

  if [[ -n "$build" ]] && $RESTART && systemctl is-active --quiet "flumip_${env}"; then
    echo -e "${GREEN}Stopping flumip_${env} before replacing the build...${NC}"
    sudo systemctl stop "flumip_${env}"
  fi

  sudo mkdir -p "$target"

  if [[ -n "$build" ]]; then
    echo -e "${GREEN}Extracting build to $target${NC}"
    sudo tar -xzf "$build" -C "$target"
    sudo chmod +x "$target/server"
    if id "$SERVICE_USER" &>/dev/null; then
      sudo chown -R "$SERVICE_USER":"$SERVICE_USER" "$target"
    else
      echo -e "${YELLOW}User $SERVICE_USER does not exist; leaving ownership unchanged.${NC}"
    fi
  else
    echo -e "${YELLOW}No --url/--file given: skipping build download.${NC}"
    echo -e "${YELLOW}The build is delivered by CI, or re-run with --url/--file.${NC}"
  fi

  echo -e "${GREEN}Installing systemd unit $unit${NC}"
  sudo cp "$unit_src" /etc/systemd/system/
  sudo systemctl daemon-reload
  sudo systemctl enable "flumip_${env}"

  if $RESTART; then
    if [[ -x "$target/server" ]]; then
      echo -e "${GREEN}Restarting flumip_${env}${NC}"
      sudo systemctl restart "flumip_${env}"
    else
      echo -e "${YELLOW}No server binary at $target/server; not starting the service.${NC}"
    fi
  fi

  echo -e "${GREEN}Setup complete for $env.${NC}"
}

for env in "${ENVS[@]}"; do
  install_env "$env"
done
