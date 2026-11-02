# Pocket ID: single sign-on you host yourself

A [public instance](public-instance.md) needs single sign-on, because that is how
its administrators get in: public mode refuses the settings password. Most
installs use their organisation's identity provider for this (see
[authentication.md](authentication.md)). When there is none to use, or you would
rather not depend on it, both installers can set up
[Pocket ID](https://pocket-id.org) next to FLUMIP.

Pocket ID is a small OpenID Connect provider that signs people in with
**passkeys** only: a phone, Windows Hello, Touch ID, a security key or a password
manager. It has no passwords to guess, and it comes with a web UI for managing
users. FLUMIP talks to it like any other provider, so nothing in FLUMIP itself
changes. Only installing it is new.

**It is optional and off by default.** Nothing in this document applies unless
you ask for it.

- [What you need](#what-you-need)
- [Installing with Docker](#installing-with-docker)
- [Installing without Docker](#installing-without-docker)
- [Setting it up](#setting-it-up)
- [Administration](#administration)
- [Backups](#backups)
- [Updating](#updating)
- [Removing it](#removing-it)

## What you need

- **A second hostname with HTTPS**, such as `id.example.org` beside
  `mips.example.org`. Passkeys need a secure origin, and your reverse proxy gives
  Pocket ID its certificate the same way it gives FLUMIP one.
- **A hostname you keep.** ⚠️ Passkeys are bound to Pocket ID's domain. Moving
  it later means every administrator registers a new passkey.
- **FLUMIP must reach that address itself.** The server fetches Pocket ID's
  discovery document and exchanges the sign-in code at
  `https://id.example.org`, so the name has to resolve, and the proxy answer,
  from the FLUMIP host, and with Docker from inside its container too.
- **A device that can hold a passkey** for every administrator.

## Installing with Docker

Pocket ID is a service in the same `compose.yaml`, under the `pocket-id`
profile, so it starts only when asked for. In the directory with the Docker
install files:

```bash
./init-env.sh --pocket-id https://id.example.org
```

This writes `pocket-id.env`, readable only by you, with the address and a new
encryption key, and switches the profile on in `.env`
(`COMPOSE_PROFILES=pocket-id`). It works on an install that already has its
`.env`, and never overwrites either file. Then:

```bash
docker compose up -d
```

Pocket ID is published on `127.0.0.1:1411` only. Proxy `https://id.example.org`
to it, as the README's
[HTTPS and the reverse proxy](../README.md#https-and-the-reverse-proxy)
describes for FLUMIP. None of FLUMIP's upload settings are needed for it.

| Variable in `.env` | Default | |
| --- | --- | --- |
| `COMPOSE_PROFILES` | unset | `pocket-id` starts Pocket ID with everything else |
| `POCKET_ID_PORT` | `1411` | Where it is published on the host, always on 127.0.0.1 |
| `POCKET_ID_DATA_DIR` | `./pocket-id-data` | Its database: users, passkeys and signing keys |

`pocket-id.env` is a file of its own rather than more lines in `.env`, because
the flumip container reads all of `.env`, and Pocket ID's key has no business
there.

## Installing without Docker

```bash
./setup-flumip.sh --pocket-id https://id.example.org
```

Or answer yes when the interactive run asks. Alongside FLUMIP this:

- downloads the Pocket ID binary pinned in `deployment/pocket-id.pin`, and refuses
  it unless it matches the hash pinned there
- installs it as `/opt/pocket-id/pocket-id`, running as the `pocket-id` user
- writes `/etc/flumip/pocket-id.env` (root only) with the address, a new
  encryption key, and `HOST=127.0.0.1`
- installs and starts the `pocket-id` systemd service, which keeps its data in
  `/var/lib/pocket-id`

The choice is remembered in `/etc/flumip/setup.conf` like the others, so later
runs keep Pocket ID up to date. `--no-pocket-id` removes it again, keeping its
data. `pocket-id.env` is never overwritten. If a re-run names a different
address, the script warns and leaves the file alone, because every passkey is
bound to the old one.

Proxy `https://id.example.org` to `127.0.0.1:1411`, for example:

```bash
sudo certbot --nginx -d id.example.org
# proxy_pass http://127.0.0.1:1411;
```

## Setting it up

Do this **before anyone else can reach Pocket ID**.

1. **Open `https://id.example.org/setup` at once.** ⚠️ Whoever opens it first
   becomes Pocket ID's administrator. It stops working once that account exists.
   Enter your name, username and email, then register a passkey.
2. **Mark your address as verified.** Under **Administration → Users**, open
   your account and click the envelope beside **Email**, then **Save**. ⚠️ FLUMIP
   refuses a sign-in whose address the provider calls unverified, and Pocket ID
   creates this first account unverified. Do the same for every administrator
   you add later.
3. **Create a group** under **Administration → User Groups**, such as
   `flumip-admins`, and add yourself on its **Users** tab.
4. **Create the client** under **Administration → OIDC Clients → Add OIDC
   Client**:
   - Name `FLUMIP`, client type **Confidential**
   - Callback URL `https://mips.example.org/auth/callback`, exactly as FLUMIP's
     Settings tab shows it
   - Copy the **client secret** now: it is shown only once.
   - On the client's **Access** tab, choose **Selected user groups** and tick
     your group. A new client lets nobody in until you do.
5. **Point FLUMIP at it**, in `.env` with Docker or `/etc/flumip/flumip.env`
   without:

   ```bash
   FLUMIP_OIDC_ISSUER=https://id.example.org
   FLUMIP_OIDC_CLIENT_ID=<client id>
   FLUMIP_OIDC_CLIENT_SECRET=<client secret>
   FLUMIP_OIDC_ADMIN_EMAILS=you@example.org
   FLUMIP_PUBLIC_URL=https://mips.example.org
   ```

   Apply with `docker compose up -d` or `sudo systemctl restart flumip`, sign in
   through **Administrator sign-in**, then switch on public mode as
   [public-instance.md](public-instance.md#switching-it-on) describes.

Sign-ups stay off unless you change that in Pocket ID's **Application
Configuration**, so nobody can create an account but you. Pocket ID reads that
setting, and whether new addresses count as verified, from its own UI, not from
its environment.

## Administration

Almost everything happens in Pocket ID's web UI.

| Task | How |
| --- | --- |
| Add an administrator | **Users → Add User**, mark the address verified, add them to the group. Then **⋯ → Login Code** and send them the link: they sign in once with it and register a passkey. Add their address to `FLUMIP_OIDC_ADMIN_EMAILS`. |
| Someone lost their passkey | **⋯ → Login Code** again. It works like a passkey until it expires, so send it to that person only. |
| The last administrator lost theirs | A one-time sign-in link, valid for an hour, from the server: see below. |
| Remove someone | Turn on **Account Disabled**, or take them out of the group: Pocket ID checks the group on every sign-in. Remove their address from the FLUMIP list too. |
| Who signed in when | Pocket ID's **Audit Log**. |

With nobody left who can sign in:

```bash
# Docker, in the install directory
docker compose exec pocket-id /app/pocket-id one-time-access-token <username or email>

# Without Docker
sudo systemd-run --pipe --wait --quiet -p User=pocket-id \
  -p EnvironmentFile=/etc/flumip/pocket-id.env -p WorkingDirectory=/var/lib/pocket-id \
  /opt/pocket-id/pocket-id one-time-access-token <username or email>
```

Anyone with that link can sign in as that user, so pass it on carefully.

If Pocket ID itself is down, FLUMIP's own way back still works:
`FLUMIP_PUBLIC_MODE=false` and a restart turn public mode off, and the settings
password opens Settings again.

## Backups

Back up Pocket ID's data **together with its encryption key**. One is useless
without the other.

| | Data | Key |
| --- | --- | --- |
| Docker | `pocket-id-data/` | `pocket-id.env` |
| Without Docker | `/var/lib/pocket-id/` | `/etc/flumip/pocket-id.env` |

## Updating

The Pocket ID version is pinned in each FLUMIP release, in
`deployment/pocket-id.pin` and in the image tag in `compose.yaml`, and the
release pipeline checks that the two agree. Updating FLUMIP updates Pocket ID:
re-run `setup-flumip.sh`, or with Docker download the new release's
`compose.yaml` and run `docker compose up -d`.

## Removing it

- **Docker:** remove `pocket-id` from `COMPOSE_PROFILES` in `.env`, then

  ```bash
  docker compose rm -sf pocket-id
  ```

  (`up -d --remove-orphans` does not do it: a service whose profile is off is
  still in the compose file, so it is no orphan.) Delete `pocket-id-data/` and
  `pocket-id.env` too if you no longer want them.
- **Without Docker:** `./setup-flumip.sh --no-pocket-id` removes the service and
  the binary, keeping the data. `./uninstall-flumip.sh --pocket-id-data` (or
  `--purge`) also deletes the data, the key and the `pocket-id` user. A plain
  `./uninstall-flumip.sh` removes Pocket ID's software with FLUMIP's and keeps
  its data.

Then switch FLUMIP back to another provider, or turn public mode off, before
anyone needs to sign in.
