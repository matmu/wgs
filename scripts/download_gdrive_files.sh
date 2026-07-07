#!/usr/bin/env bash
set -euo pipefail

if [[ -f .env ]]; then
    # shellcheck disable=SC1091
    source .env
fi

DOWNLOAD_DIR="${DOWNLOAD_DIR:-fastq}"
MANIFEST="${FASTQ_MANIFEST:-config/fastqs.local.tsv}"

mkdir -p "${DOWNLOAD_DIR}"

if [[ ! -f "${MANIFEST}" ]]; then
    echo "Missing FASTQ manifest: ${MANIFEST}" >&2
    exit 1
fi

download_one() {
    local file_id="$1"
    local out_name="$2"
    local out_path="${DOWNLOAD_DIR}/${out_name}"
    local tmp_html

    if [[ -f "${out_path}" ]]; then
        if gzip -t "${out_path}" 2>/dev/null; then
            echo "Skipping existing valid file: ${out_path}"
            return 0
        else
            echo "Existing file is not valid gzip, removing: ${out_path}"
            rm -f "${out_path}"
        fi
    fi

    tmp_html="$(mktemp)"

    echo "Requesting Google Drive file: ${out_name}"

    wget -q \
        "https://drive.google.com/uc?export=download&id=${file_id}" \
        -O "${tmp_html}"

    if grep -qi "Quota exceeded\|Too many users have viewed or downloaded" "${tmp_html}"; then
        echo "ERROR: Google Drive quota exceeded for ${out_name}" >&2
        echo "Try again later, or copy the file to another Drive location and use the new file ID." >&2
        rm -f "${tmp_html}"
        exit 1
    fi

    local confirm
    local uuid

    confirm="$(sed -n 's/.*name="confirm" value="\([^"]*\)".*/\1/p' "${tmp_html}" | head -n 1)"
    uuid="$(sed -n 's/.*name="uuid" value="\([^"]*\)".*/\1/p' "${tmp_html}" | head -n 1)"

    if [[ -n "${confirm}" && -n "${uuid}" ]]; then
        echo "Downloading large file with confirmation token: ${out_name}"

        wget -c \
            "https://drive.usercontent.google.com/download?id=${file_id}&export=download&confirm=${confirm}&uuid=${uuid}" \
            -O "${out_path}"
    else
        echo "Downloading file: ${out_name}"

        wget -c \
            "https://drive.google.com/uc?export=download&id=${file_id}" \
            -O "${out_path}"
    fi

    rm -f "${tmp_html}"

    if file "${out_path}" | grep -qi "HTML"; then
        echo "ERROR: ${out_path} looks like HTML, not FASTQ." >&2
        echo "Removing failed download." >&2
        rm -f "${out_path}"
        exit 1
    fi

    gzip -t "${out_path}"

    echo "OK: ${out_path}"
}

tail -n +2 "${MANIFEST}" | while IFS=$'\t' read -r file_id out_name; do
    [[ -z "${file_id}" ]] && continue
    [[ "${file_id}" =~ ^[[:space:]]*# ]] && continue

    if [[ -z "${out_name:-}" ]]; then
        echo "Missing output filename for file_id=${file_id}" >&2
        exit 1
    fi

    download_one "${file_id}" "${out_name}"
done
