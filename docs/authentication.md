# Authentication

FLUMIP can require everyone to sign in through your organisation's existing
identity provider — Keycloak, Microsoft Entra ID, Google Workspace, Authentik,
or anything else that speaks OpenID Connect.

**It is off by default, and leaving it off is a supported configuration.** On a
trusted network you can ignore this whole document; nothing in FLUMIP nags you to
turn it on, and the admin Settings tab keeps working as it always has, gated by
its own password.

## What this does and does not do

It handles **authentication**: proving who you are, and keeping strangers out.

It also handles **project ownership**: with sign-in switched on, a project belongs
to whoever created it, and other users neither see it in their list nor can open
it. Administrators see everything. That is documented separately in
[authorization.md](authorization.md) — read it before switching sign-in on for an
install that already has projects in it, because it explains what happens to the
projects you already have.

What it still does not do is anything finer-grained than that: no roles beyond
administrator, no sharing a project with a named colleague, no per-project
permissions. Projects can also be shared by department, using a group claim
from your provider — see the authorization document.

## The redirect URI, which is where most setups go wrong

Your identity provider will only send someone back to an address you have
registered with it in advance, and it must match **character for character**. Get
it wrong and the error appears at the provider, on a page that does not tell you
what value FLUMIP actually sent.

So start here: **the Settings tab shows the redirect URI this server computes.**
Open Settings, tick "Require sign-in", and register exactly the URI shown in the
box at the top of that section.

It is `<public origin>/auth/callback`, and the public origin is worked out in this
order:

1. The `FLUMIP_PUBLIC_URL` environment variable, if set.
2. The "Public URL of this server" setting, if set.
3. Otherwise, the `webServer` scheme, host and port from
   `config/<mode>.yaml`.

Three ways this goes wrong:

- **A reverse proxy terminates TLS.** Your browser is at
  `https://flumip.example.org` but the server still thinks it is at
  `http://flumip.example.org:9082`, because that is what its config says. Fix it
  by setting `FLUMIP_PUBLIC_URL=https://flumip.example.org`. This is the common
  case: `setup-flumip.sh` generates a plain-HTTP config and tells you to add
  nginx afterwards.
- **Plain HTTP at all.** Most providers refuse a non-HTTPS redirect URI unless
  the host is `localhost`. Put a reverse proxy with a certificate in front first.
- **A trailing slash on the issuer.** `https://idp.example.org/realms/staff/`
  becomes `https://idp.example.org/realms/staff//.well-known/openid-configuration`,
  which most providers answer with a 404. FLUMIP strips trailing slashes for you,
  but if you are testing the discovery URL by hand, that is why it 404s.

## Configuring your provider

FLUMIP needs a **confidential client** (one with a client secret) using the
**authorization code** flow with **PKCE**, and the `openid`, `email` and `profile`
scopes. It never asks for offline access and never stores a provider token: after
the initial code exchange it does not talk to your provider again.

The client secret never reaches the browser and is never sent back by the API.

### Keycloak

Clients → Create client → OpenID Connect. Then:

- Client authentication: **On** (this makes it confidential)
- Authentication flow: **Standard flow** only
- Valid redirect URIs: the URI from the Settings tab
- Credentials tab → copy the client secret

Issuer: `https://<keycloak>/realms/<realm>`

### Microsoft Entra ID

App registrations → New registration. Then:

- Redirect URI: platform **Web**, the URI from the Settings tab
- Certificates & secrets → New client secret
- Token configuration → add the **email** optional claim, otherwise Entra may
  return no email address and FLUMIP cannot identify the user

Issuer: `https://login.microsoftonline.com/<tenant-id>/v2.0`

### Google Workspace

Google Cloud console → APIs & Services → Credentials → Create OAuth client ID →
Web application. Add the URI from the Settings tab as an authorised redirect URI.

Issuer: `https://accounts.google.com`

Google will let anyone with a Google account through, so set the allowed email
domains (below) to your Workspace domain.

### Authentik

Applications → Providers → Create → OAuth2/OpenID Provider.

- Client type: **Confidential**
- Redirect URIs: the URI from the Settings tab

Issuer: `https://<authentik>/application/o/<slug>/`

### Shibboleth / SAML

FLUMIP speaks OpenID Connect only. A SAML-only identity provider needs an OIDC
bridge in front of it — Keycloak configured with a SAML identity provider is the
usual arrangement, and FLUMIP then points at Keycloak.

## Configuring FLUMIP

Two places, and the environment always wins.

### In the Settings tab

Open the Settings tab, enter the admin password, tick **Require sign-in**, and
fill in:

| Field | Notes |
| --- | --- |
| OIDC issuer | No trailing slash |
| Client ID | |
| Client secret | Write-only. Empty means "keep what is stored" |
| Public URL of this server | Needed behind a TLS-terminating proxy |
| Allowed email domains | Comma-separated. Empty allows everyone the provider authenticates |
| Administrator email addresses | Comma-separated. These can open Settings without the password |
| Scopes | Defaults to `openid email profile` |
| Sign-in button label | |

Then press **Test connection** — it fetches the discovery document and shows
either the provider's authorization endpoint or the error. Save.

Domain matching is on the full domain or a subdomain of it, case-insensitively:
`uni.example` admits `a@uni.example` and `b@dept.uni.example`, and does **not**
admit `c@evil-uni.example`.

### In the environment

The systemd units read `/etc/flumip/flumip_<env>.env`, created by
`setup-flumip.sh` with every key present but commented out. Anything set there
overrides the stored setting and shows read-only in the Settings tab, so nobody
saves a value that silently does nothing.

| Variable | Overrides |
| --- | --- |
| `FLUMIP_AUTH_ENABLED` | "Require sign-in". Works in **both** directions |
| `FLUMIP_OIDC_ISSUER` | OIDC issuer |
| `FLUMIP_OIDC_CLIENT_ID` | Client ID |
| `FLUMIP_OIDC_CLIENT_SECRET` | Client secret |
| `FLUMIP_OIDC_ALLOWED_DOMAINS` | Allowed email domains |
| `FLUMIP_OIDC_ADMIN_EMAILS` | Administrator addresses |
| `FLUMIP_OIDC_DEPARTMENT_CLAIM` | Department claim; see [authorization.md](authorization.md#departments) |
| `FLUMIP_PUBLIC_URL` | Public URL |
| `FLUMIP_AUTH_STRICT` | See "Why sign-in might not be enforced" |

A blank value counts as unset, so uncommenting a key and leaving it empty means
"not filled in yet" rather than "blank out the stored value".

Apply changes with `sudo systemctl restart flumip_<env>`. Settings-tab changes
take effect immediately, with no restart.

The client secret can also go in `config/passwords.yaml` as `oidcClientSecret`
under the shared section, if that fits your secret management better.

## Why sign-in might not be enforced

FLUMIP only refuses requests when **all three** of these hold:

1. "Require sign-in" is on, and
2. the issuer, client ID and client secret are all set, and
3. the provider's discovery document has been fetched successfully.

If sign-in is on but the configuration is incomplete or the provider cannot be
reached, FLUMIP **stays reachable without signing in** and logs a warning on every
refresh — and the Settings tab says so in an orange banner.

That is deliberate. Enforcing a sign-in that cannot succeed locks everyone out
permanently, including whoever needs to fix it. And it is not a security hole:
turning the flag on requires the admin password in the first place.

Once the provider *has* answered successfully, a later outage does **not** open
the door again — FLUMIP keeps the cached discovery document and keeps enforcing,
retrying every 30 seconds. A blip at your provider will not sign everyone out.

If you would rather fail closed, set `FLUMIP_AUTH_STRICT=true`. Requests are then
refused whenever sign-in is on, configuration or no configuration. Make sure you
have console access before you do.

## Verifying it works

1. Open the app in a private window. You should get a sign-in screen with your
   button label.
2. Sign in. You should land back on the app at a clean URL with no `code=` or
   `state=` left in the address bar.
3. Your email appears at the top right.
4. Reload. You should stay signed in.
5. Sign out. You should be back at the sign-in screen.

## Troubleshooting

**`invalid_redirect_uri`, or the provider says the redirect URI does not match.**
Compare the URI in the Settings tab with what is registered at the provider, exactly
— scheme, host, port, path, no trailing slash. This is nearly always the problem.

**Sign-in appears to do nothing: you click the button, the provider flashes past,
and you are back at the sign-in screen with no error.** The session cookie was
dropped. Either the public scheme says `https` while you are actually on plain
HTTP (the cookie is then marked `Secure` and the browser discards it), or you are
running the app from `flutter run` — see below.

**Discovery fails with a 404.** Check the issuer for a trailing slash or an extra
path segment. Fetch `<issuer>/.well-known/openid-configuration` with curl from the
server itself; if that works but FLUMIP does not, the server cannot reach the
provider (firewall, proxy, DNS).

**`The identity provider did not tell this server your email address.`** The
`email` scope is not granted, or the provider does not include it. For Entra ID,
add the `email` optional claim.

**`The ID token expired` or clock complaints.** The server's clock and the
provider's disagree by more than five minutes. Install NTP.

**`This sign-in link has already been used.`** Expected if you reload the callback
URL or use the back button — the authorization code is single-use. Start again
from the app.

**A restart signed nobody out.** Correct, and intended: sessions live in
PostgreSQL, not in memory. A deploy or restart does not disturb anyone.

**`flutter run -d chrome` cannot sign in.** That serves the app on its own port,
so the app is no longer same-origin with the server and the session cookie is not
sent. Build into `flumip_server/web/app` and open the server's web port instead.

## What this server checks in an ID token

Everything OpenID Connect Core §3.1.3.7 asks of a client in the authorization
code flow, except the signature — and that exception is the spec's own:

| Check | Where |
| --- | --- |
| `iss` matches the configured issuer | §3.1.3.7 item 1 |
| `aud` contains this client id | items 3 |
| **`azp` equals this client id when present, and is required when `aud` names several** | items 4 and 5 |
| `exp` has not passed, with five minutes of clock skew | item 9 |
| `nonce` matches the one sent with the request | item 11 |
| `sub` is present and non-empty | §2 |

⚠️ **The signature is not verified, deliberately.** §3.1.3.7 item 6 allows it:
the token arrives by direct TLS-authenticated communication with the token
endpoint, so TLS already establishes that the bytes came from the provider. The
precondition is structural — `IdTokenClaims.parse` has exactly one caller, the
`/auth/callback` route, acting on a body it just received. **Never add an
endpoint that accepts an ID token from a client.**

### email_verified

`email` decides two things here: the domain allowlist, and who gets the
administrator scope. Core §5.7 warns that the claim is neither guaranteed unique
nor guaranteed verified, so:

- **`email_verified: false` is refused.** At a provider that lets an account
  assert an address it does not own, accepting it would hand out the admin scope
  for the price of typing somebody else's address.
- **An absent claim is accepted**, because it is optional and plenty of
  providers omit it. It is logged when this install decides access by address,
  which is the only case where it matters.

Identity itself is keyed on `iss` + `sub`, never on the address — so a changed
email moves with the account rather than creating a second one.

## If you are locked out

In order of preference:

1. **Sign in as an administrator.** Any address on the admin list reaches the
   Settings tab with no password at all; untick "Require sign-in" there. This is
   the normal route, and it is why the admin list is worth keeping correct.
2. **The settings password — but only if sign-in is not being enforced.**
   ⚠️ Once sign-in *is* enforced, the password is refused, deliberately: a user
   who knows the shared password must not be able to reach an administrator's
   configuration with it.

   In practice this still covers the most common mistake. If the provider has
   **never** answered — a typo in the issuer, a firewall, a client ID that does
   not exist — FLUMIP does not enforce at all (it fails open rather than locking
   you out), so the password works and you can undo the change from the UI.

   What it does not cover is a provider that worked and then broke: FLUMIP keeps
   enforcing from its cached configuration, nobody can sign in, and the password
   will not help. Use option 3 or 4.
3. **The environment override.** Set `FLUMIP_AUTH_ENABLED=false` in
   `/etc/flumip/flumip_<env>.env` and `sudo systemctl restart flumip_<env>`.
4. **The database.**

   ```sql
   UPDATE settings SET "loginRequired" = false, "settingsPassword" = 'changeme';
   ```

   Change that password again immediately afterwards.

   ⚠️ **That column holds a PBKDF2 hash, not the password** — and the statement
   above still works anyway. A value that is not a hash is read as a password
   left there by an install that predates hashing: it is accepted once, and
   accepting it is what replaces it with a hash of itself. So writing a plaintext
   password in is a supported way back in, and the next sign-in tidies up after
   you. Nothing can read the real password out of that column, including this
   server.

## How it works, briefly

The whole OpenID Connect exchange runs on FLUMIP's *web* server, which is the
same origin that serves the app. The Flutter app never sees a provider token.

```
browser → GET  <site>/auth/login       redirect to your provider, with PKCE
provider → GET <site>/auth/callback    code exchanged server-to-server
                                       Set-Cookie: flumip_auth (HttpOnly)
                                       redirect to "/"
app     → GET  <site>/auth/session     cookie traded for a short-lived bearer
app     → API calls with Authorization: Bearer <token>
```

The cookie is `HttpOnly`, so no script — including a compromised FLUMIP page —
can read it. It is `SameSite=Lax` because it has to survive the cross-site
redirect back from your provider, and `Secure` only when the public scheme is
`https`, because a `Secure` cookie on a plain-HTTP install is silently discarded.

API calls — answered by the same server under `/api` — do not authenticate with
the cookie. They carry a bearer token instead, in an `Authorization: Bearer`
header, which the browser never attaches on its own, so no other site can make a
signed-in browser call the API. (Not `Basic`, which Serverpod offers for its own `id:hash` auth keys:
relic splits a decoded `Basic` value on a colon, so an opaque token without one is
rejected with a 400 before FLUMIP's own code runs.) That bearer is short-lived
(30 minutes), held only in memory, and re-minted from the cookie as needed. Signing
out revokes the browser session, which cascades to every bearer minted from it, so
other tabs lose access too.

Only sha256 hashes of the cookie and the bearer are stored. A database backup
yields no usable credentials.

FLUMIP does not verify the ID token's signature, which is permitted here because
the token arrives directly from the token endpoint over TLS, authenticated with
the client secret — OpenID Connect Core §3.1.3.7. That saves a JWKS cache and key
rotation handling. It is only sound because the token never comes from a client;
see the comment on `IdTokenClaims` in the server source.

Sessions last 12 hours and live in PostgreSQL, so restarts do not sign anyone out.
Expired rows are cleaned up opportunistically.
