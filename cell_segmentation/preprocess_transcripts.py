import pandas as pd
import argparse
import os
import numpy as np
import sys
import logging
logging.basicConfig(format='%(asctime)s - %(message)s', datefmt='%d-%b-%y %H:%M:%S')
logging.getLogger().setLevel(logging.INFO)

## Check if pyometiff is installed. If not install it inside the docker image (=> everytime the image gets run, it has to be installed)
import importlib

# Specify the package name
package_name = 'pyometiff'

# Check if the package is installed
try:
    importlib.import_module(package_name)
    logging.info(f'{package_name} is already installed.')
except ImportError:
    logging.info(f'{package_name} is not installed. Installing...')

    # Install the package using pip
    import subprocess
    subprocess.check_call(['pip', 'install', package_name])

    logging.info(f'{package_name} has been successfully installed.')

from pyometiff import OMETIFFReader


#### THIS SCRIPTS FILTERS LOW QUALITY TRANSCRIPT READS + CONVERTS THE X,Y,Z COORDINATES FROM MICROMETER TO PIXELS


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Convert the transcript coordinates from micrometers to pixels in order for Baysor to use it')
    parser.add_argument('-d', '--sample_dir', required=True, type=str, 
        help='Input directory of Xenium sample containing transcripts.csv.gz + morphology_mip.ome.tiff files')
    parser.add_argument('-p', '--proc_out_dir', required=True, type=str, 
        help='Output directory of processed cell segmentation data for the given sample')
    parser.add_argument('-ow', '--overwrite',action='store_true',
        help='If converted transcripts transcripts_pixel.csv.gz file already exists, overwrite it')
    parser.add_argument('-s', '--segment', default=None, type=str,
        help='Segmentation method used for image') 


    args = parser.parse_args()
    sample_dir=args.sample_dir
    proc_out_dir=args.proc_out_dir
    overwrite=args.overwrite
    output_fn=os.path.join(proc_out_dir,'transcripts_pixel.csv.gz')
    segmentation_method = args.segment

    ## Read the transcripts and FILTER LOW QUALITY READS
    tr_fn=os.path.join(sample_dir,'transcripts.csv.gz')
    transcripts=pd.read_csv(tr_fn) 
    transcripts=transcripts.loc[transcripts['qv']>20,:]
    logging.info('Dropping low quality reads')

    ## Check if mask already exists => if overwrite is not True, exit the script with saving the filtered transcript.csv
    if '10x' in segmentation_method:
        if os.path.isfile(output_fn)==True and overwrite!=True:
            ## Save dataframe with filtered transcripts
            transcripts.to_csv(output_fn,compression='gzip')
            logging.info('10x nuclear binary mask file already exists! As overwrite parameter is not set, exiting script')
            sys.exit()

    
    
    ## Read OME-TIFF slide of sample and extract the um-to-pixel ratio for the given sample
    tr_fn=os.path.join(sample_dir,'morphology_mip.ome.tif')
    reader=OMETIFFReader(fpath=tr_fn)                       
    _,metadata,_=reader.read()
    pixel_width=np.float64(metadata['PhysicalSizeX'])
    pixel_height=np.float64(metadata['PhysicalSizeY'])

    
    ## Calculate pixel coordinates for nucleus/cell boundaries
    transcripts['x_location_pixel']=(transcripts['x_location']/pixel_width).apply(lambda x: round(x))
    transcripts['y_location_pixel']=(transcripts['y_location']/pixel_height).apply(lambda x: round(x))
    transcripts['z_location_pixel']=(transcripts['z_location']/pixel_height).apply(lambda x: round(x))
    transcripts['pixel_height']=pixel_height
    transcripts['pixel_width']=pixel_width
    
    logging.info('Starting to save filtered transcript.csv.gz')
    logging.info(f'Pixel width & height {pixel_width} , {pixel_height}')
    print('transcripts.shape',transcripts.shape)
    ## Save dataframe with converted coordinates
    transcripts.to_csv(output_fn,compression='gzip')
    logging.info('Saved filtered transcript.csv.gz')