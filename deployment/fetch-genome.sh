#!/bin/bash
# fetch-genome.sh - Download the reference data FLUMIP needs for a genome: the
# sequence, the refGene annotations and, where there is one, a built-in SNP set.
#
# Used by setup-mipgen.sh on a bare-metal install, and inside the Docker image as
# `docker compose run --rm flumip fetch-genome hg38`. It never uses sudo and never
# changes ownership, so it runs the same in both places; the caller decides who
# owns what.
#
# Usage:
#   fetch-genome.sh [--root DIR] genome...
#   fetch-genome.sh --list
#
# Options:
#   --root DIR   The FLUMIP base directory (default: /opt/flumip). Data goes to
#                DIR/data/genomes/human/<genome>/.
#   --list       Print the genomes this script knows and exit.
#   -h, --help   Show this help and exit.
#
# Genomes: hg38 hg19 hg18 hs1
#
# Anything already present is skipped, so re-running after an interrupted
# download picks up where it stopped. hs1 needs UCSC's bigGenePredToGenePred,
# taken from $BIGGENEPRED (default: DIR/tools/bigGenePredToGenePred).
#
# After it finishes, click "Scan for new genomes" in FLUMIP and build the bwa
# index from there.

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

KNOWN_GENOMES=("hg38" "hg19" "hg18" "hs1")

ROOT="/opt/flumip"
GENOMES=()

usage() {
  awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "$0"
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --root)
      if [[ -z "${2:-}" ]]; then
        echo -e "${RED}--root requires a value${NC}" >&2
        exit 1
      fi
      ROOT="$2"
      shift
      ;;
    --list)
      printf '%s\n' "${KNOWN_GENOMES[@]}"
      exit 0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo -e "${RED}Unknown option: $1${NC}" >&2
      echo "Run '$0 --help' for usage." >&2
      exit 1
      ;;
    *)
      GENOMES+=("$1")
      ;;
  esac
  shift
done

if [ ${#GENOMES[@]} -eq 0 ]; then
  echo -e "${RED}Name at least one genome: ${KNOWN_GENOMES[*]}${NC}" >&2
  exit 1
fi

# ⚠️ Every name is checked before anything is downloaded. This used to skip an
# unknown name with a message and carry on, so a typo in a list of three
# produced two genomes and an "all done" at the end of an hour of downloading.
for GENOME in "${GENOMES[@]}"; do
  if [[ ! " ${KNOWN_GENOMES[*]} " == *" $GENOME "* ]]; then
    echo -e "${RED}Unknown genome: $GENOME. Known: ${KNOWN_GENOMES[*]}${NC}" >&2
    exit 1
  fi
done

BIGGENEPRED="${BIGGENEPRED:-$ROOT/tools/bigGenePredToGenePred}"

# Unpacks $1 (a .gz in the current directory) beside itself. Each genome step
# below is skipped when its unpacked file exists, so a file that is there must
# be whole. gunzip -f wrote straight into it, and a run killed partway (power
# loss, the OOM killer, kill -9) left a truncated genome or refGene.txt that
# every later run trusted. Unpacking to a temporary name and renaming it at the end means the
# file only appears once it is complete. The .gz goes last, so a rerun after a
# failed unpack finds it and wget -N need not fetch it again.
unpack() {
  local out="${1%.gz}"
  gunzip -c "$1" > "$out.tmp"
  mv "$out.tmp" "$out"
  rm -f "$1"
}

for GENOME in "${GENOMES[@]}"; do
  echo -e "\n${GREEN}Setting up genome directories for $GENOME...${NC}\n"
  BASE_DIR="$ROOT/data/genomes/human/$GENOME"
  FA_DIR="$BASE_DIR/fa"
  FA_FILE="$FA_DIR/$GENOME.fa"
  REFGENE_FILE="$BASE_DIR/refGene.txt"
  mkdir -p "$FA_DIR"

  if [ "$GENOME" == "hg38" ]; then
    SNP_DIR="$BASE_DIR/snp/00-common_all"
    mkdir -p "$SNP_DIR"

    # Download refGene for hg38 if not present.
    if [ ! -f "$REFGENE_FILE" ]; then
      echo -e "\n${GREEN}Downloading refGene for hg38...${NC}\n"
      cd "$BASE_DIR"
      wget -N https://hgdownload.soe.ucsc.edu/goldenPath/hg38/database/refGene.txt.gz
      unpack refGene.txt.gz
    fi

    # Download SNP files for hg38 if not present.
    SNP1_FILE="$SNP_DIR/00-common_all.vcf.gz"
    SNP2_FILE="$SNP_DIR/00-common_all.vcf.gz.tbi"
    if [ ! -f "$SNP1_FILE" ] || [ ! -f "$SNP2_FILE" ]; then
      echo -e "\n${GREEN}Downloading SNP files for hg38...${NC}\n"
      cd "$SNP_DIR"
      wget -N https://ftp.ncbi.nih.gov/snp/organisms/human_9606/VCF/00-common_all.vcf.gz
      wget -N https://ftp.ncbi.nih.gov/snp/organisms/human_9606/VCF/00-common_all.vcf.gz.tbi
    fi

    # Download hg38 genome sequence if not present.
    if [ ! -f "$FA_FILE" ]; then
      echo -e "\n${GREEN}Downloading hg38 genome sequence...${NC}\n"
      cd "$FA_DIR"
      wget -N https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/latest/hg38.fa.gz
      unpack hg38.fa.gz
    fi

  elif [ "$GENOME" == "hg18" ]; then
    # Download refGene for hg18 if not present.
    if [ ! -f "$REFGENE_FILE" ]; then
      echo -e "\n${GREEN}Downloading refGene for hg18...${NC}\n"
      cd "$BASE_DIR"
      wget -N https://data.broadinstitute.org/igvdata/annotations/hg18/refGene.txt
    fi

    # Download hg18 genome sequence if not present.
    if [ ! -f "$FA_FILE" ]; then
      echo -e "\n${GREEN}Downloading hg18 genome sequence...${NC}\n"
      cd "$FA_DIR"
      wget -N https://hgdownload.soe.ucsc.edu/goldenPath/hg18/bigZips/hg18.fa.gz
      unpack hg18.fa.gz
    fi

  elif [ "$GENOME" == "hg19" ]; then
    # Download refGene for hg19 if not present.
    if [ ! -f "$REFGENE_FILE" ]; then
      echo -e "\n${GREEN}Downloading refGene for hg19...${NC}\n"
      cd "$BASE_DIR"
      wget -N https://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/refGene.txt.gz
      unpack refGene.txt.gz
    fi

    # Download hg19 genome sequence if not present.
    if [ ! -f "$FA_FILE" ]; then
      echo -e "\n${GREEN}Downloading hg19 genome sequence...${NC}\n"
      cd "$FA_DIR"
      wget -N https://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/hg19.fa.gz
      unpack hg19.fa.gz
    fi

  elif [ "$GENOME" == "hs1" ]; then
    # Download hs1 genome sequence if not present.
    if [ ! -f "$FA_FILE" ]; then
      echo -e "\n${GREEN}Downloading hs1 genome sequence...${NC}\n"
      cd "$FA_DIR"
      wget -N https://hgdownload.soe.ucsc.edu/goldenPath/hs1/bigZips/hs1.fa.gz
      unpack hs1.fa.gz
    fi

    # Generate refGene for hs1 if not present.
    if [ ! -f "$REFGENE_FILE" ]; then
      echo -e "\n${GREEN}Generating refGene for hs1...${NC}\n"
      if [ ! -x "$BIGGENEPRED" ]; then
        echo -e "${RED}hs1 needs UCSC's bigGenePredToGenePred, which is not at $BIGGENEPRED.${NC}" >&2
        echo -e "${RED}Run setup-mipgen.sh, or set BIGGENEPRED to where it is.${NC}" >&2
        exit 1
      fi
      cd "$BASE_DIR"
      "$BIGGENEPRED" https://hgdownload.soe.ucsc.edu/gbdb/hs1/ncbiRefSeq/ncbiRefSeq.bb "$BASE_DIR/refWithoutBin.txt"
      # MIPGEN's exon extraction expects refGene.txt's layout, which starts
      # with the UCSC bin column that bigGenePredToGenePred leaves out. Prepend
      # it, computed from txStart/txEnd ($4/$5) by UCSC's binFromRange: the
      # smallest of the 128k, 1M, 8M, 64M or whole-chromosome bins that holds
      # the range. Written beside the target and moved into place, so a
      # failure leaves no refGene.txt for the next run to mistake for done.
      awk -F'\t' -v OFS='\t' '
        function ucsc_bin(start, end,   s, e, i, offsets) {
          split("585 73 9 1 0", offsets, " ")
          s = int(start / 131072); e = int((end - 1) / 131072)
          for (i = 1; i <= 5; i++) {
            if (s == e) return offsets[i] + s
            s = int(s / 8); e = int(e / 8)
          }
          return -1
        }
        /^[[:space:]]*$/ { next }
        {
          if (NF < 5 || $4 !~ /^[0-9]+$/ || $5 !~ /^[0-9]+$/ || (bin = ucsc_bin($4, $5)) < 0) {
            print "refWithoutBin.txt line " NR ": no transcript range to bin" > "/dev/stderr"
            exit 1
          }
          print bin, $0
        }' refWithoutBin.txt > refGene.txt.tmp
      mv refGene.txt.tmp refGene.txt
      rm refWithoutBin.txt
    fi

    # Set up SNP directory for hs1 with the new name and download SNP files.
    SNP_DIR="$BASE_DIR/snp/dbSNPv155"
    mkdir -p "$SNP_DIR"
    SNP1_FILE="$SNP_DIR/chm13v2.0_dbSNPv155.vcf.gz"
    SNP2_FILE="$SNP_DIR/chm13v2.0_dbSNPv155.vcf.gz.tbi"
    if [ ! -f "$SNP1_FILE" ] || [ ! -f "$SNP2_FILE" ]; then
      echo -e "\n${GREEN}Downloading SNP files for hs1...${NC}\n"
      cd "$SNP_DIR"
      wget -N https://hgdownload.soe.ucsc.edu/gbdb/hs1/dbSNP155/chm13v2.0_dbSNPv155.vcf.gz
      wget -N https://hgdownload.soe.ucsc.edu/gbdb/hs1/dbSNP155/chm13v2.0_dbSNPv155.vcf.gz.tbi
    fi
  fi
done

echo -e "\n${GREEN}Reference data ready for: ${GENOMES[*]}.${NC}"
echo -e "In FLUMIP, click \"Scan for new genomes\", then \"Build index\" on each new genome.\n"
