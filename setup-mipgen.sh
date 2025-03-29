#!/bin/bash
# setup.sh - A script to install dependencies, clone MIPGEN, set up data directories,
# and optionally download required reference files for selected genomes.
# Supported genomes: hg18, hg19, hg38, hs1.
#
# Usage:
#   ./setup.sh -download [genome1 genome2 ...]
# If no genome is specified, defaults to hg38.

# Exit immediately if a command exits with a non-zero status.
set -e

# Define colors.
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No Color

# Default flags.
DOWNLOAD=false
GENOMES=()

# Parse command-line arguments.
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -download)
      DOWNLOAD=true
      ;;
    -*)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
    *)
      # Treat as genome name.
      GENOMES+=("$1")
      ;;
  esac
  shift
done

# If no genomes specified, default to hg38.
if [ ${#GENOMES[@]} -eq 0 ]; then
  GENOMES=("hg38")
fi

echo -e "\n${GREEN}Selected genomes: ${GENOMES[*]}${NC}\n"

# Update system package repository.
echo -e "\n${GREEN}Updating system packages...${NC}\n"
sudo apt update

# Install required packages.
echo -e "\n${GREEN}Installing required packages: build-essential, tabix, samtools, bwa, trf, python-is-python3...${NC}\n"
sudo apt install build-essential tabix samtools bwa trf python-is-python3 -y

# Create the mipgen directory and clone the MIPGEN repository.
echo -e "\n${GREEN}Creating '/opt/flumip' directory and cloning MIPGEN repository...${NC}\n"
sudo mkdir -p /opt/flumip
sudo chown $USER:$USER /opt/flumip
cd /opt/flumip
if [ ! -d "MIPGEN" ]; then
  git clone https://github.com/simonzeilmann/MIPGEN.git
fi
cd MIPGEN

echo -e "\n${GREEN}Building MIPGEN...${NC}\n"
make

echo -e "\n${GREEN}Setting execute permissions for MIPGEN tools...${NC}\n"
chmod +x mipgen
chmod +x tools/extract_coding_gene_exons.sh
chmod +x tools/generate_ucsc_track.py
chmod +x tools/add_bins_to_refgene.py
cd ..

# Create the base directory structure.
echo -e "\n${GREEN}Setting up base data directories...${NC}\n"
mkdir -p /opt/flumip/data/genomes/
mkdir -p /opt/flumip/projects
mkdir -p /opt/flumip/tools
mkdir -p /opt/flumip/data/custom_snp/{common,private}

# Download and activate bigGenePredToGenePred (needed for hs1).
echo -e "\n${GREEN}Downloading bigGenePredToGenePred...${NC}\n"
cd /opt/flumip/tools
wget -N http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bigGenePredToGenePred
chmod +x bigGenePredToGenePred

# Download genomes if the download flag is set.
if $DOWNLOAD; then
  for GENOME in "${GENOMES[@]}"; do
    echo -e "\n${GREEN}Setting up genome directories for $GENOME...${NC}\n"
    if [ "$GENOME" == "hg38" ]; then
      BASE_DIR="/opt/flumip/data/genomes/human/hg38"
      FA_DIR="$BASE_DIR/fa"
      SNP_DIR="$BASE_DIR/snp/00-common_all"
      FA_FILE="$FA_DIR/hg38.fa"
      REFGENE_FILE="$BASE_DIR/refGene.txt"
      mkdir -p "$BASE_DIR"
      mkdir -p "$FA_DIR"
      mkdir -p "$SNP_DIR"

      # Download refGene for hg38 if not present.
      if [ ! -f "$REFGENE_FILE" ]; then
        echo -e "\n${GREEN}Downloading refGene for hg38...${NC}\n"
        cd "$BASE_DIR"
        wget -N https://hgdownload.cse.ucsc.edu/goldenPath/hg38/database/refGene.txt.gz
        gunzip -f refGene.txt.gz
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
        wget -N https://hgdownload.cse.ucsc.edu/goldenPath/hg38/bigZips/latest/hg38.fa.gz
        gunzip -f hg38.fa.gz
      fi

    elif [ "$GENOME" == "hg18" ]; then
      BASE_DIR="/opt/flumip/data/genomes/human/hg18"
      FA_DIR="$BASE_DIR/fa"
      FA_FILE="$FA_DIR/hg18.fa"
      REFGENE_FILE="$BASE_DIR/refGene.txt"
      mkdir -p "$BASE_DIR"
      mkdir -p "$FA_DIR"

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
        gunzip -f hg18.fa.gz
      fi

    elif [ "$GENOME" == "hg19" ]; then
      BASE_DIR="/opt/flumip/data/genomes/human/hg19"
      FA_DIR="$BASE_DIR/fa"
      FA_FILE="$FA_DIR/hg19.fa"
      REFGENE_FILE="$BASE_DIR/refGene.txt"
      mkdir -p "$BASE_DIR"
      mkdir -p "$FA_DIR"

      # Download refGene for hg19 if not present.
      if [ ! -f "$REFGENE_FILE" ]; then
        echo -e "\n${GREEN}Downloading refGene for hg19...${NC}\n"
        cd "$BASE_DIR"
        wget -N https://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/refGene.txt.gz
        gunzip -f refGene.txt.gz
      fi

      # Download hg19 genome sequence if not present.
      if [ ! -f "$FA_FILE" ]; then
        echo -e "\n${GREEN}Downloading hg19 genome sequence...${NC}\n"
        cd "$FA_DIR"
        wget -N https://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/hg19.fa.gz
        gunzip -f hg19.fa.gz
      fi

    elif [ "$GENOME" == "hs1" ]; then
      BASE_DIR="/opt/flumip/data/genomes/human/hs1"
      FA_DIR="$BASE_DIR/fa"
      FA_FILE="$FA_DIR/hs1.fa"
      REFGENE_FILE="$BASE_DIR/refGene.txt"
      mkdir -p "$BASE_DIR"
      mkdir -p "$FA_DIR"

      # Download hs1 genome sequence if not present.
      if [ ! -f "$FA_FILE" ]; then
        echo -e "\n${GREEN}Downloading hs1 genome sequence...${NC}\n"
        cd "$FA_DIR"
        wget -N https://hgdownload.soe.ucsc.edu/goldenPath/hs1/bigZips/hs1.fa.gz
        gunzip -f hs1.fa.gz
      fi

      # Generate refGene for hs1 if not present.
      if [ ! -f "$REFGENE_FILE" ]; then
        echo -e "\n${GREEN}Generating refGene for hs1...${NC}\n"
        cd "$BASE_DIR"
        /opt/flumip/tools/bigGenePredToGenePred https://hgdownload.soe.ucsc.edu/gbdb/hs1/ncbiRefSeq/ncbiRefSeq.bb "$BASE_DIR/refWithoutBin.txt"
        python /opt/flumip/MIPGEN/tools/add_bins_to_refgene.py refWithoutBin.txt refGene.txt
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

    else
      echo -e "${RED}Invalid genome option: $GENOME. Skipping.${NC}"
    fi
  done
fi

echo -e "\n${GREEN}Setup completed successfully for genomes: ${GENOMES[*]}.${NC}\n"
