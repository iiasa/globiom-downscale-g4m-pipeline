# G4M results merger

Accelerator routine that converts one scenario's G4M country table to the CSV
used as GLOBIOM feedback. It runs after G4M. No GLOBIOM GDX files are needed.

## Input and output

For `ROOT_JOB_ID=chubi-pipeline-test-g4m--3`, `NSIM=8`, and
`CARBON_PRICE=0`:

```text
scenarios/8/g4m/
  GLOBIOM2G4M_output_<variable>_chubi-pipeline-test-g4m--3.csv
scenarios/8/downscaled/merged/
  GLOBIOM2G4M_output_LC_abs_chubi-pipeline-test-g4m--3.csv
scenarios/8/g4m-results/
  tabs_gui_chubi-pipeline-test-g4m--3_SSP2_scenRCPref_SCEN_Pco2_0.gdc
  tabs_gui_chubi-pipeline-test-g4m--3_SSP2_scenRCPref_SCEN_Pco2_0.gdt
  g4m_outputs_merged/
    tabs_gui_chubi-pipeline-test-g4m--3_final_csv.csv
```

`<variable>` is `SupplyResidues`, `SupplyWood`, `Wood_price`, `LandRent`, or `CO2price`.

For a nonzero carbon price (including `-1`, which reads prices from input),
G4M omits `_Pco2_0` from the input filenames.
The converter reads the G4M binary table and its textual dimensions. The CSV
has country, scenario, parameter, and year columns. As in the legacy notebook,
rows containing `NaN` are removed. Each run replaces the output file.

## Accelerator

This `wkube` branch reads `SCEN1`, `SCEN2`, and `SCEN3` from the six G4M input tables beside `g4m-results`.
The label order is `SCEN1_SCEN3_SCEN2`, the same order as `run_g4m.sh`.
The merger then opens these files in `g4m-results`:

```text
tabs_gui_<ROOT_JOB_ID>_<SCEN1>_<SCEN3>_<SCEN2>.gdc
tabs_gui_<ROOT_JOB_ID>_<SCEN1>_<SCEN3>_<SCEN2>.gdt
```

A carbon price of zero adds `_Pco2_0` before the extension.
The country-table scenario must match that label.
The `main` branch retains the SSP/RCP image contract.

Set `nsim` and `carbon_price` in `merge.json` before you dispatch
`wkube.py`. The platform supplies `ROOT_JOB_ID`. The routine reads the
collector CSVs, the land-cover CSV, and `g4m-results/`. It writes
`g4m_outputs_merged/`. For a manual routine, use the `routine-schema.json`
settings and this command:

```text
SCENARIO_ROOT="/mnt/wdrv/globiom-results/${ROOT_JOB_ID}/scenarios/${NSIM}"
python3 /opt/globiom-g4m-results-merge/merge_g4m.py \
  --input-root "${SCENARIO_ROOT}/g4m-results" \
  --output-root "${SCENARIO_ROOT}/g4m-results/g4m_outputs_merged"
```

The image compiles G4M's table reader at build time. The files under
`vendor/g4m_GUI_elements/` come from the `G4M_global` submodule at commit
`fdb9865e946ba64cfa1bf39ca8835cb87a93f4cb`. The only source edit is the
case of the `IntToStr.h` include for Linux. `convert_country.cpp` invokes the
reader for one country table; `merge_g4m.py` checks the binary/labels and
publishes the cleaned CSV.

## Local check

Build the converter with `g++ -std=c++17 -Dunix -O2 convert_country.cpp -o
convert-country`, then run:

```sh
python3 merge_g4m.py \
  --root-job-id chubi-pipeline-test-g4m--3 \
  --carbon-price 0 \
  --input-root /mnt/wdrv/globiom-results/chubi-pipeline-test-g4m--3/scenarios/8/g4m-results \
  --output-root /tmp/opencode/g4m_outputs_merged
```
