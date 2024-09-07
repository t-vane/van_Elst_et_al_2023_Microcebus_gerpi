#!/bin/bash
#SBATCH -p medium40
#SBATCH -t 48:00:00
#SBATCH --signal=B:12@1800

set -euo pipefail

################################################################################
#### SET-UP ####
################################################################################
## Software:
#dmtcp needs to be included in $PATH (https://dmtcp.sourceforge.io/)
#G-PhoCS needs to be included in $PATH (http://compgen.cshl.edu/GPhoCS/)

## Command-line args:
nt=$1
check_in=$2
check_out=$3

export OMP_NUM_THREADS=$nt # This line is necessary because otherwise G-PhoCS will only run with one core despite specifying -n

## Report:
echo -e "\n\n###################################################################"
date
echo -e "#### gphocs_checkpoint_cont.sh: Starting script."
echo -e "#### gphocs_checkpoint_cont.sh: Number of threads: $nt"
echo -e "#### gphocs_checkpoint_cont.sh: Previous checkpointing directory: $check_in"
echo -e "#### gphocs_checkpoint_cont.sh: Checkpointing directory: $check_out \n\n"

################################################################################
#### Coalescent modelling in G-PhoCS ####
################################################################################
trap 'echo -e "#### gphocs_checkpoint_cont.sh: Checkpointing ..."; date; dmtcp_command --bcheckpoint; echo -e "#### gphocs_checkpoint_cont.sh: Checkpointing done."; date; exit 12' 12

echo -e "#### gphocs_checkpoint_cont.sh: Coalescent modelling in G-PhoCS ..."
dmtcp_restart --ckptdir $check_out $check_in/ckpt_*.dmtcp &
wait

