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
 && apt-get install -y --no-install-recommends build-essential git ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Upstream, unmodified, at the commit this FLUMIP version was released with.
# The pin travels inside the published image (deployment/mipgen.pin), so a new
# FLUMIP version that moves the pin rebuilds MIPGEN without anyone editing this.
RUN . /usr/share/flumip/mipgen.pin \
 && git clone "$MIPGEN_REPO" /opt/flumip/MIPGEN \
 && cd /opt/flumip/MIPGEN \
 && git -c advice.detachedHead=false checkout -q "$MIPGEN_COMMIT" \
 && make \
 && chmod +x mipgen tools/extract_coding_gene_exons.sh

# UCSC's bigGenePredToGenePred, which fetch-genome needs for hs1. Fetched here
# rather than shipped in the published image: the UCSC Genome Browser tools are
# free for academic and non-profit use, but commercial use needs a licence, so
# they are no more FLUMIP's to redistribute than MIPGEN is.
ADD --chmod=755 https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bigGenePredToGenePred /out/bigGenePredToGenePred

FROM ${FLUMIP_IMAGE}:${FLUMIP_VERSION}

# The compiler toolchain stays behind in the build stage. MIPGEN was compiled on
# this very image, so it links against the libstdc++ it will run with.
COPY --from=mipgen-build /opt/flumip/MIPGEN /opt/flumip/MIPGEN
COPY --from=mipgen-build /out/bigGenePredToGenePred /opt/flumip/tools/bigGenePredToGenePred
