#!/bin/bash
#SBATCH -p medium40

set -euo pipefail

################################################################################
#### SET-UP ####
################################################################################

## Command-line args:
scripts_dir=$1
model=$2
run_id=$3
mcmc=$4
burnin=$5
last_sample=$6
mutrate=$7
mutrate_var=$8
gentime=$9
gentime_sd=$10
m_scale=$11
t_scale=$12
poplist=$13

## Report:
echo -e "\n\n###################################################################"
date
echo -e "#### process_logs.sh: Starting script."
echo -e "#### process_logs.sh: Directory with scripts: $scripts_dir"
echo -e "#### process_logs.sh: Model: $model"
echo -e "#### process_logs.sh: Run ID: $run_id"
echo -e "#### process_logs.sh: MCMC file: $mcmc"
echo -e "#### process_logs.sh: Burn-in: $burnin"
echo -e "#### process_logs.sh: Last sample to keep: $last_sample"
echo -e "#### process_logs.sh: Gamma distribution of mutation rate will have mean $mutrate * 10e-8"
echo -e "#### process_logs.sh: Gamma distribution of mutation rate will have variance $mutrate_var * 10e-8"
echo -e "#### process_logs.sh: Lognormal distribution of generation time will have mean ln($gentime)"
echo -e "#### process_logs.sh: Lognormal distribution of generation time will have mean ln($gentime_sd)"
echo -e "#### process_logs.sh: Inverse scaling factor used in the G-PhoCS configuration file for migration parameter: $m_scale"
echo -e "#### process_logs.sh: Inverse scaling factor used in the G-PhoCS configuration file for tau and theta: $t_scale"
echo -e "#### process_logs.sh: File with information on parent and child populations: $poplist \n\n"

################################################################################
#### PROCESS LOGS ####
################################################################################
echo -e "#### process_logs.sh: Reformatting G-PhoCS output to remove empty column inserted by bug ..."
awk -v OFS="\t" '$1=$1' $mcmc > $mcmc.reform

echo -e "#### process_logs.sh: Processing logs and converting to demographic values ..."
Rscript $scripts_dir/process_logs.R $model $run_id $mcmc.reform $burnin $last_sample $mutrate $mutrate_var $gentime $gentime_sd $m_scale $t_scale $poplist

## Report:
echo -e "\n#### process_logs.sh: Done with script."
date


