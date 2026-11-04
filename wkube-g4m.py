"""Build G4M from its source folder for a single scenario."""

from pathlib import Path

from accli import WKubeTask


def build_task(name, conf):
    return WKubeTask(
        name=name,
        job_folder=str(Path(__file__).resolve().parent),
        base_stack="WINE64__CONSOLE",
        # docker_filename="Dockerfile",
        exclude="Default/*,wkube.py",
        command=(
            "set -eu; "
            'SCENARIO_ROOT="/mnt/wdrv/globiom-results/${ROOT_JOB_ID}/scenarios/${NSIM}"; '
            'sh /code/run_g4m.sh "${SCENARIO_ROOT}/g4m" '
            '"${SCENARIO_ROOT}/downscaled/merged" "$ROOT_JOB_ID" '
            '"$CARBON_PRICE" "${SCENARIO_ROOT}/g4m-results"'
        ),
        required_cores=1,
        required_ram=16 * 1024**3,
        required_storage_local=12 * 1024**3,
        required_storage_workflow=1 * 1024**3,
        timeout=24 * 60 * 60,
        build_timeout=2 * 60 * 60,
        conf=conf,
    )
