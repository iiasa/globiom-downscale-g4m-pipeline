"""Merge the regional downscaling results for one nsim."""

from pathlib import Path

from accli import WKubeTask

ROOT = Path(__file__).resolve().parent


def build_task(name, conf):
    return WKubeTask(
        name=name,
        job_folder=str(ROOT),
        base_stack="R4_4",
        exclude="wkube.py",
        command=(
            "set -eu; "
            'SCENARIO_ROOT="/mnt/wdrv/globiom-results/${ROOT_JOB_ID}/scenarios/${NSIM}"; '
            "Rscript --vanilla /code/merge_downscaling.R "
            '--input "${SCENARIO_ROOT}/downscaled" '
            '--output "${SCENARIO_ROOT}/downscaled/merged"'
        ),
        required_cores=1,
        required_ram=4 * 1024**3,
        required_storage_local=4 * 1024**3,
        required_storage_workflow=1 * 1024**3,
        timeout=2 * 60 * 60,
        build_timeout=30 * 60,
        conf=conf,
    )
