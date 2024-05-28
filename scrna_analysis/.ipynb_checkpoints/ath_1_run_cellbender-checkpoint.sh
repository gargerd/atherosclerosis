#!/bin/bash

module load Anaconda3/2022.10
eval "$(conda shell.bash hook)"
conda activate cellbender


base_dir="/data/gpfs/projects/punim2121/Atherosclerosis/"
#base_dir='/data/gpfs/projects/punim2121/Atherosclerosis/data/raw_counts'

ref_genome_list=("GRCh38-p13-Gencode_v33" "GRCh38-p14-Gencode_v44")

ref_genome_list=("GRCh38-p14-Gencode_v44")

#declare -a batch_list=("Batch1" "Batch2" "Batch3" "Batch4")

batch_list=("Batch1" "Batch2" "Batch3" "Batch4" "Batch5" "Batch6")
sample_list=('CAR1_D' 'CAR2_H' 'CAR2_D' 'CAR3_H' 'CAR3_D' 'CAR4_H' 'CAR4_D' 'CAR5_H' 'CAR5_D' 'CAR6_H' 'CAR6_D' 'CAR7_H' 'CAR7_D' 'CAR8_H' 'CAR8_D' 'CAR9_H' 'CAR9_D' 'CAR10_H' 'CAR10_D' 'CAR11_D' 'CAR11_H' 'CAR12_D' 'CAR12_H' 'CAR13_D' 'CAR13_H' 'CAR14_D' 'CAR14_H' 'CAR15_D' 'CAR15_H' 'CAR16_D' 'CAR16_H' 'CAR17_D' 'CAR17_H')

sample_list=('CAR10_H' 'CAR10_D' 'CAR11_D' 'CAR11_H' 'CAR12_D' 'CAR12_H' 'CAR13_D' 'CAR13_H' 'CAR14_D' 'CAR14_H' 'CAR15_D' 'CAR15_H' 'CAR16_D' 'CAR16_H' 'CAR17_D' 'CAR17_H')

# Get the list of all files in the folder
files=$(ls $base_dir/data/raw_counts)

# Loop through each file
#for file in $files; do
#    echo "Processing $file"
#done


for ref_genome in ${ref_genome_list[@]};do

    # Iterate the string array using for loop
    for batch in ${batch_list[@]}; do

        ## Create output folder for cellbender output
        mkdir -p "${base_dir}/data/cellbender_output/${ref_genome}/${batch}"

        ## Iterate over all the sample names and create an .h5ad file name 
        #  Here all batch-patient-condition combinations are created (i.e. Batch1_CAR1_H,Batch1_CAR1_D,Batch1_CAR2_H...) 
        #  => in reality no tall of them correspond to a file ==> check if file exists 
        for sample_name in ${sample_list[@]}; do
            input_file="${base_dir}/data/raw_counts/${ref_genome}_${batch}_${sample_name}_raw.h5ad"

                ## If given .h5ad file exsists, run cellbender
                if [ -e "$input_file" ]; then
                
    
                    output_file="${batch}_${sample_name}_cb.h5"
                    echo "Starting ${ref_genome} ${batch} ${sample_name}"
                    #echo "$output_file"
                
                    cd "${base_dir}/data/cellbender_output/${ref_genome}/${batch}"
                    cellbender remove-background \
                    	--input "$input_file" \
                    	--output "$output_file" \
                    	--learning-rate 0.00005 \
                    	--cuda
                fi

      done
    done

done

