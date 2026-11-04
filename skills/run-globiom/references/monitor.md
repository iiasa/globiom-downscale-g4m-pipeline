# Watch a GLOBIOM job

`accli` 2.1.1 takes the project slug on every job command. Do not use `-p`. Do not omit the slug.

The published page https://accelerator.iiasa.ac.at/docs/routine-getting-started still shows `accli logs <job_id>` and `-p`. That form is wrong. If that page and `accli logs --help` disagree, follow the installed help.

Dispatch prints the holder job id. That id does not contain the GAMS output. A GLOBIOM run is a holder plus one child per `nsim`.

## See whether the run is alive

```bash
accli jobs PROJECT_SLUG
```

This lists root jobs, newest first. `TYPE` is `children` for a scenario holder. `GRAPH` is the status of the jobs under that root. Use `GRAPH`, not the holder `STATUS`, to decide if the scenarios are still running.

```bash
accli jobs PROJECT_SLUG --status processing
accli jobs PROJECT_SLUG --status error
accli jobs PROJECT_SLUG --status done
```

`processing` and `active` are the same filter. `error` and `failed` are the same filter. Repeat `--status`, or pass a comma-separated list. `--limit` accepts 1 to 200. The default is 10.

Use this when the dispatch id was lost, or when you need to see if an older test is still using a GAMS seat.

## See which scenario failed

```bash
accli job PROJECT_SLUG ROOT_JOB_ID
```

This prints the holder and each child. Read the child id and status before you read logs. A failed graph can contain one failed scenario and several that are still running.

## Read the log that answers the question

```bash
accli logs PROJECT_SLUG JOB_ID --follow
```

`--follow` prints new lines every few seconds until that job finishes. Logs belong to one job id. Follow the child that runs GAMS. Follow the holder only for graph scheduling.

The merged log has three sources:

| Source | What it shows | Use it for |
| --- | --- | --- |
| `wkube` | The container command | GAMS output, missing files, license errors |
| `celery` | The scheduler | Image build and queue errors |
| `podevents` | Cluster events | Image pull, scheduling, and memory kills |

Add `--source wkube` to hide the build noise. Add `--source celery` or `--source podevents` when the child never starts. Repeat `--source` to combine them.

`--all` prints the whole log. The default is only the latest part. Use `--all` when the latest part does not show the build error. `--attempt N` selects an older attempt. The default is the latest attempt. `--no-time` hides the timestamp.

Do not treat a holder log with no GAMS output as a successful solve. Check the child status and the mapped result path.
