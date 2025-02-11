#!/bin/bash
# setup.sh - A script to install dependencies, clone MIPGEN, set up data directories,
# and optionally download required reference files and index the hg38 genome.

# Exit immediately if a command exits with a non-zero status.
set -e

# Define colors.
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No Color

# Flags
DOWNLOAD=false
INDEX=false

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -download)
      DOWNLOAD=true
      ;;
    -index)
      INDEX=true
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
  shift
done

# Check if hg38.fa file exists
FA_FILE="~/mipgen/data/genes/human/hg38/fa/hg38.fa"
FA_EXISTS=false
if [[ -f "$FA_FILE" ]]; then
  FA_EXISTS=true
fi

# Check if refGene.txt file exists
REFGENE_FILE="~/mipgen/data/genes/human/hg38/refGene.txt"
REFGENE_EXISTS=false
if [[ -f "$REFGENE_FILE" ]]; then
  REFGENE_EXISTS=true
fi

# If -index is set but not -download and hg38.fa doesn't exist, return an error
if $INDEX && ! $DOWNLOAD && ! $FA_EXISTS; then
  echo -e "${RED}Error: The -index flag requires the -download flag to be set first or an existing hg38.fa file.${NC}"
  exit 1
fi

# Update and upgrade system packages
echo -e "\n${GREEN}Updating and upgrading system packages...${NC}\n"
sudo apt update && sudo apt upgrade -y

# Install required packages
echo -e "\n${GREEN}Installing required packages: build-essential, tabix, samtools, bwa, trf...${NC}\n"
sudo apt install build-essential tabix samtools bwa trf python-is-python3 -y

# Create the mipgen directory and clone the MIPGEN repository
echo -e "\n${GREEN}Creating 'mipgen' directory and cloning MIPGEN repository...${NC}\n"
mkdir -p mipgen
cd mipgen
if [ ! -d "MIPGEN" ]; then
  git clone https://github.com/shendurelab/MIPGEN.git
fi
cd MIPGEN

echo -e "\n${GREEN}Building MIPGEN...${NC}\n"
make

echo -e "\n${GREEN}Setting execute permissions...${NC}\n"
chmod +x mipgen
chmod +x tools/extract_coding_gene_exons.sh
cd ..

# Create the directory structure for data etc.
echo -e "\n${GREEN}Setting up data directories...${NC}\n"
mkdir -p data/genes/human/hg38/{fa,snp} projects log

if $DOWNLOAD; then
  # Download and extract refGene file if not already present
  if ! $REFGENE_EXISTS; then
    echo -e "\n${GREEN}Downloading and extracting refGene data...${NC}\n"
    cd data/genes/human/hg38
    wget -N https://hgdownload.cse.ucsc.edu/goldenPath/hg38/database/refGene.txt.gz
    gunzip -f refGene.txt.gz
    cd ../..
  fi

  # Download SNP files
  echo -e "\n${GREEN}Downloading SNP files...${NC}\n"
  cd data/genes/human/hg38/snp
  wget -N https://ftp.ncbi.nih.gov/snp/organisms/human_9606/VCF/00-common_all.vcf.gz
  wget -N https://ftp.ncbi.nih.gov/snp/organisms/human_9606/VCF/00-common_all.vcf.gz.tbi
  cd ../..

  # Download and extract hg38 genome sequence if not already present
  if ! $FA_EXISTS; then
    echo -e "\n${GREEN}Downloading and extracting hg38 genome sequence...${NC}\n"
    cd fa
    wget -N https://hgdownload.cse.ucsc.edu/goldenPath/hg38/bigZips/latest/hg38.fa.gz
    gunzip -f hg38.fa.gz
    cd ../../..
  fi
fi

if $INDEX; then
  echo -e "\n${GREEN}Indexing hg38 genome with bwa...${NC}\n"
  bwa index "$FA_FILE"
fi

echo -e "\n${GREEN}Setup completed successfully.${NC}\n"
