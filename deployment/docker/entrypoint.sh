#!/bin/sh
# flumip-entrypoint - starts FLUMIP in its container, and runs its helpers.
#
#   serve           (default) Start the server, applying any pending migrations.
#   fetch-genome …  Download reference data into /opt/flumip/data; see
#                   `fetch-genome --help`.
#   check           Check that MIPGEN, its tools and the data directories are
#                   usable, and say what is wrong if not.
#   anything else   Run it, as www-data.
#
# Everything runs as www-data (uid 33), as the systemd install does. The
# container starts as root only so a fresh bind mount — which Docker creates
# owned by root — can be handed over before the server needs to write to it.

set -eu

FLUMIP_UID=33
FLUMIP_GID=33
DATA_DIR=/opt/flumip/data
PROJECTS_DIR=/opt/flumip/projects
MIPGEN=/opt/flumip/MIPGEN/mipgen

# Runs "$@" as www-data, replacing this shell.
as_flumip() {
  if [ "$(id -u)" = 0 ]; then
    exec setpriv --reuid="$FLUMIP_UID" --regid="$FLUMIP_GID" --init-groups "$@"
  fi
  exec "$@"
}

# Like as_flumip, but returns.
run_as_flumip() {
  if [ "$(id -u)" = 0 ]; then
    setpriv --reuid="$FLUMIP_UID" --regid="$FLUMIP_GID" --init-groups "$@"
  else
    "$@"
  fi
}

# Hands data/ and projects/ to www-data if Docker has just created them.
#
# Only a directory owned by root is taken over, and only its top level: that is
# what Docker leaves behind when it creates a missing bind-mount source. Anything
# else belongs to somebody, and the existing layout from setup-mipgen.sh
# (group www-data, 775, setgid) already works as it is.
take_over_dirs() {
  [ "$(id -u)" = 0 ] || return 0
  for dir in "$DATA_DIR" "$PROJECTS_DIR"; do
    if [ "$(stat -c %u "$dir")" = 0 ]; then
      chown "$FLUMIP_UID:$FLUMIP_GID" "$dir"
    fi
  done
}

# Makes data/ and projects/ usable by www-data, or explains why they are not.
prepare_dirs() {
  take_over_dirs
  for dir in "$DATA_DIR" "$PROJECTS_DIR"; do
    if ! run_as_flumip test -w "$dir"; then
      echo "flumip: $dir is not writable by www-data (uid $FLUMIP_UID)." >&2
      echo "flumip: On the host: sudo chown -R $FLUMIP_UID:$FLUMIP_GID <the directory mounted there>" >&2
      exit 1
    fi
  done
  run_as_flumip mkdir -p "$DATA_DIR/genomes" \
    "$DATA_DIR/custom_snp/common" "$DATA_DIR/custom_snp/private"
}

check() {
  failed=0
  ok() { echo "  ok    $1"; }
  bad() { echo "  FAIL  $1"; failed=1; }
  note() { echo "  warn  $1"; }

  echo "FLUMIP container check"

  if [ -x "$MIPGEN" ]; then
    ok "MIPGEN at $MIPGEN"
  else
    bad "MIPGEN is not at $MIPGEN. This is the published image, which cannot include it; build the local one with deployment/docker/compose.yaml."
  fi
  if [ -x /opt/flumip/MIPGEN/tools/extract_coding_gene_exons.sh ]; then
    ok "MIPGEN's exon extraction script"
  else
    bad "MIPGEN's tools/extract_coding_gene_exons.sh is missing or not executable"
  fi

  # MIPGEN probes its -trf executable with no arguments and wants exit code 255.
  rc=0
  /opt/flumip/tools/mipgen-trf >/dev/null 2>&1 || rc=$?
  if [ "$rc" = 255 ]; then
    ok "mipgen-trf answers MIPGEN's probe"
  else
    bad "mipgen-trf exited $rc instead of 255; MIPGEN will reject TRF"
  fi

  for tool in bwa samtools tabix trf ps pgrep; do
    if command -v "$tool" >/dev/null 2>&1; then
      ok "$tool"
    else
      bad "$tool is not installed"
    fi
  done
  # The server runs kill without a shell, so the shell builtin does not count.
  if [ -x /usr/bin/kill ]; then ok "/usr/bin/kill"; else bad "/usr/bin/kill is not installed"; fi

  if [ -x /opt/flumip/tools/bigGenePredToGenePred ]; then
    ok "bigGenePredToGenePred (for fetch-genome hs1)"
  else
    note "bigGenePredToGenePred is missing; fetch-genome cannot set up hs1"
  fi

  # Taken over first, as `serve` would: a directory Docker has only just
  # created is root's until then, and that is not a fault.
  take_over_dirs
  for dir in "$DATA_DIR" "$PROJECTS_DIR"; do
    if run_as_flumip test -w "$dir"; then
      ok "$dir is writable by www-data"
    else
      bad "$dir is not writable by www-data (uid $FLUMIP_UID). On the host: sudo chown -R $FLUMIP_UID:$FLUMIP_GID <the directory mounted there>"
    fi
  done

  if [ "$failed" = 0 ]; then
    echo "All good."
  else
    echo "Some checks failed; see above."
  fi
  return "$failed"
}

command="${1:-serve}"
[ $# -gt 0 ] && shift

case "$command" in
  serve)
    prepare_dirs
    if [ ! -x "$MIPGEN" ]; then
      echo "flumip: ⚠️  MIPGEN is not installed in this image, so designs will fail." >&2
      echo "flumip: The published image cannot include it (its licence forbids" >&2
      echo "flumip: redistribution). Use deployment/docker/compose.yaml, which builds" >&2
      echo "flumip: it locally. See docs/docker.md." >&2
    fi
    # The command line of deployment/flumip_production.service. --apply-migrations
    # makes every start, including the first and every upgrade, bring the
    # database schema up to date.
    as_flumip bundle/bin/main \
      --mode=production \
      --server-id="${SERVERPOD_SERVER_ID:-production}" \
      --logging=normal \
      --role=monolith \
      --apply-migrations \
      "$@"
    ;;
  fetch-genome)
    prepare_dirs
    as_flumip fetch-genome "$@"
    ;;
  check)
    check
    ;;
  *)
    as_flumip "$command" "$@"
    ;;
esac
