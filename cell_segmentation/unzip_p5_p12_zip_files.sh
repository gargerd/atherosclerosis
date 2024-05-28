#!/bin/bash


data_dir="/home/unimelb.edu.au/gargerd/data/Atherosclerosis/xenium_data"

# Drop scratch folders that start with "._"
panel_dir_list=($(find "$data_dir" -maxdepth 1 -type d -name '*202312*' -a ! -name '._*' | sort))


data_dir="/home/unimelb.edu.au/gargerd/data/Atherosclerosis/xenium_data/20231212__144648__2311-Sachs_Panel2/"
sample_name_list=('P5_D' 'P6_D' 'P7_D' 'P8_D' 'P9_D' 'P10_D' 'P11_D' 'P12_D')

for panel in "${panel_dir_list[@]}"; do
    echo $panel
    
    ## Extract PanelX as the panel suffix
    panel_suffix=$(echo "$panel" | rev | cut -d'_' -f 1 | rev)
   
    # Loop over all samples in a batch
    for sample_name in "${sample_name_list[@]}"; do
        # Create path of sample, where slide image can be found
        sample_dir="$panel/${panel_suffix}_${sample_name}_"
        zip_dir="$panel/${panel_suffix}_${sample_name}"
        new_dir=$(echo "$sample_dir" | sed 's/_$//')

        unzip "$sample_dir" -d "${zip_dir}"
    done    

done    