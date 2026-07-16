#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)

cd "${PROJECT_ROOT}"

mkdir -p logs

JOB_ID=$(
    sbatch \
        --parsable \
        --chdir="${PROJECT_ROOT}" \
        scripts/run_verifybamid.sbatch
)

JOB_ID="${JOB_ID%%;*}"

echo "Submitted VerifyBamID job: ${JOB_ID}"
echo "Follow output:"
echo "  tail -f logs/verifybamid-${JOB_ID}.out"
echo "  tail -f logs/verifybamid-${JOB_ID}.err"
