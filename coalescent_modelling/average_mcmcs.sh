#!/bin/bash
#SBATCH -p medium40

set -euo pipefail

################################################################################
#### SET-UP ####
################################################################################

## Command-line args:
scripts_dir=$1
mcmc1=$2
mcmc2=$3
mcmc3=$4
mcmc4=$5
mcmc_out=$6

## Report:
echo -e "\n\n###################################################################"
date
echo -e "#### average_mcmcs.sh: Starting script."
echo -e "#### average_mcmcs.sh: Directory with scripts: $scripts_dir"
echo -e "#### average_mcmcs.sh: First MCMC: $mcmc1"
echo -e "#### average_mcmcs.sh: Second MCMC: $mcmc2"
echo -e "#### average_mcmcs.sh: Third MCMC: $mcmc3"
echo -e "#### average_mcmcs.sh: Fourth MCMC: $mcmc4"
echo -e "#### average_mcmcs.sh: MCMC output: $mcmc_out \n\n"

################################################################################
#### AVERAGE MCMCS ####
################################################################################
echo -e "#### average_mcmcs.sh: Averaging MCMCs ..."
Rscript $scripts_dir/average_mcmcs.R $mcmc1 $mcmc2 $mcmc3 $mcmc4 $mcmc_out

## Report:
echo -e "\n#### average_mcmcs.sh: Done with script."
date


