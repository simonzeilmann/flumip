#!/bin/sh
# init-env.sh - Writes .env for the Docker install from .env.example, with a
# fresh database password and service secret.
#
#   ./init-env.sh                         .env only
#   ./init-env.sh --pocket-id URL         also pocket-id.env, for the optional
#                                         self-hosted single sign-on at URL
#                                         (e.g. https://id.example.org); see
#                                         docs/pocket-id.md
#
# Run once, before the first `docker compose up`. It never overwrites an existing
# .env: the database password in it is the one PostgreSQL was initialised with,
# and replacing it would lock FLUMIP out of its own database. Nor an existing
# pocket-id.env, whose key is the only way to read Pocket ID's database. So
# --pocket-id can be added to an install that already has its .env.

set -eu

cd "$(dirname "$0")"

POCKET_ID_URL=""

while [ $# -gt 0 ]; do
  case "$1" in
    --pocket-id)
      [ -n "${2:-}" ] || { echo "--pocket-id needs the URL Pocket ID will be reached at." >&2; exit 1; }
      POCKET_ID_URL="$2"; shift ;;
    -h|--help)
      awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "$0"; exit 0 ;;
    *)
      echo "Unknown option: $1 (see --help)" >&2; exit 1 ;;
  esac
  shift
done

if [ -n "$POCKET_ID_URL" ]; then
  # Passkeys are bound to this domain for good, so a typo here costs every
  # administrator their passkey later. https, or plain http on localhost for a
  # trial; no path, and no trailing slash.
  POCKET_ID_URL="${POCKET_ID_URL%/}"
  case "$POCKET_ID_URL" in
    https://*/*|http://*/*)
      echo "--pocket-id takes the bare origin, with no path: $POCKET_ID_URL" >&2; exit 1 ;;
    https://?*|http://localhost|http://localhost:*) ;;
    *)
      echo "--pocket-id must be an https:// URL (http:// only for localhost): $POCKET_ID_URL" >&2; exit 1 ;;
  esac
fi

# Same lengths as setup-flumip.sh: 24 bytes for the database, 32 for the service
# secret, as hex. /dev/urandom when openssl is not installed.
random_hex() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex "$1"
  else
    od -An -N"$1" -tx1 /dev/urandom | tr -d ' \n'
  fi
}

# Created private before anything secret is written into it.
umask 077

if [ -e .env ]; then
  echo ".env already exists; leaving it alone."
else
  DB_PASSWORD="$(random_hex 24)"
  SERVICE_SECRET="$(random_hex 32)"
  # The first settings password. The server takes it from here only when it
  # creates its settings, on the first start against an empty database, so it
  # does nothing for an existing one. 12 bytes, 24 hex characters: typed once,
  # then changed in the Settings tab.
  SETTINGS_PASSWORD="$(random_hex 12)"
  sed -e "s/^FLUMIP_DB_PASSWORD=.*/FLUMIP_DB_PASSWORD=$DB_PASSWORD/" \
      -e "s/^FLUMIP_SERVICE_SECRET=.*/FLUMIP_SERVICE_SECRET=$SERVICE_SECRET/" \
      -e "s/^FLUMIP_DB_USER=.*/FLUMIP_DB_USER=flumip/" \
      -e "s/^FLUMIP_INITIAL_SETTINGS_PASSWORD=.*/FLUMIP_INITIAL_SETTINGS_PASSWORD=$SETTINGS_PASSWORD/" \
      .env.example > .env.tmp
  # A new install connects as its own role, not as the superuser postgres;
  # compose.yaml creates it with the database. Only here, for a new .env: an
  # existing database has no such role (see "Database role" in docs/docker.md).
  if ! grep -q '^FLUMIP_DB_USER=' .env.tmp; then
    printf '\n# Written by init-env.sh: the database role FLUMIP connects as, created\n# with the database. Do not change it once the database exists.\nFLUMIP_DB_USER=flumip\n' >> .env.tmp
  fi
  if ! grep -q '^FLUMIP_INITIAL_SETTINGS_PASSWORD=' .env.tmp; then
    printf '\n# Written by init-env.sh: the first settings password, read only when the\n# database is new. Change it in the Settings tab; this line can then go.\nFLUMIP_INITIAL_SETTINGS_PASSWORD=%s\n' "$SETTINGS_PASSWORD" >> .env.tmp
  fi
  mv .env.tmp .env
  echo "Wrote .env with a new database password and service secret."
  echo ""
  echo "The settings password of this new install is:"
  echo ""
  echo "    $SETTINGS_PASSWORD"
  echo ""
  echo "Open Settings in the app and change it. Until you do, it is also in .env"
  echo "(FLUMIP_INITIAL_SETTINGS_PASSWORD). It only takes effect on an empty"
  echo "database: one this machine already has keeps the password it had."
  echo ""
fi

if [ -z "$POCKET_ID_URL" ]; then
  echo "Review it, then: docker compose build && docker compose up -d"
  exit 0
fi

if [ -e pocket-id.env ]; then
  echo "pocket-id.env already exists; leaving it alone."
else
  # 32 random bytes, which Pocket ID takes in any form of at least 16 bytes.
  cat > pocket-id.env.tmp <<EOF
# Pocket ID's configuration, written by init-env.sh. See docs/pocket-id.md.
# Apply changes with: docker compose up -d

# The address people reach Pocket ID at. ⚠️ Passkeys are bound to its domain:
# changing it later means every administrator registers theirs again.
APP_URL=${POCKET_ID_URL}

# ⚠️ Encrypts the signing keys in Pocket ID's database. Without it the
# database is useless: back the two up together, and never change it.
ENCRYPTION_KEY=$(random_hex 32)

# The published port is 127.0.0.1 only, so whatever reaches it is the reverse
# proxy, and its X-Forwarded-For is the visitor's real address.
TRUST_PROXY=true

# Not settable here: whether addresses count as verified, and whether anyone may
# sign up, are Pocket ID settings in its own web UI, and it ignores them in the
# environment. Sign-ups are off by default. ⚠️ Every administrator's address has
# to be marked verified there (Administration → Users → the envelope beside
# Email), the one from /setup included: FLUMIP refuses a sign-in whose address
# the provider calls unverified.

# No daily heartbeat to Pocket ID's instance counter.
ANALYTICS_DISABLED=true
EOF
  mv pocket-id.env.tmp pocket-id.env
  echo "Wrote pocket-id.env for $POCKET_ID_URL with a new encryption key."
fi

# The profile is what makes `docker compose up -d` start Pocket ID at all.
if grep -q '^COMPOSE_PROFILES=' .env; then
  if ! grep -q '^COMPOSE_PROFILES=.*pocket-id' .env; then
    echo "⚠️  .env already sets COMPOSE_PROFILES; add pocket-id to it yourself." >&2
  fi
else
  printf '\n# Added by init-env.sh --pocket-id.\nCOMPOSE_PROFILES=pocket-id\n' >> .env
  echo "Switched the pocket-id profile on in .env."
fi

# A localhost trial needs no proxy, and FLUMIP's own container cannot use it:
# localhost inside the container is the container itself.
case "$POCKET_ID_URL" in
  http://localhost*)
    cat <<EOF

Next, for a trial on this machine (see docs/pocket-id.md). Passkeys work on
localhost without HTTPS, so there is nothing to proxy:
  1. docker compose up -d pocket-id
  2. Open ${POCKET_ID_URL}/setup and create the administrator.
  3. Under Administration → Users, mark your address as verified (the envelope
     beside Email). FLUMIP refuses unverified addresses.
  4. Create a group, and an OIDC client for FLUMIP restricted to it, with the
     callback http://localhost:<FLUMIP's port>/auth/callback.
  5. Point a FLUMIP running on this host, not in a container, at it:
     FLUMIP_OIDC_ISSUER=${POCKET_ID_URL}, the client's id and secret, and
     FLUMIP_PUBLIC_URL=http://localhost:<FLUMIP's port> in its environment.
EOF
    exit 0 ;;
esac

cat <<EOF

Next, before anyone else can reach it (see docs/pocket-id.md):
  1. Proxy ${POCKET_ID_URL} to 127.0.0.1:1411 over HTTPS.
  2. docker compose build && docker compose up -d
  3. Open ${POCKET_ID_URL}/setup at once: whoever opens it first becomes
     Pocket ID's administrator.
  4. Under Administration → Users, mark your address as verified (the envelope
     beside Email). FLUMIP refuses unverified addresses.
  5. Create a group, and an OIDC client for FLUMIP restricted to it, then set
     FLUMIP_OIDC_ISSUER=${POCKET_ID_URL} and the client's id and secret in .env.
EOF
