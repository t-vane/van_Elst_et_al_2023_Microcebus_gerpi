################################################################################
#### VCF FILTERING ####
################################################################################
## Pipeline adapted and modified from Poelstra et al. 2021, Systematic Biology (https://doi.org/10.1093/sysbio/syaa053)

scripts_dir=/home/nibtve93/scripts/vcfFiltering

set_id=gerpi
vcf_raw=$PWORK/$set_id/gatk/allScaffolds.vcf
vcf_dir=$PWORK/$set_id/vcf
bam_dir=$PWORK/bamFiles/$set_id
reference=$PWORK/mmur3/GCF_000165445.2_Mmur_3.0_genomic_reduced.fna # Reference genome in fasta format, not containing unlocalized chromosomal scaffolds between chromosomal ones

mkdir -p $vcf_dir/logFiles

## Softlink raw VCF to VCF directory
ln -s $vcf_raw $vcf_dir

#################################################################
#### 1 MAIN FILTERING PIPELINE ####
#################################################################
## Remove indels and invariant sites
sbatch --job-name=vcf_filter_pip --account=nib00015 --output=$vcf_dir/logFiles/00_filter_indels_invariants.$set_id.oe $scripts_dir/00_filter_indels_invariants.sh $reference $vcf_raw $vcf_dir/allScaffolds.snps.vcf

## Filter for minimum depth
min_dp=5
mean_dp=5
jid1=$(sbatch --job-name=vcf_filter_pip --dependency=singleton --account=nib00015 --output=$vcf_dir/logFiles/01_filter_min-dp.$set_id.oe $scripts_dir/01_filter_min-dp.sh $vcf_dir/allScaffolds.snps.vcf $min_dp $mean_dp $vcf_dir/$set_id.allScaffolds.snps.01filt.vcf)

## Apply three rounds of filtering for missing data across individuals and genotypes
maxmiss_geno1=0.5 # One minus maxmimum missingness across genotypes (filtering round 1), i.e., maximum missingness = 1-$maxmiss_geno1
maxmiss_geno2=0.6 # One minus maxmimum missingness across genotypes (filtering round 2), i.e., maximum missingness = 1-$maxmiss_geno2
maxmiss_geno3=0.7 # One minus maxmimum missingness across genotypes (filtering round 3), i.e., maximum missingness = 1-$maxmiss_geno3
filter_inds=TRUE # Boolean specifying whether to filter for missingness across individuals
maxmiss_ind1=0.9 # Maxmimum missingness across individuals (filtering round 1)
maxmiss_ind2=0.7 # Maxmimum missingness across individuals (filtering round 2)
maxmiss_ind3=0.5 # Maxmimum missingness across individuals (filtering round 3)
sbatch --job-name=vcf_filter_pip --dependency=singleton --account=nib00015 --output=$vcf_dir/logFiles/02_filter_missing-1.$set_id.oe $scripts_dir/02_filter_missing-1.sh \
	$vcf_dir/$set_id.allScaffolds.snps.01filt.vcf $vcf_dir/$set_id.allScaffolds.snps.02filt.vcf $maxmiss_geno1 $maxmiss_geno2 $maxmiss_geno3 $filter_inds $maxmiss_ind1 $maxmiss_ind2 $maxmiss_ind3

## Annotate with INFO fields FisherStrand, RMSMappingQuality, MappingQualityRankSumTest, ReadPosRankSumTest and AlleleBalance
suffix=auto
sbatch --job-name=vcf_filter_pip --dependency=singleton --account=nib00015 --output=$vcf_dir/logFiles/03_annot_gatk.$set_id.oe $scripts_dir/03_annot_gatk.sh \
	$vcf_dir/$set_id.allScaffolds.snps.02filt.vcf $vcf_dir/$set_id.allScaffolds.snps.03filt.vcf $bam_dir $reference $suffix

## Retain only bi-allelic sites and filter for INFO fields FisherStrand, RMSMappingQuality, MappingQualityRankSumTest, ReadPosRankSumTest and AlleleBalance
sbatch --job-name=vcf_filter_pip --dependency=singleton --account=nib00015 --output=$vcf_dir/logFiles/04_filter_gatk.$set_id.oe $scripts_dir/04_filter_gatk.sh \
	$vcf_dir/$set_id.allScaffolds.snps.03filt.vcf $vcf_dir/$set_id.allScaffolds.snps.04filt-soft.vcf $vcf_dir/$set_id.allScaffolds.snps.04filt-hard.vcf $reference

## Filter for maximum depth as (mean depth + 2 * standard deviation) / number of individuals
sbatch --job-name=vcf_filter_pip --dependency=singleton --account=nib00015 --output=$vcf_dir/logFiles/05_filter_max-dp.$set_id.oe $scripts_dir/05_filter_max-dp.sh \
	$vcf_dir/$set_id.allScaffolds.snps.04filt-hard.vcf $vcf_dir/$set_id.allScaffolds.snps.05filt.vcf 

## Apply final round of filtering for missing data across individuals and genotypes
maxmiss_geno=0.9 # One minus maxmimum missingness across genotypes, i.e., maximum missingness = 1-$maxmiss_geno
filter_inds=TRUE # Boolean specifying whether to filter for missingness across individuals
maxmiss_ind=0.5 # Maxmimum missingness across individuals
sbatch --job-name=vcf_filter_pip --dependency=singleton --account=nib00015 --output=$vcf_dir/logFiles/06_filter_missing-2.$set_id.oe $scripts_dir/06_filter_missing-2.sh \
	$vcf_dir/$set_id.allScaffolds.snps.05filt.vcf $vcf_dir/$set_id.allScaffolds.snps.06filt.vcf $maxmiss_geno $filter_inds $maxmiss_ind
	
## Create VCF file without outgroups
rem_string="--remove-indv Mmur_RMR44 --remove-indv Mmur_RMR45 --remove-indv Mmur_RMR49 --remove-indv Mjol_LAKI5.20a --remove-indv Mjol_LAKI5.24 --remove-indv Mmaro_RMR131"
sbatch --job-name=vcf_filter_pip --dependency=singleton --account=nib00015 --output=$vcf_dir/logFiles/07_filter_outgroups.$set_id.oe $scripts_dir/07_filter_outgroups.sh \
	$vcf_dir/$set_id.allScaffolds.snps.06filt.vcf $vcf_dir/$set_id.allScaffolds.snps.07filt.vcf "$rem_string"

#################################################################
#### 2 CREATING PARTIALLY FILTERED VCF (NECESSARY FOR LOCUS EXTRACTION) ####
#################################################################
## Here, we skip scripts that filter for missing data based on individuals and genotypes, i.e., 02_filter_missing-1.sh and 06_filter_missing-2.sh

## Annotate with INFO fields FisherStrand, RMSMappingQuality, MappingQualityRankSumTest, ReadPosRankSumTest and AlleleBalance
suffix=auto
sbatch --job-name=vcf_filter_part_pip --dependency=afterany:${jid1##* } --account=nib00015 --output=$vcf_dir/logFiles/03_annot_gatk.part.$set_id.oe $scripts_dir/03_annot_gatk.sh \
	$vcf_dir/$set_id.allScaffolds.snps.01filt.vcf $vcf_dir/$set_id.allScaffolds.snps.03filt.part.vcf $bam_dir $reference $suffix

## Filter for INFO fields FisherStrand, RMSMappingQuality, MappingQualityRankSumTest, ReadPosRankSumTest and AlleleBalance
sbatch --job-name=vcf_filter_part_pip --dependency=singleton --account=nib00015 --output=$vcf_dir/logFiles/04_filter_gatk.part.$set_id.oe $scripts_dir/04_filter_gatk.sh \
	$vcf_dir/$set_id.allScaffolds.snps.03filt.part.vcf $vcf_dir/$set_id.allScaffolds.snps.04filt-soft.part.vcf $vcf_dir/$set_id.allScaffolds.snps.04filt-hard.part.vcf $reference

## Filter for maximum depth as (mean depth + 2 * standard deviation) / number of individuals
sbatch --job-name=vcf_filter_part_pip --dependency=singleton --account=nib00015 --output=$vcf_dir/logFiles/05_filter_max-dp.part.$set_id.oe $scripts_dir/05_filter_max-dp.sh \
	$vcf_dir/$set_id.allScaffolds.snps.04filt-hard.part.vcf $vcf_dir/$set_id.allScaffolds.snps.05filt.part.vcf 

