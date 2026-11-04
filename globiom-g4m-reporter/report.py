"""Pool scenario GDX files and G4M feedback, then run the combined Stage 8 report."""

import argparse
import csv
import os
import shutil
import subprocess
from pathlib import Path


ROOT_JOB_ID_PATTERN = r"[a-z0-9][a-z0-9_-]*\Z"
LABEL_PATTERN = r"[A-Za-z0-9_]+\Z"
IAMC_SYMBOLS = ("Output4_SSP", "Output4_SSP_AG", "Output4_SSP_AG_2DIM", "REGION_AG_MAP")


def require(value: str | None, name: str, pattern: str) -> str:
    import re

    if value is None or not re.fullmatch(pattern, value):
        raise SystemExit(f"{name} does not match {pattern}")
    return value


def scenario_dimensions(gdx: Path) -> tuple[str, str, str]:
    result = subprocess.run(
        ["gdxdump", str(gdx), "symb=Obj_Compare", "format=csv"],
        check=True,
        capture_output=True,
        text=True,
    )
    rows = csv.DictReader(result.stdout.splitlines())
    found = {(row["ALLSCEN1"], row["ALLSCEN2"], row["ALLSCEN3"]) for row in rows}
    if len(found) != 1:
        raise SystemExit(
            f"{gdx} must contain one GLOBIOM scenario, found {sorted(found)}"
        )
    return found.pop()


def feedback_label(path: Path) -> tuple[list[str], list[list[str]], str]:
    with path.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.reader(handle))
    if len(rows) < 2:
        raise SystemExit(f"G4M feedback CSV has no data: {path}")
    labels = {row[1] for row in rows[1:] if len(row) > 1}
    if len(labels) != 1:
        raise SystemExit(
            f"{path} must contain one G4M scenario label, found {sorted(labels)}"
        )
    return rows[0], rows[1:], labels.pop()


def gams_symbol(value: str) -> str:
    if not value or any(character in value for character in "\"' \t"):
        raise SystemExit(f"Unsafe GAMS scenario label: {value!r}")
    return f'"{value}"'


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True, help="Scenario directory")
    parser.add_argument(
        "--g4m-results-path",
        type=Path,
        required=True,
        help="Feedback directory relative to each scenario",
    )
    parser.add_argument("--output", type=Path, required=True, help="Report directory")
    args = parser.parse_args()
    if args.g4m_results_path.is_absolute() or ".." in args.g4m_results_path.parts:
        parser.error("--g4m-results-path must stay within each scenario")

    root_job_id = require(os.environ.get("ROOT_JOB_ID"), "ROOT_JOB_ID", ROOT_JOB_ID_PATTERN)
    baseline_nsim = require(os.environ.get("BASELINE_NSIM"), "BASELINE_NSIM", r"(0|[1-9][0-9]*)\Z")
    license_file = os.environ.get("GAMS_LICENSE_FILE", "")
    if not license_file:
        raise SystemExit("GAMS_LICENSE_FILE is required")
    input_root = args.input
    output_root = args.output
    model_dir = Path(os.environ.get("GLOBIOM_MODEL_DIR", "/opt/globiom/Model"))
    baseline_gdx = input_root / baseline_nsim / "output.gdx"
    if not baseline_gdx.is_file():
        raise SystemExit(f"Missing baseline nsim GDX: {baseline_gdx}")
    baseline = scenario_dimensions(baseline_gdx)

    scenarios = sorted(input_root.glob("*/output.gdx"))
    if not scenarios:
        raise SystemExit(f"No scenario GDX files under {input_root}")

    maps = []
    headers = None
    pooled_rows: list[list[str]] = []
    for gdx in scenarios:
        scenario_dir = gdx.parent
        feedback = scenario_dir / args.g4m_results_path / f"tabs_gui_{root_job_id}_final_csv.csv"
        if not feedback.is_file():
            raise SystemExit(f"Missing G4M country feedback: {feedback}")
        dimensions = scenario_dimensions(gdx)
        header, rows, label = feedback_label(feedback)
        if headers is None:
            headers = header
        elif header != headers:
            raise SystemExit(f"G4M feedback header differs: {feedback}")
        maps.append((label, *dimensions))
        pooled_rows.extend(rows)

    if baseline not in {(row[1], row[2], row[3]) for row in maps}:
        raise SystemExit(f"Baseline {baseline} is not one of the mapped scenarios")
    if len({row[0] for row in maps}) != len(maps):
        raise SystemExit("G4M scenario labels are not unique")

    feedback_dir = model_dir / "output" / "g4m"
    feedback_dir.mkdir(parents=True, exist_ok=True)
    pooled = feedback_dir / f"tabs_gui_{root_job_id}_final_csv.csv"
    with pooled.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(headers)
        writer.writerows(pooled_rows)

    map_lines = [
        "SETS",
        "G4MScen2 /",
        *[f"  {gams_symbol(label)}" for label, *_ in maps],
        "/",
        "G4M_SCEN_MAP(G4MScen2,*,*,*) /",
        *[
            "  "
            + " . ".join(gams_symbol(value) for value in (label, scen1, scen2, scen3))
            for label, scen1, scen2, scen3 in maps
        ],
        "/",
        ";",
        "",
    ]
    (model_dir / "g4m_scen_map.gms").write_text("\n".join(map_lines), encoding="utf-8")

    (model_dir / "gdx").mkdir(exist_ok=True)
    (model_dir / "logs").mkdir(exist_ok=True)
    (model_dir / "output" / "iamc").mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            "gdxmerge",
            *[str(path) for path in scenarios],
            "strict=true",
            f"output=gdx/output_{root_job_id}_merged.gdx",
        ],
        cwd=model_dir,
        check=True,
    )
    subprocess.run(
        [
            "gams",
            "8_merge_output.gms",
            "lo=3",
            f"license={license_file}",
            "o=logs/8_merge_output.lst",
            f"--project={root_job_id}",
            "--rep_g4m=no",
            "--rep_iamc_glo=yes",
            "--rep_iamc_g4m=yes",
            "--lookup=0",
            "--regionagg=ggi",
            f"--g4mcsv=output/g4m/tabs_gui_{root_job_id}_final_csv.csv",
            f"--base1={baseline[0]}",
            f"--base2={baseline[1]}",
            f"--base3={baseline[2]}",
        ],
        cwd=model_dir,
        check=True,
    )

    reports = sorted(
        (model_dir / "output" / "iamc").glob(
            f"Output4_IAMC_template_{root_job_id}_*_ggi.gdx"
        )
    )
    if len(reports) != 1:
        raise SystemExit(
            f"Expected one IAMC GDX for {root_job_id}, found {[path.name for path in reports]}"
        )
    report = reports[0]
    output_root.mkdir(parents=True, exist_ok=True)
    shutil.copy2(report, output_root / f"Output4_IAMC_template_{root_job_id}.gdx")
    shutil.copy2(
        model_dir / "logs" / "8_merge_output.lst", output_root / "8_merge_output.lst"
    )
    for symbol in IAMC_SYMBOLS:
        destination = output_root / f"{symbol}.csv"
        with destination.open("w", encoding="utf-8") as handle:
            subprocess.run(
                ["gdxdump", str(report), f"symb={symbol}", "format=csv"],
                check=True,
                stdout=handle,
            )
    print(
        f"Wrote Output4_IAMC_template_{root_job_id}.gdx and {len(IAMC_SYMBOLS)} CSV dumps for {len(maps)} scenarios"
    )


if __name__ == "__main__":
    main()
