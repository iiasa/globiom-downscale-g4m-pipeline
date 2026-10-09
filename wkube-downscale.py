"""Dispatch regional downscaling and merge the results by Model nsim."""

import importlib.util
import subprocess
from pathlib import Path

from accli import WKubeTask

ROOT = Path(__file__).resolve().parent


def load_source(folder):
    directory = ROOT / folder
    branch = subprocess.run(
        ["git", "-C", str(directory), "branch", "--show-current"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()
    if branch != "wkube":
        raise ValueError(f"{directory} must be on branch wkube, found {branch!r}")
    spec = importlib.util.spec_from_file_location(
        f"source_{folder.replace('-', '_')}", directory / "wkube.py"
    )
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load routine: {directory}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


downscaler_flow = load_source("downscaler")
downscale_merger_flow = load_source("downscale-merger")


def build_scenario(nsim):
    conf = {"NSIM": str(nsim)}
    downscale_jobs = WKubeTask(name=f"Downscaling nsim {nsim}")
    for region in downscaler_flow.REGION59:
        downscale_jobs.add_child(
            downscaler_flow.build_task(
                f"DownscaleR nsim {nsim} {region}", {**conf, "REGION": region}
            )
        )
    downscale_jobs.add_callback(
        downscale_merger_flow.build_task(f"DownscaleR merger nsim {nsim}", conf)
    )
    return downscale_jobs


scenarios = [8]
globiom_downscale = WKubeTask(name="GLOBIOM downscaling and merger")
for nsim in scenarios:
    globiom_downscale.add_child(build_scenario(nsim))
