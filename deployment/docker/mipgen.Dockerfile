# syntax=docker/dockerfile:1.7
#
# The image FLUMIP actually runs as: the published image plus MIPGEN, compiled
# here, on your machine, from its authors' repository.
#
# ⚠️ NEVER PUSH THIS IMAGE ANYWHERE. MIPGEN's licence (University of Washington)
# permits use for non-commercial academic and research activities and
# distribution only within your own organisation. That is why the published
# image leaves MIPGEN out and this file exists. compose.yaml tags the result
# `flumip-local:<version>`, with no registry in the name, so an accidental
# `docker push` has nowhere to go.
#
# Built by `docker compose build`; see docs/docker.md.

ARG FLUMIP_IMAGE=ghcr.io/simonzeilmann/flumip
ARG FLUMIP_VERSION=latest

FROM ${FLUMIP_IMAGE}:${FLUMIP_VERSION} AS mipgen-build

RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential git ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

# Upstream, unmodified, at the commit this FLUMIP version was released with.
# The pin travels inside the published image (deployment/mipgen.pin), so a new
# FLUMIP version that moves the pin rebuilds MIPGEN without anyone editing this.
# The pin is the full commit id, and the build stops unless HEAD is exactly it:
# an abbreviated id can be made to match another commit.
RUN . /usr/share/flumip/mipgen.pin \
 && git clone "$MIPGEN_REPO" /opt/flumip/MIPGEN \
 && cd /opt/flumip/MIPGEN \
 && git -c advice.detachedHead=false checkout -q "$MIPGEN_COMMIT" \
 && head="$(git rev-parse HEAD)" \
 && if [ "$head" != "$MIPGEN_COMMIT" ]; then \
      echo "MIPGEN is at $head, not the pinned $MIPGEN_COMMIT; not building it." >&2; exit 1; \
    fi \
 && make -f makefile \
 && chmod +x mipgen tools/extract_coding_gene_exons.sh

# UCSC's bigGenePredToGenePred, which fetch-genome needs for hs1. Fetched here
# rather than shipped in the published image: the UCSC Genome Browser tools are
# free for academic and non-profit use, but commercial use needs a licence, so
# they are no more FLUMIP's to redistribute than MIPGEN is.
#
# Checked against a pinned SHA-256, because UCSC publishes no checksums. Keep
# these two in step with deployment/ucsc-tools.pin, which explains the pin. UCSC
# replaces the file in place with each release, so the pin goes stale; then the
# tool is left out with a warning instead of failing the build, and only hs1 is
# affected (`check` reports it). After checking the new file yourself:
#   docker compose build --build-arg BIGGENEPRED_SHA256=<its sha256>
# An empty hash is refused the same way.
ARG BIGGENEPRED_URL=https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bigGenePredToGenePred
ARG BIGGENEPRED_SHA256=
RUN mkdir -p /out \
 && curl -fsSL --proto '=https' --proto-redir '=https' --tlsv1.2 --retry 3 \
      -o /tmp/bigGenePredToGenePred "$BIGGENEPRED_URL" \
 && got="$(sha256sum /tmp/bigGenePredToGenePred | cut -d' ' -f1)" \
 && if [ -n "$BIGGENEPRED_SHA256" ] && [ "$got" = "$BIGGENEPRED_SHA256" ]; then \
      install -m 755 /tmp/bigGenePredToGenePred /out/bigGenePredToGenePred; \
    else \
      echo "WARNING: bigGenePredToGenePred (sha256 $got) does not match the pinned" >&2; \
      echo "WARNING: '${BIGGENEPRED_SHA256}', so it is left out and hs1 cannot be set up." >&2; \
      echo "WARNING: After checking it: docker compose build --build-arg BIGGENEPRED_SHA256=$got" >&2; \
    fi \
 && rm -f /tmp/bigGenePredToGenePred

FROM ${FLUMIP_IMAGE}:${FLUMIP_VERSION}

# The compiler toolchain stays behind in the build stage. MIPGEN was compiled on
# this very image, so it links against the libstdc++ it will run with.
COPY --from=mipgen-build /opt/flumip/MIPGEN /opt/flumip/MIPGEN
# /out/ rather than the file: it is empty when the hash did not match.
COPY --from=mipgen-build /out/ /opt/flumip/tools/
