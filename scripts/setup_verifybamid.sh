#!/usr/bin/env bash
set -euo pipefail

# Directories
SAREK_DIR="results/sarek"
OUTDIR="results/verifybamid"

# Sample
SAMPLE_ID="S001"

# Files generated or used by Sarek
SAREK_ALIGNMENT="${SAREK_DIR}/preprocessing/recalibrated/${SAMPLE_ID}/${SAMPLE_ID}.recal.cram"
SAREK_ALIGNMENT_INDEX="${SAREK_ALIGNMENT}.crai"

SAREK_REFERENCE="${SAREK_DIR}/reference/genome/Homo_sapiens_assembly38.fasta"
SAREK_REFERENCE_INDEX="${SAREK_REFERENCE}.fai"

# VerifyBamID2 directories
INPUT_DIR="${OUTDIR}/input"
REFERENCE_DIR="${OUTDIR}/reference"
SVD_DIR="${REFERENCE_DIR}/verifybamid2"

# Destination files
ALIGNMENT="${INPUT_DIR}/${SAMPLE_ID}.recal.cram"
ALIGNMENT_INDEX="${INPUT_DIR}/${SAMPLE_ID}.recal.cram.crai"

REFERENCE="${REFERENCE_DIR}/Homo_sapiens_assembly38.fasta"
REFERENCE_INDEX="${REFERENCE_DIR}/Homo_sapiens_assembly38.fasta.fai"

# VerifyBamID2 GRCh38 reference panel
SVD_NAME="1000g.phase3.100k.b38.vcf.gz.dat"
SVD_URL="https://raw.githubusercontent.com/Griffan/VerifyBamID/master/resource"

# Check input files
for FILE in \
    "${SAREK_ALIGNMENT}" \
    "${SAREK_ALIGNMENT_INDEX}" \
    "${SAREK_REFERENCE}" \
    "${SAREK_REFERENCE_INDEX}"
do
    if [[ ! -f "${FILE}" ]]; then
        printf 'ERROR: File not found: %s\n' "${FILE}" >&2
        exit 1
    fi
done

if ! command -v curl >/dev/null 2>&1; then
    printf 'ERROR: curl is not available.\n' >&2
    exit 1
fi

# Create directories
mkdir -p \
    "${INPUT_DIR}" \
    "${REFERENCE_DIR}" \
    "${SVD_DIR}"

# Copy Sarek files
printf 'Copying alignment...\n'

cp -L -f \
    "${SAREK_ALIGNMENT}" \
    "${ALIGNMENT}"

cp -L -f \
    "${SAREK_ALIGNMENT_INDEX}" \
    "${ALIGNMENT_INDEX}"

printf 'Copying reference genome...\n'

cp -L -f \
    "${SAREK_REFERENCE}" \
    "${REFERENCE}"

cp -L -f \
    "${SAREK_REFERENCE_INDEX}" \
    "${REFERENCE_INDEX}"

# Download VerifyBamID2 resources
printf 'Downloading VerifyBamID2 reference panel...\n'

for SUFFIX in UD mu bed V; do
    OUTPUT_FILE="${SVD_DIR}/${SVD_NAME}.${SUFFIX}"

    if [[ -s "${OUTPUT_FILE}" ]]; then
        printf 'Already present: %s\n' "${OUTPUT_FILE}"
        continue
    fi

    curl \
        --fail \
        --location \
        --retry 3 \
        --output "${OUTPUT_FILE}" \
        "${SVD_URL}/${SVD_NAME}.${SUFFIX}"
done

printf '\nVerifyBamID2 setup complete.\n'
printf 'Alignment:  %s\n' "${ALIGNMENT}"
printf 'Index:      %s\n' "${ALIGNMENT_INDEX}"
printf 'Reference:  %s\n' "${REFERENCE}"
printf 'SVD prefix: %s/%s\n' "${SVD_DIR}" "${SVD_NAME}"
