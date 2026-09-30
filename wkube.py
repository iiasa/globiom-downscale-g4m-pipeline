"""Dispatch one complete GLOBIOM–G4M chain for each configured scenario."""

import importlib.util
import json
from pathlib import Path

from accli import WKubeTask


ROOT = Path(__file__).resolve().parent
SCENARIO_MODULE = ROOT.parent / "globiom-region59" / "scenarios.py"


def load_source(folder):
    path = ROOT.parent / folder / "wkube.py"
    spec = importlib.util.spec_from_file_location(
        f"source_{folder.replace('-', '_')}", path
    )
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load routine: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


region59_flow = load_source("globiom-region59")
downscaler_flow = load_source("downscaler")
downscale_merger_flow = load_source("downscale-merger")
collector_flow = load_source("globiom-region59-g4m-collector")
g4m_flow = load_source("g4m")
g4m_merger_flow = load_source("g4m-input-merger")
reporter_flow = load_source("globiom-g4m-reporter")


def load_scenarios():
    with (ROOT / "scenarios.json").open(encoding="utf-8") as config_file:
        config = json.load(config_file)
    default_run_id = config.get("run_id")
    rows = config.get("scenarios")

    spec = importlib.util.spec_from_file_location("globiom_scenarios", SCENARIO_MODULE)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load scenario definitions: {SCENARIO_MODULE}")
    scenario_module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(scenario_module)

    scenarios = []
    for row in rows:
        row_run_id = row.get("run_id", default_run_id)
        ssp_input, rcp_input = row["ssp"], row["rcp"]
        rcp_labels = {
            label.lower(): key
            for key, label in scenario_module.DOWNSCALING_SCEN3.items()
        }
        rcp_key = rcp_labels.get(rcp_input.lower(), rcp_input)
        ssp, rcp, nsim = scenario_module.resolve_scenario(ssp_input, rcp_key)

        carbon_price = row.get("co2_price", 0)
        restart_file = row.get("restart_file", "")
        scenarios.append(
            (
                row_run_id,
                ssp.upper(),
                scenario_module.DOWNSCALING_SCEN3[rcp],
                nsim,
                carbon_price,
                restart_file,
            )
        )
    return scenarios


def build_scenario(run_id, ssp, rcp, nsim, carbon_price, restart_file):
    scenario_root = f"/mnt/wdrv/globiom-results/{run_id}/scenarios/{ssp}_{rcp}"
    dims = {"RUN_ID": run_id, "SSP": ssp, "RCP": rcp}

    region59 = region59_flow.build_task(
        f"GLOBIOM REGION59 {ssp} {rcp}",
        {
            **dims,
            "NSIM": str(nsim),
            "GAMS_LICENSE_FILE": "/mnt/wdrv/gamslice.txt",
            "GLOBIOM_A6_RESTART": restart_file,
            "output_mappings": (
                f"/tmp/o/:{scenario_root}/;"
                f"/code/Model/output/:{scenario_root}/output/;"
                f"/code/Model/gdx/:{scenario_root}/gdx/;"
                f"/code/Model/restarts/:{scenario_root}/restarts/"
            ),
        },
    )

    branches = WKubeTask(name=f"Downscaling {ssp} {rcp}")
    for region in downscaler_flow.REGION59:
        branches.add_child(
            downscaler_flow.build_task(
                f"DownscaleR {ssp} {rcp} {region}",
                {
                    **dims,
                    "REGION": region,
                    "input_mappings": f"{scenario_root}/gdx/output.gdx:/tmp/input/input.gdx",
                    "output_mappings": f"/tmp/output/:{scenario_root}/downscaled/",
                },
            )
        )
    region59.add_callback(branches)
    downscale_merger = downscale_merger_flow.build_task(
        f"DownscaleR merger {ssp} {rcp}",
        {
            **dims,
            "input_mappings": f"{scenario_root}/downscaled/:/tmp/input/",
            "output_mappings": f"/tmp/output/:{scenario_root}/downscaled/merged/",
        },
    )
    branches.add_callback(downscale_merger)

    collector = collector_flow.build_task(
        f"GLOBIOM G4M input collector {ssp} {rcp}",
        {
            **dims,
            "GAMS_LICENSE_FILE": "/mnt/wdrv/gamslice.txt",
            "input_mappings": f"{scenario_root}/gdx/output.gdx:/code/Model/input.gdx",
            "output_mappings": (
                f"/code/Model/gdx/:{scenario_root}/globiom-g4m-inputs/gdx/;"
                f"/code/Model/output/g4m/:{scenario_root}/globiom-g4m-inputs/csvs/;"
                f"/code/Model/logs/:{scenario_root}/globiom-g4m-inputs/logs/"
            ),
        },
    )
    downscale_merger.add_callback(collector)

    g4m = g4m_flow.build_task(
        f"G4M {ssp} {rcp}",
        {
            **dims,
            "CARBON_PRICE": str(carbon_price),
            "input_mappings": (
                f"{scenario_root}/globiom-g4m-inputs/csvs/:/code/globiom-inputs/;"
                f"{scenario_root}/downscaled/merged/:/code/downscaled-inputs/"
            ),
            "output_mappings": f"/code/out/:{scenario_root}/g4m-results/",
        },
    )
    collector.add_callback(g4m)

    g4m_merger = g4m_merger_flow.build_task(
        f"G4M input merger {ssp} {rcp}",
        {
            **dims,
            "CARBON_PRICE": str(carbon_price),
            "input_mappings": f"{scenario_root}/g4m-results/:/mnt/tmp/i/",
            "output_mappings": f"/mnt/tmp/o/:{scenario_root}/g4m-results/merged/",
        },
    )
    g4m.add_callback(g4m_merger)
    return region59


scenarios = load_scenarios()
globiom_full = WKubeTask(name="GLOBIOM–G4M- Local Pipeline")
for run_id, ssp, rcp, nsim, carbon_price, restart_file in scenarios:
    globiom_full.add_child(
        build_scenario(run_id, ssp, rcp, nsim, carbon_price, restart_file)
    )

run_id = scenarios[0][0]
base_ssp, base_rcp = reporter_flow.load_config()
shared_root = f"/mnt/wdrv/globiom-results/{run_id}"
globiom_full.add_callback(
    reporter_flow.build_task(
        f"GLOBIOM G4M report: {run_id}",
        {
            "RUN_ID": run_id,
            "BASE_SSP": base_ssp,
            "BASE_RCP": base_rcp,
            "GAMS_LICENSE_FILE": "/mnt/tmp/.local/share/GAMS/gamslice.txt",
            "REPORT_INPUT_ROOT": "/mnt/tmp/i",
            "REPORT_OUTPUT_ROOT": "/mnt/tmp/o",
            "input_mappings": (
                f"{shared_root}/scenarios/:/mnt/tmp/i/;"
                "/mnt/wdrv/gamslice.txt:/mnt/tmp/.local/share/GAMS/gamslice.txt"
            ),
            "output_mappings": (
                f"/mnt/tmp/o/:{shared_root}/merged/;"
                f"{shared_root}/merged/:acc://globiom-results/{run_id}/merged/"
            ),
        },
    )
)
