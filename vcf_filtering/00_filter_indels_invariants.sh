#!/bin/bash
#SBATCH -p medium40

set -euo pipefail

################################################################################
#### SET-UP ####
################################################################################
## Software:
# VCFtools needs to be included in $PATH (v0.1.17; https://vcftools.github.io/index.html)
gatk3=/home/nibtve93/software/GenomeAnalysisTK-3.8-1-0-gf15c1c3ef/GenomeAnalysisTK.jar # (v3.8.1; https://gatk.broadinstitute.org/hc/en-us)

## Command-line args:
reference=$1
vcf_in=$2
vcf_out=$3

## Activate conda environment
conda activate java

## Report:
echo -e "\n\n###################################################################"
date
echo -e "#### 00_filter_indels_invariants.sh: Starting script."
echo -e "#### 00_filter_indels_invariants.sh: Reference genome: $reference"
echo -e "#### 00_filter_indels_invariants.sh: Input VCF: $vcf_in"
echo -e "#### 00_filter_indels_invariants.sh: Output VCF: $vcf_out \n\n"

################################################################################
#### REMOVE INDELS AND INVARIANT SITES ####
################################################################################
echo -e "#### 00_filter_indels_invariants.sh: Removing indels ...\n"
java -jar $gatk3 -T SelectVariants -R $reference -V $vcf_in -o $(dirname $vcf_in)/$(basename $vcf_in .vcf)/.tmp.vcf -selectType SNP

echo -e "#### 00_filter_indels_invariants.sh: Removing invariant sites ...\n"
vcftools --vcf $(dirname $vcf_in)/$(basename $vcf_in .vcf)/.tmp.vcf --recode --recode-INFO-all --max-non-ref-af 0.99 --min-alleles 2 --stdout > $vcf_out

## Report:
nvar_in=$(grep -cv "^#" $vcf_in)
nvar_out=$(grep -cv "^#" $vcf_out)
nvar_filt=$(( $nvar_in - $nvar_out ))

echo -e "\n\n"
echo -e "#### 00_filter_indels_invariants.sh: Number of sites in input VCF: $nvar_in"
echo -e "#### 00_filter_indels_invariants.sh: Number of sites in output VCF: $nvar_out"
echo -e "#### 00_filter_indels_invariants.sh: Number of sites filtered: $nvar_filt"
echo
echo -e "#### 00_filter_indels_invariants.sh: Listing output VCF:"
ls -lh $vcf_out
[[ $(grep -cv "^#" $vcf_out) = 0 ]] && echo -e "\n\n#### 00_filter_indels_invariants.sh: ERROR: VCF is empty\n" >&2 && exit 1

echo -e "\n#### 00_filter_indels_invariants.sh: Done with script."
date


