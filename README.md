# GLOBIOM downscale G4M pipeline

This `wkube` branch dispatches local Model scenarios by `nsim`.
The Model's `SCEN_MAP` is the scenario authority. `scenarios.py` is a reference only.
The `master` branch preserves the SSP/RCP jobflow configuration.
Each routine retains its SSP/RCP image contract on `master`, or `main` where applicable.

## Repositories

The routine directories are independent Git repositories, not submodules.
The parent repository ignores those directories. A clone of the parent does not include the routines.
Keep all seven routines inside this folder:

```text
globiom-downscale-g4m-pipeline/
  wkube.py
  scenarios.json
  globiom-region59/
  downscaler/
  downscale-merger/
  g4m/
  g4m-input-merger/
  globiom-g4m-reporter/
```

Check out `wkube` in each routine before you dispatch the parent.
The parent refuses to load a routine on another branch.
Commit changes separately in each repository.

## Configuration

Set `scenarios.json`:

```json
{
  "run_id": "my-run",
  "scenarios": [
    {"nsim": 0},
    {"nsim": 8, "co2_price": -1}
  ]
}
```

Use scenario numbers from your personal `globiom-region59/Model/6_scenarios.gms` map.
Each scenario number must occur once. `co2_price` defaults to zero and controls G4M.
Set `baseline_nsim` in `globiom-g4m-reporter/report.json` to one of the selected scenarios.
There is no restart-file configuration. Each solve starts from `Model/t/a4_r1`.
Keep that restart consistent with your Model files.

The platform supplies `ROOT_JOB_ID`, which labels G4M and report files.
`run_id` selects the shared storage directory. Use a new run directory for each dispatch to avoid stale results.
Standalone routines use `ROOT_JOB_ID` as the storage directory unless `RUN_ID` is set.
Mount `/mnt/wdrv` in every task, with a valid `/mnt/wdrv/gamslice.txt` license.

## Execution

1. GLOBIOM runs its configured stages and stage 8 on `GAMS52_5__R4_6`, then publishes the GDX and five G4M CSVs per `nsim`.
2. Downscale runs 59 regional image tasks. Each reads the tuple for `nsim` from the GDX `SCEN_MAP`.
3. The downscale merger uses `R4_4` and writes the land-cover CSV. Its `init.R` installs `readr` at build time.
4. G4M derives its label from the complete tuple in GLOBIOM's stage 8 and downscaled CSVs.
5. The feedback merger reads the scenario label from G4M's country table.
6. The reporter pools all scenario results and reads the baseline tuple from the selected baseline GDX.

The downscale merger uses the predefined R stack. G4M uses the predefined Wine stack. The other downstream tasks build their Dockerfiles from the `wkube` source trees.
They do not use the published SSP/RCP images as unchanged runtime contracts.
No scenario labels are guessed from `nsim`, folder names, or underscore-separated G4M labels.

```text
/mnt/wdrv/globiom-results/<run_id>/
  scenarios/<nsim>/
    a6_r1.g00
    a6_r1.gdx
    output.gdx
    downscaled/downscaled_<REGION>.rds
    downscaled/merged/GLOBIOM2G4M_output_LC_abs_<ROOT_JOB_ID>.csv
    g4m/GLOBIOM2G4M_output_*_<ROOT_JOB_ID>.csv
    g4m-results/
    g4m-results/g4m_outputs_merged/tabs_gui_<ROOT_JOB_ID>_final_csv.csv
  merged/
```
