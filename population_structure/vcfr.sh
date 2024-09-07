#!/bin/bash
#SBATCH -p medium40

set -euo pipefail

################################################################################
#### SET-UP ####
################################################################################

## Command-line args
scripts_dir=$1
vcf_file=$2
out_file=$3

## Report:
echo -e "\n\n###################################################################"
date
echo -e "#### vcfr.sh: Starting script."
echo -e "#### vcfr.sh: Directory with scripts: $scripts_dir"
echo -e "#### vcfr.sh: Input VCF file: $vcf_file"
echo -e "#### vcfr.sh: Output file: $out_file \n\n"

################################################################################
#### ESTIMATE GENETIC DISTANCES BETWEEN INDIVIDUALS ####
################################################################################
echo -e "#### vcfr.sh: Estimating genetic distances between individuals ...\n"
Rscript $scripts_dir/vcfr.R $vcf_file $out_file

## Report:
echo -e "\n#### vcfr.sh: Done with script."
date

