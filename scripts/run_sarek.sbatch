#!/usr/bin/env bash
#SBATCH --job-name=sarek
#SBATCH --output=logs/sarek-%j.out
#SBATCH --error=logs/sarek-%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=16G
#SBATCH --time=48:00:00
#SBATCH --qos=3d


set -euo pipefail

if [[ -f .env ]]; then
    # shellcheck disable=SC1091
    source .env
fi

SAREK_VERSION="${SAREK_VERSION:-3.9.0}"
PROFILE="${PROFILE:-apptainer}"
NEXTFLOW_CONFIG="${NEXTFLOW_CONFIG:-config/nextflow.example.config}"

export NXF_OPTS="${NXF_OPTS:--Xms1g -Xmx4g}"

if [[ -n "${NXF_APPTAINER_CACHEDIR:-}" ]]; then
    export NXF_APPTAINER_CACHEDIR
    mkdir -p "${NXF_APPTAINER_CACHEDIR}"
fi

if [[ -n "${NXF_SINGULARITY_CACHEDIR:-}" ]]; then
    export NXF_SINGULARITY_CACHEDIR
    mkdir -p "${NXF_SINGULARITY_CACHEDIR}"
fi

if [[ ! -f "${NEXTFLOW_CONFIG}" ]]; then
    echo "Missing Nextflow config: ${NEXTFLOW_CONFIG}" >&2
    echo "Create it with:" >&2
    echo "  cp config/nextflow.example.config config/nextflow.local.config" >&2
    echo "Then edit config/nextflow.local.config." >&2
    exit 1
fi

mkdir -p results

cmd=(
    nextflow run nf-core/sarek
    -r "${SAREK_VERSION}"
    -profile "${PROFILE}"
    -c "${NEXTFLOW_CONFIG}"
    -params-file config/sarek.params.yaml
    -resume
)

if [[ -n "${VEP_CACHE:-}" ]]; then
    cmd+=(--vep_cache "${VEP_CACHE}")
fi

if [[ -n "${SNPEFF_CACHE:-}" ]]; then
    cmd+=(--snpeff_cache "${SNPEFF_CACHE}")
fi

if [[ -n "${OUTDIR_CACHE:-}" ]]; then
    cmd+=(--outdir_cache "${OUTDIR_CACHE}")
fi

if [[ "${DOWNLOAD_CACHE:-false}" == "true" ]]; then
    cmd+=(--download_cache)
fi

if [[ -n "${IGENOMES_BASE:-}" ]]; then
    cmd+=(--igenomes_base "${IGENOMES_BASE}")
fi

printf '%q ' "${cmd[@]}"
printf '\n'

"${cmd[@]}"
