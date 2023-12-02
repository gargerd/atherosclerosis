import pandas as pd
import argparse
import os
import numpy as np

## Check if pyometiff is installed. If not install it inside the docker image (=> everytime the image gets run, it has to be installed)
import importlib

# Specify the package name
package_name = 'pyometiff'

# Check if the package is installed
try:
    importlib.import_module(package_name)
    print(f'{package_name} is already installed.')
except ImportError:
    print(f'{package_name} is not installed. Installing...')

    # Install the package using pip
    import subprocess
    subprocess.check_call(['pip', 'install', package_name])

    print(f'{package_name} has been successfully installed.')

from pyometiff import OMETIFFReader





if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Convert the transcript coordinates from micrometers to pixels in order for Baysor to use it')
    parser.add_argument('-d', '--sample_dir', required=True, type=str, 
        help='Input directory of Xenium sample containing transcripts.csv.gz + morphology_mip.ome.tiff files')
    parser.add_argument('-p', '--proc_out_dir', required=True, type=str, 
        help='Output directory of processed cell segmentation data for the given sample')


    args = parser.parse_args()
    sample_dir=args.sample_dir
    proc_out_dir=args.proc_out_dir

    ## Read the transcripts
    tr_fn=os.path.join(sample_dir,'transcripts.csv.gz')
    transcripts=pd.read_csv(tr_fn) 

    
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

    ## Save dataframe with converted coordinates
    save_fn=os.path.join(proc_out_dir,'transcripts_pixel.csv.gz')
    print(save_fn)
    transcripts.to_csv(save_fn,compression='gzip')