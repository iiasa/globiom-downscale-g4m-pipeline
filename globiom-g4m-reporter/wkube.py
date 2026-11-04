"""Accelerator task for the combined GLOBIOM and G4M Stage 8 report."""

import json
from pathlib import Path

from accli import WKubeTask


def load_config() -> int:
    with Path(__file__).with_name("report.json").open(encoding="utf-8") as handle:
        config = json.load(handle)
    if not isinstance(config, dict):
        raise ValueError("report.json must contain a JSON object")
    nsim = config.get("baseline_nsim")
    if type(nsim) is not int or nsim < 0:
        raise ValueError("baseline_nsim must be a nonnegative integer")
    return nsim


def load_g4m_results_path() -> str:
    with Path(__file__).with_name("report.json").open(encoding="utf-8") as handle:
        value = json.load(handle)["g4m_results_path"]
    if (
        not isinstance(value, str)
        or not value
        or Path(value).is_absolute()
        or ".." in Path(value).parts
    ):
        raise ValueError("g4m_results_path must stay within each scenario")
    return value


def build_task(name, conf):
    return WKubeTask(
        name=name,
        job_folder=str(Path(__file__).resolve().parent),
        docker_filename="Dockerfile",
        exclude="wkube.py",
        command=(
            "set -eu; "
            'ROOT="/mnt/wdrv/globiom-results/${ROOT_JOB_ID}"; '
            "python3 /opt/globiom-combined-report/report.py "
            '--input "$ROOT/scenarios" '
            '--g4m-results-path "$G4M_RESULTS_PATH" '
            '--output "$ROOT/merged"'
        ),
        required_cores=2,
        required_ram=16 * 1024**3,
        required_storage_local=40 * 1024**3,
        required_storage_workflow=4 * 1024**3,
        timeout=8 * 60 * 60,
        build_timeout=60 * 60,
        conf={**conf, "G4M_RESULTS_PATH": load_g4m_results_path()},
    )


if __name__ == "workflow":
    baseline_nsim = load_config()

    globiom_combined_report = build_task(
        "GLOBIOM G4M report",
        {
            "BASELINE_NSIM": str(baseline_nsim),
            "GAMS_LICENSE_FILE": "/mnt/wdrv/gamslice.txt",
        },
    )
