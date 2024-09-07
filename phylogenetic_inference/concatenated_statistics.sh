#!/bin/bash
#SBATCH -p medium40

set -euo pipefail

################################################################################
#### SET-UP ####
################################################################################
## Software:
amas=/home/nibtve93/software/AMAS/amas/AMAS.py # (https://github.com/marekborowiec/AMAS)

## Command-line args:
alignment=$1

## Report:
echo -e "\n\n###################################################################"
date
echo -e "#### concatenated_statistics.sh: Starting script."
echo -e "#### concatenated_statistics.sh: Alignment file: $alignment \n\n"

################################################################################
#### CALCULATE STATISTICS FOR CONCATENATED ALIGNMENT ####
################################################################################
echo -e "#### concatenated_statistics.sh: Calculating statistics for concatenated alignment ..."
python $amas summary -f nexus -d dna -i $alignment -o $alignment.stats -s
mv $alignment-seq-summary.txt $alignment.taxon.stats

## Report:
echo -e "#### concatenated_statistics.sh: Done with script."
date





