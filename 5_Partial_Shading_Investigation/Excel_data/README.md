# Excel data: Partial Shading Investigation

Two shading campaigns:

* `outdoor_sunlight_07Oct/`: outdoor runs in sunlight with a resistive DC load (col 2 = V, col 3 = I). Used by `partial_shading_outside_07Oct.m`. `PV_outside_PS_7Oct.xlsx` is the original logbook with every run on a separate sheet.
* `indoor_lab_03Oct_08Oct/`: indoor runs under the halogen lamp, recorded as FRA linear-sweep (LSV) exports (col 6 = V, col 7 = I, col 8 = P). Used by `Panel_different_shading_3Oct.m`. The file names give the shaded cell(s) as COLxROWy; `75%` marks the 75 % shading runs and `TAKE2` marks repeat runs.

Files marked *(read by the script)* are the ones listed at the top of the script(s) in `../MATLAB_code/`. The files in `additional_measurements/` are extra runs from the same test campaign. They are kept for completeness, and you can add them to a script's file list to analyse them.

Before running, add this folder and its subfolders to the MATLAB path:

```matlab
addpath(genpath('../Excel_data'))
```

## Contents

**`indoor_lab_08Oct/`**

- `BAELINE_indoors_08Oct.xlsx`  *(read by the script)*
- `BASELINE_TAKE2_indoors_08Oct.xlsx`  *(read by the script)*
- `IV_PS_COL1ROW1_75%_indoors_08Oct.xlsx`  *(read by the script)*
- `IV_PS_COL2ROW1_75%_indoors_08Oct.xlsx`  *(read by the script)*
- `IV_PS_COL2ROW6_75%_indoors_08Oct.xlsx`  *(read by the script)*
- `IV_PS_COL3ROW1_75%_indoors_08Oct.xlsx`  *(read by the script)*

**`indoor_lab_08Oct/additional_measurements/`**

- `IV_BASELINE.xlsx`
- `IV_COL1_ROW11_COL3_ROW1.xlsx`
- `IV_COL1_ROW11_COL3_ROW1_TAKE2.xlsx`
- `IV_COL1_ROW1_COL2_ROW11.xlsx`
- `IV_COL1_ROW1_COL2_ROW11_TAKE2.xlsx`
- `IV_COL1_ROW2_COL3_ROW8.xlsx`
- `IV_COL1_ROW2_COL3_ROW8_TAKE2.xlsx`
- `IV_COL1_ROW2_ROW8.xlsx`
- `IV_COL1_ROW2_ROW8_TAKE2.xlsx`
- `IV_COL2_ROW1.xlsx`
- `IV_COL2_ROW1_COL3_ROW8.xlsx`
- `IV_COL2_ROW1_COL3_ROW8_TAKE2.xlsx`
- `IV_COL2_ROW1_ROW11_2substrings.xlsx`
- `IV_COL2_ROW1_ROW11_TAKE2_2substrings.xlsx`
- `IV_COL2_ROW1_TAKE2.xlsx`
- `IV_COL3_ROW1.xlsx`
- `IV_COL3_ROW11.xlsx`
- `IV_COL3_ROW11_TAKE2.xlsx`
- `IV_COL3_ROW1_TAKE2.xlsx`
- `IV_COL3_ROW2_ROW8.xlsx`
- `IV_COL3_ROW2_ROW8_TAKE2.xlsx`
- `IV_COL3_ROW5.xlsx`
- `IV_COL3_ROW5_TAKE2.xlsx`
- `IV_PS_COL1ROW1_indoors_08Oct.xlsx`
- `IV_PS_COL2ROW1_indoors_08Oct.xlsx`
- `IV_PS_COL2ROW6_indoors_08Oct.xlsx`
- `IV_PS_COL3ROW1._indoors_08Oct.xlsx`

**`outdoor_sunlight_07Oct/`**

- `IV_PS_col1row1_cardboard.xlsx`  *(read by the script)*
- `IV_PS_col1row1_paper.xlsx`  *(read by the script)*
- `IV_PS_col1row1_paper_50%.xlsx`  *(read by the script)*
- `IV_PS_col2row1_paper.xlsx`  *(read by the script)*
- `IV_PS_col3row1_paper.xlsx`  *(read by the script)*
- `baseline_12h00.xlsx`  *(read by the script)*

**`outdoor_sunlight_07Oct/additional_measurements/`**

- `PV_outside_PS_7Oct.xlsx`
- `baseline_16h00.xlsx`
