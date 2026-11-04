# GLOBIOM combined report

Accelerator routine that runs after every per-scenario G4M feedback conversion.
It pools the raw GLOBIOM GDX files and G4M country-feedback CSVs, then runs
Stage 8 with both IAMC reports enabled.

## Inputs

The platform supplies `ROOT_JOB_ID`. Pass the scenarios directory with
`--input`, the G4M feedback directory within each scenario with
`--g4m-results-path`, and the report directory with `--output`. For each
scenario, the routine reads:

```text
scenarios/<scenario>/output.gdx
scenarios/<scenario>/<g4m-results-path>/tabs_gui_<ROOT_JOB_ID>_final_csv.csv
```

It does not read `scenarios/<scenario>/merged/`. Those files already have a run
dimension.

`GAMS_LICENSE_FILE` is passed to `gams` as `license=`. Without it, GAMS
uses the expired license in its installation directory. `gdxmerge` has no
license argument and does not need one.

This `wkube` branch uses `BASELINE_NSIM` to select the forest-management reference.
Set `baseline_nsim` in `report.json` to a scenario selected by the parent pipeline.
The reporter reads all three baseline labels from that scenario's `output.gdx`.
It does not assume that the middle dimension is `SCEN`.
The `main` branch retains the SSP/RCP image contract.

## Outputs

Stage 8 writes an IAMC GDX. The routine copies it to the output root and dumps
its four reporting symbols to CSV:

```text
Output4_IAMC_template_<ROOT_JOB_ID>.gdx
Output4_SSP.csv
Output4_SSP_AG.csv
Output4_SSP_AG_2DIM.csv
REGION_AG_MAP.csv
8_merge_output.lst
```

The routine writes that directory to `--output`.
Set `g4m_results_path` in `report.json` for the Accelerator routine. This path
is relative to each scenario and must not contain `..`.

## Command

```sh
ROOT="/mnt/wdrv/globiom-results/${RUN_ID:-$ROOT_JOB_ID}"
export BASELINE_NSIM=8
export GAMS_LICENSE_FILE=/mnt/wdrv/gamslice.txt
G4M_RESULTS_PATH=g4m-results/g4m_outputs_merged
python3 /opt/globiom-combined-report/report.py \
  --input "$ROOT/scenarios" \
  --g4m-results-path "$G4M_RESULTS_PATH" \
  --output "$ROOT/merged"
```

## Model copy

`8c_rep_iamc_g4m_newIAMCSept24.gms` is a static copy. It takes the pooled CSV
path and baseline names as GAMS arguments and includes `g4m_scen_map.gms`.
The routine writes that map from each scenario GDX and its feedback label. It
does not edit `8c` at runtime.

`sets_g4m.gms` comes from Trunk-region59. The image starts from
`globiom-region59-g4m-collector:6424b86`, which already contains the rest of
Stage 8.
