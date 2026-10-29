# Excel data: Analytical Parameter Extraction

DC-load I-V sweeps (col 1 = V, col 2 = I), sorted by test type:

* `constant_G_varying_T/`: G held at about 340 W/m² while T changes. Used by `temperatureVSvoltage.m` for n and I0.
* `constant_T_varying_G/`: T held constant while G changes. Used by `calculateResistanceparameters.m` for Rs and Rsh.
* `SDM_validation/`: the runs used by `validatetheSDM.m`. `results/` holds the exported validation results table.

Files marked *(read by the script)* are the ones listed at the top of the script(s) in `../MATLAB_code/`. The files in `additional_measurements/` are extra runs from the same test campaign. They are kept for completeness, and you can add them to a script's file list to analyse them.

Before running, add this folder and its subfolders to the MATLAB path:

```matlab
addpath(genpath('../Excel_data'))
```

