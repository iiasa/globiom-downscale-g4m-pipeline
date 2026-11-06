---
name: run-globiom
description: >-
  Run a researcher's own GLOBIOM model on the IIASA Accelerator with wkube.py and accli.
  Use this skill when the user wants to install or log in to accli, write or edit wkube.py,
  dispatch GLOBIOM, run one or more nsim scenarios, change model code and run it,
  choose a base stack, GAMS version, or GAMS license, write a Dockerfile, set include or exclude lists,
  or map job results to the project space.
---

# Run GLOBIOM

Help the user run their GLOBIOM tree on the Accelerator. The job runs the files in that tree. Help the user edit those files when they ask. Then dispatch the edited tree.

Read these files before you write `wkube.py`:

- [references/include-exclude.md](references/include-exclude.md)
- [references/stacks-and-cost.md](references/stacks-and-cost.md)
- [references/gams-image.md](references/gams-image.md)
- [references/wkube-template.py](references/wkube-template.py)
- [references/monitor.md](references/monitor.md)

Fetch and read https://accelerator.iiasa.ac.at/docs/routine-jobflow before you write a jobflow. Use that page for the holder task, `add_child`, `add_callback`, and dispatch. The examples on that page use `PYTHON3_7`. Do not copy that stack. The GLOBIOM stack and filter rules in this skill override those examples.

Fetch and read https://accelerator.iiasa.ac.at/docs/routine-data-mappings before you set `input_mappings` or `output_mappings`. If that page does not answer the mapping question, fetch https://accelerator.iiasa.ac.at/docs/routine-introduction.

## 1. Find the model root

The model root is the directory that contains both `Model/6_scenarios.gms` and `Model/t/a4_r1.g00`.

Do not infer the root from a directory name or a Git branch. Do not search the home directory.

1. If the current directory is the model root, use it.
2. If the user gives a path, check that path.
3. If more than one root is plausible, ask which root to use.
4. If you cannot find the root, ask for the path. Stop.

Write `wkube.py` in that model root. `accli dispatch` reads `./wkube.py` from the directory where you run it. Do not pass `-f`. Do not put `wkube.py` in a parent directory.

If `wkube.py` already exists in the model root, edit that file. Do not create a second workflow file.

## 2. Prepare the environment

1. Check that `accli` is on `PATH`.
2. If `accli` is missing, install it with the official command for that operating system. Linux and macOS:

```bash
curl -fsSL https://raw.githubusercontent.com/iiasa/accli/master/scripts/install.sh | bash
```

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/iiasa/accli/master/scripts/install.ps1 | iex
```

3. A token file at `~/.accli/data.json` means the user has logged in. If the file is missing, ask the user to run `accli login`. The user must open `https://accelerator.iiasa.ac.at/acli-auth-code` and enter the code. Do not complete login for the user. Do not print the token.
4. Ask for the Accelerator project slug if the user did not give one. The slug is the path segment after `/projects/` on `https://accelerator.iiasa.ac.at`. Do not guess the slug. The default GLOBIOM slug is `globiom-scenario`.

### Windows & SVN Permissions Check
On Windows SVN working copies, pristine files or local files may carry read-only attributes, causing `PermissionError: [WinError 5] Access is denied` during file packaging. Run this in PowerShell before dispatch:

```powershell
Get-ChildItem -Path . -Recurse -Force | Where-Object { $_.IsReadOnly } | ForEach-Object { $_.IsReadOnly = $false }
```

### Prevent UTF-8 BOM
Ensure any created or edited script (`init.R`, `*.gms`, `*.sh`) is saved without a UTF-8 Byte Order Mark (`utf8NoBOM`). A BOM will cause Linux bash/Rscript to crash with `unexpected input in '\ufeff'`.

## 3. Verify Checkpoint Version Compatibility

GAMS restart workfiles (`.g00`) can only be opened by the same major/minor GAMS version that created them. Loading a newer checkpoint in an older GAMS version causes `*** Gams Exit Msg = New Workfile (Exit code 5)`.

Inspect the first bytes of `Model/t/a4_r1.g00`:
- `WEX533-533` -> GAMS 53.3
- `LEX525-525` -> GAMS 52.5

In PowerShell:
```powershell
(Get-Content -Path "Model/t/a4_r1.g00" -Encoding Byte -TotalCount 100 | ForEach-Object { [char]$_ }) -join ""
```

- If `52.5`: You may use the built-in stack `base_stack="GAMS52_5__R4_6"`.
- If `53.3` (or other non-52.5 version): You **MUST** use a custom `Dockerfile` targeting that exact GAMS version (see [references/gams-image.md](references/gams-image.md)).

## 4. Scenarios

Use the `nsim` values the user names. Do not add a scenario they did not name.

You may read the active `SCEN_MAP` in `Model/6_scenarios.gms` to suggest an integer. Ignore a commented map. If `lookup` is not 0, read the included map file instead. Show the suggestion. Wait for the user to confirm it.

The Accelerator cluster has approximately **750 GiB worker RAM**. Each scenario requests 24 GiB RAM, so about **31 tasks** run at once and the rest wait in `Pending`. Do not split scenarios into separate batch files. Set a long `build_timeout` (1 day or more) when dispatching so queued tasks are not killed with `PREPARING_TIMEOUT` while they wait for capacity. Dispatch the full confirmed `nsim` list in a single `wkube.py`.

## 5. Edit the model first

The uploaded tree is the model that runs. Edit `Model/*.gms`, `cplex.opt`, `Data_Scen/`, and `include/` when the user asks.

After an edit, compare the changed paths with the include and exclude rules. If a changed file is excluded, say so. Do not dispatch until the user moves that edit or adds a narrow `include`. Do not remove `Data/*` to make an edit visible.

`wkube.py` is not model code. The dispatcher removes it from the upload. An edit to `wkube.py` changes the job definition only.

## 6. Choose GAMS and the license

- **Base stack**: Use `base_stack="GAMS52_5__R4_6"` ONLY if the checkpoint is GAMS 52.5. Read [references/stacks-and-cost.md](references/stacks-and-cost.md).
- **Custom version**: Set `docker_filename="Dockerfile"`, remove `base_stack`, and write `Dockerfile` matching the checkpoint version. Read [references/gams-image.md](references/gams-image.md).

Keep the license file in the model root. That directory is `job_folder`. The container then has the file at `/code/<filename>`. Point every `gams` command at that path with `license=/code/<filename>` and `//extra_parameters=license=/code/<filename>`. Child `execute_abort` jobs do not inherit `license=`. They open the image `gamslice.txt` under `/opt/gams`. Do not exclude the license file. Do not print it.

If the license file is not in the model root, ask the user to put it there. Stop until the file is there.

## 7. Choose the GAMS entry

Ask which program the command should run. Look for `Model/0_executebatch.gms`, `Model/6_scenarios.gms`, or `Model/7_output.gms`.

When running `6_scenarios.gms`:
- Specify restart checkpoint: `r=t/a4_r1`.
- Ensure output is copied to a uniquely named GDX file so results are not overwritten:
  ```bash
  cp -a gdx/output.gdx "/code/results/${NSIM}/${NSIM}.gdx" || true
  cp -a gdx/. "/code/results/${NSIM}/" || true
  ```

## 8. Map and Retrieve Results

### Output Mappings in `wkube.py`
Write job outputs under `/code/results/<nsim>/` and map that directory to the project space:

```python
"output_mappings": f"/code/results/{nsim}/:acc://globiom-scenario/globiom-results/RUN_LABEL/{nsim}/"
```

### Storage Layout and `accli copy`
When WKube uploads mapped outputs to S3/MinIO, it automatically prefixes the path with:
`acc://<PROJECT_SLUG>/job-outputs/<ROOT_JOB_ID>/<PROJECT_SLUG>/...`

To copy scenario results back to your local machine, query the root job ID (e.g. `15966`) and run:

```powershell
accli copy acc://PROJECT_SLUG/job-outputs/<ROOT_JOB_ID>/PROJECT_SLUG/globiom-results/RUN_LABEL/ ./results/
```

*Note*: Attempting to copy directly from `acc://PROJECT_SLUG/globiom-results/...` without the `job-outputs/<ROOT_JOB_ID>/PROJECT_SLUG/` prefix will return `No files found matching the remote prefix`.

## 9. Write wkube.py

Start from [references/wkube-template.py](references/wkube-template.py).

- Put the file in the model root.
- Set `job_folder` to the directory that contains `wkube.py`.
- Keep the include and exclude strings from the template.
- Create one child task for each confirmed `nsim`. Pass that integer as `NSIM`.
- **CRITICAL**: The root holder task **must have a name**, e.g.:
  ```python
  globiom = WKubeTask(name="GLOBIOM Run")
  ```
  Calling `WKubeTask()` without a `name` will fail Pydantic validation (`ValidationError: name`).
- Specify required resource and timeout arguments on every child task (`timeout=12 * 60 * 60`, `build_timeout=24 * 60 * 60`). Use a `build_timeout` of 1 day or more for expensive jobs.
- The root variable must be named `globiom`.

Do not import `wkube.py` to test it. The import uploads the tree.

## 10. Confirm, then dispatch

Show the user this summary before dispatch:

- model root
- GAMS choice: base stack or Dockerfile version
- license file name under `/code/`
- GAMS entry file (with restart file `r=t/a4_r1` if applicable)
- `nsim` list
- result path in the project space
- files they edited, and whether each file is uploaded
- project slug
- resource requests per scenario (1 core, 24 GiB RAM, 12 GiB local storage)

Wait for user confirmation.

## 11. First run & Monitoring

If this `wkube.py` has not yet produced a successful run, test with one scenario first and follow [references/monitor.md](references/monitor.md):
1. Run `accli job PROJECT_SLUG ROOT_JOB_ID` to inspect child tasks.
2. Run `accli logs PROJECT_SLUG CHILD_JOB_ID --follow` to watch live solver output.
3. If the child fails before starting, check holder events with `--source celery` and `--source podevents`.

Once verified, dispatch the full confirmed scenario list.

## 12. Merge Scenario Results

Once all scenarios complete and results are downloaded locally, merge the individual scenario GDX files into a unified dataset:

```powershell
# Using GAMS gdxmerge
gdxmerge *.gdx id=OUTPUT,OUTPUT_AG output=merged_results.gdx
```

Verify the merged dataset:
```powershell
gdxdump merged_results.gdx symbols
```

## 13. Troubleshooting & Common Errors

| Error | Root Cause | Solution |
| --- | --- | --- |
| `ValidationError: name` | Root `globiom = WKubeTask()` missing `name` | Set `globiom = WKubeTask(name="GLOBIOM Run")` |
| `PermissionError: [WinError 5]` | Windows SVN pristine files marked `ReadOnly` | Run PowerShell command to set `IsReadOnly = $false` on all files |
| `unexpected input in '\ufeff'` | File saved with UTF-8 BOM on Windows | Save `init.R`, `*.gms`, `*.sh` as UTF-8 without BOM (`utf8NoBOM`) |
| `Gams Exit Msg = New Workfile (Exit code 5)` | Checkpoint was created by a different GAMS version than the container | Check `a4_r1.g00` header and use matching Dockerfile (e.g. 53.3) |
| `gams: not found` (Exit 127) | PATH missing or non-root user lacks execute permission | Symlink `/usr/local/bin/gams`, add `chmod -R 755 /opt/gams` in Dockerfile |
| `curl: not found` during build | Minimal base image lacks curl/ca-certificates | Add `apt-get install -y curl ca-certificates` to Dockerfile |
| `PREPARING_TIMEOUT` | Cluster RAM full; pending pods wait for capacity | Set a long `build_timeout` (1 day or more); do not batch |
| `No files found matching remote prefix` | WKube prefixes output paths with `job-outputs/<id>/<slug>/` | Add `job-outputs/<job_id>/<slug>/` to `accli copy` remote path |
| `No root task variable found with name 'wkube.py:globiom'` | Passed filename to `accli dispatch` task parameter | Use `accli dispatch <slug> globiom [-f <file>.py]` |
