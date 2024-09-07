#!/bin/bash
#SBATCH -p medium40

set -euo pipefail

################################################################################
#### SET-UP ####
################################################################################
## Software:
# SplitsTree needs to be included in $PATH (v4.19.0; https://uni-tuebingen.de/fakultaeten/mathematisch-naturwissenschaftliche-fakultaet/fachbereiche/informatik/lehrstuehle/algorithms-in-bioinformatics/software/splitstree/)

## Command-line args:
in_file=$1
out_file=$2

## Report:
echo -e "\n\n###################################################################"
date
echo -e "#### splitstree.sh: Starting script."
echo -e "#### splitstree.sh: Input alignment file: $in_file"
echo -e "#### splitstree.sh: Output file: $out_file \n\n"

################################################################################
#### PREPARE NEXUS FILE FOR GUI VERSION OF SPLITSTREE ####
################################################################################
echo -e "#### splitstree.sh: Preparing NEXUS file for GUI version of SplitsTree ..."
SplitsTree -g -i $in_file -x "UPDATE; SAVE REPLACE=yes FILE=$out_file.tmp; QUIT"

echo -e "#### splitstree.sh: Removing sequence from NEXUS output file ..."
first_line=$(grep -n "BEGIN Characters;" $out_file.tmp | cut -f1 -d:)
last_line=$(grep -n "END;.*Characters" $out_file.tmp | cut -f1 -d:)
sed "$first_line,${last_line}d" $out_file.tmp > $out_file
rm -f $out_file.tmp

## Report:
echo -e "#### splitstree.sh: Done with script."
date
