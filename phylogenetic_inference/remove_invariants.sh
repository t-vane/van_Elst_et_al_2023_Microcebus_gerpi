#!/bin/bash
#SBATCH -p medium40

set -euo pipefail

################################################################################
#### SET-UP ####
################################################################################
## Software:
ascbias=/home/nibtve93/software/raxml_ascbias/ascbias.py # (https://github.com/btmartin721/raxml_ascbias)
amas=/home/nibtve93/software/AMAS/amas/AMAS.py # (https://github.com/marekborowiec/AMAS)

## Command-line args:
in_file=$1
out_file=$2

## Report:
echo -e "\n\n###################################################################"
date
echo -e "#### remove_invariants.sh: Starting script."
echo -e "#### remove_invariants.sh: Input alignment: $in_file"
echo -e "#### remove_invariants.sh: Output alignment: $out_file \n\n"

################################################################################
#### REMOVE INVARIANT SITES ####
################################################################################
echo -e "#### remove_invariants.sh: Removing invariant sites ..."
python $ascbias -p $in_file -o $out_file

## Report:
echo -e "#### remove_invariants.sh: Done with script."
date



