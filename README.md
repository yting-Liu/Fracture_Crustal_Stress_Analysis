## Overview

This repository provides a workflow for inverting the background crustal stress by matching the polarity of motion on earthquake induced fractures.

## Workflow

### Step 1. InSAR Data Processing
The full-resolution interferograms and InSAR phase-gradient maps were generated using the GMTSAR software.

### Step 2. Fracture Polarity Analysis
- Displacement Decomposition:
``` 
python ./src/decompose/decomposition.py
```
- Output:
``` 
east_west.grd
up_down.grd
```

- Profile Extraction:
``` 
bash ./src/Profiles_Analysis/make_profiles.csh
```
- Output:
``` 
A new folder named 'profiles', containing displacement profiles across each fracture.
```

- Profile Parameters:
```  
bash ./src/Profiles_Analysis/run_all_profiles.sh
```
- Output:
``` 
For each fracture, the output folder contains a profile plot showing the selected left and right extrema, along with a corresponding parameter file.
```

- Profile Symmetry:
``` 
python ./src/Profiles_Analysis/symmetry_statistics.py
```
- Output:
``` 
profile_symmetry.txt
``` 

### Step 3. Coseismic Slip and Stress Modeling
The coseismic slip model was generated using Geodetic_Inversion_Package_with_Matlab, and the associated coseismic stress perturbations were calculated using Coulomb 3.4.

- Convert inverted slip model into the input format required by Coulomb 3.4:
``` 
matlab re_format_reviver.m 
matlab re_format_slip.m
```
- Output:
```
.inr files
```

### Step 4. Background Stress Inversion
The input files calculated from Coulomb 3.4 are located in: ./data/examples/Monte_Cristo_Range/model/

```
python main_QA.py 
or
python main_QA_parallel.py
```
- Output:
```
result_QA.csv/result_QA_parallel_mean.csv
last_result_QA_parallel.csv
best_result_QA_parallel.csv
trade-off curve
3d scatter plot
```
