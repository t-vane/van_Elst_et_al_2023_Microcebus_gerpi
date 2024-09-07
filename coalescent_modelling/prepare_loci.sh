#!/bin/bash
#SBATCH -p medium40

set -euo pipefail

################################################################################
#### SET-UP ####
################################################################################
## Software:
# faidx of SAMtools needs to be included in $PATH (v1.11; http://www.htslib.org/)

## Command-line args:
in_dir=$1
out_dir=$2

## Report:
echo -e "\n\n###################################################################"
date
echo -e "#### prepare_loci.sh: Starting script."
echo -e "#### prepare_loci.sh: Input directory with extracted loci: $in_dir"
echo -e "#### prepare_loci.sh: Output directory for reformatted loci: $out_dir \n\n"

################################################################################
#### REFORMAT LOCUS FILES FOR GPHOCS ####
################################################################################
echo -e "#### prepare_loci.sh: Reformatting locus files for G-PhoCS ..."
for fasta in $in_dir/*fa
do
	fasta_id=$(basename $fasta)	
	echo -e "#### prepare_loci.sh: Processing locus $fasta_id ..."

	# Remove locus name from header
	sed 's/__.*//' $in_dir/$fasta_id | sed -e 's/.*_\(.*_A[01]\)_.*/>\1/' > $out_dir/$fasta_id.tmp1
	# Reformat to have one sample per line; then remove second and third column
	faidx --transform transposed $out_dir/$fasta_id.tmp1 | tee $out_dir/$fasta_id.tmp2 | cut -f 1,4 > $out_dir/$fasta_id.tmp3

	# Get number of bases
	seq_len=$(cut -f 3 $out_dir/$fasta_id.tmp2 | head -n 1)
	# Get number of individuals
	no_seqs=$(cat $out_dir/$fasta_id.tmp2 | wc -l)

	if [[ no_seqs != 0 ]] && [[ seq_len != 0 ]]
	then
		echo -e "## prepare_loci.sh: Number of individuals: $no_seqs ..."
		echo -e "## prepare_loci.sh: Sequence length: $seq_len ..."
		
		# Print output file
		echo "$fasta_id $no_seqs $seq_len" > $out_dir/$fasta_id.locus
		cat $out_dir/$fasta_id.tmp3 >> $out_dir/$fasta_id.locus
	else
		echo -e "## prepare_loci.sh: Skipping empty locus ..."
	fi
done

echo -e "#### prepare_loci.sh: Removing temporary files ..."
rm -f $out_dir/*tmp*
rm -f $out_dir/*fai

echo -e "#### prepare_loci.sh: Counting loci ..."
nloci=$(ls $out_dir/*locus | wc -l)
printf "${nloci}\n\n" > $out_dir/loci.count
echo -e "## prepare_loci.sh: Number of loci: $NLOCI ..."

## Report:
echo -e "\n#### prepare_loci.sh: Done with script."
date


