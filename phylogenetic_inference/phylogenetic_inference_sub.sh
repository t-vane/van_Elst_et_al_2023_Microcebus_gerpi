################################################################################
#### PHYLOGENETIC INFERENCE ####
################################################################################
scripts_dir=/home/nibtve93/scripts/phylogeneticInference

set_id=gerpi
vcf_dir=$PWORK/$set_id/vcf
locus_dir=$PWORK/$set_id/locusExtraction/fasta/${set_id}_bylocus_final
alignment_dir=$PWORK/$set_id/alignment
phyl_dir=$PWORK/$set_id/phylogeneticInference

mkdir -p $alignment_dir/logFiles
mkdir -p $phyl_dir/logFiles

#################################################################
#### 0 ALIGNMENT ####
#################################################################
## Align loci with muscle and change headers to remove locus IDs (otherwise concatenation will not work)
nt=64 # Number of loci processed in parallel
jid1=$(sbatch --account=nib00015 --output=$alignment_dir/logFiles/alignment.oe $scripts_dir/alignment.sh $nt $locus_dir $alignment_dir)

## Calculate statistics for locus alignments
sbatch --account=nib00015 --dependency=afterok:${jid1##* } --output=$alignment_dir/logFiles/locus_statistics.oe $scripts_dir/locus_statistics.sh $alignment_dir $alignment_dir/locus.stats

## Concatenate locus alignments
nt=8
jid2=$(sbatch --account=nib00015 --dependency=afterok:${jid1##* } --output=$alignment_dir/logFiles/concatenate.oe $scripts_dir/concatenate.sh $nt $alignment_dir $set_id)

## Calculate statistics for concatenated alignment (including per-taxon)
sbatch --account=nib00015 --dependency=afterok:${jid2##* } --output=$alignment_dir/logFiles/concatenated_statistics.oe $scripts_dir/concatenated_statistics.sh $alignment_dir/$set_id.concatenated.nex

#################################################################
#### 1 MAXIMUM LIKELIHOOD INFERENCE ####
#################################################################
mkdir -p $phyl_dir/ml

## Remove invariant sites (high memory consumption)
jid3=$(sbatch --account=nib00015 --dependency=afterok:${jid2##* } --output=$phyl_dir_DIR/logFiles/remove_invariants.oe $scripts_dir/remove_invariants.sh $alignment_dir/$set_id.concatenated.phy $alignment_dir/$set_id.concatenated.noinv.phy)

## Run phylogenetic inference with ascertainment bias correction in RAxML-NG
nt=80
bootstrap=100 # Number of bootstrap replicates
outgroup="Mmur_RMR44,Mmur_RMR45,Mmur_RMR49" # Outgroup individuals in alignment file
sbatch --account=nib00015 --dependency=afterok:${jid3##* } --output=$phyl_dir/logFiles/raxml_asc.$set_id.oe $scripts_dir/raxml_asc.sh $nt $bootstrap $outgroup $alignment_dir/$set_id.concatenated.noinv.phy $phyl_dir/ml/$set_id.concatenated.noinv.tre

#################################################################
#### 2 QUARTET-BASED INFERENCE FOR INDIVIDUAL AND POPULATION ASSIGNMENT ####
#################################################################
mkdir -p $phyl_dir/quartet

## Wait until alignment concatenation has been terminated (i.e., the following job has started)
until [ -f $alignment_dir/logFiles/concatenated_statistics.oe ]
do
	sleep 20
done

## Create locus partitions block file
echo "BEGIN SETS;" > $phyl_dir/quartet/$set_id.locusPartitions.txt
echo -e "\t CHARPARTITION LOCI =" >> $phyl_dir/quartet/$set_id.locusPartitions.txt
while read line
do
	loc_name=$(cut -f1 -d' ' <<< $line)
	loc_coord=$(cut -f3 -d' ' <<< $line)
	echo -e "#### Processing locus $loc_name ..."
	echo -e "\t\t$loc_name:$loc_coord," >> $phyl_dir/quartet/$set_id.locusPartitions.txt
done < $alignment_dir/$set_id.partitions.txt
sed -i '$ s/,$//' $phyl_dir/quartet/$set_id.locusPartitions.txt # Remove last comma
echo -e "\t\t;" >> $phyl_dir/quartet/$set_id.locusPartitions.txt
echo "END;" >> $phyl_dir/quartet/$set_id.locusPartitions.txt
echo "" >> $phyl_dir/quartet/$set_id.locusPartitions.txt

## Create taxon partitions block files
# For population assignment, the file has to be created manually
# For individual assignment:
echo "BEGIN SETS;" > $phyl_dir/quartet/$set_id.taxPartitions.individual.nex
echo -e "\t TAXPARTITION SPECIES =" >> echo "BEGIN SETS;" > $phyl_dir/quartet/$set_id.taxPartitions.individual.nex
for ind in $(awk '{ print $1 }' $alignment_dir/$set_id.concatenated.noinv.phy | tail -n+2)
do
	echo -e "\t\t$ind:$ind," >> echo "BEGIN SETS;" > $phyl_dir/quartet/$set_id.taxPartitions.individual.nex
done
sed -i '$ s/,$//' echo "BEGIN SETS;" > $phyl_dir/quartet/$set_id.taxPartitions.individual.nex # Remove last comma
echo -e "\t\t;" >> echo "BEGIN SETS;" > $phyl_dir/quartet/$set_id.taxPartitions.individual.nex
echo "END;" >> echo "BEGIN SETS;" > $phyl_dir/quartet/$set_id.taxPartitions.individual.nex
echo "" >> echo "BEGIN SETS;" > $phyl_dir/quartet/$set_id.taxPartitions.individual.nex

## Create PAUP block files
nt=80
seed=$RANDOM
# For population assignment:
echo "BEGIN PAUP;" > $phyl_dir/quartet/$set_id.paup.population.nex
echo -e "\toutgroup SPECIES.Mmurinus;" >> $phyl_dir/quartet/$set_id.paup.population.nex
echo -e "\tset root=outgroup outroot=monophyl;" >> $phyl_dir/quartet/$set_id.paup.population.nex
echo -e "\tsvdq nthreads=$nt evalQuartets=all taxpartition=SPECIES loci=LOCI bootstrap=standard seed=$seed;" >> $phyl_dir/quartet/$set_id.paup.population.nex
echo -e "\tsavetrees format=Newick file=$phyl_dir/quartet/$set_id.concatenated.noinv.population.svdq.tre savebootp=nodelabels;" >> $phyl_dir/quartet/$set_id.paup.population.nex
echo -e "\tquit;" >> $phyl_dir/quartet/$set_id.paup.population.nex
echo "END;" >> $phyl_dir/quartet/$set_id.paup.population.nex
# For individual assignment
echo "BEGIN PAUP;" > $phyl_dir/quartet/$set_id.paup.individual.nex
echo -e "\toutgroup SPECIES.Mmur_RMR44 SPECIES.Mmur_RMR45 SPECIES.Mmur_RMR49;" >> $phyl_dir/quartet/$set_id.paup.individual.nex
echo -e "\tset root=outgroup outroot=monophyl;" >> $phyl_dir/quartet/$set_id.paup.individual.nex
echo -e "\tsvdq nthreads=$nt evalQuartets=all taxpartition=SPECIES loci=LOCI bootstrap=standard seed=$seed;" >> $phyl_dir/quartet/$set_id.paup.individual.nex
echo -e "\tsavetrees format=Newick file=$phyl_dir/quartet/$set_id.concatenated.noinv.individual.svdq.tre savebootp=nodelabels;" >> $phyl_dir/quartet/$set_id.paup.individual.nex
echo -e "\tquit;" >> $phyl_dir/quartet/$set_id.paup.individual.nex
echo "END;" >> $phyl_dir/quartet/$set_id.paup.individual.nex

## Concatenate files and submit SVDquartets job
for i in population individual
do
	cat $alignment_dir/$set_id.concatenated.nex $phyl_dir/quartet/$set_id.taxPartitions.$i.nex $phyl_dir/quartet/$set_id.paup.$i.nex > $phyl_dir/quartet/$set_id.paup.$i.concat.nex
	sbatch --account=nib00015 --output=$phyl_dir/logFiles/svdq.$set_id.oe $scripts_dir/svdq.sh $phyl_dir/quartet/$set_id.paup.$i.concat.nex $phyl_dir/quartet/$set_id.paup.$i.concat.nex.log
done

#################################################################
#### 3 NEIGHBOR-NET INFERENCE IN SPLITSTREE ####
#################################################################
mkdir -p $phyl_dir/neighbor-net

## Prepare NEXUS file which can be opened in the GUI version of SplitsTree to obtain the Neighbor-Net network
sbatch --account=nib00015 --output=$phyl_dir/logFiles/splitstree.oe $scripts_dir/splitstree.sh $alignment_dir/$set_id.concatenated.nex $phyl_dir/neighbor-net/splitstree.out.nex
