"""Convert one nsim's G4M country table to GLOBIOM feedback."""

import json
from pathlib import Path

from accli import WKubeTask


def load_config():
    with Path(__file__).with_name("merge.json").open(encoding="utf-8") as source:
        config = json.load(source)
    nsim, price = config["nsim"], config["carbon_price"]
    if type(nsim) is not int or nsim < 0 or type(price) is not int:
        raise ValueError(
            "nsim must be a nonnegative integer; carbon_price must be an integer"
        )
    return nsim, price


def build_task(name, conf):
    return WKubeTask(
        name=name,
        job_folder=str(Path(__file__).resolve().parent),
        docker_filename="Dockerfile",
        exclude="wkube.py",
        command=(
            "set -eu; "
            'SCENARIO_ROOT="/mnt/wdrv/globiom-results/${ROOT_JOB_ID}/scenarios/${NSIM}"; '
            "python3 /opt/globiom-g4m-results-merge/merge_g4m.py "
            '--input-root "${SCENARIO_ROOT}/g4m-results" '
            '--output-root "${SCENARIO_ROOT}/g4m-results/g4m_outputs_merged"'
        ),
        required_cores=1,
        required_ram=2 * 1024**3,
        required_storage_local=2 * 1024**3,
        required_storage_workflow=1 * 1024**3,
        timeout=60 * 60,
        build_timeout=30 * 60,
        conf=conf,
    )


if __name__ == "workflow":
    nsim, carbon_price = load_config()
    globiom_g4m_results_merge = build_task(
        f"G4M country feedback nsim {nsim}",
        {"NSIM": str(nsim), "CARBON_PRICE": str(carbon_price)},
    )
