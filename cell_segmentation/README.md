1. Cell pre-segmentation
   - Run cs_2_run_cell_segm_benchm.sh to create binary masks of segmented cells with different cell segmentation methods (see first lines of .sh file), that can be used as input to Baysor
2. Run baysor segmentation
   - Run bays_run_baysor_within_docker.sh.sh file to create final cell segmentation using the pre-segmented binary masks + the transcipt coordinates (Xenium output)




### Readme from https://github.com/Moldia/Xenium_benchmarking/tree/main/notebooks/4_segmentation_benchmark
Provided are the scripts to 
- run the different segmentation methods (run_segmentation.py, run_{method}.py)
- generate the count matrix (gen_counts.py)
- and the functions to calculate the reported metrics (metrics.py)

- 