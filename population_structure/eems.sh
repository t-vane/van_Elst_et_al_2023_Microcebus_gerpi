#!/bin/bash
#SBATCH -p medium40

set -euo pipefail

################################################################################
#### SET-UP ####
################################################################################

## Command-line args
config=$1
seed=$2

## Report:
echo -e "\n\n###################################################################"
date
echo -e "#### eems.sh: Starting script."
echo -e "#### eems.sh: Configuration file: $config"
echo -e "#### eems.sh: Seed: $seed \n\n"

################################################################################
#### ESTIMATE EFFECTIVE MIGRATION SURFACE ####
################################################################################
echo -e "#### eems.sh: Estimating effective migration surface ...\n"
runeems_snps --params $config --seed=$seed

## Report:
echo -e "\n#### eems.sh: Done with script."
date

