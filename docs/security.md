# Security: what FLUMIP does, and what is yours to do

This page collects the protections a FLUMIP server has, the few switches for
them, and the steps an existing install needs by hand. Who may see which project
or SNP set is in [authorization.md](authorization.md); sign-in is in
[authentication.md](authentication.md).

## The browser can only reach FLUMIP from FLUMIP

- **The API accepts POST only, and only from FLUMIP's own pages.** On a server
  without sign-in, a page on another site can no longer use somebody's browser
  to change or delete projects. Scripts and tools that do not run in a browser
  (curl, automation) are unaffected.
- **Another web application of yours** that calls the API from a browser has to
  be listed: set `FLUMIP_ALLOWED_ORIGINS` to its origin, for example
  `https://tools.example.org`, several separated by commas.
- **Behind a reverse proxy**, forward the original host
  (`proxy_set_header Host $host;`, as in the README) or set `FLUMIP_PUBLIC_URL`.
  Otherwise the app's own requests are refused with "This request came from a
  page on another site".
- Serverpod's internal API port (9080) is not usable from a browser at all; the
  app uses `/api` on the web port. URL query parameters are ignored: arguments
  come from the request body only.
- **Signing out, entering as a guest and uploading** need a request from FLUMIP
  itself. Opening `/auth/logout` directly shows a page with a **Sign out**
  button.
- **A sign-in can only be finished in the browser that started it.** If the
  sign-in page says it "was not started in this browser", start again from the
  sign-in button.
- Every response tells the browser not to guess content types, not to show
  FLUMIP inside a frame on another site, and not to send FLUMIP's addresses to
  other sites. UCSC custom tracks are unaffected.

## The settings password

- **A new install no longer starts with `changeme`.** `setup-flumip.sh` and the
  Docker `init-env.sh` generate a random password, hand it to the server in
  `FLUMIP_INITIAL_SETTINGS_PASSWORD` and show it once. If that variable is not
  set, the server picks a random password itself and prints it once in its log,
  on a line starting with `FLUMIP INITIAL SETTINGS PASSWORD:`
  (`sudo journalctl -u flumip | grep 'INITIAL SETTINGS PASSWORD'`, or
  `docker compose logs flumip | grep 'INITIAL SETTINGS PASSWORD'`).
- The variable is read only when the settings are first created. Changing it
  later does nothing; change the password in **Settings**.
- An install that still has `changeme` keeps working, and the Settings tab
  keeps reminding you. Change it: whoever has this password can point FLUMIP at
  another program to run.
- Wrong guesses are slowed down; see
  [authentication.md](authentication.md#if-you-are-locked-out).

## Programs FLUMIP runs

- MIPGEN, bwa, samtools, tabix, TRF and the helper scripts run with a minimal
  environment (PATH, HOME, user, locale, time zone, TMPDIR). Database passwords
  and single sign-on secrets are never passed to them. The tools must be on the
  server's PATH.
- A project's name never reaches MIPGEN's command line; result files use a
  cleaned-up version of it.
- Every project option is checked before it is saved and again just before a
  design starts. Numbers must be between 0 and 1,000,000; arm lengths, arm
  length sums and tag sizes may contain only digits, commas and colons.
- "Download all" archives are built in a private temporary folder and deleted
  once sent.

## SNP sets

- An SNP set holds exactly one `.vcf.gz` and at most one `.tbi`. To replace the
  files, cancel the set and upload again.
- Someone who can open a project that uses a private SNP set sees the set's
  name, but not where its files are or where they came from.
- **Import from a web address.** Before connecting, the server looks the address
  up and refuses anything on a private, internal or reserved network. The
  connection then goes to exactly the address it checked, for the first request
  and every redirect, so a hostile DNS server cannot swap in an internal address
  in between. These downloads never use a proxy from the server's environment
  (`HTTP_PROXY`); a server that can only reach the internet through a proxy
  cannot import by address, and files are uploaded instead. To also stop the
  server fetching from arbitrary public sites, fill in **Allowed SNP download
  hosts** in Settings, for example
  `ftp.ncbi.nlm.nih.gov, ftp.ensembl.org, hgdownload.soe.ucsc.edu`.

## The server itself (bare-metal install)

- The program files (`/var/www/flumip`, `/opt/flumip/MIPGEN`,
  `/opt/flumip/tools`) belong to root or the installing admin. The service can
  write only its data: projects, genomes and custom SNP sets.
- The service runs in a systemd sandbox. If you move a data directory in
  **Settings → Storage**, re-run `setup-flumip.sh`, or it cannot write there.
- Ports 9080 and 9081 are kept to the machine by the `flumip-firewall` service.
  It adds one nftables table of its own and touches no other port.
  `sudo systemctl stop flumip-firewall` lifts it.
- The build is checked against the release's `SHA256SUMS` before it is
  installed; MIPGEN is built only from the exact commit in `mipgen.pin`.
- A new install's database role is an ordinary one, not the superuser.

## Upgrading an existing install

Re-running the two scripts does most of it. Do it between designs.

```bash
./deployment/setup-mipgen.sh --yes
```

```bash
./deployment/setup-flumip.sh --yes
```

What is left by hand:

1. **Change the settings password** if it is still `changeme`.
2. **If you moved a data directory** and the database is external without
   `psql` on the host, pass `--writable-dir /that/dir` once; it is remembered.
3. **Administrators and `email_verified`.** If your identity provider does not
   send `email_verified: true`, administrators sign in without admin rights
   after the upgrade. See
   [authentication.md](authentication.md#email_verified) before you upgrade.
4. **Optional: move off the database superuser.** The upgrade keeps the role
   the install has. To change it on a bare-metal install with the bundled
   database:

   ```bash
   sudo systemctl stop flumip
   PW="$(openssl rand -hex 24)"
   FLUMIP_ROLE_PW="$PW" docker exec -i -e FLUMIP_ROLE_PW flumip_postgres psql -U postgres -d flumip -v ON_ERROR_STOP=1 <<'SQL'
   \getenv pw FLUMIP_ROLE_PW
   CREATE ROLE flumip LOGIN PASSWORD :'pw';
   ALTER DATABASE flumip OWNER TO flumip;
   DO $$DECLARE r record; BEGIN
     FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' LOOP
       EXECUTE format('ALTER TABLE public.%I OWNER TO flumip', r.tablename);
     END LOOP;
   END$$;
   SQL
   # The superuser's password was FLUMIP's too; give it one nobody keeps.
   FLUMIP_ROLE_PW="$(openssl rand -hex 24)" docker exec -i -e FLUMIP_ROLE_PW flumip_postgres psql -U postgres -v ON_ERROR_STOP=1 <<'SQL'
   \getenv pw FLUMIP_ROLE_PW
   ALTER ROLE postgres PASSWORD :'pw';
   SQL
   sudo sed -i "s/^  database: .*/  database: '$PW'/" /etc/flumip/passwords.yaml
   sudo sed -i 's/^DB_USER=.*/DB_USER=flumip/' /etc/flumip/setup.conf
   ./deployment/setup-flumip.sh --yes
   ```

   For a database you run yourself, use the same SQL as a superuser, then
   `--db-user flumip`. For Docker, see "Database role" in
   [docker.md](docker.md).

## Environment switches

| Variable | What it does |
| --- | --- |
| `FLUMIP_ALLOWED_ORIGINS` | Extra origins whose pages may call the API from a browser |
| `FLUMIP_INITIAL_SETTINGS_PASSWORD` | The settings password of a new install; read once |
| `FLUMIP_OIDC_ADMIN_REQUIRE_VERIFIED_EMAIL` | `false` grants the admin list without a verified address |
| `FLUMIP_AUTH_ENABLED`, `FLUMIP_PUBLIC_MODE` | See [authentication.md](authentication.md#why-sign-in-might-not-be-enforced) |
