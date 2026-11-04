# Own GAMS version

Use this path only when the user does not want `GAMS52_5__R4_6`.

Ask for:

- the GAMS version, such as `52.5.0`
- the license file name

Put the license file in the model root. That directory is `job_folder`. Do not exclude it. Do not print it.

The platform copies the filtered model root to `/code`. The command must use `license=/code/<filename>` and `//extra_parameters=license=/code/<filename>`. Check that this path matches the file name in the model root before dispatch. `execute_abort` children do not inherit `license=`. They open the image `gamslice.txt`. The job user cannot replace that file.

`Model/t/a4_r1.g00` was saved by GAMS 52.5. If they open that restart, warn them when the version is not 52.5. Let them keep the version they named.

## Dockerfile

Write `Dockerfile` in the model root. Set `docker_filename="Dockerfile"`. Do not set `base_stack`.

Guide the user. Do not hide the version or the user id in a different file.

Build as root. Run the job as `65534:65534`. Install GAMS before the `USER` line. Copy the model after the install, or the copy can overwrite `/opt/gams`.

```dockerfile
FROM public.ecr.aws/docker/library/debian:bookworm-slim

ARG GAMS_VERSION=52.5.0
ENV GAMS_VERSION_SHORT=52.5 \
    GAMS_BIT_ARC=x64_64
ENV GAMS_PATH=/opt/gams/gams${GAMS_VERSION_SHORT}_linux_${GAMS_BIT_ARC}_sfx
ENV PATH="${PATH}:${GAMS_PATH}" \
    LD_LIBRARY_PATH="${GAMS_PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl libgomp1 \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /opt/gams \
    && curl -fsSL \
        "https://d37drm4t2jghv5.cloudfront.net/distributions/${GAMS_VERSION}/linux/linux_${GAMS_BIT_ARC}_sfx.exe" \
        -o /opt/gams/gams.exe \
    && chmod +x /opt/gams/gams.exe \
    && /opt/gams/gams.exe \
    && rm /opt/gams/gams.exe

WORKDIR /code
COPY --chown=65534:65534 . /code
USER 65534:65534
```

Replace `GAMS_VERSION` and `GAMS_VERSION_SHORT` with the version the user named. `52.5.0` uses short form `52.5`.

The installer creates `gams<short>_linux_x64_64_sfx`. If a run cannot find `gams`, that folder name did not match `GAMS_PATH`. Fix `GAMS_PATH`. Do not switch back to the base stack unless the user asks.

`USER 65534:65534` must stay after `COPY`. The job writes under `/code`, which that user owns. Do not run the job as root.

Do not add `init.R` for this image. Do not install R packages unless the user asks.
