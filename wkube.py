"""Dispatch the local GLOBIOM–downscale–G4M pipeline by Model nsim."""

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


region59_flow = load_source("globiom-region59")
downscaler_flow = load_source("downscaler")
downscale_merger_flow = load_source("downscale-merger")
g4m_flow = load_source("g4m")
g4m_merger_flow = load_source("g4m-input-merger")
reporter_flow = load_source("globiom-g4m-reporter")


def build_scenario(nsim, carbon_price):
    conf = {"NSIM": str(nsim)}
    region59 = region59_flow.build_task(f"GLOBIOM REGION59 nsim {nsim}", conf)
    downscale_jobs = WKubeTask(
        name=f"Downscaling nsim {nsim}",
    )
    for region in downscaler_flow.REGION59:
        downscale_jobs.add_child(
            downscaler_flow.build_task(
                f"DownscaleR nsim {nsim} {region}", {**conf, "REGION": region}
            )
        )
    region59.add_callback(downscale_jobs)
    downscale_merger = downscale_merger_flow.build_task(
        f"DownscaleR merger nsim {nsim}", conf
    )
    downscale_jobs.add_callback(downscale_merger)
    g4m = g4m_flow.build_task(
        f"G4M nsim {nsim}", {**conf, "CARBON_PRICE": str(carbon_price)}
    )
    downscale_merger.add_callback(g4m)
    g4m_merger = g4m_merger_flow.build_task(
        f"G4M feedback nsim {nsim}", {**conf, "CARBON_PRICE": str(carbon_price)}
    )
    g4m.add_callback(g4m_merger)
    return region59


run_id = "GLOBIOM-G4M-PIPELINE LOCAL RUN"
# scenarios = [(0, 0), (8, 0)]
scenarios = [(8, 0)]
baseline_nsim = 0
globiom_full = WKubeTask(
    name="GLOBIOM–G4M Local Pipeline test Trunk59 without collector 2 (downscale waiter)",
)
for nsim, carbon_price in scenarios:
    globiom_full.add_child(build_scenario(nsim, carbon_price))
globiom_full.add_callback(
    reporter_flow.build_task(
        f"GLOBIOM G4M report: {run_id}",
        {
            "BASELINE_NSIM": str(baseline_nsim),
            "GAMS_LICENSE_FILE": "/mnt/wdrv/gamslice.txt",
        },
    )
)
