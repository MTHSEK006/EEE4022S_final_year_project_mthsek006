# Development of a Basic Digital Twin for Photovoltaic Panel Performance Monitoring

**EEE4022S Final Year Project, University of Cape Town**
**Author:** Sekoati Pearl Mothiba (MTHSEK006), BSc (Eng) Mechatronics
**Supervisor:** Dr Paul Barendse

This repository contains the MATLAB code and the measured Excel data used in the project. The project builds a single-diode model (SDM) digital twin of an 80 W, 36-cell monocrystalline PV panel. The model is verified against indoor (halogen) and outdoor I-V measurements. It is then used, together with electrochemical impedance spectroscopy (EIS), to detect partial shading.

The folders are numbered in the same order as the Methodology chapter of the report. Each stage uses results from the stages before it.

---

## Repository structure

```
EEE4022S_final_year_project_mthsek006/
│
├── README.md                              <- this file
├── Environmental_Conditions/             <- G and T grid log for every test day
│
├── 1_IV_PV_Verification/
│   ├── MATLAB_code/   indoorOutdoorIVcurves.m
│   └── Excel_data/    DC-load I-V sweeps for the baseline check (+ additional_measurements/)
│
├── 2_Effective_Irradiance/
│   ├── MATLAB_code/   effective_irradiance_check.m
│   └── Excel_data/    indoor/ (halogen) and outdoor/ (sun) I-V sweeps
│
├── 3_SDM_Parameters_from_Nameplate/
│   ├── MATLAB_code/   SDMparametersfromdatasheet.m
│   └── Excel_data/    (none needed: the inputs are the nameplate values)
│
├── 4_Analytical_Parameter_Extraction/
│   ├── MATLAB_code/   temperatureVSvoltage.m
│   │                  calculateResistanceparameters.m
│   │                  validatetheSDM.m
│   └── Excel_data/    constant_G_varying_T/, constant_T_varying_G/, SDM_validation/
│
├── 5_Partial_Shading_Investigation/
│   ├── MATLAB_code/   partial_shading_outside_07Oct.m
│   │                  Panel_different_shading_3Oct.m
│   └── Excel_data/    outdoor_sunlight_07Oct/ (DC load), indoor_lab_03Oct_08Oct/ (FRA LSV)
│
├── 6_EIS_Investigation/
│   ├── MATLAB_code/   CompareEISconditions.m
│   └── Excel_data/    Nova EIS raw exports and fitted parameter (PARAMS) files
│
└── 7_MATLAB_Dashboard/
    ├── MATLAB_code/   PV_Diagnostic_Dashboard.m
    └── Excel_data/    I-V (LSV) and EIS files used by the dashboard demo
```

Every stage has the same two subfolders:

* **`MATLAB_code/`** holds the scripts for that stage.
* **`Excel_data/`** holds the measured data for that stage, sorted into subfolders by test type where needed. Each `Excel_data/` folder has its own README. It lists every file and marks the ones the scripts read. Extra runs from the same test campaign are kept in `additional_measurements/` subfolders.

---

## What each folder does

| # | Folder | Report section | Purpose | Main outputs |
|---|--------|----------------|---------|--------------|
| 1 | `1_IV_PV_Verification` | I-V and P-V curve verification | Checks the measured DC-load I-V and P-V curves against the nameplate (STC) values scaled to the test conditions. It extrapolates I<sub>sc</sub> from the flat part of the curve and prints an ATP pass/fail table. | I-V/P-V plots, I<sub>sc</sub>, V<sub>oc</sub>, P<sub>mp</sub> errors, pass/fail table |
| 2 | `2_Effective_Irradiance` | Effective irradiance | Finds the panel's current responsivity outdoors (sun) and indoors (halogen), K = I<sub>sc</sub>/G, by regression through the origin. It computes the halogen spectral correction factor and the effective indoor irradiance G<sub>eff</sub>. | K<sub>outdoor</sub>, K<sub>indoor</sub>, R², C<sub>halogen</sub>, G<sub>eff</sub> table, linearity plot |
| 3 | `3_SDM_Parameters_from_Nameplate` | SDM parameters from the nameplate | Identifies the five SDM parameters (I<sub>L</sub>, I<sub>0</sub>, n, R<sub>s</sub>, R<sub>sh</sub>) from datasheet values only, using a genetic algorithm with Lambert-W I-V solutions (method of Lo Brano et al.). | Nameplate-based SDM parameter set |
| 4 | `4_Analytical_Parameter_Extraction` | Analytical parameter extraction and SDM validation | Extracts the SDM parameters from measured curves (see the three scripts below), then validates the final model against measured I-V curves. | n, I<sub>0,STC</sub>, R<sub>s</sub>, R<sub>sh</sub>; measured vs expected vs SDM plots and error tables |
| 5 | `5_Partial_Shading_Investigation` | Partial shading investigation | Overlays the I-V and P-V curves for unshaded and partially shaded cases (different cells, shading levels and materials) to show the bypass-diode steps and power loss. | Overlay I-V/P-V figures, P<sub>mp</sub> and power-loss values |
| 6 | `6_EIS_Investigation` | EIS investigation | Compares two EIS runs (healthy vs shaded). It refits a Randles circuit with a CPE (R<sub>s</sub>, R<sub>ct</sub>, Q, α) to the capacitive arc and overlays the Nyquist plots. | Nyquist overlay, parameter table with percentage changes, f<sub>c</sub> |
| 7 | `7_MATLAB_Dashboard` | System integration / dashboard | A MATLAB app (uifigure) that joins the stages into a two-stage digital-twin check. Stage 1 compares a measured I-V curve with the SDM and flags an anomaly when any residual exceeds 5 %. Stage 2 compares EIS runs and reports partial shading when \|ΔR<sub>s</sub>\| < 5 % and ΔR<sub>ct</sub> ≤ −10 %. | Interactive dashboard with I-V, P-V and Nyquist plots and a verdict |

### Folder 4: the three scripts

Run them in this order:

1. **`temperatureVSvoltage.m`** uses curves at constant irradiance and varying temperature. It extracts the ideality factor **n** from dV<sub>oc</sub>/dT and the saturation current **I<sub>0</sub>** at each temperature. It then finds **I<sub>0,STC</sub>** by direct inversion and by an Arrhenius fit.
2. **`calculateResistanceparameters.m`** uses curves at constant temperature and varying irradiance. It finds **R<sub>s</sub>** with the temperature-compensated two-curve method and **R<sub>sh</sub>** from the slope of the low-voltage region.
3. **`validatetheSDM.m`** solves the SDM with Newton-Raphson using the extracted parameters. It compares three things on the same plot: the measured curve, the expected values from G<sub>eff</sub> scaling, and the SDM curve. It prints the I<sub>sc</sub>, V<sub>oc</sub> and P<sub>mp</sub> errors.

### Final SDM parameters (used in folders 4 and 7)

| Parameter | Value |
|-----------|-------|
| N<sub>s</sub> | 36 cells in series |
| n | 1.000 |
| I<sub>0,STC</sub> | 4.0491 × 10⁻¹¹ A |
| R<sub>s</sub> | 0.13043 Ω |
| R<sub>sh</sub> | 1721.41 Ω |
| K<sub>indoor</sub> | 0.002425 A/(W/m²) |
| K<sub>outdoor</sub> | I<sub>sc,STC</sub>/1000 = 0.00476 A/(W/m²) |

Nameplate (STC): V<sub>oc</sub> = 21.6 V, I<sub>sc</sub> = 4.76 A, V<sub>mp</sub> = 18.0 V, I<sub>mp</sub> = 4.44 A, P<sub>mp</sub> = 80 W.

---

## How to run a script

1. Clone or download the repository.
2. In MATLAB, go to the stage's `MATLAB_code/` folder and add its data folder, with all of its subfolders, to the path:
   ```matlab
   cd('5_Partial_Shading_Investigation/MATLAB_code')
   addpath(genpath('../Excel_data'))
   ```
   The scripts open the data files by name only, so the data folders must be on the MATLAB path.
3. To use new measurements, copy the Excel files into the stage's `Excel_data/` folder. The filenames must match those listed at the top of the script.
4. Open the script and check the **inputs section at the top**: the list of Excel filenames and the matching irradiance (W/m²) and temperature (°C) values for each file. Edit these to analyse other measurements.
5. Run the script (`F5`, or type its name in the Command Window). The results tables print in the Command Window and the figures open in separate windows.

**Dashboard (folder 7):** run `PV_Diagnostic_Dashboard` to open the app.
* **Stage 1:** choose the I-V file (or type its name), enter G and T, and press *Run Macro I-V & Check Residuals*.
* **Stage 2:** unlocks if an anomaly is found. Choose the reference and test EIS files (PARAMS and raw) and run the EIS comparison.

---

## Expected Excel data formats

| Data type | Used in | Columns read |
|-----------|---------|--------------|
| DC electronic-load I-V sweep | folders 1, 2, 4 | col 1 = Voltage (V), col 2 = Current (A) |
| Outdoor shading sweep (DC load) | `partial_shading_outside_07Oct.m` | col 2 = Voltage (V), col 3 = Current (A) |
| FRA linear sweep voltammetry (LSV) export | `Panel_different_shading_3Oct.m`, dashboard Stage 1 | col 6 = Voltage (V), col 7 = Current (A), col 8 = Power (W) |
| Nova EIS raw impedance export | folders 6, 7 | col 1 = Z' (Ω), col 3 = −Z'' (Ω), col 8 = ω (rad/s) |
| Nova fitted-parameter file (`*_PARAMS.xlsx`) | folders 6, 7 | cells G2:J2 = CPE.Y0 (Q), R<sub>p</sub> (R<sub>ct</sub>), R<sub>s</sub>, CPE.N (α) |

The first row of each sheet can be a header row; empty and NaN rows are skipped.

**File naming.** Data files follow `<type>_<date>_<indoor/outdoor>_<condition>.xlsx`, e.g. `IV_25Sep_indoor_G318_T31.xlsx` or `EIS_02Oct_indoor_PS75_cell31_OPX70_R01_PARAMS.xlsx`:
* `IV` = I-V sweep, `EIS` = impedance spectrum, `ENV` = environmental log;
* `G…`/`T…` = average irradiance (W/m²) and temperature (°C);
* `healthy` = unshaded, `PS75_cell31` = 75 % shading of cell 3-1, `COL1ROW1` = shaded cell position;
* `OPX70`, `OPF`, `OPB` = EIS DC operating point (see the folder 6 data README);
* `R01`, `TAKE2` = run / repeat number; `_PARAMS` = circuit-fit results exported from Nova.

**Environmental conditions.** `Environmental_Conditions/` holds the log of the irradiance and temperature grids, and the test set-up, for every test day. Its README shows which sheet belongs to which data folder.

---

## Requirements

* MATLAB R2021a or newer (uses `readmatrix`, `readtable`, `uifigure`, `xline`/`yline`).
* **Symbolic Math Toolbox**: needed by `SDMparametersfromdatasheet.m` (`lambertw`).
* **Signal Processing Toolbox**: needed by `PV_Diagnostic_Dashboard.m` (`sgolayfilt`).
* All other scripts use base MATLAB only. The EIS refit uses `fminsearch`, so no Optimization Toolbox is needed.

---

## Citation

If you use this code or data, please cite:

> S. P. Mothiba, *Development of a Basic Digital Twin for Photovoltaic Panel Performance Monitoring*, BSc (Eng) Final Year Project (EEE4022S), Department of Electrical Engineering, University of Cape Town, 2026.

The nameplate-based parameter identification in folder 3 follows the genetic-algorithm method of V. Lo Brano et al. for single-diode PV models.
