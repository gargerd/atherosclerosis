import pandas as pd
import argparse
import os
from pathlib import Path


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Assign molecules to cells using Baysor')
    parser.add_argument('-m', '--molecules', required=True, type=str, 
        help='Input csv file in format [Gene, x, y]')
    parser.add_argument('-sf', '--segment_dir', default=None, type=str, 
        help='Directory- containing segmented image')
    parser.add_argument('-d', '--data', required=True, type=str, 
        help='Output data directory ')
    parser.add_argument('-s', '--segment', default=None, type=str,
        help='Segmentation method used for image') 
    parser.add_argument('-p', '--hyperparams', default=None, type=str,
        help='Dictionary of hyperparameters') 
    parser.add_argument('-id', '--id_code', required=True, type = str,
        help='ID of method to be used for saving') 
    parser.add_argument('--temp', default=None, type=str, 
        help='Temp data directory for intermediate files') # 
    
    DEFAULT_HYPERPARAMS = {
        # Taken from https://github.com/kharchenkolab/Baysor/blob/master/configs/example_config.toml
        
        # [Data]
        # Name of the x column in the input data. Default: "x"
        'x' : '"x_location_pixel"',
        # Name of the y column in the input data. Default: "y"
        "y" : '"y_location_pixel"',
        # Name of the y column in the input data. Default: "z"
        "z" : '"z_location_pixel"',
        # Name of gene column in the input data. Default: "gene"
        "gene" : '"feature_name"',
        # Minimal number of molecules per gene. Default: 1
        "min_molecules_per_gene" : 1,
        # Minimal number of molecules for a cell to be considered as real. It's an important parameter, as it's used to infer several other parameters. Default: 3
        "min_molecules_per_cell" : 3,
        # Scale parameter, which suggest approximate cell radius for the algorithm. This parameter is required.
        "scale" : -1,
        # Standard deviation of scale across cells. Can be either number, which means absolute value of the std, or string ended with "%" to set it relative to scale. Default: "25%"
        # "scale-std" : '"25%"',
        "force_2d":"false",
        # Not exactly sure if this one should be in [Data], therefore we don't provide it via the toml, so not possibl issues here.
        "prior-segmentation-confidence" : 0.5

    }
    
    
    args = parser.parse_args()
    molecules = args.molecules
    segment_dir = args.segment_dir
    data = args.data
    segmentation_method = args.segment

    ## Exract pixel width (um/pixel) for converting 'scale' parameter into pixels
    mols=pd.read_csv(molecules)
    pixel_width=mols['pixel_width'].unique()[0]
   
    if args.hyperparams!=None:
        hyperparams = eval(args.hyperparams)
        hparams = {}
        for key in DEFAULT_HYPERPARAMS:
            if key in hyperparams:
                hparams[key] = hyperparams[key]
            else:
                hparams[key] = DEFAULT_HYPERPARAMS[key]
    if args.hyperparams==None:  
        hparams=DEFAULT_HYPERPARAMS
        
    id_code = args.id_code
    segment = True if args.segment!='no_segmentation'else False
    temp = args.temp if args.temp is not None else data
    
    if segment:
        temp = os.path.join(temp,f"assignments_{segmentation_method}_baysor-{id_code}")
    else:
        temp =os.path.join(temp,f"assignments_baysor-{id_code}")
    toml_file=os.path.join(temp,'config.toml')

    print('temp:    ', temp)
    #temp.mkdir(parents=True, exist_ok=True)
    os.makedirs(temp, exist_ok=True)


    baysor_seg = os.path.join(temp, "segmentation.csv")
    baysor_cell = os.path.join(temp, "segmentation_cell_stats.csv")
    
    # Remove existing outputs (otherwise Errors while running Baysor might be overseen)
    if os.path.isfile(baysor_seg):
        os.remove(baysor_seg)
    if os.path.isfile(baysor_cell):
        os.remove(baysor_cell)
        
    # Write toml
    with open(toml_file, "w") as file:
        for key, val in hparams.items():
            if key == "x":
                file.write(f'[data]\n')
            elif key == "new-component-weight":
                file.write(f'\n[Sampling]\n')
            if key not in ["scale", "prior-segmentation-confidence"]:
                file.write(f'{key} = {val}\n')
                
   
    # Note: we provide scale separately because when providing it via .toml baysor can complain that's it's not a float
    baysor_cli = f"run -s {hparams['scale']/pixel_width} -c {toml_file} -o {temp}/ {molecules} --save-polygons=geojson"
    if segment:
        print("Running Baysor with prior segmentation")
        baysor_cli += f" --prior-segmentation-confidence {hparams['prior-segmentation-confidence']}"
        baysor_cli += f" {segment_dir}/segments_{segmentation_method}-{id_code}.tif"
    else:
        print("Running Baysor without prior segmentation")


    #os.system(f'''/Baysor/bin/baysor {baysor_cli}''') # use in docker container: docker pull louisk92/txsim_baysor:latest
    #os.system(f'''baysor {baysor_cli}''') # use in docker container: docker pull louisk92/txsim_baysor:v0.6.2bin
    os.system(f'''JULIA_NUM_THREADS=auto baysor {baysor_cli}''') # use in docker container: docker pull louisk92/txsim_baysor:v0.6.2bin

    
    print("Ran Baysor")

    df = pd.read_csv(baysor_seg)
    spots = pd.read_csv(molecules)
    spots=spots[['feature_name','x_location','y_location','z_location']]
    spots.columns=['Gene','x','y','z']
    spots["cell"] = df["cell"]
    
    #spots.rename(columns = {spots.columns[0]:'Gene', spots.columns[1]:'x', spots.columns[2]:'y'} , inplace = True)

    df = pd.read_csv(baysor_cell)
    areas = df[['cell','area']]

    #Save to csv
    if segment:
        areas.to_csv(f'{data}/areas_{segmentation_method}_baysor-{id_code}.csv', index = False, header = False)
        spots.to_csv(f'{data}/assignments_{segmentation_method}_baysor-{id_code}.csv', index = False)
    else:
        areas.to_csv(f'{data}/areas_baysor-{id_code}.csv', index = False, header = False)
        spots.to_csv(f'{data}/assignments_baysor-{id_code}.csv', index = False)

        