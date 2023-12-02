#!/bin/bash

ather_dir='/home/unimelb.edu.au/gargerd/data/Atherosclerosis'
baysor_path='/Atherosclerosis/atherosclerosis/cell_segmentation/run_baysor.py'
#dock_img_name='8f02118f6c19' #v0.6.2
#dock_img_name='ecab4cc3d386' # v0.6.2bin
dock_img_name='94ed89218e8d' # v0.6.2bin + pyometiff installed to read slide metadata for um=>pixel conversion

## Run docker with baysor image
sudo docker run -it --name baysor_docker \
            --mount type=bind,source=$ather_dir,target=/Atherosclerosis -w /Atherosclerosis/atherosclerosis/cell_segmentation \
            $dock_img_name bash 

## Execute run_baysor.py file            
#sudo docker exec -w /Atherosclerosis/atherosclerosis/cell_segmentation baysor_docker python3.10 $baysor_path

sudo docker exec baysor_docker python3.10 $baysor_path

## Stop & delete the docker image 
sudo docker stop baysor_docker
sudo docker rm baysor_docker