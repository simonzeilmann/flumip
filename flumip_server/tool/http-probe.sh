#!/usr/bin/env bash
# Probes a running development server over HTTP and prints a normalised
# transcript: every custom web route, the origin guard, the API under /api and
# on its own port, cookies, downloads. Nothing in test/ can see any of this
# (no test builds a Relic request), so a framework bump is checked by running
# this against the old version and the new one and diffing the two files:
#
#   tool/http-probe.sh <project-id> [file-in-project] > before.txt   # old
#   tool/http-probe.sh <project-id> [file-in-project] > after.txt    # new
#   diff before.txt after.txt
#
# Start both servers the same way. Under `serverpod start` every HTML page
# carries a dev auto-refresh script, so a plain `dart bin/main.dart` and a
# runner differ by 299 bytes per page for that reason alone.
#
# Needs sign-in enabled, the dev database container, and a project that has
# result files. It signs in by inserting a one-hour admin session for the
# first user with an email address, and removes it again on exit.
set -u
WEB=${FLUMIP_WEB:-http://localhost:8082}
API=${FLUMIP_API:-http://localhost:8080}
DB=${FLUMIP_DB_CONTAINER:-flumip_server-postgres-1}
PROJECT=${1:?usage: http-probe.sh <project-id> [file-in-project]}
FILE=${2:-genes.bed}

sql() { docker exec "$DB" psql -U postgres -d postgres -qAtc "$1"; }

COOKIE_VALUE="probe$(head -c 24 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 37)"
COOKIE_HASH=$(printf '%s' "$COOKIE_VALUE" | sha256sum | cut -d' ' -f1)
sql "insert into auth_session (\"userId\",\"cookieHash\",email,\"isAdmin\",expires,\"isGuest\")
     select id, '$COOKIE_HASH', email, true, (now() at time zone 'utc') + interval '1 hour', false
     from flumip_user where coalesce(email,'') <> '' order by id limit 1" >/dev/null
trap 'sql "delete from auth_session where \"cookieHash\" = '"'"'$COOKIE_HASH'"'"'" >/dev/null' EXIT

norm() {
  # Drop volatile headers, mask volatile values, sort header lines.
  python3 -c '
import sys, re, hashlib
raw = sys.stdin.buffer.read()
head, _, body = raw.partition(b"\r\n\r\n")
lines = head.decode("latin1").split("\r\n")
print("  " + lines[0])
out = []
for l in lines[1:]:
    k, _, v = l.partition(":")
    k = k.lower(); v = v.strip()
    if k in ("date", "x-serverpod-request-id"): continue
    v = re.sub(r"(flumip_auth(?:_flow)?=)[A-Za-z0-9_\-\.]+", r"\1<val>", v)
    v = re.sub(r"(state|nonce|code_challenge)=[^&;\s]+", r"\1=<val>", v)
    if k in ("etag", "last-modified"): v = "<val>"
    out.append(f"  {k}: {v}")
for l in sorted(out): print(l)
b = body
txt = b[:160].decode("utf8", "replace").replace("\n", "\\n")
txt = re.sub(r"\"token\":\"[^\"]+\"", "\"token\":\"<val>\"", txt)
txt = re.sub(r"\"expires[A-Za-z]*\":\"?[^,}]+", "\"expires\":<val>", txt)
print(f"  body[{len(b)}]: {txt}")
'
}

p() { # p <label> <curl args...>
  echo "== $1"; shift
  curl -sS -m 20 -i "$@" 2>&1 | norm
}

p "GET /"                         $WEB/
p "HEAD /"                        -I $WEB/
p "GET unknown path"              $WEB/no/such/page
p "GET /version.json"             $WEB/version.json
p "HEAD /version.json"            -I $WEB/version.json
p "GET /flutter.js range"         -H 'Range: bytes=0-9' $WEB/flutter.js
p "GET /download traversal"       --path-as-is "$WEB/download/$PROJECT/../../etc/passwd"

p "session: no cookie"            $WEB/auth/session
p "session: HEAD"                 -I $WEB/auth/session
p "session: duplicate cookie"     -H 'Cookie: a=1; a=2' $WEB/auth/session
p "session: junk cookie header"   -H 'Cookie: ===;;;' $WEB/auth/session
p "session: unknown cookie value" -H 'Cookie: flumip_auth=garbage' $WEB/auth/session
p "session: valid cookie"         -H "Cookie: flumip_auth=$COOKIE_VALUE" $WEB/auth/session
p "session: valid + duplicate"    -H "Cookie: x=1; flumip_auth=$COOKIE_VALUE; x=2" $WEB/auth/session
p "session: POST"                 -X POST $WEB/auth/session

p "login"                         $WEB/auth/login
p "callback: no params"           $WEB/auth/callback
p "callback: state, no flow"      "$WEB/auth/callback?code=x&state=y"
p "logout: GET"                   $WEB/auth/logout
p "logout: POST cross-origin"     -X POST -H 'Origin: http://evil.example' $WEB/auth/logout
p "logout: POST no cookie"        -X POST $WEB/auth/logout
p "guest: POST"                   -X POST $WEB/auth/guest
p "guest: GET"                    $WEB/auth/guest
p "guest: cross-origin"           -X POST -H 'Origin: http://evil.example' $WEB/auth/guest

J='content-type: application/json'
p "api: POST auth.config"         -X POST -H "$J" -d '{}' $WEB/api/auth/config
p "api: GET"                      $WEB/api/auth/config
p "api: HEAD"                     -I $WEB/api/auth/config
p "api: PUT"                      -X PUT -H "$J" -d '{}' $WEB/api/auth/config
p "api: evil origin"              -X POST -H "$J" -H 'Origin: http://evil.example' -d '{}' $WEB/api/auth/config
p "api: same origin"              -X POST -H "$J" -H 'Origin: http://localhost:8082' -d '{}' $WEB/api/auth/config
p "api: dev loopback origin"      -X POST -H "$J" -H 'Origin: http://localhost:8083' -d '{}' $WEB/api/auth/config
p "api: preflight loopback"       -X OPTIONS -H 'Origin: http://localhost:8083' -H 'Access-Control-Request-Method: POST' -H 'Access-Control-Request-Headers: authorization,content-type' $WEB/api/auth/config
p "api: preflight evil"           -X OPTIONS -H 'Origin: http://evil.example' -H 'Access-Control-Request-Method: POST' $WEB/api/auth/config
p "api: gated, no bearer"         -X POST -H "$J" -d '{}' $WEB/api/project/getProjects
p "api: gated, junk bearer"       -X POST -H "$J" -H 'Authorization: Bearer garbage' -d '{}' $WEB/api/project/getProjects
p "api: gated, basic scheme"      -X POST -H "$J" -H 'Authorization: Basic Z2FyYmFnZQ==' -d '{}' $WEB/api/project/getProjects
p "api: ?auth= query"             -X POST -H "$J" -d '{}' "$WEB/api/project/getProjects?auth=garbage"
p "api: unknown endpoint"         -X POST -H "$J" -d '{}' $WEB/api/nope/nothing
p "api: malformed json"           -X POST -H "$J" -d '{' $WEB/api/auth/config
p "api: health"                   $WEB/api/
p "api direct: POST"              -X POST -H "$J" -d '{}' $API/auth/config
p "api direct: GET"               $API/auth/config
p "api direct: GET /"             $API/
p "api direct: evil origin"       -X POST -H "$J" -H 'Origin: http://evil.example' -d '{}' $API/auth/config

TOKEN=$(curl -sS -m 20 -H "Cookie: flumip_auth=$COOKIE_VALUE" $WEB/auth/session | python3 -c 'import sys,json; print(json.load(sys.stdin).get("token",""))')
p "api: bearer getProjects"       -X POST -H "$J" -H "Authorization: Bearer $TOKEN" -d '{}' $WEB/api/project/getProjects
p "api: bearer getProject"        -X POST -H "$J" -H "Authorization: Bearer $TOKEN" -d "{\"id\":$PROJECT}" $WEB/api/project/getProject
p "api: bad argument type"        -X POST -H "$J" -H "Authorization: Bearer $TOKEN" -d '{"id":"abc"}' $WEB/api/project/getProject
p "api: missing argument"         -X POST -H "$J" -H "Authorization: Bearer $TOKEN" -d '{}' $WEB/api/project/getProject

p "download: no cookie"           $WEB/download/$PROJECT/$FILE
p "download: file"                -H "Cookie: flumip_auth=$COOKIE_VALUE" $WEB/download/$PROJECT/$FILE
p "download: HEAD file"           -I -H "Cookie: flumip_auth=$COOKIE_VALUE" $WEB/download/$PROJECT/$FILE
p "download: missing file"        -H "Cookie: flumip_auth=$COOKIE_VALUE" $WEB/download/$PROJECT/nope.txt
p "download: bad id"              -H "Cookie: flumip_auth=$COOKIE_VALUE" $WEB/download/abc/$FILE
p "download: zip"                 -H "Cookie: flumip_auth=$COOKIE_VALUE" $WEB/download/$PROJECT/all.zip
echo "== leftover zips: $(find "${TMPDIR:-/tmp}" -maxdepth 2 -path "*/flumip-zips-*/*" 2>/dev/null | wc -l)"

p "ucsc: bad token"               $WEB/ucsc_track/nosuchtoken
p "upload: no cookie"             -X PUT --data-binary 'x' $WEB/snp_upload/999999/x.vcf.gz
p "upload: unknown set"           -X PUT -H "Cookie: flumip_auth=$COOKIE_VALUE" --data-binary 'x' $WEB/snp_upload/999999/x.vcf.gz
p "upload: cross-origin"          -X PUT -H 'Origin: http://evil.example' -H "Cookie: flumip_auth=$COOKIE_VALUE" --data-binary 'x' $WEB/snp_upload/999999/x.vcf.gz
p "upload: GET"                   $WEB/snp_upload/999999/x.vcf.gz

p "logout: POST with cookie"      -X POST -H "Cookie: flumip_auth=$COOKIE_VALUE" $WEB/auth/logout
p "session: after logout"         -H "Cookie: flumip_auth=$COOKIE_VALUE" $WEB/auth/session
p "api: bearer after logout"      -X POST -H "$J" -H "Authorization: Bearer $TOKEN" -d '{}' $WEB/api/project/getProjects
