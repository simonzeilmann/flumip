#!/usr/bin/env bash
#
# Local single sign-on, without a real identity provider.
#
# Two ways to get an authenticated call, because they cost very different
# amounts and answer different questions:
#
#   token   mints a bearer straight into the database. No provider round trip at
#           all. Use it when the question is "does this endpoint refuse the right
#           people" — which is most of the time.
#
#   signin  drives the real /auth/login -> provider -> /auth/callback -> cookie
#           -> /auth/session flow against the mock provider. Slower, and the only
#           way to exercise PKCE, the code exchange, and the cookie.
#
# Usage:
#   ./tool/dev-auth.sh enable                      point settings at the mock IdP, switch SSO on
#   ./tool/dev-auth.sh disable                     switch SSO back off
#   ./tool/dev-auth.sh token alice@uni.example     mint a bearer, no provider needed
#   ./tool/dev-auth.sh token boss@x --admin        ... with the admin scope
#   ./tool/dev-auth.sh signin boss@uni.example     full OIDC round trip, prints the bearer
#   ./tool/dev-auth.sh status                      what the server currently thinks
#
# The mock provider is the `auth` compose profile:
#   docker compose --profile auth up -d mock_oidc
#
set -euo pipefail

ISSUER="${FLUMIP_DEV_ISSUER:-http://localhost:9999/default}"
CLIENT_ID="${FLUMIP_DEV_CLIENT_ID:-flumip}"
CLIENT_SECRET="${FLUMIP_DEV_CLIENT_SECRET:-s3cret}"
WEB="${FLUMIP_DEV_WEB:-http://localhost:8082}"
API="${FLUMIP_DEV_API:-http://localhost:8080}"

cd "$(dirname "$0")/.."

psql_do() {
  # -T because there is no TTY when this runs from a script or CI.
  docker compose exec -T postgres psql -U postgres -d postgres -v ON_ERROR_STOP=1 "$@"
}

sql() { psql_do -q -c "$1" >/dev/null; }
sql_value() { psql_do -tAc "$1"; }

# The server stores only sha256 hex of a token; see AuthTokens.sha256Hex.
sha256_hex() { printf '%s' "$1" | sha256sum | cut -d' ' -f1; }

require_provider() {
  if ! curl -sf "$ISSUER/.well-known/openid-configuration" >/dev/null; then
    echo "No provider at $ISSUER" >&2
    echo "Start it with: docker compose --profile auth up -d mock_oidc" >&2
    exit 1
  fi
}

# Checked explicitly so a stopped server says so, rather than this failing
# somewhere mid-flow and printing an empty token that looks like a bug in the
# thing being tested.
require_server() {
  if ! curl -s -o /dev/null "$WEB/"; then
    echo "No server at $WEB — start the 'Server' launch configuration first." >&2
    exit 1
  fi
}

cmd_enable() {
  require_provider
  sql "UPDATE settings SET
         \"loginRequired\" = true,
         \"oidcIssuer\" = '$ISSUER',
         \"oidcClientId\" = '$CLIENT_ID',
         \"oidcClientSecret\" = '$CLIENT_SECRET',
         \"authPublicUrl\" = '$WEB';"
  echo "SSO on, pointed at $ISSUER."
  echo "The gate closes on the runtime's own refresh tick — up to 30s, no restart needed."
  echo "Admin emails are the oidcAdminEmails setting; set it with:"
  echo "  ./tool/dev-auth.sh admins boss@uni.example"
}

cmd_disable() {
  sql "UPDATE settings SET \"loginRequired\" = false;"
  echo "SSO off. Opens again within the refresh tick."
}

cmd_admins() {
  sql "UPDATE settings SET \"oidcAdminEmails\" = '${1:-}';"
  echo "Admin emails: ${1:-<none>}"
  echo
  echo "⚠️  Wait ~30s before signing in."
  echo "    Admin is decided at sign-in from the config AuthRuntime last read, and this"
  echo "    writes the database directly — it does not go through"
  echo "    SettingsEndpoint.updateSettings, which is what normally calls"
  echo "    broadcastConfigChange to apply a change at once. Sign in too early and you"
  echo "    are silently an ordinary user, with the admin-only controls simply absent."
}

# Mint a bearer with no provider involved: seed the identity, a browser session,
# and an API token whose hash the authentication handler will find.
cmd_token() {
  local email="$1" admin="${2:-}" is_admin=false
  [ "$admin" = "--admin" ] && is_admin=true

  local token hash
  token="devtok-$(head -c 24 /dev/urandom | base64 | tr -d '=+/' | head -c 32)"
  hash="$(sha256_hex "$token")"

  sql "INSERT INTO flumip_user (email, subject, issuer, \"displayName\", created, \"lastLogin\")
       VALUES ('$email', '$email', '$ISSUER', '$email', now(), now())
       ON CONFLICT (issuer, subject) DO UPDATE SET \"lastLogin\" = now();"

  sql "WITH u AS (SELECT id FROM flumip_user WHERE email = '$email' LIMIT 1),
            s AS (
              INSERT INTO auth_session (\"userId\", \"cookieHash\", email, \"isAdmin\", expires, created)
              SELECT u.id, 'dev-cookie-' || md5(random()::text), '$email', $is_admin,
                     now() + interval '8 hours', now()
              FROM u RETURNING id
            )
       INSERT INTO auth_api_token (\"authSessionId\", \"tokenHash\", email, \"isAdmin\", expires, created)
       SELECT s.id, '$hash', '$email', $is_admin, now() + interval '8 hours', now() FROM s;"

  echo "$token"
}

# The whole round trip, as a browser would do it.
cmd_signin() {
  require_provider
  require_server
  local email="$1" jar location callback

  jar="$(mktemp)"
  trap 'rm -f "$jar"' RETURN

  location="$(curl -s -c "$jar" -o /dev/null -D - "$WEB/auth/login" \
    | tr -d '\r' | awk 'tolower($1) == "location:" { print $2 }')"
  if [ -z "$location" ]; then
    echo "No redirect from /auth/login — is SSO enabled and enforcing?" >&2
    echo "Check with: ./tool/dev-auth.sh status" >&2
    exit 1
  fi

  # The mock provider serves a login form rather than auto-approving, which is
  # what makes it useful in a browser: any username signs you in as that user.
  # Posting the form is the scripted equivalent of typing one in.
  callback="$(curl -s -o /dev/null -D - -X POST "$location" \
    --data-urlencode "username=$email" \
    --data-urlencode "claims={\"email\":\"$email\",\"name\":\"$email\"}" \
    | tr -d '\r' | awk 'tolower($1) == "location:" { print $2 }')"
  if [ -z "$callback" ]; then
    echo "The provider did not redirect back; check it is reachable at $ISSUER" >&2
    exit 1
  fi

  curl -s -b "$jar" -c "$jar" -o /dev/null "$callback"
  curl -s -b "$jar" "$WEB/auth/session" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["token"])'
}

cmd_status() {
  echo "settings:  loginRequired=$(sql_value 'SELECT "loginRequired" FROM settings LIMIT 1;')" \
       "issuer=$(sql_value 'SELECT "oidcIssuer" FROM settings LIMIT 1;')"
  echo "admins:    $(sql_value 'SELECT "oidcAdminEmails" FROM settings LIMIT 1;')"
  echo "users:     $(sql_value 'SELECT count(*) FROM flumip_user;')"
  echo -n "provider:  "
  curl -sf "$ISSUER/.well-known/openid-configuration" >/dev/null \
    && echo "up at $ISSUER" || echo "DOWN — docker compose --profile auth up -d mock_oidc"
  echo -n "enforcing: "
  # 401 unauthenticated is the only externally visible proof the gate is closed.
  case "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API/project/getProjects" \
            -H 'Content-Type: application/json' -d '{}')" in
    401) echo "yes (unauthenticated getProjects is 401)" ;;
    200) echo "no (unauthenticated getProjects is 200)" ;;
    *)   echo "unknown — is the server running?" ;;
  esac
}

case "${1:-}" in
  enable)  cmd_enable ;;
  disable) cmd_disable ;;
  admins)  shift; cmd_admins "${1:-}" ;;
  token)   shift; [ $# -ge 1 ] || { echo "usage: dev-auth.sh token <email> [--admin]" >&2; exit 2; }; cmd_token "$@" ;;
  signin)  shift; [ $# -ge 1 ] || { echo "usage: dev-auth.sh signin <email>" >&2; exit 2; }; cmd_signin "$1" ;;
  status)  cmd_status ;;
  *)       sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//' ; exit 2 ;;
esac
