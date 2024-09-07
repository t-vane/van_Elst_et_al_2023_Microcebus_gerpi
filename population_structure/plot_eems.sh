#!/bin/bash
#SBATCH -p medium40

set -euo pipefail

################################################################################
#### SET-UP ####
################################################################################

## Command-line args
scripts_dir=$1
input=$2
out_dir=$3
pop_coords=$4
shape=$5

## Report:
echo -e "\n\n###################################################################"
date
echo -e "#### plot_eems.R: Starting script."
echo -e "#### plot_eems.R: Directory with scripts: $scripts_dir"
echo -e "#### plot_eems.R: Input prefix: $input"
echo -e "#### plot_eems.R: Output directory: $out_dir"
echo -e "#### plot_eems.R: File with population coordinates: $pop_coords"
echo -e "#### plot_eems.R: Shape file prefix: $shape \n\n"

################################################################################
#### PLOT ESTIMATED EFFECTIVE MIGRATION SURFACE ####
################################################################################
echo -e "#### plot_eems.R: Plotting estimated effective migration surface ...\n"
Rscript $scripts_dir/plot_eems.R $input $out_dir $pop_coords $shape

## Report:
echo -e "\n#### plot_eems.R: Done with script."
date

