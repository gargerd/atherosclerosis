#!/bin/bash

## Set errors for bash script
set -euo pipefail #o

### SETUP DATA FOLDER TO LOOP OVER
#data_dir="/data/gpfs/projects/punim2121/Atherosclerosis/xenium_data/"
data_dir="/home/unimelb.edu.au/gargerd/Atherosclerosis/xenium_data"

# Drop scratch folders that start with "._"
panel_dir_list=($(find "$data_dir" -maxdepth 1 -type d -name '*Panel*' -a ! -name '._*' | sort))

for panel in "${panel_dir_list[@]}"; do
    sample_name_list=($(find "$panel" -maxdepth 1 -type d -printf '%f\n' | sort))
   
    # Loop over all samples in a batch
    for sample_name in "${sample_name_list[@]}"; do
        sample_dir="$panel/$sample_name"
  	
	if [[ -d "$sample_dir" ]]; then #&& [[ "$sample_dir" == *"P3_H"* ]]

     ## Extract PanelX + PX_X -> i.e. Panel1_P3_D as sample dirname + later as output directory	     
    panel_suffix=$(echo "$panel" | rev | cut -d'_' -f 1 | rev)
    sample_suffix=$(awk -F__ '{print $3}' <<< "$sample_name")

    sample_dirname="${panel_suffix}_${sample_suffix}"
    #echo $sample_dir
    #echo $panel/$sample_dirname
    mv $sample_dir $panel/$sample_dirname
 

    fi
  done
done  