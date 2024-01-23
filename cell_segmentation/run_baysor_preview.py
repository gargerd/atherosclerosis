import pandas as pd
import argparse
import os
from pathlib import Path


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Assign molecules to cells using Baysor')
    parser.add_argument('-m', '--molecules', required=True, type=str, 
        help='Input csv file in format [Gene, x, y]') 
    parser.add_argument('-d', '--data', required=True, type=str, 
        help='Ouput data directory- should also contain segmented image')
    parser.add_argument('--temp', default=None, type=str, 
        help='Temp data directory for intermediate files') # 
    parser.add_argument('-p', '--hyperparams', default=None, type=str,
        help='Dictionary of hyperparameters') 
    
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
        # Minimal number of molecules for a cell to be considered as real. It's an important parameter, as it's used to infer several other parameters. Default: 3
        "min_molecules_per_cell" : 3,
        # Scale parameter, which suggest approximate cell radius for the algorithm. This parameter is required.
        "scale" : -1
    }
    
    
    args = parser.parse_args()

    molecules = args.molecules
    data = args.data   
    temp = args.temp if args.temp is not None else data
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

    temp =os.path.join(temp,f"baysor_preview")
    toml_file=os.path.join(temp,'config.toml')

    print('temp:    ', temp)
    #temp.mkdir(parents=True, exist_ok=True)
    os.makedirs(temp, exist_ok=True)

        
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
    baysor_cli = f"preview -c {toml_file} -o {temp}/ {molecules}"
    print(baysor_cli)

    #os.system(f'''/Baysor/bin/baysor {baysor_cli}''') # use in docker container: docker pull louisk92/txsim_baysor:latest
    #os.system(f'''baysor {baysor_cli}''') # use in docker container: docker pull louisk92/txsim_baysor:v0.6.2bin
    os.system(f'''JULIA_NUM_THREADS=auto baysor {baysor_cli}''') # use in docker container: docker pull louisk92/txsim_baysor:v0.6.2bin

    
    print("Ran Baysor preview")
