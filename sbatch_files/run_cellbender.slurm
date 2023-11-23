#!/bin/bash
#SBATCH -o slurm_cellbender.log
#SBATCH -e slurm_cellbender.log
#SBATCH --job-name=CELLBENDER
#SBATCH --ntasks=1
#SBATCH -c 4
##SBATCH --mem-per-cpu=64
#SBATCH --partition=gpu-a100
#SBATCH --mem-per-gpu=8G
##SBATCH --qos=gpu_normal
#SBATCH --gres=gpu:1
#SBATCH --time=06:00:00
#SBATCH --nice=10000

## Load conda and activate environment with cellbender installed in it
module load Anaconda3/2022.10
eval "$(conda shell.bash hook)"
conda deactivate
conda activate cellbender

## Run cellbender
sh /data/gpfs/projects/punim2121/Atherosclerosis/src/scrna_analysis/ath_1_run_cellbender.sh
