################################################################################
#### GENOTYPE CALLING WITH GATK####
################################################################################
scripts_dir=/home/nibtve93/scripts/gatk

set_id=gerpi
bam_dir=$PWORK/bamFiles/$set_id
ind_file=$PWORK/$set_id/gatk/individuals.txt # Contains individual IDs in list format (".bam" will be appended in haplotypeCaller.sh)
reference_dir=$PWORK/mmur3
reference=$reference_dir/GCF_000165445.2_Mmur_3.0_genomic.fna # Reference genome in fasta format
region_file=$reference_dir/regionFileAutosomes_modified.bed # Regions (i.e., scaffolds) for which genotyping should be conducted jointly; should start at 1 and not at 0

gvcf_dir=$PWORK/$set_id/gatk/gvcfFiles
db_dir=$PWORK/$set_id/gatk/DBs
vcf_scaffold_dir=$PWORK/$set_id/gatk/vcfFilesScaffolds
tmp_dir=$PWORK/$set_id/gatk/tmp

mkdir -p $PWORK/$set_id/gatk/logFiles
mkdir -p $tmp_dir
mkdir -p $gvcf_dir
mkdir -p $db_dir
mkdir -p $vcf_scaffold_dir

## Variant discovery with haplotype caller
nt=40
mem=100
no_inds=$(cat $ind_file | wc -l)
suffix=auto.bam
sbatch --array=1-$no_inds --job-name=gatk -c $nt --account=nib00015 --output=$PWORK/$set_id/gatk/logFiles/haplotype_caller.%A_%a.oe $scripts_dir/haplotype_caller.sh $nt $mem $reference $ind_file $bam_dir $gvcf_dir $suffix

## Joint genotyping per scaffold
no_regions=$(cat $region_file | wc -l)
sbatch --array=1-$no_regions--job-name=gatk --dependency=singleton -c $nt --account=nib00015 --output=$PWORK/$set_id/gatk/logFiles/joint_genotyping.%A_%a.oe $scripts_dir/joint_genotyping.sh $nt $reference $ind_file $region_file $gvcf_dir $db_dir $vcf_scaffold_dir $tmp_dir

## Merge per-scaffold VCFs
ls $vcf_scaffold_dir/*vcf.gz > $vcf_scaffold_dir/allScaffolds.vcflist
sbatch --job-name=gatk --dependency=singleton --account=nib00015 --output=$PWORK/$set_id/gatk/logFiles/merge_vcfs.oe $scripts_dir/merge_vcfs.sh $vcf_scaffold_dir/allScaffolds.vcflist $PWORK/$set_id/gatk/allScaffolds.vcf.gz



