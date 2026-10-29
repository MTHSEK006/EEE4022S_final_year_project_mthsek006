# Environmental conditions

This folder holds two environmental logs. Together they give the panel temperature and irradiance for every I-V test day.

## 1. Main test log

`ENV_Aug-Oct2026_lab_and_outdoor_test_conditions.xlsx` is the environmental log for the I-V test days in folders 2, 4 and 5. For each test day there is one sheet with:

* a 3 × 3 grid of panel temperature (°C) and irradiance (W/m²) readings (top / middle / bottom × left / centre / right), with the average, minimum, maximum, range and standard deviation;
* the test conditions: indoor (halogen lamp, variac voltage, lamp distance, fan on/off) or outdoor, and the purpose of the test.

The G and T values entered at the top of each MATLAB script are the grid averages from this log.

| Sheet | Tests | Used in |
|-------|-------|---------|
| Lab Test Data Grids, Sheet1, Master Raw Data Log | August trial runs (TEST1–TEST4 halogen runs) | `2_Effective_Irradiance` |
| Env 01 Sep 2026 | Constant T, varying G (indoor) | `2_Effective_Irradiance`, `4_.../constant_T_varying_G` |
| Env 02 Sep 26, Env 07 Sep 2026 | Outdoor sunlight I-V runs | `2_Effective_Irradiance/outdoor` |
| Env 17 Sep 2026, Env 18 Sep 2026 | Constant G (~340 W/m²), varying T | `2_Effective_Irradiance`, `4_.../constant_G_varying_T` |
| Env 22 Sep, Env 23 Sep, Env 25Sep 2026 | SDM validation runs (varying G and T) | `4_.../SDM_validation` and `additional_measurements` |
| Env 28 Sep, Env 30 Sep (×2), Env 1 October, Env 2Oct | Indoor partial-shading runs (single cells, multiple cells, two substrings) | `5_.../indoor_lab_03Oct_08Oct/additional_measurements` |
| Env 05Oct, Env 06Oct, Env 07Oct | Partial-shading runs on the second ("panel sunlight") panel: 05 and 07 Oct outdoors, 06 Oct indoors | `5_.../outdoor_sunlight_07Oct` |
| Env 08Oct, Env 09Oct | Indoor shading with paper (100 %, 75 % and 50 %) | `5_.../indoor_lab_03Oct_08Oct` |

## 2. DC-load baseline log

`ENV_07-09Sep_DCload_indoor_outdoor_conditions.xlsx` is the environmental log for the I-V curves recorded with the DC electronic load, indoors (halogen) and outdoors (sun). Each entry gives the date, the time, the 3 × 3 temperature and irradiance grids with their averages, and the test set-up.

| Sheet | Tests | Used in |
|-------|-------|---------|
| PV indoor-panel control | 09 Sep, indoor halogen runs on the control panel at variac voltages of 150, 200 and 220 V, first with the fan off and then with the fan on (`IV_panelcontrol_indoor150V/200V/220V` and `..._fanOn` files) | `1_IV_PV_Verification`, `2_Effective_Irradiance/indoor` |
| PV indoor-panel control (2) | Copy of the sheet above | |
| PV Lab Data-panel control | 07 and 08 Sep, outdoor runs on the control panel (`IV_panelcontrol_outdoor1–3`) | `2_Effective_Irradiance/outdoor` |
| PV lab data-panel sunlight | 08 Sep, outdoor runs on the second ("panel sunlight") panel | Reference only |
