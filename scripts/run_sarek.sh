#!/usr/bin/env bash
set -euo pipefail

if [[ -f .env ]]; then
    # shellcheck disable=SC1091
    source .env
fi

SAREK_VERSION="${SAREK_VERSION:-3.9.0}"
PROFILE="${PROFILE:-apptainer}"
SLURM_CONFIG="${SLURM_CONFIG:-config/slurm.example.config}"

export NXF_OPTS="${NXF_OPTS:--Xms1g -Xmx4g}"

if [[ ! -f "${SLURM_CONFIG}" ]]; then
    echo "Missing Slurm config: ${SLURM_CONFIG}" >&2
    echo "Create it with:" >&2
    echo "  cp config/slurm.example.config config/slurm.local.config" >&2
    echo "Then edit config/slurm.local.config for your cluster." >&2
    exit 1
fi

mkdir -p results

cmd=(
    nextflow run nf-core/sarek
    -r "${SAREK_VERSION}"
    -profile "${PROFILE}"
    -c "${SLURM_CONFIG}"
    -params-file config/sarek.params.yaml
    -resume
)

if [[ -n "${IGENOMES_BASE:-}" ]]; then
    cmd+=(--igenomes_base "${IGENOMES_BASE}")
fi

printf '%q ' "${cmd[@]}"
printf '\n'

"${cmd[@]}"
