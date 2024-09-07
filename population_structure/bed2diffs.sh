#!/bin/bash
#SBATCH -p medium40

set -euo pipefail

################################################################################
#### SET-UP ####
################################################################################
## Software:
# BCFtools needs to be included in $PATH (v0.1.17; https://vcftools.github.io/index.html)
# bed2diffs of EEMS needs to be included in $PATH (https://github.com/dipetkov/eems)
# PLINK needs to be included in $PATH (v1.90b6.22; https://zzz.bwh.harvard.edu/plink/)

## Command-line args:
nt=$1
eems_dir=$2
vcf_file=$3
chrom_file=$4

## Report:
echo -e "\n\n###################################################################"
date
echo -e "#### bed2diffs.sh: Starting script."
echo -e "#### bed2diffs.sh: Number of threads: $nt"
echo -e "#### bed2diffs.sh: Directory for estimated effective migration surfaces: $eems_dir"
echo -e "#### bed2diffs.sh: Input VCF file: $vcf_file"
echo -e "#### bed2diffs.sh: Renaming file for chromosomes: $chrom_file \n\n"

################################################################################
#### ESTIMATE AVERAGE GENETIC DISSIMILARITY MATRIX ####
################################################################################
echo -e "#### bed2diffs.sh: Renaming chromosomes ...\n"
bcftools annotate --rename-chrs $chrom_file $vcf_file > $vcf_file.tmp

echo -e "#### bed2diffs.sh: Converting VCF to BED file ...\n"
plink --vcf $vcf_file.tmp --make-bed --double-id --chr-set 32 --out $eems_dir/$(basename $vcf_file .vcf)
rm $vcf_file.tmp

echo -e "#### bed2diffs.sh: Estimating average genetic dissimilarity matrix ...\n"
bed2diffs_v1 --bfile $eems_dir/$(basename $vcf_file .vcf) --nthreads $nt


echo -e "\n#### bed2diffs.sh: Done with script."
date

