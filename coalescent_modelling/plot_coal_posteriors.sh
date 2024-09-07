#!/bin/bash
#SBATCH -p medium40

set -euo pipefail

################################################################################
#### SET-UP ####
################################################################################

## Command-line args:
scripts_dir=$1
mcmc_nm1=$2
mcmc_nm2=$3
mcmc_nm3=$4
mcmc_nm4=$5
mcmc_m1=$6
mcmc_m2=$7
mcmc_m3=$8
mcmc_m4=$9
m_scale=$10
t_scale=$11
out_dir=$12

## Report:
echo -e "\n\n###################################################################"
date
echo -e "#### plot_coal_posteriors.sh: Starting script."
echo -e "#### plot_coal_posteriors.sh: Directory with scripts: $scripts_dir"
echo -e "#### plot_coal_posteriors.sh: First MCMC (no migration): $mcmc_nm1"
echo -e "#### plot_coal_posteriors.sh: Second MCMC (no migration): $mcmc_nm2"
echo -e "#### plot_coal_posteriors.sh: Third MCMC (no migration): $mcmc_nm3"
echo -e "#### plot_coal_posteriors.sh: Fourth MCMC (no migration): $mcmc_nm4"
echo -e "#### plot_coal_posteriors.sh: First MCMC (migration): $mcmc_m1"
echo -e "#### plot_coal_posteriors.sh: Second MCMC (migration): $mcmc_m2"
echo -e "#### plot_coal_posteriors.sh: Third MCMC (migration): $mcmc_m3"
echo -e "#### plot_coal_posteriors.sh: Fourth MCMC (migration): $mcmc_m4"
echo -e "#### plot_coal_posteriors.sh: Inverse scaling factor used in the G-PhoCS configuration file for migration parameter: $m_scale"
echo -e "#### plot_coal_posteriors.sh: Inverse scaling factor used in the G-PhoCS configuration file for tau and theta: $t_scale"
echo -e "#### plot_coal_posteriors.sh: Output directory: $out_dir \n\n"

################################################################################
#### PLOT POSTERIORS ####
################################################################################
echo -e "#### plot_coal_posteriors.sh: Plotting posteriors ..."
Rscript $scripts_dir/plot_coal_posteriors.R $mcmc_nm1 $mcmc_nm2 $mcmc_nm3 $mcmc_nm4 $mcmc_m1 $mcmc_m2 $mcmc_m3 $mcmc_m4 $m_scale $t_scale $out_dir

## Report:
echo -e "\n#### plot_coal_posteriors.sh: Done with script."
date
