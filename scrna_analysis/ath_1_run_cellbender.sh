#!/bin/bash
  
base_dir="/data/gpfs/projects/punim2121/Atherosclerosis/"

ref_genome_list=("GRCh38-p13-Gencode_v33" "GRCh38-p14-Gencode_v44")

declare -a batch_list=("Batch1" "Batch2" "Batch3" "Batch4")


nvidia-smi

for ref_genome in ${ref_genome_list[@]};do

  # Iterate the string array using for loop
  for batch in ${batch_list[@]}; do
	input_file="${base_dir}/data/${ref_genome}_${batch}_raw.h5ad"

	mkdir -p "${base_dir}/data/cellbender_output/${ref_genome}/${batch}"
	output_file="${batch}_cb.h5"
	echo "Starting ${batch}"

	cd "${base_dir}/data/cellbender_output/${ref_genome}/${batch}"
	cellbender remove-background \
		--input "$input_file" \
		--output "$output_file" \
		--learning-rate 0.00005 \
		--cuda

  done

done
