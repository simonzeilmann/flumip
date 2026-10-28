# syntax=docker/dockerfile:1.7
#
# The published FLUMIP image: the server, the web app and the bioinformatics
# tools MIPGEN calls — but **not MIPGEN itself**.
#
# ⚠️ MIPGEN's licence (University of Washington) allows distributing it only
# within your own organisation, so a public image must not contain it. The
# install builds a small local image on top of this one that compiles upstream
# MIPGEN on the user's own machine: deployment/docker/mipgen.Dockerfile, driven
# by deployment/docker/compose.yaml. See docs/docker.md.
#
# Build from source (the repository root is the context, because the build
# needs flumip_client, flumip_flutter and flumip_server together):
#
#   docker build -t ghcr.io/simonzeilmann/flumip:dev .
#
# CI instead packages the exact bits of the release tarball, without building
# them a second time (see the `image` job in .github/workflows/release.yml):
#
#   docker buildx build --build-arg APP_SOURCE=release-tarball \
#     --build-context release-tarball=./dist .

# Where the application files come from: `app-from-source` builds them here;
# CI points this at a named build context holding the unpacked release tarball.
# BuildKit only builds the stages the chosen source needs, so the Flutter stage
# is skipped entirely in that case.
ARG APP_SOURCE=app-from-source

# --- Build: Flutter web app and Dart server ---------------------------------
#
# debian:trixie rather than a ready-made Flutter image: the usual one
# (ghcr.io/cirruslabs/flutter) lags behind the release FLUMIP builds with, and
# building on the runtime stage's own Debian release keeps the server binary
# and its native libraries on the glibc they will run against.
FROM debian:trixie AS build

# Keep in step with flutter-version in .github/workflows/*.yml.
ARG FLUTTER_VERSION=3.47.5

# build-essential: Serverpod 4 pulls in sqlite3, whose native build hook may
# compile C. The rest is what the Flutter tool itself needs.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential ca-certificates curl git unzip xz-utils zip \
 && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch "$FLUTTER_VERSION" \
      https://github.com/flutter/flutter.git /opt/flutter
ENV PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH \
    PUB_CACHE=/opt/pub-cache
RUN flutter --disable-analytics \
 && flutter config --no-cli-animations \
 && flutter precache --web --no-android --no-ios

WORKDIR /src

# Dependencies first, in their own layer, so a source change does not refetch
# them. flumip_client goes in whole: it is a path dependency of the web app.
COPY flumip_client/ flumip_client/
COPY flumip_server/pubspec.yaml flumip_server/pubspec.lock flumip_server/
COPY flumip_flutter/pubspec.yaml flumip_flutter/pubspec.lock flumip_flutter/
RUN cd flumip_server && flutter pub get \
 && cd ../flumip_flutter && flutter pub get

COPY flumip_server/ flumip_server/
COPY flumip_flutter/ flumip_flutter/
COPY LICENSE ./

# The same two builds as release.yml. APP_VERSION defaults to the pubspec's,
# which is what release.yml derives it from too.
ARG APP_VERSION=
ARG SITE_TITLE=FLUMIP
RUN version="${APP_VERSION:-$(grep '^version:' flumip_flutter/pubspec.yaml | awk '{print $2}')}" \
 && cd flumip_flutter \
 && flutter build web --release --wasm \
      --dart-define=APP_VERSION="$version" \
      --dart-define=SITE_TITLE="$SITE_TITLE" \
      --output ../flumip_server/web/app

# `dart build cli`, not `dart compile exe`: the latter skips build hooks, so the
# binary would lack its native libraries. The bundle has to travel intact, as
# the executable finds bundle/lib/ relative to itself.
RUN cd flumip_server && dart build cli --target bin/main.dart --output build

# Laid out like the release tarball, so either source fits the runtime stage.
RUN mkdir -p /out/web \
 && cp -r flumip_server/build/bundle /out/bundle \
 && cp -r flumip_server/migrations /out/migrations \
 && cp -r flumip_server/web/app /out/web/app \
 && cp LICENSE /out/LICENSE

FROM scratch AS app-from-source
COPY --from=build /out/ /

FROM ${APP_SOURCE} AS app

# --- Runtime ---------------------------------------------------------------
FROM debian:trixie-slim AS runtime

# What MIPGEN and the server call out to:
# - bwa, samtools, tabix and trf — MIPGEN's own dependencies; the same Debian
#   packages setup-mipgen.sh installs with apt.
# - ⚠️ procps. The server runs `ps`, `pgrep --list-full` and `/usr/bin/kill`
#   directly, without a shell (process_service.dart), and slim images leave
#   procps out. Without it every design looks finished the moment it starts,
#   and cancelling one kills nothing.
# - wget and ca-certificates — fetch-genome, and the health check.
#
# /usr/share/doc/*/copyright stays: bwa is GPL-3 and trf AGPL-3, and their
# notices travel with the binaries.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bwa samtools tabix trf procps wget ca-certificates \
 && rm -rf /var/lib/apt/lists/*

COPY --from=app /bundle /srv/flumip/bundle
COPY --from=app /migrations /srv/flumip/migrations
COPY --from=app /web /srv/flumip/web
COPY --from=app /LICENSE /srv/flumip/LICENSE
# Host-neutral: the repository's config/production.yaml names the author's own
# servers. Every value in it can be overridden by a SERVERPOD_* variable.
COPY deployment/docker/production.yaml /srv/flumip/config/production.yaml

COPY --chmod=755 deployment/mipgen-trf /opt/flumip/tools/mipgen-trf
COPY --chmod=755 deployment/fetch-genome.sh /usr/local/bin/fetch-genome
COPY --chmod=755 deployment/docker/entrypoint.sh /usr/local/bin/flumip-entrypoint
COPY deployment/mipgen.pin /usr/share/flumip/mipgen.pin

# The data directories the settings point at by default. ⚠️ Only data/ and
# projects/ are ever mounted over. A volume on /opt/flumip itself would hide
# MIPGEN and tools/, which live in the image.
#
# uid 33 is www-data in Debian and Ubuntu alike, so files a bare-metal install
# created under /opt/flumip keep working when that directory is bind-mounted.
#
# The last line: passwords.yaml must never ship, and release.yml refuses it too.
RUN mkdir -p /opt/flumip/data/genomes \
             /opt/flumip/data/custom_snp/common \
             /opt/flumip/data/custom_snp/private \
             /opt/flumip/projects \
 && chown -R 33:33 /opt/flumip/data /opt/flumip/projects \
 && test ! -e /srv/flumip/config/passwords.yaml

# ⚠️ The server must start here. server.dart reads web/app relative to the
# working directory, and Serverpod finds config/ and migrations/ the same way.
WORKDIR /srv/flumip

# Only the web port: it serves the app, the API under /api, downloads, uploads
# and sign-in. The API (9080) and Insights (9081) servers start too, but nothing
# needs to reach them.
EXPOSE 9082

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:9082/ || exit 1

LABEL org.opencontainers.image.title="FLUMIP" \
      org.opencontainers.image.description="Web front end for MIPGEN probe design. MIPGEN is not included; see docs/docker.md." \
      org.opencontainers.image.source="https://github.com/simonzeilmann/flumip" \
      org.opencontainers.image.licenses="MIT"

# Stays root so the entrypoint can fix up a fresh bind mount's ownership; it
# drops to www-data before starting anything.
ENTRYPOINT ["flumip-entrypoint"]
CMD ["serve"]
