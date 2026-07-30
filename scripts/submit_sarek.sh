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
        scripts/run_sarek.sbatch
)

JOB_ID="${JOB_ID%%;*}"

echo "Submitted Sarek job: ${JOB_ID}"
echo "Follow output:"
echo "  tail -f logs/sarek-${JOB_ID}.out"
echo "  tail -f logs/sarek-${JOB_ID}.err"
