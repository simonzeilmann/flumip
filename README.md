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
- [Installing and operating a server](#installing-and-operating-a-server) — requirements, the two install scripts, HTTPS, updates, backups
- [Configuration](#configuration) — the Settings tab, email, single sign-on
- [Development](#development) — building, running and testing from source
- [License](#license) — MIT for FLUMIP; MIPGEN has its own terms

---

## Quickstart

You need an **x86_64 Ubuntu or Debian** machine with **sudo**, **git** and
**Docker**, at least **8 GB of RAM** and about **20 GB of free disk** for one
genome (see [Requirements](#requirements)).

**1. Download a release and unpack it.** The archive contains the server, the
web app and both install scripts.

```bash
mkdir flumip && cd flumip
curl -LO https://github.com/simonzeilmann/flumip/releases/latest/download/flumip-build.tar.gz
tar -xzf flumip-build.tar.gz
```

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

1. **Settings** — the settings password is `changeme`. Change it now; the tab
   warns until you do.
2. **Genomes & SNP** — click **Scan for new genomes**. hg38 appears. Click
   **Build index** on it and wait: `bwa index` on a human genome takes about an
   hour, and the genome shows **Indexing** until it is done.
3. **Projects** — **Create project**, choose the genome, add a few genes (for
   example `BRCA1`), then **Create BED file** and **Generate MIPs**.
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
**hg38** (the default), **hg19**, **hg18** and **hs1** (T2T-CHM13).

Each genome folder holds:

| Path | What it is |
| --- | --- |
| `fa/<name>.fa` | the reference sequence |
| `refGene.txt` | gene annotations, used to turn a gene symbol into coordinates |
| `snp/<set>/` | optional built-in SNP sets (a bgzipped VCF and its `.tbi` index) |

After adding or removing a folder, click **Scan for new genomes**. MIPGEN needs a
**bwa index** of the genome: click **Build index** on it (the log goes to
`fa/bwa-index.log`). The genome picker marks a genome without one **Not
indexed**, and one being built **Indexing**. The **Active** switch hides a
genome from the project picker without deleting anything.

To add another genome later, run `setup-mipgen.sh` again with its name, for
example `./deployment/setup-mipgen.sh --download hg19`, then scan and index it.

### SNP sets

A SNP set is a VCF of known variants. MIPGEN uses it to avoid placing probe arms
over common polymorphisms, which would otherwise capture unevenly between
samples.

- **Built-in sets** come from a genome's `snp/` folder. `setup-mipgen.sh`
  installs dbSNP common variants for hg38 and dbSNP 155 for hs1. Only an
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

1. **Create project** and give it a name and description. **Show options**
   exposes the MIPGEN parameters — capture size, arm lengths, tag sizes, scoring
   method, copy-number checks, tiling and so on. The defaults are MIPGEN's own
   and are a sensible starting point.
2. Choose the **Genome** and, optionally, the **SNP set**, and **Add a gene** for
   each target. Genes are looked up by their HGNC symbol in the genome's
   `refGene.txt`.
3. **Create BED file** turns the gene list into target regions.
4. **Generate MIPs** starts MIPGEN. The project shows its live progress and the
   elapsed time. Two optional switches:
   - **Delete intermediate files** — on by default. bwa's working files are
     most of a project's size and nothing reads them afterwards; switch it off
     only to keep them for debugging a design.
   - **Email me when it finishes** — shown once an administrator has
     [configured email](#email).

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

### Requirements

| | |
| --- | --- |
| **OS** | Ubuntu or Debian on x86_64. The scripts use `apt`, systemd and a `linux.x86_64` UCSC tool. |
| **Software** | `sudo`, `git`, `curl`, `openssl`, and Docker (unless you bring your own PostgreSQL 18 with `--db existing`). `setup-mipgen.sh` installs the rest: `bwa`, `samtools`, `tabix`, `trf`, a build toolchain and Python. |
| **Memory** | **8 GB minimum.** `bwa` against hg38 needs about 5 GB on its own, during both indexing and design. Without enough memory the kernel kills it, and the design fails partway through. Add swap on a small machine. |
| **Disk** | Roughly **15–20 GB per human genome** (sequence, bwa index, annotations, dbSNP), plus space for projects. A design whose intermediate files are kept can run to gigabytes. |
| **Network** | Outbound HTTPS to UCSC, NCBI and GitHub during installation. Users reach the server on one port, or on 443 behind a reverse proxy. |

### What the two scripts do

**`deployment/setup-mipgen.sh`** prepares everything MIPGEN needs and is run
once, then again whenever you want another genome:

- installs the bioinformatics tools with `apt`;
- clones MIPGEN, unmodified and pinned to a known commit, into
  `/opt/flumip/MIPGEN`, and builds it;
- installs FLUMIP's two helpers into `/opt/flumip/tools`: `mipgen-trf`, which
  lets MIPGEN accept the Tandem Repeats Finder that Ubuntu ships, and
  `add_bins_to_refgene.py`, which builds the hs1 gene annotations;
- creates `/opt/flumip/{data/genomes,data/custom_snp,projects,tools}`;
- downloads the reference data for the genomes you name (with `--download`);
- gives the service user (default `www-data`, `--service-user` to change) write
  access to `/opt/flumip`.

Run it with no arguments on a terminal for interactive prompts, or pass
switches to script it. `--help` lists them all.

**`deployment/setup-flumip.sh`** installs or updates the application itself:

- checks prerequisites, and warns if `setup-mipgen.sh` has not run;
- downloads the latest release (or uses `--file`, `--url`, `--release TAG`);
- starts a `postgres:18` container (or connects to an existing database with
  `--db existing --db-host … --db-port …`);
- writes `config/<env>.yaml`, generates random secrets into
  `/etc/flumip/passwords_<env>.yaml`, and creates an optional settings file at
  `/etc/flumip/flumip_<env>.env`;
- applies database migrations;
- installs and starts the `flumip_<env>` systemd service.

Like the MIPGEN script, it prompts on a terminal when run with no switches. Two
environments can live side by side on one machine:

| | `--prod` (default) | `--staging` |
| --- | --- | --- |
| Install directory | `/var/www/flumip_production` | `/var/www/flumip_staging` |
| Service | `flumip_production` | `flumip_staging` |
| Public port (web: app, API under `/api`, downloads, sign-in) | 9082 | 8092 |
| Internal ports (API, Insights) — keep firewalled | 9080, 9081 | 8090, 8091 |
| Database | container `postgres_production`, port 5432 | container `postgres_staging`, port 5433 |

### HTTPS and the reverse proxy

FLUMIP serves plain HTTP. For anything beyond a trusted lab network, put a
reverse proxy in front that terminates TLS.

Everything a browser needs is on **one port**, the web port (9082 for
production): the app, its API calls (under `/api`), downloads, uploads,
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
servers too, but the app never uses either; Insights is only for Serverpod's own
monitoring tool.

Then re-run `setup-flumip.sh` with `--host` set to the public domain, so the
server advertises the right URL. If you use single sign-on, also set
`FLUMIP_PUBLIC_URL=https://mips.example.org`; see
[docs/authentication.md](docs/authentication.md).

### Updating

Re-run `setup-flumip.sh`. It downloads the latest release (or the one you name
with `--release`), keeps the existing database, secrets and settings file,
applies any new migrations and restarts the service.

### Operating

```bash
systemctl status flumip_production      # is it running?
journalctl -u flumip_production -f      # follow the log
sudo systemctl restart flumip_production
```

**Back up** `/etc/flumip/` (it holds the only copy of the database password), the
database volume `flumip_production_data`, and `/opt/flumip/projects` if the
designs matter to you. The reference data under `/opt/flumip/data/genomes` can
always be downloaded again.

---

## Configuration

Almost everything is configured in the **Settings** tab and takes effect without
a restart.

**Who can open Settings:** anyone with the settings password while single
sign-on is off, and only the administrator addresses while it is on. The
password is stored hashed and the field is write-only: type a new one to change
it, or leave it empty to keep it.

| Section | What you set |
| --- | --- |
| **Paths** | Where genomes, projects, custom SNP sets, tools and the MIPGEN executable live. The defaults match `setup-mipgen.sh`. |
| **Mail** | SMTP server, port, user, password, sender address, STARTTLS, and a **Send test email** button. |
| **Sign-in** | Single sign-on through OpenID Connect; see below. |
| **Allowed SNP download hosts** | Restricts where SNP sets may be imported from by URL. |
| **Demo mode** | Deletes projects automatically after a set number of hours (default 168). Meant for public demonstration servers. |

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

Every sign-in setting can also be fixed from `/etc/flumip/flumip_<env>.env`
(`FLUMIP_AUTH_ENABLED`, `FLUMIP_OIDC_ISSUER`, and so on, all listed in that
file). A value set there overrides the Settings tab, which then shows it
read-only. `FLUMIP_AUTH_ENABLED=false` plus a restart is the way back in if
sign-in ever locks you out.

---

## Development

### Layout

| Directory | What it is |
| --- | --- |
| `flumip_server/` | The [Serverpod](https://serverpod.dev) 4 backend: endpoints, services that drive MIPGEN, web routes for downloads, sign-in and UCSC tracks, database models and migrations. |
| `flumip_flutter/` | The Flutter web app. |
| `flumip_client/` | The client library, **generated** by `serverpod generate`. Do not edit it. |
| `deployment/` | The install scripts and systemd units. |
| `docs/` | Operator documentation. |
| `.github/workflows/` | CI, the staging and production deploys, and the release build. |

### Toolchain

- Flutter **3.47.5** (pinned in CI), which brings Dart 3.12
- Serverpod CLI **4.0.1**: `dart pub global activate serverpod_cli 4.0.1`
- Docker, for PostgreSQL 18 and Redis

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
   flutter build web --debug && rm -rf ../flumip_server/web/app && cp -r build/web ../flumip_server/web/app
   cd ../flumip_server
   dart run bin/main.dart --apply-migrations
   ```

4. Open <http://localhost:8082>.

For a quicker edit loop, `flutter run -d chrome` in `flumip_flutter` talks to the
server's API at `localhost:8082/api`. Single sign-on cannot work that way, because it relies on
a same-origin cookie; use the served build at :8082 for anything behind sign-in.

MIP design itself needs MIPGEN and an indexed genome on the development machine
too: run `deployment/setup-mipgen.sh` once.

**VS Code** users get all of this as launch configurations: `Server`,
`Frontend (debug)`, `Full stack (debug)`, and `Server (single sign-on)`, which
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
  host-independent `flumip-build.tar.gz` that `setup-flumip.sh` downloads:

  ```bash
  git tag v0.7.0
  git push origin v0.7.0
  ```

  Keep the tag in step with `version:` in `flumip_flutter/pubspec.yaml`, which is
  what the app reports about itself.

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

The reference genomes, gene annotations and dbSNP files the setup script fetches
come from UCSC and NCBI under their own terms of use.

