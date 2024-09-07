#!/bin/bash
#SBATCH -p medium40

set -euo pipefail

################################################################################
#### SET-UP ####
################################################################################
## Software:
amas=/home/nibtve93/software/AMAS/amas/AMAS.py # (https://github.com/marekborowiec/AMAS)

## Command-line args:
nt=$1
alignment_dir=$2
set_id=$3

## Report:
echo -e "\n\n###################################################################"
date
echo -e "#### concatenate.sh: Starting script."
echo -e "#### concatenate.sh: Number of threads: $nt"
echo -e "#### concatenate.sh: Alignment directory: $alignment_dir"
echo -e "#### concatenate.sh: Set ID: $set_id \n\n"

################################################################################
#### CONCATENATE LOCUS ALIGNMENTS ####
################################################################################
echo -e "#### concatenate.sh: Concatenating locus alignments ..."
python $amas concat -i $alignment_dir/*.muscle.fa -t $alignment_dir/$set_id.concatenated.nex -p $alignment_dir/$set_id.partitions.txt -f fasta -d dna -u nexus -c $nt

echo -e "#### concatenate.sh: Replacing 'N' by '?' ..."
head -n 6 $alignment_dir/$set_id.concatenated.nex
awk 'NR>=7 {gsub("N","?",$2)}1' $alignment_dir/$set_id.concatenated.nex > $alignment_dir/$set_id.concatenated.nex.tmp
mv $alignment_dir/$set_id.concatenated.nex.tmp $alignment_dir/$set_id.concatenated.nex

echo -e "#### concatenate.sh: Converting NEXUS to PHYLIP format ..."
python $amas convert -i $alignment_dir/$set_id.concatenated.nex -f nexus -u phylip -d dna
mv $alignment_dir/$set_id.concatenated.nex-out.phy $alignment_dir/$set_id.concatenated.phy

## Report:
echo -e "#### concatenate.sh: Done with script."
date



