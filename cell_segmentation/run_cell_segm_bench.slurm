#!/bin/bash
#SBATCH --job-name=cellpose_segm
#SBATCH -o "slurm-%N.%j.out" # STDOUT
#SBATCH -e "slurm-%N.%j.out" # STDERR
#SBATCH --ntasks=1
#SBATCH --time=0-08:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --mem=32G
#SBATCH -p gpu-a100
#SBATCH --gres=gpu:1

## Run cell segmentation
sh run_cell_segm_bench.sh