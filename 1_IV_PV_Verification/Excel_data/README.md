# Excel data: IV PV Verification

DC electronic-load I-V sweeps of the panel (col 1 = V, col 2 = I) used for the baseline I-V / P-V check against the nameplate.

Files marked *(read by the script)* are the ones listed at the top of the script(s) in `../MATLAB_code/`. The files in `additional_measurements/` are extra runs from the same test campaign. They are kept for completeness, and you can add them to a script's file list to analyse them.

Before running, add this folder and its subfolders to the MATLAB path:

```matlab
addpath(genpath('../Excel_data'))
```

## Contents

**``**

- `IV_panelcontrol_indoor150V.xlsx`  *(read by the script)*
- `IV_panelcontrol_indoor200V.xlsx`  *(read by the script)*
- `IV_panelcontrol_indoor200_fanOn.xlsx`  *(read by the script)*
- `IV_panelcontrol_indoor220_fanOn.xlsx`  *(read by the script)*

**`additional_measurements/`**

- `IV_09Sep_indoor_G317_T45.6.xlsx`
- `IV_09Sep_indoor_G340_T36.xlsx`
- `IV_09Sep_indoor_G644_T48.xlsx`
- `IV_09Sep_indoor_G716_T59.xlsx`
- `IV_09Sep_indoor_G811.8_T45.xlsx`
- `IV_09Sep_indoor_G835_T65.xlsx`
- `IV_panelcontrol_indoor220V.xlsx`
