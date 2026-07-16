#!/usr/bin/env bash
#SBATCH --job-name=verifybamid
#SBATCH --output=logs/verifybamid-%j.out
#SBATCH --error=logs/verifybamid-%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=24:00:00
#SBATCH --qos=3d

set -euo pipefail

cd "${SLURM_SUBMIT_DIR}"

if [[ -f .env ]]; then
    # shellcheck disable=SC1091
    source .env
fi

PROFILE="${PROFILE:-singularity}"
NEXTFLOW_CONFIG="${NEXTFLOW_CONFIG:-config/nextflow.local.config}"
VERIFYBAMID_WORKFLOW="${VERIFYBAMID_WORKFLOW:-scripts/verifybamid.nf}"
VERIFYBAMID_PARAMS="${VERIFYBAMID_PARAMS:-config/verifybamid.params.yaml}"
VERIFYBAMID_OUTDIR="${VERIFYBAMID_OUTDIR:-results/verifybamid}"

export NXF_OPTS="${NXF_OPTS:--Xms1g -Xmx4g}"

module purge
module load Nextflow

echo "Host: $(hostname)"
echo "Nextflow: $(command -v nextflow)"
nextflow -version

if ! command -v singularity >/dev/null 2>&1; then
    echo "ERROR: singularity is not available on compute node $(hostname)." >&2
    echo "PATH: ${PATH}" >&2
    module list 2>&1 || true
    exit 1
fi

echo "Singularity: $(command -v singularity)"
singularity --version

if [[ -n "${NXF_SINGULARITY_CACHEDIR:-}" ]]; then
    mkdir -p "${NXF_SINGULARITY_CACHEDIR}"
    export NXF_SINGULARITY_CACHEDIR
fi

for FILE in \
    "${NEXTFLOW_CONFIG}" \
    "${VERIFYBAMID_WORKFLOW}" \
    "${VERIFYBAMID_PARAMS}"
do
    if [[ ! -f "${FILE}" ]]; then
        echo "ERROR: Missing file: ${FILE}" >&2
        exit 1
    fi
done

mkdir -p \
    logs \
    "${VERIFYBAMID_OUTDIR}"

cmd=(
    nextflow run "${VERIFYBAMID_WORKFLOW}"
    -profile "${PROFILE}"
    -c "${NEXTFLOW_CONFIG}"
    -params-file "${VERIFYBAMID_PARAMS}"
    --outdir "${VERIFYBAMID_OUTDIR}"
    -resume
)

printf 'Running:'
printf ' %q' "${cmd[@]}"
printf '\n'

"${cmd[@]}"
