#!/bin/bash

#baysor_path='/Atherosclerosis/atherosclerosis/cell_segmentation/run_baysor.py'


#source ~/anaconda3/etc/profile.d/conda.sh
#conda activate xenium
#echo "Active conda environment: $CONDA_DEFAULT_ENV"

#### ========================= #####
### DEF FUNCTIONS
# Function to calculate and print elapsed time
print_elapsed_time() {
    elapsed_seconds=$1

    hours=$((elapsed_seconds / 3600))
    minutes=$(( (elapsed_seconds % 3600) / 60 ))
    seconds=$((elapsed_seconds % 60))

    printf "$2: %02d hours : %02d minutes : %02d seconds\n" "$hours" "$minutes" "$seconds"
}

#### ========================= #####
### RUN DOCKER CONTAINER WITH BAYSOR IMAGE
start_baysor_docker_container() {
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
}

#### ========================= #####
### RUN BAYSOR COMMAND (EITHER BAYSOR RUN OR BAYSOR PREVIEW
run_baysor_cli(){
    baysor_command=$1
    baysor_molecules=$2
    baysor_data_dir=$3
    segm_method=$4
    id_cod=$5
    baysor_output_fold=$6
    hyperparams=$7
    cell_segm_dir=$8
    
    
    if [ "$baysor_command" == "run" ]; then
    echo "Executing run_baysor.py"
    ## Execute run_baysor.py file                              
    sudo docker exec baysor_docker python3.10 run_baysor.py -m $baysor_molecules \
                                                            -d $baysor_data_dir \
                                                            -s $segm_method \
                                                            -id $id_code \
                                                            --temp $baysor_output_fold \
                                                            -p $hyperparams \
                                                            -sf $cell_segm_dir

    fi
    
    if [ "$baysor_command" == "preview" ]; then
    ## Execute run_baysor_preview.py file  
    echo "Executing run_baysor_preview.py"
    sudo docker exec baysor_docker python3.10 run_baysor_preview.py -m $baysor_molecules \
                                                                    -d $baysor_data_dir \
                                                                   --temp $baysor_output_fold #\
                                                                   #-p $hyperparams 
    fi                                                                    
}



#### ========================= #####
## Set errors for bash script
set -euo pipefail #o

### SETUP DATA FOLDER TO LOOP OVER
data_dir="/home/unimelb.edu.au/gargerd/data/Atherosclerosis/xenium_data"

#data_dir="/Atherosclerosis/xenium_data"

# Drop scratch folders that start with "._"
panel_dir_list=($(find "$data_dir" -maxdepth 1 -type d -name '*Panel*' -a ! -name '._*' | sort))

sample_name_list=('P1_H' 'P1_D' 'P2_H' 'P2_D' 'P3_H' 'P3_D' 'P4_H' 'P4_D') #


### SEGMENTATION PARAMETERS
# Size of cell expansion after cell segmentation (um) => has to be converted to pixels!
segment_expansion_sizes_um=('0') #'4' '6' '10') 

# Segmentation methods
segment_methods=('no_segmentation' '10x') #'cellpose' 

## Cellpose model types
cellpose_model_types=('cyto' 'nuclei')


### BAYSOR PARAMETERS
# Values for 'scale' parameter in Baysor => ~ expected RADIUS of cells in um-s
#baysor_scale_arr_um=('3' '5' '8') 


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

           

            ## Create dirname of cell segmentation output files(....cell_segmentation/PanelX_PX_X)
    	    sample_dirname="${panel_suffix}_${sample_name}"
    	    cell_segm_dir="${data_dir}/processed_data/cell_segmentation/$sample_dirname"

             ## Create output parent folder if necessary
            baysor_output_fold="${data_dir}/processed_data/baysor_output/$sample_dirname"
            if [ ! -d "$baysor_output_fold" ]; then
                echo "/baysor_output does not exist. Creating it..."
                mkdir -p "$baysor_output_fold"
                echo "/baysor_output created successfully."
            fi 
  
    
            ## Loop over segmentation methods
            for segm_method in "${segment_methods[@]}"; do
                
                ## CELLPOSE SEGMENTATION
                if [ "$segm_method" = "cellpose" ]; then
                    
                    ## Loop over cellpose hypterparameters
                    for cp_model_type in "${cellpose_model_types[@]}"; do
                        for cp_expans_size in "${segment_expansion_sizes_um[@]}"; do
    
                            #### BAYSOR inputs       
                            id_code="CP${cp_model_type:0:1}_${cp_expans_size}"
                            baysor_molecules="${cell_segm_dir}/transcripts_pixel.csv.gz"
                            baysor_data_dir=$output_dir                            


                            echo "Sample ${sample_dirname} ${id_code}"
                            segm_start=$(date +%s)

                            
                            ### FOR EACH BAYSOR RUN THE BAYSOR DOCKER IMAGE HAS TO BE STARTED FRESHLY, AS AFTER HAVING RUN BAYSOR ONCE THE IMAGE
                            #   DOCKER ALWAYS RETURNED AN ERROR (Killed) => 
                            #   1. start the baysor docker image as container with name "baysor_image"
                            #   2. execute the convert_um_to_pixel.py in the baysor_docker container
                            #   3. execute run_baysor in baysor_image container
                            #   4. stop & remove baysor_image container

                            # 1. Start docker container
                            start_baysor_docker_container
                            
                            ## 2. Convert transcript coordinates to pixels from micrometers
                            sudo docker exec baysor_docker python3.10 convert_um_to_pixel.py -d $sample_dir  -p $cell_segm_dir #-ow  #if file already exists, overwrite
        
                            ## 3. Execute run_baysor.py file or run_baysor_preview.py file
                            bays_cmd_list=("preview") # "run")
                            
                            for bays_comd in "${bays_cmd_list[@]}"; do                        
                                run_baysor_cli $bays_comd $baysor_molecules $baysor_data_dir $segm_method $id_code $baysor_output_fold $hyperparams $cell_segm_dir
                            done     
            
                            
                            segm_stop=$(date +%s)
                            elapsed_seconds=$((segm_stop - segm_start))
                            print_elapsed_time "$elapsed_seconds" "Sample ${sample_dirname} ${id_code} runtime"
                            echo '============================'
                        
                    done
                done
            fi

            ## OTHER SEGMENTATION METHODS
            if [ "$segm_method" == "10x" ]; then
                for expans_size in "${segment_expansion_sizes_um[@]}"; do
                    segm_start=$(date +%s)

                    hyperparams='{"x-column":"x","y-column":"y","z-column":"z","gene-column":"Gene","min-molecules-per-gene":1,"min-molecules-per-cell":3,"scale":10,"scale-std":"50%","prior-segmentation-confidence":0.5}'
    
                    id_code="${segm_method}_${expans_size}"
                    baysor_molecules="${cell_segm_dir}/transcripts_pixel.csv.gz"
                    baysor_data_dir=$output_dir

                    echo "Sample ${sample_dirname} ${id_code}"
                    
                    # 1. Start docker container
                    start_baysor_docker_container
                    
                    ## 2. Convert transcript coordinates to pixels from micrometers
                    sudo docker exec baysor_docker python3.10 convert_um_to_pixel.py -d $sample_dir  -p $cell_segm_dir -ow  #if file already exists, overwrite

                    ## 3. Execute run_baysor.py file or run_baysor_preview.py file
                    bays_cmd_list=("run") # "preview")
                    
                    for bays_comd in "${bays_cmd_list[@]}"; do                        
                        run_baysor_cli $bays_comd $baysor_molecules $baysor_data_dir $segm_method $id_code $baysor_output_fold $hyperparams $cell_segm_dir
                    done                
                                                                                                               
    
                    segm_stop=$(date +%s)
                    elapsed_seconds=$((segm_stop - segm_start))
                    print_elapsed_time "$elapsed_seconds" "Segmentation time"
                    echo '============================'
                done 
            fi


            ## Segmentation free baysor run
            if [ "$segm_method" == "no_segmentation" ]; then

                segm_start=$(date +%s)

                hyperparams='{"x-column":"x","y-column":"y","z-column":"z","gene-column":"Gene","min-molecules-per-gene":1,"min-molecules-per-cell":3,"scale":10,"scale-std":"50%","prior-segmentation-confidence":0.5}'

                id_code="${segm_method}"
                baysor_molecules="${cell_segm_dir}/transcripts_pixel.csv.gz"
                baysor_data_dir=$output_dir

                echo "Sample ${sample_dirname} ${id_code}"
                
                # 1. Start docker container
                start_baysor_docker_container
                
                ## 2. Convert transcript coordinates to pixels from micrometers
                sudo docker exec baysor_docker python3.10 convert_um_to_pixel.py -d $sample_dir  -p $cell_segm_dir -ow  #if file already exists, overwrite

                ## 3. Execute run_baysor.py file or run_baysor_preview.py file
                bays_cmd_list=("run") # "preview")
                
                for bays_comd in "${bays_cmd_list[@]}"; do                        
                    run_baysor_cli $bays_comd $baysor_molecules $baysor_data_dir $segm_method $id_code $baysor_output_fold $hyperparams $cell_segm_dir
                done                
                                                                                                           

                segm_stop=$(date +%s)
                elapsed_seconds=$((segm_stop - segm_start))
                print_elapsed_time "$elapsed_seconds" "Segmentation time"
                echo '============================'
            
            fi

        done ## Segmentation loop done

        
        
        fi
    done
done

sleep 1
end=$(date +%s)
elapsed_seconds=$((end - start))
print_elapsed_time "$elapsed_seconds" "Script duration"

