# Excel data: MATLAB Dashboard

The dashboard opens with these files by default:

| Stage | File(s) | Format |
|-------|---------|--------|
| Stage 1: I-V check (G = 390.3 W/m², T = 39.4 °C) | `IV_02Oct_indoor_healthy_R01.xlsx` (unshaded) or `IV_02Oct_indoor_PS75_cell31_R01.xlsx` (75 % shading of cell 3-1) | FRA LSV export: col 6 = V, col 7 = I |
| Stage 2: reference EIS | `EIS_02Oct_indoor_healthy_OPX70_R01.xlsx` and `..._PARAMS.xlsx` | Nova raw export and circuit-fit export |
| Stage 2: test EIS | `EIS_02Oct_indoor_PS75_cell31_OPX70_R01.xlsx` and `..._PARAMS.xlsx` | Nova raw export and circuit-fit export |

You can choose any other file with the Browse buttons in the app.

Before running: `addpath(genpath('../Excel_data'))`
