#!/bin/sh
# init-env.sh - Writes .env for the Docker install from .env.example, with a
# fresh database password and service secret.
#
# Run once, before the first `docker compose up`. It never overwrites an existing
# .env: the database password in it is the one PostgreSQL was initialised with,
# and replacing it would lock FLUMIP out of its own database.

set -eu

cd "$(dirname "$0")"

if [ -e .env ]; then
  echo ".env already exists; leaving it alone."
  exit 0
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

DB_PASSWORD="$(random_hex 24)"
SERVICE_SECRET="$(random_hex 32)"

# Created private before anything secret is written into it.
umask 077
sed -e "s/^FLUMIP_DB_PASSWORD=.*/FLUMIP_DB_PASSWORD=$DB_PASSWORD/" \
    -e "s/^FLUMIP_SERVICE_SECRET=.*/FLUMIP_SERVICE_SECRET=$SERVICE_SECRET/" \
    .env.example > .env.tmp
mv .env.tmp .env

echo "Wrote .env with a new database password and service secret."
echo "Review it, then: docker compose build && docker compose up -d"
