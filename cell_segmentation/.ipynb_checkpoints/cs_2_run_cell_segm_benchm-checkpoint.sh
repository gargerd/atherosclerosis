#!/bin/bash

## Load anaconda + activate "xenium" conda environment
#module load Anaconda3/2022.10
#eval "$(conda shell.bash hook)"

source ~/anaconda3/etc/profile.d/conda.sh
conda activate xenium
echo "Active conda environment: $CONDA_DEFAULT_ENV"



# Function to calculate and print elapsed time
print_elapsed_time() {
    elapsed_seconds=$1

    hours=$((elapsed_seconds / 3600))
    minutes=$(( (elapsed_seconds % 3600) / 60 ))
    seconds=$((elapsed_seconds % 60))

    printf "$2: %02d hours : %02d minutes : %02d seconds\n" "$hours" "$minutes" "$seconds"
}



## Set errors for bash script
set -euo pipefail #o

### SETUP DATA FOLDER TO LOOP OVER
#data_dir="/data/gpfs/projects/punim2121/Atherosclerosis/xenium_data/"
data_dir="/home/unimelb.edu.au/gargerd/data/Atherosclerosis/xenium_data"

# Drop scratch folders that start with "._"
panel_dir_list=($(find "$data_dir" -maxdepth 1 -type d -name '*Panel*' -a ! -name '._*' | sort))

sample_name_list=('P1_H' 'P1_D' 'P2_H' 'P2_D' 'P3_H' 'P3_D' 'P4_H' 'P4_D')


### SEGMENTATION PARAMETERS
# Size of cell expansion after cell segmentation (um) => has to be converted to pixels!
segment_expansion_sizes_um=('0' '4' '6' '10') 

# Segmentation methods
segment_methods=('10x') #'cellpose' 

## Cellpose model types
cellpose_model_types=('cyto' 'nuclei')


### BAYSOR PARAMETERS
# Values for 'scale' parameter in Baysor => ~ expected RADIUS of cells in um-s
baysor_scale_arr_um=('3' '5' '8') 


start=$(date +%s)

#nvcc --version
#nvidia-smi


for panel in "${panel_dir_list[@]}"; do
    #sample_name_list=($(find "$panel" -maxdepth 1 -type d -printf '%f\n' | sort))

    ## Extract PanelX as the panel suffix
    panel_suffix=$(echo "$panel" | rev | cut -d'_' -f 1 | rev)
   
    # Loop over all samples in a batch
    for sample_name in "${sample_name_list[@]}"; do
        # Create path of sample, where slide image can be found
        sample_dir="$panel/${panel_suffix}_${sample_name}"

     	
    	if [[ -d "$sample_dir" ]]; then #&& [[ "$sample_dir" == *"P3_H"* ]]

            ## Input filename of DAPI image
    	    input_fn="$sample_dir/morphology_mip.ome.tif"          

            ## Create output parent folder if necessary
            proc_fold="${data_dir}/processed_data/cell_segmentation"
            if [ ! -d "$proc_fold" ]; then
                echo "/xenium_data/processed_data/cell_segmentation does not exist. Creating it..."
                mkdir -p "$proc_fold"
                echo "/xenium_data/processed_data/cell_segmentation created successfully."
            fi    

            ## Create dirname of output files to save to (....cell_segmentation/PanelX_PX_X)
    	    sample_dirname="${panel_suffix}_${sample_name}"
    	    output_dir="${data_dir}/processed_data/cell_segmentation/$sample_dirname"
  
    
            ## Loop over segmentation methods
            for segm_method in "${segment_methods[@]}"; do
                
                ## CEELPOSE SEGMENTATION
                if [ "$segm_method" = "cellpose" ]; then
                    
                    ## Loop over cellpose hypterparameters
                    for cp_model_type in "${cellpose_model_types[@]}"; do

                        ### Cell segmentation hyperparameter dictionary
                                                hyperparams='{"model_type":"'"$cp_model_type"'","batch_size":2,"channel_axis":None,"z_axis":None,"invert":False,"normalize":True,"diameter":30.0,"do_3D":False,"anisotropy":None,"net_avg":False,"augment":False,"tile":True,"tile_overlap":0.1,"resample":True,"interp":True,"flow_threshold":0.0,"cellprob_threshold":0.0,"min_size":15,"stitch_threshold":0.0,"rescale":True,"progress":True,"model_loaded":False}'
                        id_code="CP${cp_model_type:0:1}" #_${cp_expans_size}"
    
                        segm_start=$(date +%s)

                        ## Run segmentation 
                        echo "Starting cell segmentation for model: ${sample_dirname} ${id_code}"
                        python run_segmentation.py -i $input_fn -o $output_dir -s $segm_method -id $id_code -p $hyperparams -e ${segment_expansion_sizes_um[@]}
                                                   #-b \  => 'If the input image is a segmented, binary image (e.g. watershed via ImageJ)',then include -b ('binary' var in Python==True)
                                                   #          If input image is not segmented, comment -b out => sets 'binary' value in python script to False

                        #python -m cellpose --use_gpu --verbose --image_path $input_fn
                        segm_stop=$(date +%s)
                        elapsed_seconds=$((segm_stop - segm_start))
                        print_elapsed_time "$elapsed_seconds" "Segmentation time"
                        echo '============================'
                        
                    
                done
            fi
            
            ## OTHER SEGMENTATION METHODS
            if [ "$segm_method" == "10x" ]; then
                segm_start=$(date +%s)

                ## Create nucleus boundary path filename
                nucleus_bound_fn="$sample_dir/nucleus_boundaries.csv.gz" 

                ## CREATE BINARY MASK IMAGE FROM 10X NUCLEAR MASKS
                echo "Creating 10x nuclear mask for model: ${sample_dirname} ${segm_method}"                
                python cs_1_create_10x_nuclear_masks.py -i $input_fn -o $output_dir -n $nucleus_bound_fn #-ow # if cell mask alrady exists, overwrite it


                nuclear_mask_fn="${output_dir}/10x_nuclear_binary_mask.tif"
                
                ## Run segmentation 
                echo "Starting cell segmentation for model: ${sample_dirname} ${segm_method}"
                python run_segmentation.py -i $input_fn \
                                            -o $output_dir \
                                            -s $segm_method \
                                            -id $segm_method\
                                            -e ${segment_expansion_sizes_um[@]} \
                                            -b \
                                            -sf $nuclear_mask_fn

                segm_stop=$(date +%s)
                elapsed_seconds=$((segm_stop - segm_start))
                print_elapsed_time "$elapsed_seconds" "Segmentation time"
                echo '============================'
      
            fi
        done ## Segmentation loop done


        fi
    done
done

end=$(date +%s)
elapsed_seconds=$((end - start))
print_elapsed_time "$elapsed_seconds" "Script duration"

