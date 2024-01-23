

from pyometiff import OMETIFFReader
import skimage.io
import argparse
import os
import logging
logging.basicConfig(format='%(asctime)s - %(message)s', datefmt='%d-%b-%y %H:%M:%S')
logging.getLogger().setLevel(logging.INFO)
import numpy as np
import cv2
import pandas as pd
import sys


if __name__ == '__main__':

    #Parse arguments
    parser = argparse.ArgumentParser(description='Extract nucleus masks from 10x cell segmentation')
    parser.add_argument('-i', '--input', required=True, type=str, help='Input path of morphology_mip.ome.tif image file of sample')
    parser.add_argument('-o', '--output', required=True, type=str, help='Output directory of segmented image')
    parser.add_argument('-n', '--nucleus_boundaries', required=True, type=str,
        help='Input path of nucleus_boundaries.csv.gz of sample containing coordinates of nucleus masks')
    parser.add_argument('-ow', '--overwrite',action='store_true',
        help='If segmented .tif file already exists, overwrite it')
    
    args = parser.parse_args()
    
    image_file_path = args.input
    output_dir = args.output
    nucleus_bound_fn = args.nucleus_boundaries 
    overwrite = args.overwrite

    ## Create filename of binary mask output
    output_fn=f'{output_dir}/10x_nuclear_binary_mask.tif'

    ## Check if mask already exists => if overwrite is not True, exit the script
    if os.path.isfile(output_fn)==True and overwrite!=True:
        logging.info('10x nuclear binary mask file already exists! As overwrite parameter is not set, exiting script')
        sys.exit()
    
    ## Else create 10x nuclear polygons as binary mask .tif file
    else:
        ## Read input ome.tif image and nucleus boundary masks
        reader = OMETIFFReader(fpath=image_file_path)
        img_array,metadata,xml_metadata=reader.read()
        nucleus_bound=pd.read_csv(nucleus_bound_fn)
        
        ## Extract pixel width and height
        pixel_width=np.float64(metadata['PhysicalSizeX'])
        pixel_height=np.float64(metadata['PhysicalSizeY'])
        
        ## Calculate pixel coordinates for nucleus/cell boundaries
        nucleus_bound['vertex_x_pixel']=(nucleus_bound['vertex_x']/pixel_width).apply(lambda x: round(x))
        nucleus_bound['vertex_y_pixel']=(nucleus_bound['vertex_y']/pixel_height).apply(lambda x: round(x))
        
        # Initialize an empty mask
        mask = np.zeros(img_array.shape, dtype=np.uint8)
        
        for cell_id,cell_coord_df in nucleus_bound.groupby('cell_id'):
            
            # Convert dataframe to a list of points
            points=cell_coord_df[['vertex_x_pixel','vertex_y_pixel']].values.astype(int)
        
            # Draw filled polygon on the mask
            cv2.fillPoly(mask, [points], color=1)
    
    
        ## Save masked image as tif file
        skimage.io.imsave(output_fn,mask)