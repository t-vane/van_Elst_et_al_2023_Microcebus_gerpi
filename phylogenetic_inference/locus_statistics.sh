#!/bin/bash
#SBATCH -p medium40

set -euo pipefail

################################################################################
#### SET-UP ####
################################################################################
## Software:
amas=/home/nibtve93/software/AMAS/amas/AMAS.py # (https://github.com/marekborowiec/AMAS)

## Command-line args:
alignment_dir=$1
out_file=$2

## Report:
echo -e "\n\n###################################################################"
date
echo -e "#### locus_statistics.sh: Starting script."
echo -e "#### locus_statistics.sh: Alignment directory: $alignment_dir"
echo -e "#### locus_statistics.sh: Output file: $out_file \n\n"

################################################################################
#### CALCULATE STATISTICS FOR LOCUS ALIGNMENTS ####
################################################################################
echo -e "#### locus_statistics.sh: Calculating statistics for locus alignments ..."
for fasta in $alignment_dir/*.muscle.fa
do
    echo -e "#### locus_statistics.sh: Locus $fasta ..."
    python $amas summary -f fasta -d dna -i $fasta -o $(dirname $out_file)/$(basename "$fasta" .muscle.fa).stats.tmp
    grep -v "Alignment_name" $(dirname $out_file)/$(basename "$fasta" .muscle.fa).stats.tmp >> $out_file
done

echo -e "#### locus_statistics.sh: Preparing final statistics file ..."
header=$(head -n 1 `dirname $out_file`/`basename "$fasta" .muscle.fa`.stats.tmp)
(echo $header && cat $out_file) > $(dirname $out_file)/final.tmp
mv $(dirname $out_file)/final.tmp $out_file

echo -e "#### locus_statistics.sh: Removing temporary files ..."
find $(dirname $out_file) -name '.tmp' -delete

## Report:
echo -e "#### locus_statistics.sh: Done with script."
date





