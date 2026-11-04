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

## Find the model root

The model root is the directory that contains both `Model/6_scenarios.gms` and `Model/t/a4_r1.g00`.

Do not infer the root from a directory name or a Git branch. Do not search the home directory.

1. If the current directory is the model root, use it.
2. If the user gives a path, check that path.
3. If more than one root is plausible, ask which root to use.
4. If you cannot find the root, ask for the path. Stop.

Write `wkube.py` in that model root. `accli dispatch` reads `./wkube.py` from the directory where you run it. Do not pass `-f`. Do not put `wkube.py` in a parent directory.

If `wkube.py` already exists in the model root, edit that file. Do not create a second workflow file.

## Prepare the environment

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

The base stack runs `/code/init.R` during the image build. If the user keeps the base stack and the model root has no `init.R`, create a file that contains only a comment. Do not replace an existing `init.R`. Do not add R packages unless the user asks for those packages. A custom Dockerfile does not use `init.R`.

## Scenarios

Use the `nsim` values the user names. Do not add a scenario they did not name.

Ask only to clarify:

- The user names no `nsim`.
- The user names a scenario, but not an integer.
- Two statements disagree.

You may read the active `SCEN_MAP` in `Model/6_scenarios.gms` to suggest an integer. Ignore a commented map. If `lookup` is not 0, read the included map file instead. Show the suggestion. Wait for the user to confirm it.

Do not start from a stock scenario list. The user's `SCEN_MAP` is the list that matters.

## Edit the model first

The uploaded tree is the model that runs. Edit `Model/*.gms`, `cplex.opt`, `Data_Scen/`, and `include/` when the user asks.

After an edit, compare the changed paths with the include and exclude rules. If a changed file is excluded, say so. Do not dispatch until the user moves that edit or adds a narrow `include`. Do not remove `Data/*` to make an edit visible.

`wkube.py` is not model code. The dispatcher removes it from the upload. An edit to `wkube.py` changes the job definition only.

## Choose GAMS and the license

Ask whether the user wants the base stack or their own GAMS version.

- Base stack: use `base_stack="GAMS52_5__R4_6"`. Do not substitute another stack. Read [references/stacks-and-cost.md](references/stacks-and-cost.md).
- Own version: do not set `base_stack`. Set `docker_filename="Dockerfile"`. Guide the user through the image in [references/gams-image.md](references/gams-image.md). Use the GAMS version they name.

In both cases, keep their license file in the model root. That directory is `job_folder`. The container then has the file at `/code/<filename>`. Point the parent `gams` command at that path with `license=/code/<filename>`. Also pass `//extra_parameters=license=/code/<filename>`. `execute_abort` children do not inherit `license=`. They open `/opt/gams/gams52.5_linux_x64_64_sfx/gamslice.txt`, the image license. The job user cannot replace that file. `%env%` in `include/environment.gms` appends `extra_parameters`, so the child command gets the user license. Do not exclude the license file. Do not print it. Do not point the command at `/mnt/wdrv/gamslice.txt` unless that is the file they named and it is also copied into the model root.

If the license file is not in the model root, ask the user to put it there. Stop until the file is there.

## Choose the GAMS entry

Ask which program the command should run. Do not pick for them.

Look for `Model/0_executebatch.gms` and `Model/0_execute_batch.gms`. If either file exists, offer it. Also offer:

- only step 6, `Model/6_scenarios.gms`
- only step 7, `Model/7_output.gms`

Use the file they choose. If they choose step 7 alone, ask which restart file to open. Include that restart file. Do not also run step 6, step 8, or a batch file unless they ask for that sequence.

## Map the results

Do not invent an output directory. Read `Model/` before you set `output_mappings`.

1. Open the entry file the user chose.
2. Follow every uncommented `execute` or `execute_abort` into the stage file it runs. Also open the includes that write files, such as `7_output.gms` and `8_merge_output.gms` when that stage runs.
3. Record each path the stage writes. Look for `-s`, `gdx=`, `outpath`, `output_name`, `put`, and `EXECUTE_UNLOAD`.
4. The command runs from `Model/`. A relative path in those files is `/code/Model/<path>` in the container.
5. Map each written directory to `/mnt/wdrv/globiom-results/RUN_LABEL/<nsim>/` and keep the same relative directory. Both sides of a folder mapping end with `/`. Separate mappings with `;`.
6. Do not copy outputs into `/code/results` and map that copy. Do not use `acc://` in `output_mappings`. An `acc://` mapping only stores the job-output location. The user browses `/mnt/wdrv`.
7. In the summary before dispatch, list each path you found and the mapping for it. If you cannot name a written path, say so. Do not guess a folder.

The left side below is an example shape. Replace it with a path you read from `Model/`. Do not keep it if the model does not write that path.

```python
"output_mappings": "/code/Model/gdx/:/mnt/wdrv/globiom-results/RUN_LABEL/8/gdx/"
```

Replace the run label and `nsim` with the confirmed values. Use a literal path. Do not expect `${ROOT_JOB_ID}` to expand inside `output_mappings`.

Before dispatch, tell the user where to open the results:

- Web UI: `https://accelerator.iiasa.ac.at/projects/PROJECT_SLUG`, then `globiom-results/RUN_LABEL/<nsim>/`
- In a job: `/mnt/wdrv/globiom-results/RUN_LABEL/<nsim>/`
- Copy: `accli copy acc://PROJECT_SLUG/globiom-results/RUN_LABEL/<nsim>/ ./results/`

## Write wkube.py

Start from [references/wkube-template.py](references/wkube-template.py).

- Put the file in the model root.
- Set `job_folder` to the directory that contains `wkube.py`.
- Start from the include and exclude strings in the template. Then look for more directories that the solve does not need. Propose those extra excludes before you write them. Wait for the user to accept or reject each one. Do not dispatch a filter the user has not confirmed.
- Create one child task for each confirmed `nsim`. Pass that integer as `NSIM`.
- The root variable must be named `globiom`. The dispatch command uses that name.
- The holder is `WKubeTask()` with no arguments, as the jobflow page requires. `add_child` works only on that holder.
- Keep the resource values in the template unless the user asks to change them.
- Set `output_mappings` on every child from the paths you read in `Model/`. Map those directories. Do not copy them to another folder first.

Do not import `wkube.py` to test it. The import uploads the tree.

## Confirm, then dispatch

Show the user this summary before dispatch:

- model root
- GAMS choice: base stack or Dockerfile version
- license file name under `/code/`
- GAMS entry file
- `nsim` list
- result path in the project space
- files they edited, and whether each file is uploaded
- exclude patterns, including any extra directories they accepted
- project slug
- one line that each scenario requests 1 core, 24 GiB of memory, and 12 GiB of local disk

If the list has more than four scenarios, state that the jobs can run in parallel and that each job uses one shared GAMS seat. Wait for confirmation.

## First run

If this `wkube.py` has not yet produced a GLOBIOM job that writes its mapped outputs, say so before dispatch. Tell the user all of this:

- The first dispatch is one test scenario, not the full list.
- You will watch that job with `accli jobs`, `accli job`, and `accli logs`.
- You are checking for image build errors and scaffolding errors.
- After that job writes its mapped outputs, you will keep `wkube.py` stable.

Ask which one `nsim` to use for the test when they named more than one. Do not dispatch the other scenarios until the test job builds and writes its mapped outputs.

Run the command from the model root:

```bash
accli dispatch PROJECT_SLUG globiom
```

Replace `PROJECT_SLUG` with the confirmed slug. Do not add `-f`.

Then follow [references/monitor.md](references/monitor.md).

1. Run `accli job PROJECT_SLUG ROOT_JOB_ID` and read the child id. The dispatch id is the holder. It does not contain the GAMS log.
2. Run `accli logs PROJECT_SLUG CHILD_JOB_ID --follow`.
3. If the child never starts, read the holder log with `--source celery` and `--source podevents`.

Read the log for a failed image build, a missing file, a license error, or a missing `gams` command. If you find one, tell the user the cause and the change you propose. Dispatch the test again only after they confirm that change.

Do not call the test reliable because the holder status is `DONE`. The child must finish, and the mapped result path must contain the output. Use `accli jobs PROJECT_SLUG --status done` to confirm the graph, then check that path.

When the test job writes the mapped outputs, tell the user the result path. After that, this `wkube.py` is stable. Do not rewrite the command, stack, mappings, or filters for a later scenario unless the user asks, or a later run shows that the file is wrong.

If this `wkube.py` already produced mapped outputs, do not run another test scenario. Dispatch the confirmed list. Keep the stable file. Change it only for the reason above.
