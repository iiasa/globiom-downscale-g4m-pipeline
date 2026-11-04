# GLOBIOM downscaling merger

Standalone Accelerator routine. Reads one scenario directory of regional
results and writes the G4M land-cover CSV.

This `wkube` branch selects storage with `NSIM`. Set `nsim` in `merge.json`.
The `master` branch retains the SSP/RCP image contract.
Mount `/mnt/wdrv` in the task.

The task uses the predefined `R4_4` base stack.
The stack runs `init.R` at build time to install `readr`, then copies the merger files into `/code`.
The task does not build the local Dockerfile.

The merger requires all 59 `downscaled_<REGION>.rds` files in the input
directory. One missing file stops the merge. It does not write a partial CSV.
If the set is incomplete, it waits 10 seconds and reads again. It stops after
4 reads.

The G4M table is `downscaled_<REGION>.rds[[2]]`. The merger drops
`LC_TYPES_EPIC` and appends the regional tables. It skips `MaltaReg`.
Malta has no GLOBIOM forest cells on the G4M crosswalk. The `MaltaReg` file
must still be present.

## Paths

| Argument / env | Default local path |
| --- | --- |
| `ROOT_JOB_ID` | CSV label and shared run directory |
| `--input` | `${SCENARIO_ROOT}/downscaled/` |
| `--output` | `${SCENARIO_ROOT}/downscaled/merged/` |

Input files are immediate children:

```text
scenarios/<nsim>/downscaled/downscaled_AustraliaReg.rds
scenarios/<nsim>/downscaled/downscaled_RomaniaReg.rds
```

## Command

```text
SCENARIO_ROOT="/mnt/wdrv/globiom-results/${ROOT_JOB_ID}/scenarios/${NSIM}"
Rscript --vanilla /code/merge_downscaling.R \
  --input "${SCENARIO_ROOT}/downscaled/" \
  --output "${SCENARIO_ROOT}/downscaled/merged/"
```

Paste `routine-schema.json` into the configuration-schema field.

## Outputs

- `GLOBIOM2G4M_output_LC_abs_<ROOT_JOB_ID>.csv`

This routine does not create the other G4M CSVs. Residues, wood, prices, land
rent, and CO2 price still come from the GLOBIOM post-processor.
