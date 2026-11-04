"""Convert one scenario's G4M country table into GLOBIOM feedback CSV."""

import argparse
import csv
import os
import re
import struct
import subprocess
import tempfile
from pathlib import Path


ROOT_JOB_ID_PATTERN = re.compile(r"[a-z0-9][a-z0-9_-]*\Z")
SCENARIO_PATTERN = re.compile(r"[A-Za-z0-9_]+\Z")
MISSING_VALUES = {"na", "nan"}
COLLECTOR_VARIABLES = (
    "SupplyResidues",
    "SupplyWood",
    "Wood_price",
    "LandRent",
    "CO2price",
)
SCENARIO_COLUMNS = ("SCEN1", "SCEN2", "SCEN3")


def scenario_dimensions(path: Path) -> tuple[str, str, str]:
    """Read one SCEN1/SCEN2/SCEN3 tuple, as run_g4m.sh does."""
    if not path.is_file():
        raise ValueError(f"Missing scenario table: {path}")
    with path.open(newline="", encoding="utf-8") as source:
        reader = csv.reader(source)
        header = next(reader, None)
        if header is None:
            raise ValueError(f"Missing scenario header: {path}")
        indexes = []
        for name in SCENARIO_COLUMNS:
            matches = [index for index, column in enumerate(header) if column == name]
            if len(matches) != 1:
                raise ValueError(f"Missing scenario column {name}: {path}")
            indexes.append(matches[0])
        scenario = None
        for row in reader:
            if any(len(row) <= index for index in indexes):
                raise ValueError(f"Incomplete scenario row: {path}")
            current = tuple(row[index] for index in indexes)
            if any(SCENARIO_PATTERN.fullmatch(value) is None for value in current):
                raise ValueError(f"Invalid scenario dimensions: {path}")
            if scenario is None:
                scenario = current
            elif scenario != current:
                raise ValueError(f"Inconsistent scenario dimensions: {path}")
        if scenario is None:
            raise ValueError(f"No scenario rows: {path}")
    return scenario


def scenario_label(input_root: Path, project: str) -> str:
    """Require one tuple in the six G4M input tables and return SCEN1_SCEN3_SCEN2."""
    scenario_root = input_root.parent
    collector_root = scenario_root / "g4m"
    landcover_root = scenario_root / "downscaled" / "merged"
    tables = [
        *(
            collector_root / f"GLOBIOM2G4M_output_{variable}_{project}.csv"
            for variable in COLLECTOR_VARIABLES
        ),
        landcover_root / f"GLOBIOM2G4M_output_LC_abs_{project}.csv",
    ]
    expected = None
    for table in tables:
        current = scenario_dimensions(table)
        if expected is None:
            expected = current
        elif current != expected:
            raise ValueError(f"Input CSVs contain different scenarios: {table}")
    assert expected is not None
    scen1, scen2, scen3 = expected
    return f"{scen1}_{scen3}_{scen2}"


def table_dimensions(gdc: Path, gdt: Path) -> tuple[str, list[str]]:
    """Check the GDC header against its GDT dimensions before using G4M's reader."""
    with gdc.open("rb") as source:
        header = source.read(4)
        if len(header) != 4:
            raise ValueError(f"Incomplete G4M table: {gdc}")
        (dimension_count,) = struct.unpack(">i", header)
        if dimension_count != 4:
            raise ValueError(f"Expected four G4M dimensions in {gdc}, got {dimension_count}")
        cardinals = source.read(4 * dimension_count)
        if len(cardinals) != 4 * dimension_count:
            raise ValueError(f"Incomplete G4M dimensions: {gdc}")
        counts = struct.unpack(">4i", cardinals)
        if any(count < 1 for count in counts) or counts[0] != 1:
            raise ValueError(f"Invalid G4M dimension sizes in {gdc}: {counts}")
        records = source.read(4)
        if len(records) != 4:
            raise ValueError(f"Missing G4M record count: {gdc}")
        (record_count,) = struct.unpack(">i", records)
        if record_count < 0 or gdc.stat().st_size != 24 + 12 * record_count:
            raise ValueError(f"Invalid G4M record data in {gdc}")

    lines = gdt.read_text(encoding="utf-8").splitlines()
    position = 1  # Description of the table.
    dimensions = []
    for count in counts:
        if len(lines) < position + count + 1:
            raise ValueError(f"Incomplete G4M dimension labels: {gdt}")
        name = lines[position]
        dimensions.append((name, lines[position + 1 : position + count + 1]))
        position += count + 1
    if [name for name, _ in dimensions] != ["Scenario", "Year", "Country", "Parameter"]:
        raise ValueError(f"Unexpected G4M dimensions in {gdt}")
    scenario = dimensions[0][1][0]
    if not SCENARIO_PATTERN.fullmatch(scenario):
        raise ValueError(f"Invalid G4M scenario label: {gdt}")
    if position != len(lines):
        raise ValueError(f"Unexpected trailing G4M dimension labels: {gdt}")
    return scenario, dimensions[1][1]


def clean_csv(source: Path, destination: Path, scenario: str, years: list[str]) -> tuple[int, int]:
    """Match the legacy notebook's removal of rows containing NaN values."""
    kept = dropped = 0
    with source.open("rb") as input_file, destination.open(
        "w", newline="", encoding="utf-8"
    ) as output_file:
        # G4M's writer copies CRLF GDT labels verbatim into unquoted CSV fields.
        reader = csv.reader(line.decode("utf-8").replace("\r", "") for line in input_file)
        writer = csv.writer(output_file)
        header = next(reader, None)
        if header != ["", "", "", *years]:
            raise ValueError(f"Unexpected G4M CSV header: {source}")
        writer.writerow(header)
        for row in reader:
            if len(row) != len(header) or row[1] != scenario:
                raise ValueError(f"Unexpected G4M CSV row: {source}")
            if any(value.lower() in MISSING_VALUES for value in row[3:]):
                dropped += 1
                continue
            writer.writerow(row)
            kept += 1
    if kept == 0:
        raise ValueError(f"No valid G4M rows in {source}")
    return kept, dropped


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-root", type=Path, default=Path(os.getenv("G4M_MERGE_INPUT_ROOT", "/mnt/tmp/i")))
    parser.add_argument("--output-root", type=Path, default=Path(os.getenv("G4M_MERGE_OUTPUT_ROOT", "/mnt/tmp/o")))
    parser.add_argument("--converter", type=Path, default=Path(__file__).with_name("convert-country"))
    parser.add_argument("--root-job-id", default=os.getenv("ROOT_JOB_ID"))
    parser.add_argument("--carbon-price", default=os.getenv("CARBON_PRICE"))
    args = parser.parse_args()

    if not isinstance(args.root_job_id, str) or not ROOT_JOB_ID_PATTERN.fullmatch(args.root_job_id):
        parser.error("ROOT_JOB_ID must use lowercase letters, digits, '_' or '-'")
    if not isinstance(args.carbon_price, str) or not re.fullmatch(r"-?\d+", args.carbon_price):
        parser.error("CARBON_PRICE must be an integer")

    price_suffix = "_Pco2_0" if int(args.carbon_price) == 0 else ""
    try:
        label = scenario_label(args.input_root, args.root_job_id)
    except ValueError as error:
        parser.error(str(error))
    stem = f"tabs_gui_{args.root_job_id}_{label}{price_suffix}"
    gdc = args.input_root / f"{stem}.gdc"
    gdt = args.input_root / f"{stem}.gdt"
    for table in (gdc, gdt):
        if not table.is_file() or table.stat().st_size == 0:
            parser.error(f"Missing G4M country table: {table}")
    scenario, years = table_dimensions(gdc, gdt)
    if scenario != label:
        parser.error(f"G4M table scenario does not match input CSVs: {gdt}")

    args.output_root.mkdir(parents=True, exist_ok=True)
    output_stem = f"tabs_gui_{args.root_job_id}_final_csv"
    with tempfile.TemporaryDirectory(prefix=".g4m-merge-", dir=args.output_root) as temp:
        work = Path(temp)
        subprocess.run([str(args.converter), str(gdc), str(work), output_stem], check=True)
        converted = work / f"{output_stem}.csv"
        kept, dropped = clean_csv(converted, work / "clean.csv", scenario, years)
        os.replace(work / "clean.csv", args.output_root / f"{output_stem}.csv")
    print(f"Wrote {kept} country rows; removed {dropped} rows with missing values")


if __name__ == "__main__":
    main()
