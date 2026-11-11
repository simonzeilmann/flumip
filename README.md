# FLUMIP

FLUMIP is a web application for designing **molecular inversion probes (MIPs)**.
It puts a browser front end on [MIPGEN](https://github.com/shendurelab/MIPGEN):
you pick a reference genome, list the genes you want to capture, optionally mask
known SNPs, and FLUMIP runs MIPGEN on the server, shows its progress, and hands
you the probe designs as downloads and as a UCSC Genome Browser track.

It is self-hosted. One Linux server runs the application, its PostgreSQL
database, MIPGEN and the reference data; everybody else just uses a browser.

- [Quickstart](#quickstart) — a working server in about an hour, most of it downloading
- [Using FLUMIP](#using-flumip) — genomes, SNP sets, projects, results
- [Installing and operating a server](#installing-and-operating-a-server) — requirements, the two install scripts, an existing PostgreSQL, HTTPS, updates, backups
- [Docker](docs/docker.md) — the alternative: the whole server with Docker Compose
- [A public instance](docs/public-instance.md) — open to anyone, with an entry notice, guest projects that expire, and share links
- [Configuration](#configuration) — the Settings tab, email, single sign-on
- [Development](#development) — building, running and testing from source
- [License](#license) — MIT for FLUMIP; MIPGEN has its own terms

---

## Quickstart

This is the bare-metal install, as a systemd service. To run FLUMIP with Docker
Compose instead, follow [docs/docker.md](docs/docker.md#installing).

You need an **x86_64 Ubuntu or Debian** machine with **sudo** and **Docker**
(with your user in the `docker` group), at least **8 GB of RAM** (16 GB
recommended) and **20–50 GB of free disk** per genome (see [Requirements](#requirements)).

**1. Download a release and unpack it.** The archive contains the server, the
web app and both install scripts.

```bash
mkdir flumip && cd flumip
curl -fLO https://github.com/simonzeilmann/flumip/releases/latest/download/flumip-build.tar.gz
curl -fLO https://github.com/simonzeilmann/flumip/releases/latest/download/SHA256SUMS
sha256sum --check --ignore-missing SHA256SUMS     # must print: flumip-build.tar.gz: OK
tar -xzf flumip-build.tar.gz
```

Keep `SHA256SUMS` next to the tarball: `setup-flumip.sh --file` checks the
tarball against it again. Releases up to v0.8.0 publish
`flumip-build.tar.gz.sha256` instead, which is used the same way.

**2. Install MIPGEN, its tools and the hg38 reference data** into `/opt/flumip`.
This downloads several gigabytes from UCSC and NCBI.

```bash
./deployment/setup-mipgen.sh --download hg38
```

**3. Install the server.** This starts a PostgreSQL 18 container, generates the
configuration and secrets, applies the database migrations and installs a
systemd service. Use the hostname people will type into their browser.

```bash
./deployment/setup-flumip.sh --file flumip-build.tar.gz --host mips.example.org --yes
```

**4. Open the app** at `http://mips.example.org:9082` and finish setting up in
the browser:

1. **Settings** — sign in with the password `setup-flumip.sh` printed at the end
   ("The settings password of this new install is …") and change it at once.
   Until you do, `sudo cat /etc/flumip/initial-settings-password.env` shows it
   again; delete that file once it is changed. Installs made before this
   version started with `changeme`, and the tab warns until that is changed.
2. **Genomes & SNP** — open the **⋮** menu beside *Genomes* and choose **Scan for
   new genomes**. hg38 appears. Click
   **Build index** on it and wait: `bwa index` on a human genome takes about an
   hour, and the genome shows **Indexing** until it is done.
3. **Projects** — **Create project**, give it a name, choose the genome, add a
   few genes (for example `BRCA1`), then **Save and start**.
   Progress is shown live; when it finishes, **Download** the results or open
   them in **UCSC**.

That is a complete, working install. Before other people use it, put it
[behind HTTPS](#https-and-the-reverse-proxy).

---

## Using FLUMIP

The app has three tabs — **Projects**, **Genomes & SNP** and **Settings** — and a
search box that finds projects, genomes and SNP sets by name.

### Genomes

FLUMIP designs against reference genomes stored under
`/opt/flumip/data/genomes/<category>/<name>/`, for example
`/opt/flumip/data/genomes/human/hg38/`. `setup-mipgen.sh` can download
**hg38** (the default), **hg19**, **hg18** and **hs1** (T2T-CHM13); a Docker
install does the same with `fetch-genome`, into its data directory.

Each genome folder holds:

| Path | What it is |
| --- | --- |
| `fa/<name>.fa` | the reference sequence |
| `refGene.txt` | gene annotations, used to turn a gene symbol into coordinates |
| `snp/<set>/` | optional built-in SNP sets (a bgzipped VCF and its `.tbi` index) |

After adding or removing a folder, choose **Scan for new genomes** from the **⋮**
menu beside *Genomes*. MIPGEN needs a
**bwa index** of the genome: click **Build index** on it (the log goes to
`fa/bwa-index.log`). The genome picker marks a genome without one **Not
indexed**, and one being built **Indexing**. The **Active** switch hides a
genome from the project picker without deleting anything.

To add another genome later, run `setup-mipgen.sh` again with its name, for
example `./deployment/setup-mipgen.sh --download hg19`, then scan and index it.
With Docker it is `docker compose run --rm --no-deps flumip fetch-genome hg19`
(see [docs/docker.md](docs/docker.md#reference-genomes)).

### SNP sets

A SNP set is a VCF of known variants. MIPGEN uses it to avoid placing probe arms
over common polymorphisms, which would otherwise capture unevenly between
samples.

- **Built-in sets** come from a genome's `snp/` folder. `setup-mipgen.sh` (or
  `fetch-genome` with Docker) installs dbSNP common variants for hg38 and
  dbSNP 155 for hs1. Only an
  administrator can change or remove them.
- **Custom sets** are added from the genome's page with **Add a custom SNP
  set**, either by **uploading** a VCF and its index or by **fetching from a
  URL**. The VCF must be **bgzip**-compressed (`bgzip -c file.vcf > file.vcf.gz`,
  then `tabix -p vcf file.vcf.gz`); a plain gzip file is rejected. Tick **Share
  with everyone on this server** to make a set visible to other users; otherwise
  it is yours.

⚠️ A SNP set must be for **the same genome build** as the project. MIPGEN does not
check this, and coordinates from the wrong build silently produce the wrong
masking.

### Projects

A project is one probe design: a genome, an optional SNP set, a list of target
**genes**, and the MIPGEN options.

**Create project** opens one form for all of it:

- **Project** — a name and, optionally, a description.
- **Design target** — the **Genome**, optionally the **SNP set**, and **Add a
  gene** for each target. Genes are looked up by their HGNC symbol in the
  genome's `refGene.txt`.
- **MIP design options** — **Show options** exposes the MIPGEN parameters:
  capture size, arm lengths, tag sizes, scoring method, copy-number checks,
  tiling and so on. The defaults are MIPGEN's own and are a sensible starting
  point.
- **Run** — two switches:
  - **Delete intermediate files** — on by default. bwa's working files are
    most of a project's size and nothing reads them afterwards; switch it off
    only to keep them for debugging a design.
  - **Email me when it finishes** — shown once an administrator has
    [configured email](#email).

The form ends in three buttons:

- **Cancel** discards it. Nothing is stored until one of the other two is
  pressed.
- **Save** stores the project as a draft. It needs only a name. The project
  opens in the list, where the genome, the SNP set and the genes can still be
  changed, and where **Create BED file** (turns the gene list into target
  regions) and **Generate MIPs** (starts MIPGEN) start it when it is ready.
- **Save and start** stores the project, creates the BED file and starts
  MIPGEN in one go. It needs a genome and at least one gene. The project shows
  its live progress and the elapsed time.

If the project is stored but cannot be started — a gene that is not in the
genome, say — it is kept as a draft and a message says why. Fix it on the
project and start it from there.

### Results

When the design completes the project shows how long it took and how much it
produced, and offers:

- **MIPs result** — the probes MIPGEN picked (`*.picked_mips.txt`).
- **SNP MIPs result** — the extra probes MIPGEN designs carrying the alternate
  allele where a SNP falls under a probe arm (`*.snp_mips.txt`). Only relevant
  when the project uses a SNP set.
- **UCSC** — opens the design as a custom track in the UCSC Genome Browser, one
  link per chromosome. The track URL contains a per-project secret token, so it
  works without signing in; treat it like a share link.
- **Download** — each file individually, or **Download all** as one zip.
- **More** → **View track file** / **View design log**.

---

## Installing and operating a server

There are two ways to install FLUMIP. The two scripts below install it
directly on an Ubuntu or Debian host, as a systemd service. **Docker Compose**
runs the same server in containers and needs nothing on the host but Docker:
see **[docs/docker.md](docs/docker.md)**. With either one, MIPGEN is compiled
on your own machine and never comes prebuilt from FLUMIP; see [License](#license).

### Requirements

| | |
| --- | --- |
| **OS** | Ubuntu or Debian on x86_64. The scripts use `apt`, systemd and a `linux.x86_64` UCSC tool. |
| **Software** | `sudo`, `curl`, `openssl`, and Docker (unless you bring your own PostgreSQL 18 with `--db existing`). The installing user must be able to run `docker` without sudo: `sudo usermod -aG docker $USER`, then log out and back in. `setup-mipgen.sh` installs the rest: `git`, `wget`, `bwa`, `samtools`, `tabix`, `trf` and a build toolchain. |
| **Memory** | **8 GB minimum, 16 GB recommended.** `bwa` against hg38 needs about 5 GB on its own, during both indexing and design. Without enough memory the kernel kills it, and the design fails partway through. Add swap on a small machine. |
| **Disk** | **15–20 GB minimum per human genome** (sequence, bwa index, annotations, dbSNP); **20–50 GB recommended**, depending on the SNP files you add. Plus space for projects. A design whose intermediate files are kept can run to gigabytes. |
| **Network** | Outbound HTTPS to UCSC, NCBI and GitHub during installation. Users reach the server on one port, or on 443 behind a reverse proxy. |

### What the two scripts do

**`deployment/setup-mipgen.sh`** prepares everything MIPGEN needs and is run
once, then again whenever you want another genome:

- installs the bioinformatics tools with `apt`;
- clones MIPGEN, unmodified, at the full commit id in `mipgen.pin` into
  `/opt/flumip/MIPGEN`, refuses to build anything else, and builds it as you.
  `/opt/flumip`, `MIPGEN` and `tools` are writable only by root or you;
- installs UCSC's `bigGenePredToGenePred` (needed for hs1 only) only if it
  matches the SHA-256 in `ucsc-tools.pin`. UCSC replaces that file in place, so
  when the hash no longer matches, the script says so, prints the new hash and
  carries on without it; after checking the file yourself,
  `BIGGENEPRED_SHA256=<hash> ./deployment/setup-mipgen.sh` installs it;
- installs FLUMIP's `mipgen-trf` helper into `/opt/flumip/tools`, which lets
  MIPGEN accept the Tandem Repeats Finder that Ubuntu ships;
- creates `/opt/flumip/{data/genomes,data/custom_snp,projects,tools}`;
- downloads the reference data for the genomes you name (with `--download`);
- gives the service user (default `www-data`, `--service-user` to change) write
  access to `/opt/flumip/data` and `/opt/flumip/projects` only, and downloads
  genomes as that user.

An install made before this version has a `MIPGEN` directory the service could
write to. The next run does not trust it: it clones and builds it afresh once.

Run it with no arguments on a terminal for interactive prompts, or pass
switches to script it. `--help` lists them all.

**`deployment/setup-flumip.sh`** installs or updates the application itself:

- checks prerequisites, and warns if `setup-mipgen.sh` has not run;
- downloads the latest release (or uses `--file`, `--url`, `--release TAG`) and
  checks it against the `SHA256SUMS` published with the release (or its
  `.sha256`). A build it cannot check is refused unless you pass
  `--skip-checksum`;
- starts a `postgres:18` container, reachable from this machine only (or
  connects to an existing database with `--db existing --db-host … --db-port …
  --db-name … --db-user …`; the password is asked for, or read from
  `FLUMIP_DB_PASSWORD` with `--yes`). A new install connects as the role
  `flumip`, an ordinary role that owns the database, not as the superuser
  (`--db-user postgres` for the old behaviour);
- installs `/var/www/flumip` owned by root and read-only to the service;
- generates a random first settings password for a new install and shows it
  once;
- writes `config/production.yaml`, generates random secrets into
  `/etc/flumip/passwords.yaml`, and creates an optional settings file at
  `/etc/flumip/flumip.env`;
- applies database migrations;
- installs and starts the `flumip` systemd service, running as
  `www-data` (`--service-user` to change; `--no-restart` to leave it stopped),
  in a systemd sandbox: it can write only the projects, genome and custom SNP
  directories. If you move one of these in **Settings → Storage**, re-run the
  script (it reads the paths from the database), or pass
  `--writable-dir /that/dir`, or add `ReadWritePaths=/that/dir` with
  `sudo systemctl edit flumip`;
- keeps ports 9080 and 9081 to this machine with a firewall rule of its own
  (the `flumip-firewall` service, nftables). It touches no other port;
  `sudo systemctl stop flumip-firewall` lifts it and `--no-firewall` removes it;
- with `--pocket-id https://id.example.org`, also installs
  [Pocket ID](docs/pocket-id.md) as the server's own single sign-on, for a
  public instance with no institutional provider to sign in with;
- remembers the hostname, database, service user and Pocket ID in
  `/etc/flumip/setup.conf`, so a later run needs none of those switches.

Like the MIPGEN script, it prompts on a terminal when run with no switches.
`--help` lists every switch. An install looks like this:

| | |
| --- | --- |
| Install directory | `/var/www/flumip` |
| Service | `flumip` |
| Public port (web: app, API under `/api`, downloads, sign-in) | 9082 |
| Internal ports (API, Insights), firewalled to this machine by `flumip-firewall` | 9080, 9081 |
| Database (localhost only) | container `flumip_postgres`, volume `flumip_data`, port 5432 |
| Database role | `flumip`, owner of the database (installs before this version: `postgres`) |

⚠️ Installers before this layout named everything `flumip_production` (service,
`/var/www/flumip_production`, `postgres_production`, `/etc/flumip/*_production.*`).
`setup-flumip.sh` does not migrate such an install and stops if it finds one;
remove it with the `uninstall-flumip.sh` from that release first, after backing
up `/etc/flumip` and the database if you want to keep them.

### Using an existing PostgreSQL

Both ways of installing can use a PostgreSQL server you already run instead of
starting their own. It has to be **PostgreSQL 18**, with a database of its own
for FLUMIP and a user that may create tables in it: FLUMIP applies its
migrations on every start. Make that an ordinary role that owns the database,
not a superuser (`CREATE ROLE flumip LOGIN PASSWORD '…'; CREATE DATABASE flumip
OWNER flumip;`); the migrations create no extensions. FLUMIP connects without TLS, so keep the database on
a network you trust.

**With the scripts**, pass the connection to `setup-flumip.sh`. The password is
asked for, or read from `FLUMIP_DB_PASSWORD` with `--yes`:

```bash
FLUMIP_DB_PASSWORD=… ./setup-flumip.sh --db existing --db-host 10.0.0.5 \
  --db-port 5432 --db-name flumip --db-user flumip --yes
```

**With Docker**, install as in [docs/docker.md](docs/docker.md#installing),
with two changes before `docker compose up -d`:

1. In `.env`, replace the generated `FLUMIP_DB_PASSWORD` with the password of
   your database user, and set `FLUMIP_DB_NAME` to your database.
2. Next to `compose.yaml`, create `compose.override.yaml`. Docker Compose reads
   it on every command, so nothing else changes:

   ```yaml
   services:
     # The bundled database is not started.
     postgres:
       profiles: [bundled-database]

     flumip:
       depends_on: !reset {}
       environment:
         SERVERPOD_DATABASE_HOST: db.example.org
         SERVERPOD_DATABASE_PORT: "5432"
         SERVERPOD_DATABASE_USER: flumip
   ```

`docker compose ps` then shows only `flumip`, and `docker compose down -v` has no
database of its own to delete. Back up with `pg_dump` against your server, not
with the `docker compose exec postgres …` command in docs/docker.md.

**A database on the same machine as Docker** is reached as
`host.docker.internal`. Use that as `SERVERPOD_DATABASE_HOST`, and add to the
`flumip` service in `compose.override.yaml`:

```yaml
    extra_hosts:
      - host.docker.internal:host-gateway
```

The container reaches the host on Docker's bridge address (usually
`172.17.0.1`), not on `127.0.0.1`. PostgreSQL therefore has to listen on that
address (`listen_addresses` in `postgresql.conf`), and `pg_hba.conf` has to
accept the containers' addresses (`172.16.0.0/12` on a default Docker setup).
⚠️ A database that listens on `127.0.0.1` only cannot be reached from the
container at all. That includes the `flumip_postgres` container `setup-flumip.sh`
creates. To move such an install to Docker, follow
[Moving a bare-metal install to Docker](docs/docker.md#moving-a-bare-metal-install-to-docker),
which copies the database into the bundled one.

### HTTPS and the reverse proxy

FLUMIP serves plain HTTP. For anything beyond a trusted lab network, put a
reverse proxy in front that terminates TLS.

Everything a browser needs is on **one port**, the web port (9082): the app, its API calls (under `/api`), downloads, uploads,
sign-in and UCSC tracks. The proxy therefore needs a single upstream, and the
app finds its API on whatever address it was loaded from. There is nothing to
rebuild and no per-host setting for it.

With nginx and certbot:

```bash
sudo apt install nginx certbot python3-certbot-nginx
```

```nginx
server {
    server_name mips.example.org;

    location / {
        proxy_pass http://127.0.0.1:9082;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # ⚠️ nginx's defaults break uploads and downloads, and the failures
        # look like application bugs rather than proxy limits.
        client_max_body_size 4G;        # the default is 1m; an SNP upload is 100M–1.5G
        proxy_request_buffering off;    # stream uploads through instead of spooling them
        proxy_buffering off;            # so a download starts at once
        proxy_read_timeout 3600s;       # a slow gigabyte legitimately takes a while
        proxy_send_timeout 3600s;
    }
}
```

```bash
sudo certbot --nginx -d mips.example.org
```

Once the proxy is in place, none of FLUMIP's ports needs to be reachable from
outside the machine. Serverpod always starts the API (9080) and Insights (9081)
servers too, on every address, and cannot be told otherwise; the app never uses
either, and `setup-flumip.sh` firewalls both to this machine. Firewall 9082 too
once the proxy is in place. The proxy has to pass the original host on
(`proxy_set_header Host $host;` above) or `FLUMIP_PUBLIC_URL` has to be set:
FLUMIP refuses browser requests that do not come from its own address.

Then re-run `setup-flumip.sh` with `--host` set to the public domain, so the
server advertises the right URL. If you use single sign-on, also set
`FLUMIP_PUBLIC_URL=https://mips.example.org`; see
[docs/authentication.md](docs/authentication.md).

### Updating

Re-run `setup-flumip.sh`. It downloads the latest release (or the one you name with `--release`, or the
tarball you pass with `--file`), keeps the existing database, secrets, settings
file and the choices of the first run, replaces the installed build, applies any
new migrations and restarts the service. Switches given on the re-run replace
the remembered values, for example `--host` after moving behind a proxy.

The first update of an install made before the security hardening also makes
the install directory root's, sandboxes the service and adds the firewall rule,
and `setup-mipgen.sh` should be run again so MIPGEN is cloned afresh. Do both
between designs. The database role and the settings password are kept; see
[docs/security.md](docs/security.md#upgrading-an-existing-install) for what is
left to do by hand.

### Operating

```bash
systemctl status flumip      # is it running?
journalctl -u flumip -f      # follow the log
sudo systemctl restart flumip
```

To reach a server that is not exposed, tunnel its web port to the **same port**
on your machine, for example `ssh -L 9082:localhost:9082 <host>`, then open
`http://localhost:9082`. On `localhost`, the app takes any port other than 9082,
8092 or 8082 for a `flutter run` and looks for a development server instead.

**Back up** `/etc/flumip/` (it holds the only copy of the database password), the
database volume `flumip_data`, and `/opt/flumip/projects` if the
designs matter to you. The reference data under `/opt/flumip/data/genomes` can
always be downloaded again.

### Uninstalling

**`deployment/uninstall-flumip.sh`** reverses both scripts. By default it removes
only the software and keeps everything that cannot be downloaded again:

| | Removed by default | Kept unless you pass |
| --- | --- | --- |
| Service and build | `flumip` unit, `/var/www/flumip`, the `flumip-firewall` unit and its rules | |
| MIPGEN | `/opt/flumip/MIPGEN` and `/opt/flumip/tools` (`--keep-mipgen` to keep them) | |
| Database | | `--database`: the `flumip_postgres` container, its volume `flumip_data`, and `/etc/flumip/{passwords.yaml,setup.conf,flumip.env,initial-settings-password.env}` |
| Projects | | `--projects`: `/opt/flumip/projects` |
| Genomes | | `--genomes`: `/opt/flumip/data/genomes`, bwa indexes included |
| Custom SNP sets | | `--custom-snps`: `/opt/flumip/data/custom_snp` |
| Packages | | `--packages`: `bwa`, `samtools`, `tabix`, `trf` |

`--purge` stands for the four data switches. A database connected with
`--db existing` is never dropped. If another FLUMIP service is on the machine (a
`flumip_<name>` unit, such as one from an older installer), MIPGEN stays and the
shared `/opt/flumip` data cannot be deleted while it is there. Reinstalling after a default uninstall
picks the kept database, projects and genomes up again.

```bash
./deployment/uninstall-flumip.sh --purge --dry-run    # see what would go
./deployment/uninstall-flumip.sh                      # interactive
```

It asks for confirmation on a terminal, and needs `--yes` without one.

The script knows nothing about a Docker install, and leaves it alone; that one is
removed with `docker compose`, see [docs/docker.md](docs/docker.md#uninstalling).

---

## Configuration

Almost everything is configured in the **Settings** tab and takes effect without
a restart. What FLUMIP does to protect a server, and the few switches for it
that live in the environment, are in [docs/security.md](docs/security.md).

**Who can open Settings:** anyone with the settings password while single
sign-on is off, and only the administrator addresses while it is on. The
password is stored hashed and the field is write-only: type a new one to change
it, or leave it empty to keep it.

| Section | What you set |
| --- | --- |
| **Storage** | Where projects, genomes and custom SNP sets live, and **Allowed SNP download hosts**, which restricts where SNP sets may be imported from by URL. The defaults match `setup-mipgen.sh`. |
| **External tools** | The tools directory, the MIPGEN executable and the helpers around it. The defaults match `setup-mipgen.sh`. |
| **Mail** | SMTP server, port, user, password, sender address, STARTTLS, and a **Send test email** button. |
| **Sign-in** | Single sign-on through OpenID Connect; see below. |
| **Security** | The settings password, and **Demo mode**, which deletes projects automatically after a set number of hours (default 168). Meant for public demonstration servers. |
| **Public instance** | **Public mode**, for a server anyone can use without an account: the entry notice, how long projects are kept, projects per visitor, and the imprint and privacy policy links. See [docs/public-instance.md](docs/public-instance.md). |
| **Run limits** | How many designs run at once (the rest wait in a queue) and the most bwa threads one design may use. Both off by default. |

### Email

Fill in the **Mail** section and switch on **Send email**. Users can then tick
**Email me when it finishes** on a design, and get a message when it succeeds or
fails. The project needs an owner to know whom to email, which in practice means
single sign-on is on.

### Single sign-on

FLUMIP runs **without any login by default**, which is a supported setup for a
trusted network. It can instead require everyone to sign in through your
organisation's identity provider: Keycloak, Microsoft Entra ID, Google
Workspace, Authentik, or anything else that speaks OpenID Connect.

With sign-in on, projects belong to whoever created them, administrators see
everything, and projects can optionally be shared by **department** using a
group claim from your provider.

- **[docs/authentication.md](docs/authentication.md)** — registering FLUMIP with
  your provider, the redirect URI, the settings, troubleshooting, and how to get
  back in if a configuration locks you out.
- **[docs/authorization.md](docs/authorization.md)** — who can see which project,
  what happens to existing projects when you switch sign-in on, and
  departments.

Most sign-in settings can also be fixed from `/etc/flumip/flumip.env`
(`FLUMIP_AUTH_ENABLED`, `FLUMIP_OIDC_ISSUER`, and so on, all listed in that
file), or, with Docker, from `.env` beside `compose.yaml`. A value set there
overrides the Settings tab, which then shows it read-only.
`FLUMIP_AUTH_ENABLED=false` plus a restart (`docker compose up -d` with Docker)
is the way back in if sign-in ever locks you out.

---

## Development

### Layout

| Directory | What it is |
| --- | --- |
| `flumip_server/` | The [Serverpod](https://serverpod.dev) 4 backend: endpoints, services that drive MIPGEN, web routes for downloads, sign-in and UCSC tracks, database models and migrations. |
| `flumip_flutter/` | The Flutter web app. |
| `flumip_client/` | The client library, **generated** by `serverpod generate`. Do not edit it. |
| `deployment/` | The install scripts and systemd units, `fetch-genome.sh`, the MIPGEN pin (`mipgen.pin`), the optional Pocket ID's pin and unit (`pocket-id.pin`, `pocket-id.service`), and in `docker/` the Docker install: compose file, local MIPGEN build, entrypoint. |
| `Dockerfile` | The published Docker image (no MIPGEN); see [docs/docker.md](docs/docker.md). |
| `docs/` | Operator documentation. |
| `.github/workflows/` | CI, the staging and production deploys, and the release build. |

### Toolchain

- Flutter **3.50.0** (pinned in CI), which brings Dart 3.14. Not older: the app
  uses `material_ui`, which needs Dart 3.13
- Serverpod CLI **4.1.1**: `dart install serverpod_cli 4.1.1` (then put
  `~/.local/state/Dart/install/bin` on your `PATH`; `serverpod doctor` checks
  the result)
- Docker, for PostgreSQL 18 (compose also starts Redis, which the server does
  not use yet)

### Running locally

1. Create `flumip_server/config/passwords.yaml`. It is gitignored and must
   exist, otherwise the server and the tests hang waiting for a database. Use the
   passwords from `flumip_server/docker-compose.yaml`:

   ```yaml
   development:
     database: <POSTGRES_PASSWORD of the postgres service>
     redis: <requirepass of the redis service>
     serviceSecret: <any random string>
   test:
     database: <POSTGRES_PASSWORD of the postgres_test service>
     redis: <requirepass of the redis_test service>
   ```

2. Start the databases (development on port 8090, test on 9090):

   ```bash
   cd flumip_server
   docker compose up -d
   ```

3. Build the web app into the server, then start the server, applying
   migrations:

   ```bash
   cd flumip_flutter
   flutter build web --debug --no-web-resources-cdn && rm -rf ../flumip_server/web/app && cp -r build/web ../flumip_server/web/app
   cd ../flumip_server
   dart run bin/main.dart --apply-migrations
   ```

   While working on the server, run it under Serverpod's runner instead, which
   reloads it when a file is saved:

   ```bash
   cd flumip_server
   ./tool/dev.sh up      # start in the background
   ./tool/dev.sh last    # after an edit: reloaded, or the compile errors
   ./tool/dev.sh down
   ```

   `./tool/dev.sh ui` adds a terminal UI and runs the app in Chrome on port
   8083 with hot reload. The script's header lists the rest, and
   `tool/mcp.py` calls the runner's and Dart's MCP tools from a shell.

4. Open <http://localhost:8082>.

For a quicker edit loop, `flutter run -d chrome` in `flumip_flutter` talks to the
server's API at `localhost:8082/api`. Single sign-on and SNP uploads cannot work
that way, because both rely on a same-origin cookie; use the served build at
:8082 for those.

MIP design itself needs MIPGEN and an indexed genome on the development machine
too: run `deployment/setup-mipgen.sh` once.

**VS Code** users get all of this as launch configurations, among them
`Server`, `Frontend (debug)`, `Full stack (debug)`, and `Server (single sign-on)`, which
also starts a mock identity provider. Sign in there as `boss@uni.example` to
be an administrator; any other name signs you in as an ordinary user.

### Changing models or endpoints

After editing a `*.spy.yaml` model or an endpoint signature:

```bash
cd flumip_server
serverpod generate
serverpod create-migration     # only when a model changed
```

`serverpod generate` occasionally fails on its first run and succeeds on the
second. `create-migration` refuses to drop a column without `--force`. Read the
column it names before forcing it.

### Tests and checks

These are what CI runs on every pull request:

```bash
cd flumip_server
dart analyze
dart test --exclude-tags env
```

```bash
cd flumip_flutter
flutter analyze
flutter test
```

Tests tagged `env` need a real `/opt/flumip`, bwa and hg38, so CI skips them.

**Formatting is checked, but never on generated code.** `serverpod generate`
does not emit formatted output, so a bare `dart format lib` in `flumip_server`
rewrites generated files and the next generate undoes it. Use the same commands
as CI:

```bash
cd flumip_flutter && dart format lib test
```

```bash
cd flumip_server && dart format $(find lib bin test -name '*.dart' -not -path 'lib/src/generated/*' -not -path 'test/integration/test_tools/*')
```

### Branches, deploys and releases

- **`development`** is the default branch to work from and the base for pull
  requests. Every push runs the checks.
- **`staging`** deploys to the staging server. It is promoted by fast-forward,
  never through a pull request:
  `git push origin development:staging`, once `development`'s own checks are
  green.
- **`main`** deploys to production.
- **Releases** are cut by pushing a version tag. `release.yml` then builds the
  host-independent `flumip-build.tar.gz` that `setup-flumip.sh` downloads, builds
  the Docker image `ghcr.io/simonzeilmann/flumip` from that same tarball (tagged
  `X.Y.Z`, `X.Y` and `latest`) along with `flumip-docker.tar.gz`, the files a
  Docker install needs, and publishes the release only once both have passed:

  ```bash
  git tag v0.7.0
  git push origin v0.7.0
  ```

  Keep the tag in step with `version:` in `flumip_flutter/pubspec.yaml`, which is
  what the app reports about itself.

  ⚠️ GitHub creates the image's package **private** on the first push. Make it
  public once, in the package settings, or every Docker install fails to build.

---

## License

FLUMIP is released under the [MIT License](LICENSE).

**MIPGEN is not covered by it.** FLUMIP runs MIPGEN as a separate program and
contains none of its code, but it cannot design anything without it, and
MIPGEN has its own licence from the University of Washington. That licence
allows use, copying and modification **only for non-commercial academic and
research activities**, permits distribution only within your own organisation,
and refers every other use to license@uw.edu. `setup-mipgen.sh` downloads
MIPGEN, its bundled libraries (libsvm, Boost) and the reference data onto your
server; read `/opt/flumip/MIPGEN/LICENSE.txt` and make sure your use of the
installation falls within those terms.

The script installs MIPGEN exactly as its authors publish it. FLUMIP does not
patch it or ship a modified copy. What FLUMIP needed done differently lives in
FLUMIP's own code under the MIT licence: the UCSC track is built by the server
rather than by MIPGEN's Python script, and the TRF check is satisfied by the
`deployment/mipgen-trf` wrapper.

The same holds for Docker. The published image, `ghcr.io/simonzeilmann/flumip`,
contains FLUMIP and Debian's packages of `bwa` (GPL-3), `trf` (AGPL-3),
`samtools` and `tabix`, but **no MIPGEN**. `docker compose build` compiles MIPGEN
into a local image, `flumip-local`, which must stay inside your organisation and
must never be pushed to a registry. See [docs/docker.md](docs/docker.md#licences).

The reference genomes, gene annotations and dbSNP files the setup script fetches
come from UCSC and NCBI under their own terms of use.

