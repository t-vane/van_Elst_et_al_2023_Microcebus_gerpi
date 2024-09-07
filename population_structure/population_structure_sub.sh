################################################################################
#### POPULATION STRUCTURE ANALYSES ####
################################################################################
## Software:
# realSFS needs to be included in $PATH (http://www.popgen.dk/angsd/index.php/RealSFS)

scripts_dir=/home/nibtve93/scripts/populationStructure

set_id=gerpi
pop_dir=$PWORK/$set_id/populationStructure
beagle=$PWORK/$set_id/angsd/$set_id.beagle.gz # Genotype likelihood file created in genotype_likelihoods_sub.sh

mkdir -p $pop_dir/logFiles

#################################################################
#### 1 PRINCIPAL COMPONENT ANALYSIS ####
#################################################################
mkdir -p $pop_dir/pca

ind_file=$pop_dir/$set_id.txt # File with individual IDs in first column and population assignments in second column
nt=20

sbatch --account=nib00015 --output=$pop_dir/logFiles/pca.$set_id.oe $scripts_dir/pca.sh $nt $beagle $pop_dir/pca $scripts_dir $ind_file $set_id

#################################################################
#### 2 ADMIXTURE ####
#################################################################
mkdir -p $pop_dir/ngsadmix

clusters=10 # Maximum number of clusters to assume in admixture analysis
repeats=10 # Number of independent runs
percentage="75/100" # Minimum percentage of represented individuals
minind=$(( ($(zcat $beagle | head -1 | wc -w)/3-1) * $percentage )) # Minimum number of represented individuals
nt=80

## Submit array job to infer individual ancestries for each number of clusters (ranging from 1 to $clusters), using $repeats repetitions 
for k in $(seq 1 $clusters)
do
	jid=$(sbatch --array=1-$repeats --output=$pop_dir/logFiles/ngsadmix$k.$set_id.%A_%a.oe $scripts_dir/ngsadmix.sh $nt $k $beagle $pop_dir/ngsadmix $minind $set_id)
	declare runid_$k=${jid##* }
done

## Print likelihood values file
like_file=$pop_dir/ngsadmix/likevalues.$set_id.txt # File for likelihoods summary
rm $like_file; touch $like_file
for k in $(seq 1 $clusters); 
do
	for seed in $(seq 1 $repeats)
	do
		[[ $k == 1 ]] && [[ $seed == 1 ]] && varname=runid_$k && jid=$(sbatch --account=nib00015 --dependency=afterok:${!varname} --output=$pop_dir/logFiles/print_likes.$set_id.oe $scripts_dir/best_likes.sh $pop_dir/ngsadmix/$set_id.K$k.seed$seed.log $like_file $k $seed)
		[[ $k != 1 ]] || [[ $seed != 1 ]] && varname=runid_$k && jid=$(sbatch --account=nib00015 --dependency=afterok:${!varname}:${jid##* } --output=$pop_dir/logFiles/print_likes.$set_id.oe $scripts_dir/best_likes.sh $pop_dir/ngsadmix/$set_id.K$k.seed$seed.log $like_file $k $seed)
	done
done

## Plot results
ind_file=$pop_dir/$set_id.txt # File with individual IDs in first columns and population assignments in second column

until [[ $(cat $like_file | wc -l) == $(( $clusters*$repeats )) ]]
do
	sleep 5
done

sbatch --account=nib00015 --output=$pop_dir/logFiles/plot_ngsadmix.$set_id.oe $scripts_dir/plot_ngsadmix.sh $scripts_dir $pop_dir/ngsadmix $like_file $ind_file $set_id

#################################################################
#### 3 ISOLATION-BY-DISTANCE ####
#################################################################

##################################################
#### 3.1 BASED ON F_ST ####
##################################################
mkdir -p $pop_dir/ibd/fst

comb_file=$PWORK/$set_id/angsd/maf/combinations.txt # File with pairwise population comparisons estimated in genotype_likelihoods_sub.sh

## Initialize summary file
echo "pair unweighted weighted" > $pop_dir/ibd/fst/$set_id.fst_sumstats.txt

## Get pairwise F_ST between populations
while read comb
do
	first=$(awk '{print $1}' <<< $comb)
	second=$(awk '{print $2}' <<< $comb)
	
	echo -e "#### Processing combination $first $second ...\n"	
	# Estimate F_ST values
	out=$pop_dir/ibd/fst/$set_id.$first.$second
	sbatch --wait --account=nib00015 --output=$pop_dir/logFiles/$set_id.realsfs_fst.$first.$second.oe $scripts_dir/realsfs_fst.sh $nt "$PWORK/$set_id/angsd/saf.$first.idx $PWORK/$set_id/angsd/saf.$second.idx" $out
	
	# Write to summary file 
	echo ${first}_$second $(realSFS fst stats $out.fst.idx) >> $pop_dir/ibd/fst/$set_id.fst_sumstats.txt
done < $comb_file

## Conduct Mantel tests and plot IBD
geo_dist=$pop_dir/ibd/geo_dist.txt # Distance matrix with mean geographic distances between population pairs as estimated with Geographic Distance Matrix Generator v1.2.3 (https://biodiversityinformatics.amnh.org/open_source/gdmg/), with row and column names
gen_dist=$pop_dir/ibd/fst/gen_dist.txt # Distance matrix with weighted pairwise F_ST between populations as estimated with realSFS, with row and column names
sbatch --account=nib00015 --output=$pop_dir/logFiles/$set_id.ibd.fst.oe $scripts_dir/ibd.sh $geo_dist $gen_dist "_fst" $pop_dir/ibd/fst/$set_id

##################################################
#### 3.1 BASED ON GENETIC DISTANCES ####
##################################################
mkdir -p $pop_dir/ibd/geneticDistances

vcf_file=$PWORK/$set_id/vcf/$set_id.allScaffolds.snps.07filt.vcf
## Estimate genetic distance between individuals
sbatch --wait --account=nib00015 --output=$pop_dir/logFiles/$set_id.vcfr.oe $scripts_dir/vcfr.sh $scripts_dir $vcf_file $pop_dir/ibd/geneticDistances/geneticDistances.csv

## Conduct Mantel tests and plot IBD
geo_dist=$pop_dir/ibd/geo_dist.txt # Distance matrix with mean geographic distances between population pairs as estimated with Geographic Distance Matrix Generator v1.2.3 (https://biodiversityinformatics.amnh.org/open_source/gdmg/), with row and column names
gen_dist=$pop_dir/ibd/geneticDistances/gen_dist.txt # Distance matrix with mean genetic distances between populations as estimated with vcfR, with row and column names
gen_dist_sd=$pop_dir/ibd/geneticDistances/gen_dist_sd.txt # Distance matrix with standard deviations of mean genetic distances between populations as estimated with vcfR, with row and column names
sbatch --account=nib00015 --output=$pop_dir/logFiles/$set_id.ibd.geneticDistances.oe $scripts_dir/ibd.sh $geo_dist $gen_dist "_geneticDistances" $pop_dir/ibd/geneticDistances/$set_id $gen_dist_sd


#################################################################
#### 4 ESTIMATED EFFECTIVE MIGRATION SURFACES (EEMS) ####
#################################################################
mkdir -p $pop_dir/eems/results

vcf_file=$PWORK/$set_id/vcf/$set_id.allScaffolds.snps.07filt.vcf

## Estimate average genetic dissimilarity matrix
nt=4
chrom_file=$pop_dir/eems/renameChromosomes.txt # File with chromosome names in first column and integers in second column (no header), which is required for formating of VCF file
sbatch --wait --account=nib00015 --output=$pop_dir/logFiles/$set_id.bed2diffs.oe $scripts_dir/bed2diffs.sh $nt $pop_dir/eems $vcf_file $chrom_file

## Two files need to be created manually:
# $pop_dir/eems/$(basename $vcf_file .vcf).coord which contains coordinates of each indivdidual
# $pop_dir/eems/$(basename $vcf_file .vcf).outer which contains coordinate boundaries of focal area

## Create configuration file
for ndemes in 200 500 1000
do
	> $pop_dir/eems/$(basename $vcf_file .vcf).ndemes$ndemes.ini
	echo "datapath = $pop_dir/eems/$(basename $vcf_file .vcf)" >> $pop_dir/eems/$(basename $vcf_file .vcf).ndemes$ndemes.ini
	echo "mcmcpath = $pop_dir/eems/results/$(basename $vcf_file .vcf).ndemes$ndemes" >> $pop_dir/eems/$(basename $vcf_file .vcf).ndemes$ndemes.ini
	echo "nIndiv = $(bcftools query -l $vcf_file | wc -l)" >> $pop_dir/eems/$(basename $vcf_file .vcf).ndemes$ndemes.ini
	echo "nSites = $(egrep -v "#" $vcf_file | wc -l)" >> $pop_dir/eems/$(basename $vcf_file .vcf).ndemes$ndemes.ini
	echo "nDemes = $ndemes" >> $pop_dir/eems/$(basename $vcf_file .vcf).ndemes$ndemes.ini
	echo "diploid = true" >> $pop_dir/eems/$(basename $vcf_file .vcf).ndemes$ndemes.ini
	echo "numMCMCIter = 4000000" >> $pop_dir/eems/$(basename $vcf_file .vcf).ndemes$ndemes.ini
	echo "numBurnIter = 1000000" >> $pop_dir/eems/$(basename $vcf_file .vcf).ndemes$ndemes.ini
	echo "numThinIter = 9999" >> $pop_dir/eems/$(basename $vcf_file .vcf).ndemes$ndemes.ini
done

## Estimate effective migration surfaces and plot
seed=123
pop_coords=$pop_dir/eems/results/$(basename $vcf_file .vcf).ndemes$ndemes/pop_coords.txt # File with coordinates to plot populations on EEMS
shape_file=$pop_dir/eems/results/$(basename $vcf_file .vcf).ndemes$ndemes/River_Mada_1 # Prefix of river shape file
for ndemes in 200 500 1000
do
	# Infer EEMS
	jid=$(sbatch --account=nib00015 --output=$pop_dir/logFiles/eems.nDemes$ndemes.oe $scripts_dir/eems.sh $pop_dir/eems/$(basename $vcf_file .vcf).ndemes$ndemes.ini $seed)
	
	# Plot results
	sbatch --account=nib00015 --dependency=afterok:${jid##* } --output=$pop_dir/logFiles/plot_eems.nDemes$ndemes.oe plot_eems.sh $scripts_dir $pop_dir/eems/$(basename $vcf_file .vcf).ndemes$ndemes $pop_dir/eems/results/$(basename $vcf_file .vcf).ndemes$ndemes $pop_coords $shape_file
done


