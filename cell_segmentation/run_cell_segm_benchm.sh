#!/bin/bash

## Load anaconda + activate "xenium" conda environment
module load Anaconda3/2022.10
eval "$(conda shell.bash hook)"
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
set -euo pipefail

### SETUP DATA FOLDER TO LOOP OVER
data_dir="/data/gpfs/projects/punim2121/Atherosclerosis/xenium_data/"

# Drop scratch folders that start with "._"
panel_dir_list=($(find "$data_dir" -maxdepth 1 -type d -name '*Panel*' -a ! -name '._*' | sort))


### SEGMENTATION PARAMETERS
# Size of cell expansion after cell segmentation (um) => has to be converted to pixels!
segment_expansion_sizes_um=('4' '6' '10') 

# Segmentation methods
segment_methods=('cellpose')

## Cellpose model types
cellpose_model_types=('cyto' 'nuclei')


### BAYSOR PARAMETERS
# Values for 'scale' parameter in Baysor => ~ expected RADIUS of cells in um-s
baysor_scale_arr_um=('3' '5' '8') 


start=$(date +%s)

for panel in "${panel_dir_list[@]}"; do
    sample_name_list=($(find "$panel" -maxdepth 1 -type d -printf '%f\n' | sort))
   
    # Loop over all samples in a batch
    for sample_name in "${sample_name_list[@]}"; do
        sample_dir="$panel/$sample_name"
  	
	if [[ -d "$sample_dir" ]] && [[ "$sample_dir" == *"P3_H"* ]]; then
	       		
        ## Input filename of DAPI image
	    input_fn="$sample_dir/morphology_mip.ome.tif"
	    
	    ## Extract PanelX + PX_X -> i.e. Panel1_P3_D as sample dirname + later as output directory	     
	    panel_suffix=$(echo "$panel" | rev | cut -d'_' -f 1 | rev)
        sample_suffix=$(awk -F__ '{print $3}' <<< "$sample_name")

	    sample_dirname="${panel_suffix}_${sample_suffix}"
	    output_dir="${data_dir}processed_data/cell_segmentation/$sample_dirname"

        ## Loop over segmentation methods
        for segm_method in "${segment_methods[@]}"; do
            
            ## CEELPOSE SEGMENTATION
            if [ "$segm_method" = "cellpose" ]; then
                
                ## Loop over cellpose hypterparameters
                for cp_model_type in "${cellpose_model_types[@]}"; do
                    for cp_expans_size in "${segment_expansion_sizes_um[@]}"; do

                        ### Cell segmentation hyperparameter dictionary
                        hyperparams='{"model_type":"'"$cp_model_type"'","batch_size":8,"channel_axis":None,"z_axis":None,"invert":False,"normalize":True,"diameter":30.0,"do_3D":False,"anisotropy":None,"net_avg":False,"augment":False,"tile":True,"tile_overlap":0.1,"resample":True,"interp":True,"flow_threshold":0,"cellprob_threshold":0.0,"min_size":15,"stitch_threshold":0.0,"rescale":None,"progress":None,"model_loaded":False}'
                        id_code="CP${cp_model_type:0:1}_${cp_expans_size}"
    
                        segm_start=$(date +%s)

                        ## Run segmentation 
                        echo "Starting cell segmentation for model: ${id_code}"
                        python run_segmentation.py -i $input_fn -o $output_dir -s $segm_method -id $id_code -p $hyperparams -e $cp_expans_size 
                                                   #-b \  => 'If the input image is a segmented, binary image (e.g. watershed via ImageJ)',then include -b ('binary' var in Python==True)
                                                   #          If input image is not segmented, comment -b out => sets 'binary' value in python script to False


                        segm_stop=$(date +%s)
                        elapsed_seconds=$((segm_stop - segm_start))
                        print_elapsed_time "$elapsed_seconds" "Segmentation time"
                        
                    done
                done
            fi
            
            ## OTHER SEGMENTATION METHODS
            if [ "$segm_method" != "cellpose" ]; then
                id_code="${segm_method}_${cp_expans_size}"
                echo $id_code
            #    ## Write this later...
            fi
        done ## Segmentation loop done

        
        #### BAYSOR inputs
        baysor_molecules="$sample_dir/transcripts.csv.gz"

	    
        #echo 'test'
 	    #echo $input_fn
	    #echo $output_dir
        fi
    done
done

sleep 1
end=$(date +%s)
elapsed_seconds=$((end - start))
print_elapsed_time "$elapsed_seconds" "Script duration"

