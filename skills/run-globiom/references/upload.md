# The dispatch upload

Every `accli dispatch` imports `wkube.py`. That import builds each `WKubeTask`. The build copies `job_folder` through the include and exclude filters and uploads that copy to the Accelerator jobstore on S3.

The client hashes every file that survived the filter. A new hash is PUT to the jobstore. A hash already stored is not sent again, but the client still reads and hashes the file. A new manifest is stored as `s3accjobstore://manifest_<hash>.json`. The job record points at that manifest. The image builder later pulls it from S3.

A second dispatch does this again. It does not reuse the previous job. A file the user has open and half-edited is the file that gets hashed and stored. Do not import `wkube.py` to test it. Do not dispatch while the user is still editing. Ask them to say the tree is ready.

## Keep the upload small

The filtered copy should be the GAMS source the command opens, `cplex.opt`, the license file, and the one restart file. It should not be `Data/`, other checkpoints, `Model/gdx`, backups, logs, or old outputs.

Before dispatch, measure the filtered copy. Name the largest directories still included. If that copy is large, stop. Propose more excludes. Wait for the user to accept them. Do not dispatch a large tree because the required patterns are already present.

Unchanged blobs skip the PUT. That does not make a large tree cheap. The client still walks and hashes every included file, and a changed file uploads its full new bytes. A wide exclude list is the way to keep the upload small. However, if its impossible to have a compilable and runnable job without a large upload, so be it. Just be mindful about upload sizes.

## Restart instead of a new dispatch

A restart runs the job that is already stored. It does not upload `job_folder` again. The backend keeps the same `s3accjobstore://` manifest and dispatches that job tree again.

Use it when the code did not change and the job is finished or failed. That includes `TIMEOUT`, `KILLED`, `ERROR`, `QUEUE_TIMEOUT`, `PREPARING_TIMEOUT`, and `DISPATCH_TO_EXECUTOR_FAILED`. A timeout is the common case. Restart that job. Do not write a new `wkube.py` and dispatch again.

```bash
accli job PROJECT_SLUG JOB_ID restart
```

`JOB_ID` can be the root id or a child id. The root id reruns the stored graph. A child id reruns that scenario. Both use the upload from the original dispatch.

Do not restart a job whose parent or child is still processing. The backend rejects that. Wait, or restart only after `accli job` shows the graph is finished or failed.

A restart does not pick up files the user edited after the original dispatch. Those edits need a new dispatch, and only after the user says the tree is ready. Say that before you choose a new dispatch over a restart.

Do not add a rebuild flag unless the user asks to rebuild the image. A normal restart reuses the image of the stored upload.
