#!/bin/bash
#SBATCH -p medium40

set -euo pipefail

################################################################################
#### SET-UP ####
################################################################################
## Software:
# muscle needs to be included in $PATH (v3.8.31; https://www.drive5.com/muscle/)

## Command-line args:
nt=$1
locus_dir=$2
alignment_dir=$3

## Report:
echo -e "\n\n###################################################################"
date
echo -e "#### alignment.sh: Starting script."
echo -e "#### alignment.sh: Number of threads: $nt"
echo -e "#### alignment.sh: Directory with locus fasta files: $locus_dir"
echo -e "#### alignment.sh: Output directory for alignments: $alignment_dir \n\n"

################################################################################
#### ALIGN LOCI WITH MUSCLE AND CHANGE HEADERS ####
################################################################################
echo -e "#### alignment.sh: Aligning loci with muscle and changing headers ..."
for locus in $locus_dir/*.fa
do 
	echo "muscle -in $locus -out $alignment_dir/$(basename $locus .fa).muscle.fa; sed -i 's/__.*//g' $alignment_dir/$(basename $locus .fa).muscle.fa" >> $alignment_dir/alignment_commands.txt
done
parallel --jobs $nt < $alignment_dir/alignment_commands.txt

## Report:
echo -e "#### alignment.sh: Done with script."
date




