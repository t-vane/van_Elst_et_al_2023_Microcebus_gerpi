#!/bin/bash
#SBATCH -p medium40

set -euo pipefail

################################################################################
#### SET-UP ####
################################################################################

## Command-line args:
scripts_dir=$1
mcmc_nm=$2
mcmc_m=$3
summary=$4
out_dir=$5

## Report:
echo -e "\n\n###################################################################"
date
echo -e "#### plot_coal_main.sh: Starting script."
echo -e "#### plot_coal_main.sh: Directory with scripts: $scripts_dir"
echo -e "#### plot_coal_main.sh: MCMC (no migration): $mcmc_nm"
echo -e "#### plot_coal_main.sh: MCMC (migration): $mcmc_m"
echo -e "#### plot_coal_main.sh: Summary table with divergence times, migration rates and genealogical divergence indices: $summary"
echo -e "#### plot_coal_main.sh: Output directory: $out_dir \n\n"

################################################################################
#### PLOT MAIN FIGURES ####
################################################################################
echo -e "#### plot_coal_main.sh: Plotting models ..."
Rscript $scripts_dir/plot_coal_models.R $mcmc_nm $mcmc_m $out_dir

echo -e "#### plot_coal_main.sh: Plotting parameter estimates ..."
Rscript $scripts_dir/plot_coal_params.R $summary $out_dir

## Report:
echo -e "\n#### plot_coal_main.sh: Done with script."
date


