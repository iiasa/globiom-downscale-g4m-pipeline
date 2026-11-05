# Include and exclude

`accli` copies `job_folder` before upload. The copy uses `include` and `exclude` on `WKubeTask`. Both values are comma-separated `fnmatch` patterns. The copier strips whitespace around each pattern.

A pattern matches the relative path or the file name. In Python, `*` matches `/`. `Data/*` matches every file under `Data/`.

`.git` directories are never copied.

After the copy, the dispatcher deletes `wkube.py` from the upload. Exclude it anyway so the rule is visible.

## How the two lists combine

Use both lists for GLOBIOM. Their combination is not a whitelist.

| `include` | `exclude` | Result                                                                                                         |
| --------- | --------- | -------------------------------------------------------------------------------------------------------------- |
| unset     | unset     | Copy every file except `.git`.                                                                                 |
| unset     | set       | Copy every file that does not match `exclude`.                                                                 |
| set       | unset     | Copy only files that match `include`. This drops the model.                                                    |
| set       | set       | Copy files that are not excluded. A file that matches `include` is copied even when it also matches `exclude`. |

An excluded directory is not entered when `include` is unset. When `include` is set, the copier still enters that directory to find exceptions. This is why `exclude` can contain `Model/t/*` and `include` can still copy `Model/t/a4_r1.g00`.

An empty match does not raise an error. A wrong `include` pattern omits the restart file silently. Before dispatch, check that `Model/t/a4_r1.g00` exists and that the include pattern matches that relative path.

## Required GLOBIOM filter

```python
exclude="Data/*,Model.bk/*,Model/t/*,Model/gdx/*,Model/output/*,temp/*,.venv/*,.svn/*,.git/*,wkube.py"
include="Model/t/a4_r1.g00"
```

Keep every pattern. Use the same pair on every child task. The upload is cached for one directory and one filter pair. A different filter uploads the tree again.

| Pattern                       | Why it is excluded                                                                                                 |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `Data/*`                      | The data tree is large. The restart file already contains stages 1–4. Do not upload `Data/` to fix a missing file. |
| `Model/t/*`                   | Other checkpoints are large. The job needs one restart file.                                                       |
| `Model/gdx/*`                 | Solver output, not source. The job creates a new `Model/gdx` in the container.                                     |
| `Model/output/*`              | Existing scenario results from local runs. Do not upload previous outputs.                                         |
| `temp/*`                      | Temporary scratch files.                                                                                           |
| `.venv/*`, `.svn/*`, `.git/*` | Local tool and version control files.                                                                              |
| `wkube.py`                    | Dispatch file. It is not model code.                                                                               |

`include="Model/t/a4_r1.g00"` puts that restart file back. The solve starts from `t/a4_r1.g00`. Do not include the rest of `Model/t`.

`Data_Scen/`, `include/`, `Model/*.gms`, `Model/cplex.opt`, and the license file in the model root stay in the upload. Do not add an exclude that matches the license file. An extra exclude can remove a file the solve opens.

## Windows / SVN file permissions

On Windows working copies checked out from Subversion (SVN), files in `.svn/pristine/` or local files may have the `ReadOnly` attribute set. When `accli` scans or packages files, Python can raise:
```text
PermissionError: [WinError 5] Access is denied
```

To prevent this:
1. Ensure `.svn/*` is always in `exclude`.
2. Clear read-only attributes on all files in the model tree before dispatching:
   ```powershell
   Get-ChildItem -Path . -Recurse -Force | Where-Object { $_.IsReadOnly } | ForEach-Object { $_.IsReadOnly = $false }
   ```

## UTF-8 Byte Order Mark (BOM)

When creating or editing scripts (`init.R`, `*.gms`, `*.sh`) on Windows using PowerShell (`Set-Content` or `Out-File`), default encodings often write a UTF-8 BOM (`\ufeff`). Linux interpreters (Bash, Rscript) fail to parse these files:
```text
Error: unexpected input in '\ufeff'
```
Always save files as ASCII or UTF-8 without BOM (`utf8NoBOM`).

## When the user changes an excluded file

Tell the user that the job will not contain that file. Then stop.

To include one required file, add its relative path to `include`. Do not delete `Data/*` or `Model/t/*`.

If the user chooses a different restart file, include that file. Use a GAMS version that can open that file. Do not search for another checkpoint and switch to it.

## Make the bundle smaller

Look through the model root before you write `exclude`. The required patterns above are the start, not the whole list. Propose more excludes for directories the chosen GAMS entry does not open.

Look for backups, old outputs, logs, editor files, `.venv`, caches, and other large trees. Name each proposed pattern and why it is safe to omit.

Show that list to the user. Wait for them to accept or reject each pattern. Do not add a pattern they did not accept. Do not remove a required pattern to make the bundle smaller.

Do not exclude the license file, the chosen entry file, `Model/cplex.opt`, or a restart file the command opens. If a proposed exclude would hide a file the user edited, say so and leave that file in the upload.
