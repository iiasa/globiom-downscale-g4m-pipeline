"""Build a single DownscaleR region task from its source folder."""

import json
from pathlib import Path

from accli import WKubeTask

ROOT = Path(__file__).resolve().parent

REGION59 = (
    "ArgentinaReg",
    "AustraliaReg",
    "BrazilReg",
    "CanadaReg",
    "ChinaReg",
    "CongoBasin",
    "Former_USSR",
    "IndiaReg",
    "IndonesiaReg",
    "JapanReg",
    "MalaysiaReg",
    "MexicoReg",
    "MiddleEast",
    "NewZealandReg",
    "NorthernAf",
    "Pacific_Islands",
    "RCAM",
    "RCEU",
    "ROWE",
    "RSAM",
    "RSAS",
    "RSEA_OPA",
    "RSEA_PAC",
    "RussiaReg",
    "SouthAfrReg",
    "SouthKorea",
    "EasternAf",
    "SouthernAf",
    "WesternAf",
    "TurkeyReg",
    "UkraineReg",
    "USAReg",
    "LatviaReg",
    "EstoniaReg",
    "LithuaniaReg",
    "LuxembourgReg",
    "SlovakiaReg",
    "AustriaReg",
    "SloveniaReg",
    "FinlandReg",
    "FranceReg",
    "SpainReg",
    "MaltaReg",
    "BelgiumReg",
    "GermanyReg",
    "SwedenReg",
    "GreeceReg",
    "BulgariaReg",
    "NetherlandsReg",
    "HungaryReg",
    "IrelandReg",
    "ItalyReg",
    "PolandReg",
    "CroatiaReg",
    "PortugalReg",
    "CyprusReg",
    "CzechRepReg",
    "DenmarkReg",
    "RomaniaReg",
)


def build_task(name, conf):
    return WKubeTask(
        name=name,
        job_folder=str(ROOT),
        docker_filename="Dockerfile",
        exclude="wkube.py",
        command=(
            "set -eu; "
            'export SCENARIO_ROOT="/mnt/wdrv/globiom-results/${ROOT_JOB_ID}/scenarios/${NSIM}"; '
            'mkdir -p "${SCENARIO_ROOT}/downscaled"; '
            "Rscript --vanilla /opt/downscaler/run_downscaling.R "
            '--input "${SCENARIO_ROOT}/output.gdx" '
            '--output "${SCENARIO_ROOT}/downscaled" '
            '--project "$ROOT_JOB_ID" --nsim "$NSIM" --region "$REGION"'
        ),
        required_cores=1,
        required_ram=8 * 1024**3,
        required_storage_local=4 * 1024**3,
        required_storage_workflow=1 * 1024**3,
        timeout=12 * 60 * 60,
        build_timeout=2 * 60 * 60,
        conf=conf,
    )
