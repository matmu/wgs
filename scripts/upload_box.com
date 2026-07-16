#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# box_upload.sh — Upload one or more files/folders to Box via FTPS using lftp
#
# Requirements:
#   - lftp installed
#
# ---------------------------------------------------------------------------
# STEP 1 — Identify destination path on Box (interactive, once)
#
#   lftp
#   lftp :~> set ftps:initial-prot ""
#   lftp :~> set ftp:ssl-force true
#   lftp :~> set ftp:ssl-protect-data true
#   lftp :~> set ftp:passive-mode true
#   lftp :~> open ftps://ftp.box.com:990
#   lftp ftp.box.com:~> user someone@example.com
#   Password:
#   lftp someone@example.com@ftp.box.com:/> ls
#
# Navigate into the destination folder using `cd` + `ls`, then run:
#   lftp ...> pwd
#
# Example `pwd` output (URL-encoded spaces etc. are normal):
#   ftps://someone%40example.com@ftp.box.com:990/Shared%20Folder/Partner%20Uploads
#
# Configure the destination in this script with EXACTLY ONE of:
#   - REMOTE_CD_PATH : decoded path you can `cd` into (recommended), e.g.
#       /Shared Folder/Partner Uploads
#   - REMOTE_FTPS_URL: full ftps://... URL from `pwd` (often URL-encoded)
#
# IMPORTANT:
#   - Do NOT use `pwd -p` (it can include the password in the URL).
#
# ---------------------------------------------------------------------------
# Usage:
#   export BOX_USER="someone@example.com"
#   export BOX_PASSWORD="your_password"     # or omit to be prompted
#
#   # Choose one destination method:
#   export REMOTE_CD_PATH="/Shared Folder/Partner Uploads"
#   # OR:
#   # export REMOTE_FTPS_URL="ftps://someone%40example.com@ftp.box.com:990/Shared%20Folder/Partner%20Uploads"
#
#   ./box_upload.sh ITEM [ITEM2 ...]
#
# Notes:
#   - ITEM can be a file or a folder.
#   - Folders are uploaded into a same-named folder on Box.
###############################################################################

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 ITEM [ITEM2 ...]   (each ITEM can be a file or folder)"
  exit 1
fi

: "${BOX_USER:?ERROR: Please export BOX_USER (e.g., someone@example.com)}"

if [[ -z "${BOX_PASSWORD:-}" ]]; then
  read -r -s -p "Box password for ${BOX_USER}: " BOX_PASSWORD
  echo
fi

# Destination: provide exactly one
REMOTE_METHOD_COUNT=0
if [[ -n "${REMOTE_CD_PATH:-}" ]]; then REMOTE_METHOD_COUNT=$((REMOTE_METHOD_COUNT+1)); fi
if [[ -n "${REMOTE_FTPS_URL:-}" ]]; then REMOTE_METHOD_COUNT=$((REMOTE_METHOD_COUNT+1)); fi
if [[ "$REMOTE_METHOD_COUNT" -ne 1 ]]; then
  echo "ERROR: Provide exactly ONE destination:"
  echo "  export REMOTE_CD_PATH=\"/Decoded/Target/Path\""
  echo "  OR"
  echo "  export REMOTE_FTPS_URL=\"ftps://.../url-encoded/path\""
  exit 2
fi

# Helper: absolute path without requiring realpath
abspath() {
  local p="$1"
  if [[ "$p" = /* ]]; then
    printf '%s\n' "$p"
  else
    printf '%s\n' "$PWD/$p"
  fi
}

# Validate + collect absolute paths
ABS_ITEMS=()
for item in "$@"; do
  if [[ ! -e "$item" ]]; then
    echo "ERROR: Not found: $item"
    exit 3
  fi
  ABS_ITEMS+=("$(abspath "$item")")
done

BASE_URL="ftps://ftp.box.com:990"
TARGET_URL="${REMOTE_FTPS_URL:-$BASE_URL}"

# Create a temporary lftp command file (safer than complex nested quoting)
LFTP_CMDS="$(mktemp)"
trap 'rm -f "$LFTP_CMDS"' EXIT

{
  echo "set cmd:fail-exit true"
  echo "set cmd:interactive false"
  echo "set ftp:passive-mode true"
  echo "set ftp:ssl-force true"
  echo "set ftp:ssl-protect-data true"
  echo "set ftps:initial-prot \"\""
  echo
  # Avoid permission preservation attempts (prevents SITE CHMOD errors on Box)
  echo "set mirror:set-permissions off"
  echo

  # Connect (URL passed on lftp command line), then optionally cd
  if [[ -n "${REMOTE_CD_PATH:-}" ]]; then
    echo "cd \"${REMOTE_CD_PATH}\""
  fi

  # Safe logging (no pwd output)
  echo "ls"
  echo

  for abs_item in "${ABS_ITEMS[@]}"; do
    if [[ -d "$abs_item" ]]; then
      base="$(basename "$abs_item")"
      echo "mkdir -p \"${base}\""
      # --no-perms stops chmod attempts; --no-umask avoids permission munging
      echo "mirror -R --continue --only-newer --verbose --no-perms --no-umask \"${abs_item}\" \"${base}\""
    else
      echo "put -c -- \"${abs_item}\""
    fi
    echo
  done

  echo "bye"
} > "$LFTP_CMDS"

# Your lftp does NOT support -f, so source the file via -e
lftp -u "${BOX_USER},${BOX_PASSWORD}" "${TARGET_URL}" -e "source ${LFTP_CMDS}"

echo "Upload complete."
