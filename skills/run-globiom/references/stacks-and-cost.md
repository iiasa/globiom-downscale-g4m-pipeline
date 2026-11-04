# Base stack and cost

## Use this stack

GLOBIOM uses:

```python
base_stack="GAMS52_5__R4_6"
```

`Model/t/a4_r1.g00` was saved by GAMS 52.5. A restart file must be opened by that GAMS release. The stack copies the filtered model root to `/code` and runs the task command there. The command must `cd Model` before it calls `gams`.

`base_stack` is required when the task has no `docker_filename` and no `docker_image`.

If the platform reports that `GAMS52_5__R4_6` is not defined, stop. Do not substitute another stack name. Ask whether the user wants their own GAMS version, then follow [gams-image.md](gams-image.md).

The license file stays in the model root. The command uses `license=/code/<filename>` and `//extra_parameters=license=/code/<filename>`. Child `execute_abort` jobs do not inherit `license=`. They open the image `gamslice.txt` under `/opt/gams`. Do not use a base64 `gams_license` value.

`init.R` runs at image build for this stack. Keep it empty unless the user asks for R packages. Package installs make every image rebuild slower.

## Resource budget

Keep this budget for each scenario:

| Field                       | Value          | Unit    |
| --------------------------- | -------------- | ------- |
| `required_cores`            | `1`            | cores   |
| `required_ram`              | `24 * 1024**3` | bytes   |
| `required_storage_local`    | `12 * 1024**3` | bytes   |
| `required_storage_workflow` | `1 * 1024**3`  | bytes   |
| `timeout`                   | `12 * 60 * 60` | seconds |
| `build_timeout`             | `2 * 60 * 60`  | seconds |

Pass bytes and seconds. The integer `24` is not 24 GiB.

Each child task reserves this budget. Parallel children can run at the same time. Each running solve also uses one seat of the shared GAMS license. A long `nsim` list can fill the cluster and the license. State that cost before dispatch when the list has more than four scenarios.

A longer `last_year` can exceed 12 hours. Warn the user before you raise `timeout`.

Do not set `required_storage_local` high enough to copy `Data/` into the container. The exclude rule exists so the job does not carry that tree.
