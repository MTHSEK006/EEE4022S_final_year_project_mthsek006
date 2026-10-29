# Excel data: Effective Irradiance

DC-load I-V sweeps (col 1 = V, col 2 = I). `outdoor/` holds the sunlight runs used for K_outdoor; `indoor/` holds the halogen runs used for K_indoor and G_eff.

Files marked *(read by the script)* are the ones listed at the top of the script(s) in `../MATLAB_code/`. The files in `additional_measurements/` are extra runs from the same test campaign. They are kept for completeness, and you can add them to a script's file list to analyse them.

Before running, add this folder and its subfolders to the MATLAB path:

```matlab
addpath(genpath('../Excel_data'))
```

## Contents

**`indoor/`**

- `IV_indoor_01Sep_G167_constT.xlsx`  *(read by the script)*
- `IV_indoor_01Sep_G308_constT.xlsx`  *(read by the script)*
- `IV_indoor_01Sep_G445_constT.xlsx`  *(read by the script)*
- `IV_indoor_18Sep_G340_T30.xlsx`  *(read by the script)*
- `IV_panelcontrol_indoor150_fanOn.xlsx`  *(read by the script)*
- `IV_panelcontrol_indoor200_fanOn.xlsx`  *(read by the script)*
- `IV_panelcontrol_indoor220_fanOn.xlsx`  *(read by the script)*
- `TEST3_G530_IV.xlsx`  *(read by the script)*
- `TEST4_G873_IV.xlsx`  *(read by the script)*
- `TEST7_T39_IV.xlsx`  *(read by the script)*
- `iv_indoor_17Sep_G340_T32.xlsx`  *(read by the script)*
- `iv_indoor_17Sep_G340_T38.xlsx`  *(read by the script)*
- `iv_indoor_18Sep_G340_T42.xlsx`  *(read by the script)*
- `test1_low_iraidance_IV.xlsx`  *(read by the script)*
- `test2_G400_IV.xlsx`  *(read by the script)*

**`outdoor/`**

- `IV_outdoor_02Sep_G184.xlsx`  *(read by the script)*
- `IV_outdoor_02Sep_G218.xlsx`  *(read by the script)*
- `IV_outdoor_07Sep_G592.xlsx`  *(read by the script)*
- `IV_outdoor_07Sep_G629.xlsx`  *(read by the script)*
- `IV_outdoor_07Sep_G651.xlsx`  *(read by the script)*
- `IV_panelcontrol_outdoor1.xlsx`  *(read by the script)*
- `IV_panelcontrol_outdoor2.xlsx`  *(read by the script)*
- `IV_panelcontrol_outdoor3.xlsx`  *(read by the script)*
