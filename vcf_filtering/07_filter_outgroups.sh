#!/bin/bash
#SBATCH -p medium40

set -euo pipefail

################################################################################
#### SET-UP ####
################################################################################
## Software:
# VCFtools needs to be included in $PATH (v0.1.17; https://vcftools.github.io/index.html)

## Command-line args:
vcf_in=$1
vcf_out=$2
rem_string=$3

## Report:
echo -e "\n\n###################################################################"
date
echo -e "#### 07_filter_outgroups.sh: Starting script."
echo -e "#### 07_filter_outgroups.sh: Input VCF: $vcf_in"
echo -e "#### 07_filter_outgroups.sh: Output VCF: $vcf_out"
echo -e "#### 07_filter_outgroups.sh: String to remove outgroups: $rem_string \n\n"

################################################################################
#### FILTER OUTGROUPS ####
################################################################################
echo -e "#### 07_filter_outgroups.sh: Filtering outgroups ...\n"
vcftools $rem_string --vcf $VCF_FILE --recode --recode-INFO-all --stdout > $vcf_out

## Report:
echo -e "\n#### 07_filter_outgroups.sh: Listing output VCF:"
ls -lh $vcf_out
[[ $(grep -cv "^#" $vcf_out) = 0 ]] && echo -e "\n\n#### 07_filter_outgroups.sh: ERROR: VCF is empty\n" >&2 && exit 1

echo -e "\n#### 07_filter_outgroups.sh: Done with script."
date

