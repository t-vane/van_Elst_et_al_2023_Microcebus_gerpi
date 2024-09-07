#!/bin/bash
#SBATCH -p medium40

set -euo pipefail

################################################################################
#### SET-UP ####
################################################################################

## Command-line args
scripts_dir=$1
geo_dist=$2
gen_dist=$3
string=$4
out=$5
gen_dist_sd=$6

## Report:
echo -e "\n\n###################################################################"
date
echo -e "#### ibd.sh: Starting script."
echo -e "#### ibd.sh: Directory with scripts: $scripts_dir"
echo -e "#### ibd.sh: Geographic distance matrix: $geo_dist"
echo -e "#### ibd.sh: Genetic distance matrix: $gen_dist"
echo -e "#### ibd.sh: String to specify IBD script to be used: $string"
echo -e "#### ibd.sh: Output prefix: $out"
echo -e "#### ibd.sh: Genetic distance standard deviation matrix (if applicable): $gen_dist_sd \n\n"

################################################################################
#### CONDUCT MANTEL TEST AND PLOT ISOLATION BY DISTANCE ####
################################################################################
echo -e "#### ibd.sh: Conducting Mantel test and plotting ...\n"
Rscript $scripts_dir/ibd$string.R $geo_dist $gen_dist $out $gen_dist_sd

## Report:
echo -e "\n#### ibd.sh: Done with script."
date

