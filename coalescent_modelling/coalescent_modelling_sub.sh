################################################################################
#### COALESCENT MODELLING ####
################################################################################
scripts_dir=/home/nibtve93/scripts/coalescentModelling

set_id=gerpi
locus_dir=$PWORK/$set_id/locusExtraction/fasta/${set_id}_bylocus_final
coal_dir=$PWORK/$set_id/coalescentModelling

mkdir -p $coal_dir/logFiles

#################################################################
#### 0 PREPARATION ####
#################################################################
## Reformat per-locus files
mkdir -p $coal_dir/loci
sbatch --wait --account=nib00015 --output=$coal_dir/logFiles/prepareLoci.oe $scripts_dir/prepareLoci.sh $locus_dir $coal_dir/loci

## Create sequence file containing all loci
cat $coal_dir/loci/loci.count > $coal_dir/$set_id.seq_file.txt
find $coal_dir/loci -maxdepth 1 -name "*locus" -type f -exec cat {} + >> $coal_dir/$set_id.seq_file.txt

## Remove undesired samples from sequence file
remove_file=$coal_dir/remove_samples.txt # List with samples to remove
remove_string=$(awk '$1=$1' RS= OFS='\\|' $remove_file) # Creates string for subsequent sed command
sed "/$remove_string/d" $coal_dir/$set_id.seq_file.txt > $coal_dir/$set_id.seq_file.reduced.txt

## Replace sample number in sequence file
no_samples_total=$(sed -n 3p $coal_dir/$set_id.seq_file.txt | awk '{print $2}'); echo $no_samples_total
no_samples_removed=$(cat $remove_file | wc -l); echo $no_samples_removed
no_samples_left=$(( $no_samples_total - $no_samples_removed )); echo $no_samples_left
sed -i "s/fa $no_samples_total /fa $no_samples_left /g" $coal_dir/$set_id.seq_file.reduced.txt

#################################################################
#### 1 PRELIMINARY MODELS ####
#################################################################
models="anc_sahaDobo_sakoVohiFina anc_sahaDobo_baoSakoVohiFina anc_bao_sakoVohiFina anc_maroJoll_gerpiRoot sako_mmaro vohiFina_sako vohiFina_dobo vohiFina_saha vohiFina_bao saha_dobo sako_bao mjoll_mmaro bao_mmaro" # Contains all model IDs

## After manually creating a control file for each preliminary model (ctrl_file.txt), submit jobs
nt=20
njobs=8 # Since there was walltime limit of 48 h on the server, we used DMTCP (https://dmtcp.sourceforge.io/) for checkpointing; $njobs jobs were then submitted, each of which would only run a maximum of 48 h 

for model in $models
do
	mkdir -p $coal_dir/models/$model
	
	for i in $(seq 1 $njobs)
	do
		echo -e "#### Submitting job $i for model $model"
		# If first script:
		if [ $i == 1 ]
		then
			# Declare directory to save checkpoint files
			check_out=$coal_dir/models/$model/checkpoint_$i
			mkdir -p $check_out
			# Submit job and save submission ID
			jid=$(sbatch --account=nib00015 --output=$coal_dir/logFiles/$model.$i.gphocs.oe $scripts_dir/gphocs_checkpoint.sh $nt $coal_dir/models/$model/ctrl_file.txt $check_out)
			declare runid_$i=${jid##* }

		# If not first script:
		else
			# Assign input directory (which is output directory of previous iteration)
			check_in=$check_out
			# Declare directory to save checkpoint files
			check_out=$coal_dir/models/$model/checkpoint_$i
			# Get submission ID of previous iteration
			varname=runid_$(( $i - 1 ))
			# Submit next job and save submission ID
			jid=$(sbatch --account=nib00015 --output=$coal_dir/logFiles/$model.$i.gphocs.oe --dependency=afterany:${!varname} $scripts_dir/gphocs_checkpoint_cont.sh $nt $check_in $check_out)
			declare runid_$i=${jid##* }
		fi
	done
done

#################################################################
#### 2 FINAL MODELS ####
#################################################################
models="noMig Mig" # Contains final model IDs

##################################################
#### 2.1 RUN FINAL MODELS ####
##################################################

## After manually creating a control file for each final model (ctrl_file.txt), submit jobs
nt=20
replicates=4 # Number of replicate runs to be submitted for each model
njobs=15 # Since there was walltime limit of 48 h on the server, we used DMTCP (https://dmtcp.sourceforge.io/) for checkpointing; $njobs jobs were then submitted, each of which would only run a maximum of 48 h 

for j in $(seq 1 $replicates)
	for model in $models
	do
		mkdir -p $coal_dir/models/$model

		for i in $(seq 1 $njobs)
		do
			echo -e "#### Submitting job $i of run $j for model $model"
			# If first script:
			if [ $i == 1 ]
			then
				# Declare directory to save checkpoint files
				check_out=$coal_dir/models/$model/checkpoint_run${j}_$i
				mkdir -p $check_out
				# Submit job and save submission ID
				jid=$(sbatch --account=nib00015 --output=$coal_dir/logFiles/$model.run$j.$i.gphocs.oe $scripts_dir/gphocs_checkpoint.sh $nt $coal_dir/models/$model/ctrl_file.run$j.txt $check_out)
				declare runid_$i=${jid##* }

			# If not first script:
			else
				# Assign input directory (which is output directory of previous iteration)
				check_in=$check_out
				# Declare directory to save checkpoint files
				check_out=$coal_dir/models/$model/checkpoint_run${j}_$i
				# Get submission ID of previous iteration
				varname=runid_$(( $i - 1 ))
				# Submit next job and save submission ID
				jid=$(sbatch --account=nib00015 --output=$coal_dir/logFiles/$model.run$j.$i.gphocs.oe --dependency=afterany:${!varname} $scripts_dir/gphocs_checkpoint_cont.sh $nt $check_in $check_out)
				declare runid_$i=${jid##* }
			fi
		done
	done
done

##################################################
#### 2.2 PROCESS OUTPUT ####
##################################################
replicates=4
burnin=200000 # Burn-in
last_samples=2000000 # Last MCMC sample to be considered
mutrate=1.236 # Gamma distribution of mutation rate will have mean $mutrate * 10e-8
mutrate_var=0.107 # Gamma distribution of mutation rate will have variance $mutrate_var * 10e-8
gentime=3.5 # Lognormal distribution of generation time will have mean ln($gentime)
gentime_sd=1.16 # Lognormal distriubtion of generation time will have standard deviation ln($gentime_sd)
m_scale=0.001 # Inverse scaling factor used in the G-PhoCS configuration file for migration parameter
t_scale=10000 # Inverse scaling factor used in the G-PhoCS configuration file for tau and theta
poplist=$coal_dir/parent_child_pops.txt # File with two columns containing information on parent and child populations (headers: "parent" and "child")

## Process output and convert to demographic values
for j in $(seq 1 $replicates)
do
	for model in $models
	do
		sbatch --account=nib00015 --output=$coal_dir/logFiles/$model.run$j.process_logs.oe $scripts_dir/process_logs.sh $scripts_dir $model $j $coal_dir/models/$model/$model.run$j.mcmc.out $burnin $last_sample $mutrate $mutrate_var $gentime $gentime_sd $m_scale $t_scale $poplist
	done 
done

## Average log files across runs
for model in $models
do
	# Wait until processed logs are ready
	until [[ $(ls $coal_dir/models/$model/cut/prep*mcmc.out | wc -l) == 4 ]]
	do
		sleep 5m
	done
	
	# Average
	sbatch --wait --acount=nib00015 --output=$coal_dir/logFiles/$model.average_mcmcs.oe $scripts_dir/average_mcmcs.sh $scripts_dir \
		$coal_dir/models/$model/cut/prep.$model.run1.mcmc.out $coal_dir/models/$model/cut/prep.$model.run2.mcmc.out $coal_dir/models/$model/cut/prep.$model.run3.mcmc.out $coal_dir/models/$model/cut/prep.$model.run4.mcmc.out $coal_dir/models/$model/cut/prep.$model.average.mcmc.out
done

##################################################
#### 2.3 PLOT RESULTS ####
##################################################
## Plot main figures
summary=$coal_dir/models/$model/cut/summary.xlsx # Excel file containing three sheets (div, mig, gdi) with columns with the following information (column headers are given in brackets): mean estimate (Mean), lower and upper 95 highest posterior density distribution limits (lower95 and upper95), underlying model (Model), and increasing integers (x) 
sbatch --acount=nib00015 --output=$coal_dir/logFiles/plot_coal_main.oe $scripts_dir/plot_coal_main.sh $scripts_dir $coal_dir/models/$model/cut/prep.noMig.average.mcmc.out $coal_dir/models/$model/cut/prep.Mig.average.mcmc.out $summary $coal_dir/models/$model/cut/

## Plot supplementary figures (i.e., posterior distributions)
m_scale=0.001 # Inverse scaling factor used in the G-PhoCS configuration file for migration parameter
t_scale=10000 # Inverse scaling factor used in the G-PhoCS configuration file for tau and theta

sbatch --acount=nib00015 --output=$coal_dir/logFiles/plot_coal_posteriors.oe $scripts_dir/plot_coal_posteriors.sh $scripts_dir \
	$coal_dir/models/noMig/cut/cut.noMig.run1.mcmc.out $coal_dir/models/noMig/cut/cut.noMig.run2.mcmc.out $coal_dir/models/noMig/cut/cut.noMig.run3.mcmc.out $coal_dir/models/noMig/cut/cut.noMig.run4.mcmc.out \
	$coal_dir/models/noMig/cut/cut.Mig.run1.mcmc.out $coal_dir/models/noMig/cut/cut.Mig.run2.mcmc.out $coal_dir/models/noMig/cut/cut.Mig.run3.mcmc.out $coal_dir/models/noMig/cut/cut.Mig.run4.mcmc.out \
	$m_scale $t_scale $coal_dir/models/noMig/cut/
