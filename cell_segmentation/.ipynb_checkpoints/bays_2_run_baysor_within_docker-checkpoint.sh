#!/bin/bash

#baysor_path='/Atherosclerosis/atherosclerosis/cell_segmentation/run_baysor.py'


#source ~/anaconda3/etc/profile.d/conda.sh
#conda activate xenium
#echo "Active conda environment: $CONDA_DEFAULT_ENV"


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
data_dir="/home/unimelb.edu.au/gargerd/data/Atherosclerosis/xenium_data"

#data_dir="/Atherosclerosis/xenium_data"

# Drop scratch folders that start with "._"
panel_dir_list=($(find "$data_dir" -maxdepth 1 -type d -name '*Panel*' -a ! -name '._*' | sort))

sample_name_list=('P1_H' 'P1_D' 'P2_H' 'P2_D' 'P3_H' 'P3_D' 'P4_H' 'P4_D')


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
                        for cp_expans_size in "${segment_expansion_sizes_um[@]}"; do
    
                            #### BAYSOR inputs       
                            id_code="CP${cp_model_type:0:1}_${cp_expans_size}"
                            baysor_molecules="${output_dir}/transcripts_pixel.csv.gz"
                            baysor_data_dir=$output_dir

                            hyperparams='{"x-column":"x","y-column":"y","z-column":"z","gene-column":"Gene","min-molecules-per-gene":1,"min-molecules-per-cell":3,"scale":-1,"prior-segmentation-confidence":0.2}'


                            echo "Sample ${sample_dirname} ${id_code}"
                            segm_start=$(date +%s)

                            

                            ### FOR EACH BAYSOR RUN THE BAYSOR DOCKER IMAGE HAS TO BE STARTED FRESHLY, AS AFTER HAVING RUN BAYSOR ONCE THE IMAGE
                            ### ALWAYS RETURNED AN ERROR (Killed) => 
                            #   1. run the baysor docker image as container with name "baysor_image"
                            #   2. execute the convert_um_to_pixel.py in the baysor_docker container
                            #   3. execute run_baysor in baysor_image container
                            #   4. stop & remove baysor_image container

                            ather_dir='/home/unimelb.edu.au/gargerd/data/Atherosclerosis'
                            baysor_path='/Atherosclerosis/atherosclerosis/cell_segmentation/run_baysor.py'
                            #dock_img_name='8f02118f6c19' #v0.6.2
                            #dock_img_name='ecab4cc3d386' # v0.6.2bin
                            dock_img_name='94ed89218e8d' # v0.6.2bin + pyometiff installed to read slide metadata for um=>pixel conversion

                            bash ${ather_dir}/atherosclerosis/cell_segmentation/bays_stop_active_baysor_docker.sh
                            
                            ## Run docker with baysor image
                            sudo docker run -it --name baysor_docker -d \
                                        --mount type=bind,source=$ather_dir,target=$ather_dir -w ${ather_dir}/atherosclerosis/cell_segmentation \
                                        $dock_img_name bash 

                            ## Convert transcript coordinates to pixels from micrometers
                            sudo docker exec baysor_docker python3.10 convert_um_to_pixel.py -d $sample_dir  -p $output_dir            
                            
                            ## Execute run_baysor.py file                              
                            sudo docker exec baysor_docker python3.10 run_baysor.py -m $baysor_molecules \
                                                                                    -d $baysor_data_dir \
                                                                                    -s $segm_method \
                                                                                    -id $id_code \
                                                                                    --temp $baysor_data_dir \
                                                                                    -p $hyperparams
                            
                            ## Stop & delete the docker image 
                            sudo docker stop baysor_docker
                            sudo docker rm baysor_docker
                            
                            ## Run Baysor 
                            #python3.10 run_baysor.py -m $baysor_molecules -d $baysor_data_dir -s $segm_method -id $id_code --temp $baysor_data_dir -p $hyperparams
            
                            
                            segm_stop=$(date +%s)
                            elapsed_seconds=$((segm_stop - segm_start))
                            print_elapsed_time "$elapsed_seconds" "Sample ${sample_dirname} ${id_code} runtime"
                            echo '============================'
                        
                    done
                done
            fi
            

        done ## Segmentation loop done

        
        
        fi
    done
done

sleep 1
end=$(date +%s)
elapsed_seconds=$((end - start))
print_elapsed_time "$elapsed_seconds" "Script duration"

