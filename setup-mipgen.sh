#!/bin/bash
# setup.sh - A script to install dependencies, clone MIPGEN, set up data directories,
# download required reference files, and finally index the hg38 genome.

# Exit immediately if a command exits with a non-zero status.
set -e

# Define colors.
GREEN='\033[0;32m'
NC='\033[0m'  # No Color

# Update and upgrade system packages.
echo -e "\n${GREEN}Updating and upgrading system packages...${NC}\n"
sudo apt update && sudo apt upgrade -y

# Install required packages.
echo -e "\n${GREEN}Installing required packages: build-essential, tabix, samtools, bwa, trf...${NC}\n"
sudo apt install build-essential tabix samtools bwa trf python-is-python3 -y

# Create the mipgen directory and clone the MIPGEN repository.
echo -e "\n${GREEN}Creating 'mipgen' directory and cloning MIPGEN repository...${NC}\n"
mkdir -p mipgen
cd mipgen
git clone https://github.com/shendurelab/MIPGEN.git
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

# Download and extract refGene file.
echo -e "\n${GREEN}Downloading and extracting refGene data...${NC}\n"
cd data/genes/human/hg38
wget https://hgdownload.cse.ucsc.edu/goldenPath/hg38/database/refGene.txt.gz
gunzip refGene.txt.gz

# Download SNP files.
echo -e "\n${GREEN}Downloading SNP files...${NC}\n"
cd snp
wget https://ftp.ncbi.nih.gov/snp/organisms/human_9606/VCF/00-common_all.vcf.gz
wget https://ftp.ncbi.nih.gov/snp/organisms/human_9606/VCF/00-common_all.vcf.gz.tbi

# Download and extract hg38 genome sequence.
echo -e "\n${GREEN}Downloading and extracting hg38 genome sequence...${NC}\n"
cd ../fa
wget https://hgdownload.cse.ucsc.edu/goldenPath/hg38/bigZips/latest/hg38.fa.gz
gunzip hg38.fa

# At the end, perform the bwa index.
echo -e "\n${GREEN}Indexing hg38 genome with bwa...${NC}\n"
bwa index hg38.fa

echo -e "\n${GREEN}Setup completed successfully.${NC}\n"
