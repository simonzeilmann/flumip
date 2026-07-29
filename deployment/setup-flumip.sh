#!/bin/bash
# setup-flumip.sh - Install and run a FLUMIP server on this machine.
#
# Run this AFTER setup-mipgen.sh, which installs MIPGEN, the reference data and
# the /opt/flumip directory tree. This script covers everything else needed to
# get the app serving:
#
#   1. checks prerequisites (and that setup-mipgen.sh has run)
#   2. downloads a release build (or uses a local tarball)
#   3. provisions a PostgreSQL container for the environment
#   4. generates config/<env>.yaml and a passwords.yaml with random secrets
#   5. applies the database migrations
#   6. installs and starts the systemd unit
#
# Re-running is safe: an existing database and its generated passwords are
# reused, so it doubles as an updater.
#
# The script has two modes, like setup-mipgen.sh:
#   * Interactive      - run with no switches on a terminal and you are prompted
#                        for the environment, hostname, service user and
#                        database setup.
#   * Non-interactive  - pass any switch below (or --yes) to script the run.
#
# Usage:
#   ./setup-flumip.sh [options]
#
# Options:
#   --prod, --production    Install the production environment (default).
#   --staging               Install the staging environment instead.
#   --host HOST             Public hostname clients reach this server on
#                           (default: localhost).
#   --url URL               Download the build tarball from URL.
#   --file FILE             Use a local build tarball.
#   --release TAG           Install a specific release tag (default: latest).
#   --db docker|existing    Provision a PostgreSQL container, or connect to a
#                           database that already exists (default: docker).
#   --db-host HOST          Database host for --db existing (default: localhost).
#   --db-port PORT          Database port (default: 5432 prod / 5433 staging).
#   --db-name NAME          Database name (default: flumip_<env>).
#   --db-user USER          Database user (default: postgres).
#   --service-user USER     Owner of the install dir (default: www-data).
#   --no-migrations         Do not apply database migrations.
#   --no-restart            Install files/unit but do not (re)start the service.
#   -i, --interactive       Force interactive prompts even if switches are given.
#   -y, --yes               Never prompt; use defaults/switches (for automation).
#   -h, --help              Show this help and exit.
#
# Examples:
#   ./setup-flumip.sh                                  # interactive install
#   ./setup-flumip.sh --yes --host mips.example.org     # scripted install
#   ./setup-flumip.sh --staging --file ./flumip-build.tar.gz
#   ./setup-flumip.sh --db existing --db-host 10.0.0.5 --yes
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
# survives a redeploy that replaces /var/www/flumip_<env> wholesale.
SECRETS_DIR="/etc/flumip"

ENV_NAME=""
PUBLIC_HOST=""
BUILD_URL=""
BUILD_FILE=""
RELEASE_TAG="latest"
DB_MODE="docker"
DB_HOST=""
DB_PORT=""
DB_NAME=""
DB_USER="postgres"
SERVICE_USER="www-data"
MIGRATIONS=true
RESTART=true

INTERACTIVE="auto"
SWITCHES_GIVEN=false

# Temp directory for a downloaded build; removed on exit.
TMP_DL=""
cleanup() {
  if [[ -n "$TMP_DL" && -d "$TMP_DL" ]]; then
    rm -rf "$TMP_DL"
  fi
  return 0
}
trap cleanup EXIT

# Directory this script lives in, so the .service files next to it are found
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
    --prod|--production) ENV_NAME="production"; SWITCHES_GIVEN=true ;;
    --staging) ENV_NAME="staging"; SWITCHES_GIVEN=true ;;
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

  if prompt_yes_no "Install the production environment? (no = staging)" "y"; then
    ENV_NAME="production"
  else
    ENV_NAME="staging"
  fi

  PUBLIC_HOST="$(prompt_value "Public hostname clients will use" "localhost")"
  SERVICE_USER="$(prompt_value "Service user" "$SERVICE_USER")"

  if prompt_yes_no "Provision a PostgreSQL container with Docker?" "y"; then
    DB_MODE="docker"
  else
    DB_MODE="existing"
    DB_HOST="$(prompt_value "Database host" "localhost")"
    DB_PORT="$(prompt_value "Database port" "5432")"
    DB_USER="$(prompt_value "Database user" "$DB_USER")"
  fi
fi

# --- Defaults ---------------------------------------------------------------

ENV_NAME="${ENV_NAME:-production}"
PUBLIC_HOST="${PUBLIC_HOST:-localhost}"
DB_HOST="${DB_HOST:-localhost}"
DB_NAME="${DB_NAME:-flumip_${ENV_NAME}}"

# Serverpod listens on different ports per environment (see config/*.yaml), so
# production and staging can coexist on one machine.
if [[ "$ENV_NAME" == "production" ]]; then
  API_PORT=9080; INSIGHTS_PORT=9081; WEB_PORT=9082
  DB_PORT="${DB_PORT:-5432}"
else
  API_PORT=8090; INSIGHTS_PORT=8091; WEB_PORT=8092
  DB_PORT="${DB_PORT:-5433}"
fi

# Container and volume names match those used by the CI deploy step so that a
# later CI deploy reattaches to this database instead of creating a second one.
DB_CONTAINER="postgres_${ENV_NAME}"
DB_VOLUME="flumip_${ENV_NAME}_data"

TARGET="/var/www/flumip_${ENV_NAME}"
UNIT="flumip_${ENV_NAME}.service"
UNIT_SRC="$SCRIPT_DIR/$UNIT"
SECRETS_FILE="$SECRETS_DIR/passwords_${ENV_NAME}.yaml"

# Fall back to the published release when no build source was given.
if [[ -z "$BUILD_URL" && -z "$BUILD_FILE" ]]; then
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
echo -e "  Environment:      ${ENV_NAME}"
echo -e "  Install dir:      ${TARGET}"
echo -e "  Public hostname:  ${PUBLIC_HOST}"
echo -e "  Server ports:     api ${API_PORT} / insights ${INSIGHTS_PORT} / web ${WEB_PORT}"
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
echo -e "  Apply migrations: ${MIGRATIONS}"
echo -e "  Start service:    ${RESTART}"
echo ""

if [[ "$INTERACTIVE" == "yes" ]]; then
  prompt_yes_no "Proceed with this configuration?" "y" || die "Aborted by user."
fi

# --- Build ------------------------------------------------------------------

# Downloads (if needed) and echoes the path to a verified build tarball.
fetch_build() {
  local out
  if [[ -n "$BUILD_FILE" ]]; then
    [[ -f "$BUILD_FILE" ]] || die "Build file not found: $BUILD_FILE"
    out="$BUILD_FILE"
  else
    TMP_DL="$(mktemp -d)"
    out="$TMP_DL/flumip-build.tar.gz"
    echo -e "${GREEN}Downloading build from $BUILD_URL${NC}" >&2
    # -f fail on HTTP errors, -sS quiet but still report errors, -L follow redirects.
    if ! curl -fsSL --retry 3 -o "$out" "$BUILD_URL" >&2; then
      echo -e "${RED}Download failed: $BUILD_URL${NC}" >&2
      echo -e "${RED}If no release has been published yet, build a tarball and pass --file.${NC}" >&2
      exit 1
    fi
  fi

  # Fail before touching the target if the archive is not a usable build.
  tar -tzf "$out" >/dev/null 2>&1 || die "Not a valid .tar.gz archive: $out"
  tar -tzf "$out" | grep -qE '(^|/)server$' \
    || die "Archive contains no 'server' binary — is this a FLUMIP build?"

  echo "$out"
}

echo -e "\n${GREEN}=== Installing flumip_${ENV_NAME} ===${NC}"
BUILD="$(fetch_build)"

# --- Database ---------------------------------------------------------------

# Reads the database password for this environment out of an existing
# passwords.yaml. Echoes nothing when the file or key is absent.
read_db_password() {
  # $SECRETS_DIR is only traversable by root and the service user, so the test
  # has to run under sudo too or it reports a missing file for any other admin.
  sudo test -f "$SECRETS_FILE" || return 0
  sudo awk -v env="$ENV_NAME" '
    /^[a-zA-Z]/ { in_env = ($0 ~ "^" env ":") ; next }
    in_env && $1 == "database:" { sub(/^[^:]*: */, ""); print; exit }
  ' "$SECRETS_FILE"
}

DB_PASSWORD="$(read_db_password)"
REUSED_SECRETS=false
if [[ -n "$DB_PASSWORD" ]]; then
  REUSED_SECRETS=true
  echo -e "${GREEN}Reusing existing credentials from $SECRETS_FILE${NC}"
else
  # base64 would include '/' and '+', which complicate YAML and URLs.
  DB_PASSWORD="$(openssl rand -hex 24)"
fi
SERVICE_SECRET="$(openssl rand -hex 32)"

if [[ "$DB_MODE" == "docker" ]]; then
  if docker ps -a --format '{{.Names}}' | grep -qx "$DB_CONTAINER"; then
    echo -e "${GREEN}Database container $DB_CONTAINER already exists; starting it if stopped.${NC}"
    docker start "$DB_CONTAINER" >/dev/null
    if ! $REUSED_SECRETS; then
      die "$DB_CONTAINER exists but $SECRETS_FILE has no password for it.
Either restore that file, or remove the container and its volume to start over:
  docker rm -f $DB_CONTAINER && docker volume rm $DB_VOLUME"
    fi
  else
    echo -e "${GREEN}Starting $POSTGRES_IMAGE container $DB_CONTAINER on port $DB_PORT${NC}"
    # The volume mounts at /var/lib/postgresql, NOT /var/lib/postgresql/data:
    # postgres:18 sets PGDATA=/var/lib/postgresql/18/docker, so mounting the
    # old path would leave the data in the container's writable layer and lose
    # it on the next `docker rm`. Matches flumip_server/docker-compose.yaml.
    docker run -d \
      --name "$DB_CONTAINER" \
      --restart unless-stopped \
      -e POSTGRES_USER="$DB_USER" \
      -e POSTGRES_PASSWORD="$DB_PASSWORD" \
      -e POSTGRES_DB="$DB_NAME" \
      -v "$DB_VOLUME":/var/lib/postgresql \
      -p "$DB_PORT":5432 \
      "$POSTGRES_IMAGE" >/dev/null
  fi
  DB_HOST="localhost"
fi

# --- Install files ----------------------------------------------------------

if $RESTART && systemctl is-active --quiet "flumip_${ENV_NAME}"; then
  echo -e "${GREEN}Stopping flumip_${ENV_NAME} before replacing the build...${NC}"
  sudo systemctl stop "flumip_${ENV_NAME}"
fi

echo -e "${GREEN}Extracting build to $TARGET${NC}"
sudo mkdir -p "$TARGET"
sudo tar -xzf "$BUILD" -C "$TARGET"
sudo chmod +x "$TARGET/server"

# --- Config -----------------------------------------------------------------

# The config shipped in the build points at the upstream project's domains, so
# it is replaced wholesale with one describing this machine.
echo -e "${GREEN}Writing config/${ENV_NAME}.yaml${NC}"
sudo tee "$TARGET/config/${ENV_NAME}.yaml" >/dev/null <<EOF
# Generated by setup-flumip.sh for host '${PUBLIC_HOST}'.
# Re-running the script overwrites this file.

apiServer:
  port: ${API_PORT}
  publicHost: ${PUBLIC_HOST}
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

${ENV_NAME}:
  database: ${DB_PASSWORD}
  serviceSecret: ${SERVICE_SECRET}
EOF
  sudo chown root:"$SERVICE_USER" "$SECRETS_FILE"
  sudo chmod 640 "$SECRETS_FILE"
fi

sudo cp "$SECRETS_FILE" "$TARGET/config/passwords.yaml"

if id "$SERVICE_USER" &>/dev/null; then
  sudo chown -R "$SERVICE_USER":"$SERVICE_USER" "$TARGET"
fi
sudo chmod 640 "$TARGET/config/passwords.yaml"

# --- Migrations -------------------------------------------------------------

# Serverpod does not apply migrations on a normal start, so a fresh database has
# no tables. The maintenance role applies them and exits, retrying the
# connection a few times in case the container is still starting up.
if $MIGRATIONS; then
  echo -e "${GREEN}Applying database migrations...${NC}"
  if ! sudo -u "$SERVICE_USER" sh -c "cd '$TARGET' && ./server \
      --mode='$ENV_NAME' \
      --server-id='$ENV_NAME' \
      --role=maintenance \
      --apply-migrations \
      --logging=normal"; then
    die "Applying migrations failed. The service was not started.
Check the database is reachable at ${DB_HOST}:${DB_PORT} and re-run, or pass
--no-migrations to skip this step."
  fi
fi

# --- systemd ----------------------------------------------------------------

echo -e "${GREEN}Installing systemd unit $UNIT${NC}"
sudo cp "$UNIT_SRC" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable "flumip_${ENV_NAME}"

if $RESTART; then
  echo -e "${GREEN}Starting flumip_${ENV_NAME}${NC}"
  sudo systemctl restart "flumip_${ENV_NAME}"
else
  echo -e "${YELLOW}--no-restart given; not starting the service.${NC}"
fi

# --- Next steps -------------------------------------------------------------

cat <<EOF

$(echo -e "${GREEN}Setup complete for ${ENV_NAME}.${NC}")

$(echo -e "${YELLOW}Next steps:${NC}")

  1. Open the app:  http://${PUBLIC_HOST}:${WEB_PORT}
     Check the service with:  systemctl status flumip_${ENV_NAME}
     Follow the logs with:    journalctl -u flumip_${ENV_NAME} -f

  2. Change the admin settings password. It defaults to 'changeme' and gates
     the settings screen, including the SMTP configuration.

  3. Traffic is plain HTTP on port ${WEB_PORT}. To serve it over HTTPS, put a
     reverse proxy in front, for example with nginx and certbot:

       sudo apt install nginx certbot python3-certbot-nginx
       # proxy_pass http://127.0.0.1:${WEB_PORT}; for the web app
       # proxy_pass http://127.0.0.1:${API_PORT}; for the API
       sudo certbot --nginx -d ${PUBLIC_HOST}

     Then re-run this script with --host set to that domain so the generated
     config advertises the right public URL.

  4. Back up ${SECRETS_FILE}. It holds the only copy of the
     database password.

EOF
