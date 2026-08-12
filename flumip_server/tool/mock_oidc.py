#!/usr/bin/env python3
"""A stand-in OpenID Connect provider, for developing against single sign-on.

Type any username into the form and you are signed in as that user. A username
containing "@" is used as the email address as-is; anything else gets
"@uni.example" appended. That is the whole point of this file: it is what lets
alice, bob and an administrator be tested without configuring users anywhere.

## Why this is hand-written rather than a real mock server

The obvious choice, ghcr.io/navikt/mock-oauth2-server, does not put an `email`
claim in the token for an interactive login, and its `tokenCallbacks`
configuration is not applied on that path — so every sign-in failed with "The
identity provider did not tell this server your email address", and the only way
through was to hand-type JSON into the form's claims box each time.

## Why writing one is reasonable at all

`IdTokenClaims.parse` deliberately does not verify the token signature (see the
long comment on that class: the token arrives over TLS straight from the token
endpoint, which OIDC Core §3.1.3.7 permits). So this needs no signing keys, no
JWKS and no crypto library — the ID token below is a real JWT structurally, with
a signature segment that is never looked at.

⚠️ That is also why this must never be reachable from anywhere real. It will
issue a token for any username asked of it, with no authentication whatsoever.

## What it does check

PKCE, properly: the S256 challenge recorded at /authorize is verified against
the verifier presented at /token. It would be easy to skip, and skipping it
would mean the one security mechanism in this flow went untested locally.
"""

import base64
import hashlib
import json
import os
import secrets
import time
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(os.environ.get("PORT", "8080"))
ISSUER = os.environ.get("ISSUER", "http://localhost:9999/default")
DEFAULT_DOMAIN = os.environ.get("DEFAULT_DOMAIN", "uni.example")
DEFAULT_USER = os.environ.get("DEFAULT_USER", "boss@uni.example")
TOKEN_TTL = 3600

# code -> {"email", "name", "nonce", "challenge", "redirect_uri"}
CODES = {}
# access token -> claims, so /userinfo can answer
TOKENS = {}


def b64url(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).decode().rstrip("=")


def make_jwt(claims: dict) -> str:
    """A structurally valid JWT whose signature is never checked.

    `alg: none` would be the honest label, but some clients special-case it, and
    this one does not look at the header at all — so it claims RS256 and puts
    random bytes in the signature segment.
    """
    header = {"alg": "RS256", "typ": "JWT", "kid": "mock"}
    return ".".join([
        b64url(json.dumps(header).encode()),
        b64url(json.dumps(claims).encode()),
        b64url(secrets.token_bytes(32)),
    ])


def email_for(username: str) -> str:
    username = username.strip()
    return username if "@" in username else f"{username}@{DEFAULT_DOMAIN}"


LOGIN_FORM = """<!doctype html>
<html><head><meta charset="utf-8"><title>FLUMIP mock sign-in</title>
<style>
 body {{ font-family: system-ui, sans-serif; max-width: 34rem; margin: 4rem auto; padding: 0 1rem; }}
 input {{ font-size: 1rem; padding: .5rem; width: 100%; box-sizing: border-box; }}
 button {{ font-size: 1rem; padding: .6rem 1.2rem; margin-top: 1rem; cursor: pointer; }}
 .hint {{ color: #666; font-size: .875rem; line-height: 1.5; }}
 code {{ background: #f4f4f4; padding: .1rem .3rem; }}
</style></head>
<body>
  <h1>Mock identity provider</h1>
  <p class="hint">Development only. Any username signs in as that user — no
  password. A name without <code>@</code> becomes
  <code>name@{domain}</code>.</p>
  <form method="post">
    <input type="hidden" name="rq" value="{rq}">
    <label>Username<br><input name="username" value="{default_user}" autofocus></label>
    <button type="submit">Sign in</button>
  </form>
  <p class="hint">Administrators are whatever <code>oidcAdminEmails</code> says;
  by default <code>{default_user}</code>. Anyone else is an ordinary user.</p>
</body></html>
"""


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    # -- helpers ----------------------------------------------------------
    def send_json(self, payload, status=200):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def send_html(self, html, status=200):
        body = html.encode()
        self.send_response(status)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def send_redirect(self, location):
        self.send_response(302)
        self.send_header("Location", location)
        self.send_header("Content-Length", "0")
        self.end_headers()

    def log_message(self, fmt, *args):
        # One readable line per request; the default logs every asset too.
        print(f"[mock-oidc] {fmt % args}", flush=True)

    # -- routes -----------------------------------------------------------
    def do_GET(self):
        path = urllib.parse.urlparse(self.path).path
        query = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)

        if path.endswith("/.well-known/openid-configuration"):
            return self.send_json({
                "issuer": ISSUER,
                "authorization_endpoint": f"{ISSUER}/authorize",
                "token_endpoint": f"{ISSUER}/token",
                "userinfo_endpoint": f"{ISSUER}/userinfo",
                "jwks_uri": f"{ISSUER}/jwks",
                "response_types_supported": ["code"],
                "subject_types_supported": ["public"],
                "id_token_signing_alg_values_supported": ["RS256"],
                "scopes_supported": ["openid", "email", "profile"],
                "code_challenge_methods_supported": ["S256"],
                "token_endpoint_auth_methods_supported": [
                    "client_secret_basic",
                    "client_secret_post",
                ],
            })

        if path.endswith("/jwks"):
            # Empty on purpose: nothing verifies signatures here.
            return self.send_json({"keys": []})

        if path.endswith("/authorize"):
            # The request is round-tripped through the form so the POST does not
            # have to re-parse a URL it never saw.
            rq = b64url(json.dumps({
                "redirect_uri": query.get("redirect_uri", [""])[0],
                "state": query.get("state", [""])[0],
                "nonce": query.get("nonce", [""])[0],
                "challenge": query.get("code_challenge", [""])[0],
            }).encode())
            return self.send_html(LOGIN_FORM.format(
                rq=rq, default_user=DEFAULT_USER, domain=DEFAULT_DOMAIN))

        if path.endswith("/userinfo"):
            auth = self.headers.get("Authorization", "")
            claims = TOKENS.get(auth[7:]) if auth.startswith("Bearer ") else None
            if claims is None:
                return self.send_json({"error": "invalid_token"}, status=401)
            return self.send_json(claims)

        self.send_json({"error": "not_found"}, status=404)

    def do_POST(self):
        path = urllib.parse.urlparse(self.path).path
        length = int(self.headers.get("Content-Length", "0"))
        form = urllib.parse.parse_qs(self.rfile.read(length).decode())

        if path.endswith("/authorize"):
            username = form.get("username", [DEFAULT_USER])[0]
            padded = form.get("rq", [""])[0]
            rq = json.loads(base64.urlsafe_b64decode(
                padded + "=" * (-len(padded) % 4)))

            code = secrets.token_urlsafe(24)
            CODES[code] = {
                "email": email_for(username),
                "name": username,
                "nonce": rq["nonce"],
                "challenge": rq["challenge"],
                "redirect_uri": rq["redirect_uri"],
            }
            sep = "&" if "?" in rq["redirect_uri"] else "?"
            return self.send_redirect(
                f"{rq['redirect_uri']}{sep}code={code}"
                f"&state={urllib.parse.quote(rq['state'])}")

        if path.endswith("/token"):
            code = form.get("code", [""])[0]
            entry = CODES.pop(code, None)
            if entry is None:
                return self.send_json(
                    {"error": "invalid_grant",
                     "error_description": "unknown or already-used code"},
                    status=400)

            # PKCE, checked rather than assumed — see the module docstring.
            verifier = form.get("code_verifier", [""])[0]
            if entry["challenge"]:
                expected = b64url(hashlib.sha256(verifier.encode()).digest())
                if expected != entry["challenge"]:
                    return self.send_json(
                        {"error": "invalid_grant",
                         "error_description": "PKCE verification failed"},
                        status=400)

            client_id = form.get("client_id", [""])[0]
            if not client_id:
                # client_secret_basic: the id is the username half of the header.
                auth = self.headers.get("Authorization", "")
                if auth.startswith("Basic "):
                    decoded = base64.b64decode(auth[6:]).decode()
                    client_id = urllib.parse.unquote(decoded.split(":", 1)[0])

            now = int(time.time())
            claims = {
                "iss": ISSUER,
                "sub": entry["email"],
                "aud": client_id,
                "exp": now + TOKEN_TTL,
                "iat": now,
                "nonce": entry["nonce"],
                "email": entry["email"],
                "email_verified": True,
                "name": entry["name"],
            }
            access_token = secrets.token_urlsafe(32)
            TOKENS[access_token] = {
                "sub": entry["email"],
                "email": entry["email"],
                "email_verified": True,
                "name": entry["name"],
            }
            return self.send_json({
                "token_type": "Bearer",
                "expires_in": TOKEN_TTL,
                "id_token": make_jwt(claims),
                "access_token": access_token,
            })

        self.send_json({"error": "not_found"}, status=404)


if __name__ == "__main__":
    print(f"[mock-oidc] issuer {ISSUER}, listening on :{PORT}", flush=True)
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
