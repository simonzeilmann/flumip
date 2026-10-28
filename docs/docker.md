# Running FLUMIP with Docker

Docker is the second way to install FLUMIP, next to the two scripts the
[README](../README.md#installing-and-operating-a-server) describes. Both end up
running the same server, with the same database, against the same MIPGEN. Docker
needs nothing on the host beyond Docker itself: no apt packages, no systemd unit,
no `sudo` once Docker is installed.

- [How it fits together](#how-it-fits-together) — two images, and why
- [Requirements](#requirements)
- [Installing](#installing)
- [Reference genomes](#reference-genomes)
- [HTTPS](#https)
- [Configuration](#configuration)
- [Updating](#updating)
- [Backups](#backups)
- [Moving a bare-metal install to Docker](#moving-a-bare-metal-install-to-docker)
- [Uninstalling](#uninstalling)
- [Troubleshooting](#troubleshooting)
- [Licences](#licences)
- [Building the image yourself](#building-the-image-yourself)

---

## How it fits together

There are **two images**, and the difference matters.

| | `ghcr.io/simonzeilmann/flumip` | `flumip-local` |
| --- | --- | --- |
| What | The server, the web app, `bwa`, `samtools`, `tabix`, `trf` | The published image **plus MIPGEN** |
| Made by | FLUMIP's release pipeline | You, with `docker compose build` |
| Where | GitHub Container Registry, public | Your machine only |

**MIPGEN cannot be in a public image.** Its licence, from the University of
Washington, allows use for non-commercial academic and research work and
distribution only within your own organisation. So the published image leaves it
out, and `docker compose build` compiles it on your machine from its authors'
repository, at the commit that FLUMIP release was tested with. That is the same
thing `setup-mipgen.sh` does on a bare-metal install.

⚠️ **Never push `flumip-local` to a registry.** Its name has no registry in it,
so `docker push` has nowhere to send it, but a retag would. Keeping it inside
your organisation is your responsibility under MIPGEN's licence.

Inside the container everything lives where a bare-metal install has it:

| Path in the container | What | Where it comes from |
| --- | --- | --- |
| `/opt/flumip/MIPGEN` | MIPGEN | the local image |
| `/opt/flumip/tools` | `mipgen-trf`, `bigGenePredToGenePred` | the images |
| `/opt/flumip/data` | genomes and SNP sets | **mounted** from the host |
| `/opt/flumip/projects` | project results | **mounted** from the host |
| `/srv/flumip` | the server and web app | the published image |

The paths in the Settings tab therefore keep their defaults. Only `data` and
`projects` are mounted. ⚠️ Do not mount anything over `/opt/flumip` itself: it
would hide MIPGEN, and every design would fail.

## Requirements

| | |
| --- | --- |
| **Machine** | x86_64 (amd64). ARM is not supported yet. |
| **Software** | Docker Engine with the Compose plugin (`docker compose`, v2). |
| **Memory** | **8 GB minimum, 16 GB recommended.** `bwa` against hg38 needs about 5 GB, both while indexing and during a design. On Docker Desktop, raise the VM's memory limit to match. |
| **Disk** | **15–20 GB minimum per human genome**; **20–50 GB recommended**, depending on the SNP files you add. Plus space for projects, plus about 1 GB for the images. |
| **Network** | Outbound HTTPS to GitHub (images and MIPGEN), UCSC and NCBI (genomes). |

## Installing

**1. Download the install files** of a release and unpack them. They are the
compose file, the local MIPGEN build, a configuration template and a helper
script, pinned to that release.

```bash
curl -fL https://github.com/simonzeilmann/flumip/releases/latest/download/flumip-docker.tar.gz | tar -xz
cd flumip-docker
```

**2. Create the configuration.** This writes `.env` with a fresh database
password and service secret, readable only by you.

```bash
./init-env.sh
```

⚠️ **Installing again on the same machine? Copy the old `.env` instead.** Every
copy of these files names its database volume `flumip_db`, so a new install
directory picks up the database an earlier one left behind (`docker compose down`
keeps it). That database still has the password it was created with, and the new
one from `init-env.sh` locks FLUMIP out of it. To run a second, separate install
next to the first, add `COMPOSE_PROJECT_NAME=<another name>` and another
`FLUMIP_PORT` to its `.env` before step 4.

**3. Build the local image.** It downloads the published image and compiles
MIPGEN on top of it. This takes a few minutes the first time.

```bash
docker compose build
```

**4. Start it.**

```bash
docker compose up -d
```

PostgreSQL starts first. FLUMIP waits until the database accepts connections,
then applies its migrations and starts. `docker compose ps` shows both
services as `healthy` once it is up.

**5. Fetch a genome** (see [Reference genomes](#reference-genomes)):

```bash
docker compose run --rm --no-deps flumip fetch-genome hg38
```

**6. Open the app** at `http://localhost:9082` and finish in the browser, exactly
as in the README's [Quickstart](../README.md#quickstart): change the settings
password (`changeme`), **Scan for new genomes**, **Build index**, create a
project.

By default the port is reachable from this machine only. Read [HTTPS](#https)
before letting anyone else use it.

## Reference genomes

```bash
docker compose run --rm --no-deps flumip fetch-genome hg38
docker compose run --rm --no-deps flumip fetch-genome hg19 hs1
docker compose run --rm --no-deps flumip fetch-genome --list
```

`fetch-genome` is the same script `setup-mipgen.sh` uses, and it fetches the same
files: the sequence, `refGene.txt`, and dbSNP for hg38 and hs1. Anything already
present is skipped, so running it again after an interrupted download picks up
where it stopped. The files land in the data directory (`./data` by default),
owned by uid 33.

Then, in the app, click **Scan for new genomes** and **Build index** on the new
genome. Indexing runs `bwa index` inside the FLUMIP container. It takes about
an hour for a human genome and needs about 5 GB of memory.

You can also put a genome of your own under
`data/genomes/<category>/<name>/` on the host, with the layout the
[README](../README.md#genomes) describes, and scan for it.

## HTTPS

FLUMIP serves plain HTTP on one port, 9082, which the compose file publishes on
`127.0.0.1` only. Put a reverse proxy that terminates TLS in front of it, as the
README's [HTTPS and the reverse proxy](../README.md#https-and-the-reverse-proxy)
describes. Its nginx example works unchanged, `proxy_pass http://127.0.0.1:9082`
included, along with its upload and timeout settings, which matter.

Then set the address people use in `.env`, and apply it:

```bash
FLUMIP_PUBLIC_URL=https://mips.example.org
```

```bash
docker compose up -d
```

`FLUMIP_PUBLIC_URL` is what the single sign-on redirect is built from. Nothing
else needs it: the app finds its API, and builds its UCSC links, from the address
it was loaded from.

On a trusted network you can publish the port directly instead, with
`FLUMIP_BIND=0.0.0.0`. ⚠️ Docker writes its own firewall rules, and they bypass
`ufw`, so that really does open the port to the whole network.

## Configuration

Almost everything is set in the app's **Settings** tab, as on any install. `.env`
holds what has to be known before the server starts:

| Variable | Default | |
| --- | --- | --- |
| `FLUMIP_VERSION` | the release's | Which published image to build on |
| `FLUMIP_DB_PASSWORD` | generated | ⚠️ Read by PostgreSQL only when the database is first created. Changing it later locks FLUMIP out. |
| `FLUMIP_SERVICE_SECRET` | generated | Serverpod's service secret |
| `FLUMIP_BIND`, `FLUMIP_PORT` | `127.0.0.1`, `9082` | Where the web port is published on the host |
| `FLUMIP_DATA_DIR`, `FLUMIP_PROJECTS_DIR` | `./data`, `./projects` | Host directories for genomes and SNP sets, and for project results |
| `FLUMIP_DB_NAME` | `flumip` | The database name |
| `COMPOSE_PROJECT_NAME` | `flumip` | Names the containers and the database volume (`<name>_db`). Set it only for a second install on the same machine, before its first start. |
| `FLUMIP_AUTH_ENABLED`, `FLUMIP_OIDC_*`, `FLUMIP_PUBLIC_URL`, `FLUMIP_AUTH_STRICT` | unset | Single sign-on; see [authentication.md](authentication.md) |
| `FLUMIP_PUBLIC_MODE` | unset | A public instance for anonymous visitors; see [public-instance.md](public-instance.md) |

The sign-in variables work exactly as they do in `/etc/flumip/flumip_<env>.env`
on a bare-metal install. A value set here overrides the Settings tab, which then
shows it read-only, and `FLUMIP_AUTH_ENABLED=false` is the way back in if sign-in
ever locks you out. Apply any change with `docker compose up -d`.

The database lives in the Docker volume `flumip_db` (`<name>_db` with
`COMPOSE_PROJECT_NAME` set). It is not published to the
host. Use `docker compose exec postgres psql -U postgres flumip` to reach it.
To use a PostgreSQL server you already run instead, see
[Using an existing PostgreSQL](../README.md#using-an-existing-postgresql) in the
README.

## Updating

Set `FLUMIP_VERSION` in `.env` to the new release, then:

```bash
docker compose build --pull
docker compose up -d
```

The rebuild compiles MIPGEN again, at whatever commit the new release pins. The
server applies any new migrations when it starts. The database, genomes and
projects are untouched.

⚠️ A container restart stops any design that is running, just as restarting the
systemd service does. Update between designs. A design that was cut off is
marked failed, with a message saying it was interrupted.

If a release changes the compose file itself, its release notes say so. Download
its `flumip-docker.tar.gz` and copy your `.env` across.

## Backups

- **The database**:

  ```bash
  docker compose exec postgres pg_dump -U postgres -Fc flumip > flumip.dump
  ```

- **`.env`**. It holds the only copy of the database password.
- **The projects directory**, if the designs matter to you.

The genomes can always be downloaded again. Custom SNP sets in `data/custom_snp`
cannot, unless you still have the files.

## Moving a bare-metal install to Docker

The data needs no conversion. uid 33 is `www-data` on Debian and Ubuntu, inside
the container and out, so the files `setup-mipgen.sh` created keep working. In
the directory with the Docker install files:

1. Stop the old service and dump its database:

   ```bash
   sudo systemctl stop flumip_production
   docker exec postgres_production pg_dump -U postgres -Fc flumip_production > flumip.dump
   ```

2. Run `./init-env.sh`. Then in `.env`, point the data at the old directories and
   keep the old database name:

   ```bash
   FLUMIP_DATA_DIR=/opt/flumip/data
   FLUMIP_PROJECTS_DIR=/opt/flumip/projects
   FLUMIP_DB_NAME=flumip_production
   ```

   Copy any `FLUMIP_*` lines you use from `/etc/flumip/flumip_production.env`.

3. Restore the database into the new one and start everything:

   ```bash
   docker compose build
   docker compose up -d postgres
   docker compose exec -T postgres pg_restore -U postgres -d flumip_production --no-owner --clean --if-exists < flumip.dump
   docker compose up -d
   ```

4. Check that projects, genomes and settings are all there. Then remove the old
   service with `deployment/uninstall-flumip.sh` from the old release. By default
   it takes only the service, the installed build, and `/opt/flumip/MIPGEN` and
   `tools`, which the container does not use. It keeps the old database and,
   ⚠️ crucially, `/opt/flumip/data` and `/opt/flumip/projects`, which the
   container now uses:

   ```bash
   ./deployment/uninstall-flumip.sh --prod
   ```

   Once you are sure you will not go back, drop the old database as well:
   `./deployment/uninstall-flumip.sh --prod --database`. Never pass `--purge`,
   `--projects`, `--genomes` or `--custom-snps` here: those delete the very
   directories the Docker install is running on.

If you ever changed a path in **Settings → Storage** or **External tools** away
from its `/opt/flumip/...` default, set it back. Inside the container only the
defaults exist.

## Uninstalling

In the directory with the Docker install files:

```bash
docker compose down                  # stop and remove the containers; keeps the data
docker compose down -v               # …and delete the database volume as well
```

After a plain `down` the database stays in the volume `flumip_db`, and the next
install on this machine uses it, wherever its files are. Keep `.env` if you might
install again: its password is the only one that database accepts.

The genomes, SNP sets and projects are ordinary directories (`./data` and
`./projects` unless `.env` points elsewhere) owned by uid 33, so removing them
takes `sudo rm -rf data projects`. Or, without sudo and before `down`, empty them
from inside the container:

```bash
docker compose run --rm --no-deps flumip sh -c 'rm -rf /opt/flumip/data/* /opt/flumip/projects/*'
```

The local image, the one that contains MIPGEN, goes with
`docker image rm flumip-local:<version>`, the version being `FLUMIP_VERSION` in
`.env`. The published image is not tagged on your machine unless you pulled it
yourself: `docker compose build` fetches it into Docker's build cache, which
`docker builder prune` clears.
Finally delete `.env`, which holds the database password.

## Troubleshooting

The container checks itself:

```bash
docker compose run --rm --no-deps flumip check
```

It confirms that MIPGEN and its exon script are there, that the TRF helper
answers MIPGEN's probe, that every tool the server calls is installed, and that
the data directories are writable. If anything fails, it says what.

| Symptom | Cause |
| --- | --- |
| The log warns *MIPGEN is not installed in this image* | You are running the published image directly. Use `docker compose`, which builds `flumip-local`. |
| *… is not writable by www-data (uid 33)* | A host directory belongs to someone else. `sudo chown -R 33:33` it. |
| A design or an index build dies partway | Almost always memory. `bwa` needs about 5 GB. See `docker compose logs flumip` and the project's `mipgen.log`. |
| `FLUMIP_DB_PASSWORD is not set` | There is no `.env`. Run `./init-env.sh`. |
| The server cannot log in to the database after `.env` changed | The password only takes effect when the database is first created. Put the old one back. |
| The same, on a new install (*Failed to connect to the database*, over and over) | An earlier Docker install on this machine left its database in the volume `flumip_db`, and the new `.env` has a different password. Copy that install's `.env` across, or, if its data can go, `docker compose down -v` and `docker compose up -d` again. |

`docker compose logs -f flumip` follows the server log.

⚠️ `docker compose exec flumip …` runs as **root** and skips the entrypoint, so
anything it writes under `data/` or `projects/` ends up owned by root, where the
server cannot touch it. Use `docker compose exec --user www-data flumip …`, or
`docker compose run --rm --no-deps flumip …`, which runs as www-data like
everything else.

## Licences

The published image contains FLUMIP (MIT), plus Debian's packages of `bwa`
(GPL-3), `trf` (AGPL-3), and `samtools` and `tabix` (MIT/Expat). Their copyright
notices are in the image under `/usr/share/doc/<package>/copyright`. The
corresponding source is available from Debian, at
[sources.debian.org](https://sources.debian.org) and
[snapshot.debian.org](https://snapshot.debian.org) for the exact versions.

MIPGEN and UCSC's `bigGenePredToGenePred` are not in it. Both are fetched and
built only into your local image: MIPGEN for the licence reasons above, and the
UCSC tool because the UCSC Genome Browser tools need a licence for commercial
use. Make sure your use of your installation falls within MIPGEN's terms; see
the README's [License](../README.md#license) section.

## Building the image yourself

To build the published image from a checkout, for development or to test a
change, use the repository root as the context:

```bash
docker build -t ghcr.io/simonzeilmann/flumip:dev .
cd deployment/docker
./init-env.sh            # then set FLUMIP_VERSION=dev in .env
docker compose build     # no --pull: uses the image you just built
docker compose up -d
```

The source build clones the Flutter SDK and builds the web app and the server,
which takes a while the first time. The release pipeline does not build it this
way: it packages the release tarball's own files with
`--build-arg APP_SOURCE=release-tarball --build-context release-tarball=<unpacked tarball>`,
so the image and the tarball carry the same bits.
