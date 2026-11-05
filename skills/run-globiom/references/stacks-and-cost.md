# Base stack, cost, and cluster limits

## Use this stack

GLOBIOM can use the pre-built base stack:

```python
base_stack="GAMS52_5__R4_6"
```

**CRITICAL**: `base_stack="GAMS52_5__R4_6"` runs GAMS 52.5. It can only open restart checkpoints (such as `Model/t/a4_r1.g00`) that were created by GAMS 52.5. If the model's checkpoint was created with a newer release (e.g. GAMS 53.3), GAMS will exit with code 5 (`New Workfile`). In that case, do NOT use `base_stack`; follow [gams-image.md](gams-image.md) to use a Dockerfile matching the checkpoint version.

The stack copies the filtered model root to `/code` and runs the task command there. The command must `cd Model` before it calls `gams`.

`base_stack` is required when the task has no `docker_filename` and no `docker_image`.

The license file stays in the model root. The command uses `license=/code/<filename>` and `//extra_parameters=license=/code/<filename>`. Child `execute_abort` jobs do not inherit `license=`. They open the image `gamslice.txt` under `/opt/gams`. Do not use a base64 `gams_license` value.

`init.R` runs at image build for this stack. Keep it empty unless the user asks for R packages. Package installs make every image rebuild slower.

## Resource budget per scenario

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

Both `timeout` and `build_timeout` are required fields on `WKubeTask`. Omitting them causes Pydantic validation errors.

## Cluster capacity and batch sizing

The IIASA Accelerator cluster has approximately **500 GiB total allocatable worker RAM**.

- **Maximum concurrent tasks**: At 24 GiB RAM per scenario, the cluster can run roughly **20–21 tasks simultaneously** ($21 \times 24\text{ GiB} \approx 504\text{ GiB}$).
- **Queue timeout (`PREPARING_TIMEOUT`)**: Any scenario task beyond the 21st is queued in Kubernetes `Pending` state. The Accelerator enforces a scheduling timeout of **~2.5 hours** on pending tasks.
- **The Pitfall**: Because each GLOBIOM scenario solve typically runs for 2.5 to 3 hours, queued tasks in `Pending` will exceed the 2.5-hour limit and fail with:
  ```text
  GLOBIOM nsim X (Job #...) — ERROR (PREPARING_TIMEOUT)
  ```

### Batching rules:
1. **Never submit more than 20 tasks in a single job** if scenario solve times exceed 2 hours.
2. For large sets (e.g. 34 scenarios):
   - **Batch 1**: Dispatch scenarios 1–20 (e.g., `wkube.py`).
   - Monitor Batch 1 until complete.
   - **Batch 2**: Dispatch remaining scenarios 21–34 (e.g., `wkube_batch2.py`).
3. This guarantees all tasks get scheduled immediately without languishing in `Pending` and hitting `PREPARING_TIMEOUT`.
