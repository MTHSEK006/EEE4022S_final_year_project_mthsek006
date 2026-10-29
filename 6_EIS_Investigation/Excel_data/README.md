# Excel data: EIS Investigation

Each EIS run has two files:

* `EIS_<...>.xlsx`: the Nova FRA potentiostatic impedance export (col 1 = Z' (Ω), col 3 = −Z'' (Ω), col 8 = ω (rad/s)).
* `EIS_<...>_PARAMS.xlsx`: the matching circuit-fit export (cells G2:J2 = CPE.Y0 (Q), Rp (Rct), Rs, CPE.N (α)).

**Naming:** `EIS_<date>_indoor_<condition>_<operating point>_<run>[_PARAMS].xlsx`.

* The condition is `healthy` (unshaded) or `PS<shading %>_cell<cell>`, for example `PS75_cell31` for 75 % shading of cell 3-1.
* The operating point is the DC bias during the sweep: `OPF` = fixed 20 V, `OPB` = 0.9·Voc, `OPX70` = Vmp + 0.70·(Voc − Vmp).

## Comparisons run with `CompareEISconditions.m`

Set these values in the inputs section at the top of the script. Run 1 is the reference and Run 2 is the comparison.

| Comparison | Run 1 (params / raw) | Run 2 (params / raw) | G (W/m²) | T (°C) |
|------------|----------------------|----------------------|----------|--------|
| Healthy vs 75 % shading (02 Oct) | `EIS_02Oct_indoor_healthy_OPX70_R01` | `EIS_02Oct_indoor_PS75_cell31_OPX70_R01` | 390.3 | 39.4 |
| Operating point OPF vs OPB, healthy (10 Sep) | `EIS_10Sep_indoor_healthy_OPF_R02` | `EIS_10Sep_indoor_healthy_OPB_R02` | 633.30 | 43.41 |
| Healthy vs 50 % shading (22 Sep, default) | `EIS_22Sep_indoor_healthy_OPX70_R01` | `EIS_22Sep_indoor_PS50_cell52_OPX70_R01` | 296.22 | 43.17 |

For each run, `file_params_*` is the `..._PARAMS.xlsx` file and `file_raw_*` is the file without `_PARAMS`.

Before running: `addpath(genpath('../Excel_data'))`
