"""Full chain: GLOBIOM unit 1 then downscaling unit 2 on the same run_id."""

import importlib.util
import json
import re
from pathlib import Path

from accli import WKubeTask

JOBFLOW_ROOT = Path(__file__).resolve().parent
WORKSPACE_ROOT = JOBFLOW_ROOT.parent
RUNNER_ROOT = WORKSPACE_ROOT / "globiom-minimal-runner"
UNIT1_ROOT = WORKSPACE_ROOT / "globiom-parallel-jobflow"
UNIT2_ROOT = WORKSPACE_ROOT / "globiom-downscaling-jobflow"


def _load_module(module_name: str, path: Path):
    spec = importlib.util.spec_from_file_location(module_name, path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load module: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


scenario_module = _load_module("globiom_scenarios", RUNNER_ROOT / "scenarios.py")
unit1_flow = _load_module("globiom_parallel_flow", UNIT1_ROOT / "flow.py")
unit2_flow = _load_module("globiom_downscaling_flow", UNIT2_ROOT / "flow.py")


def load_jobflow() -> tuple[str, list[tuple[str, str, int]]]:
    config_path = JOBFLOW_ROOT / "scenarios.json"
    try:
        with config_path.open(encoding="utf-8") as config_file:
            config = json.load(config_file)
    except FileNotFoundError:
        raise ValueError(f"Missing jobflow configuration: {config_path}") from None
    except json.JSONDecodeError as error:
        raise ValueError(f"Invalid JSON in {config_path}: {error}") from None

    if not isinstance(config, dict):
        raise ValueError("scenarios.json must contain a JSON object")

    run_id = config.get("run_id")
    if not isinstance(run_id, str) or not re.fullmatch(r"[a-z0-9][a-z0-9_-]*", run_id):
        raise ValueError(
            "scenarios.json field 'run_id' must use lowercase letters, digits, '_' or '-'"
        )

    requested_scenarios = config.get("scenarios")
    if not isinstance(requested_scenarios, list) or not requested_scenarios:
        raise ValueError("scenarios.json field 'scenarios' must be a nonempty array")
    if len(requested_scenarios) > 5:
        raise ValueError(
            "At most five scenarios can run concurrently with this license"
        )

    scenarios = []
    seen = set()
    for requested_scenario in requested_scenarios:
        if not isinstance(requested_scenario, dict):
            raise ValueError("each scenario must be a JSON object")
        scenario = scenario_module.resolve_scenario(
            requested_scenario.get("ssp"), requested_scenario.get("rcp")
        )
        scenario_key = scenario[:2]
        if scenario_key in seen:
            raise ValueError(f"Duplicate GLOBIOM scenario: {'+'.join(scenario_key)}")
        seen.add(scenario_key)
        scenarios.append(scenario)

    return run_id, scenarios


run_id, scenarios = load_jobflow()
globiom_full, merger = unit1_flow.build_globiom_parallel(run_id, scenarios)
downscaling_root = unit2_flow.build_downscaling(run_id, scenarios, scenario_module)
merger.add_callback(downscaling_root)
assert isinstance(globiom_full, WKubeTask)
