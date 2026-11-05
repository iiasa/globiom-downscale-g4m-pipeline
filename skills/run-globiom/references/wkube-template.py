from pathlib import Path

from accli import WKubeTask

MODEL_ROOT = Path(__file__).resolve().parent

# License file is in the model root. The container path is /code/<filename>.
# execute_abort children do not inherit license=. They open the image file
# /opt/gams/gams52.5_linux_x64_64_sfx/gamslice.txt. The job user cannot replace
# that file. extra_parameters puts the user license on %env% for every child.
LICENSE = "/code/gamslice.txt"
GAMS_ARGS = (
    f"lo=3 license={LICENSE} errMsg=1 PC=2 PS=0 PW=32767 checkErrorLevel=1 "
    f"//extra_parameters=license={LICENSE}"
)

# Replace ENTRY with the file the user chose:
# their 0_executebatch.gms or 0_execute_batch.gms, 6_scenarios.gms, or 7_output.gms.
# Note: 6_scenarios.gms typically restarts from stage 4 restart (e.g. r=t/a4_r1).
ENTRY = "6_scenarios.gms"
COMMAND = "\n".join(
    [
        "set -eu",
        'mkdir -p "/code/results/${NSIM}" Model/gdx',
        "cd Model",
        (
            f"gams {ENTRY} r=t/a4_r1 {GAMS_ARGS} "
            'o="/code/results/${NSIM}/${ENTRY%.gms}.lst" '
            '//nsim="$NSIM"'
        ),
        'cp -a gdx/output.gdx "/code/results/${NSIM}/${NSIM}.gdx" || true',
        'cp -a gdx/. "/code/results/${NSIM}/" || true',
    ]
)

EXCLUDE = (
    "Data/*,Model.bk/*,Model/t/*,Model/gdx/*,Model/output/*,"
    "temp/*,.venv/*,.svn/*,.git/*,wkube.py"
)
INCLUDE = "Model/t/a4_r1.g00"


def build_task(nsim: int) -> WKubeTask:
    return WKubeTask(
        name=f"GLOBIOM nsim {nsim}",
        job_folder=str(MODEL_ROOT),
        exclude=EXCLUDE,
        include=INCLUDE,
        # Base stack: base_stack="GAMS52_5__R4_6" (only if checkpoint matches GAMS 52.5).
        # Own GAMS version: delete base_stack and set docker_filename="Dockerfile".
        base_stack="GAMS52_5__R4_6",
        command=COMMAND,
        required_cores=1,
        required_ram=24 * 1024**3,
        required_storage_local=12 * 1024**3,
        required_storage_workflow=1 * 1024**3,
        timeout=12 * 60 * 60,
        build_timeout=2 * 60 * 60,
        conf={
            "NSIM": str(nsim),
            "output_mappings": (
                f"/code/results/{nsim}/:"
                f"acc://globiom-scenario/globiom-results/RUN_LABEL/{nsim}/"
            ),
        },
    )


# Replace this tuple with the nsim values the user confirmed.
# BATCHING ADVICE: If scheduling >20 scenarios (at 24 GiB RAM each),
# batch them into <= 20 tasks per dispatch to avoid cluster PREPARING_TIMEOUT (~2.5h).
NSIMS = (0,)

# IMPORTANT: The root holder task requires a non-empty name (e.g. name="GLOBIOM Run"),
# otherwise Pydantic validation fails with "ValidationError: name".
globiom = WKubeTask(name="GLOBIOM Run")
for nsim in NSIMS:
    globiom.add_child(build_task(nsim))
