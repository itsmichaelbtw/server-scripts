#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="path"
SCRIPT_DESC="Update SCRIPT_NAME and SCRIPT_DIR variables in all run.sh files"

print_script_header

ROOT_DIR="$(pwd)"

if is_macos; then
  SED_INPLACE() { sed -i '' "$@"; }
else
  SED_INPLACE() { sed -i "$@"; }
fi

echo_yellow "Scanning for run.sh files in: ${ROOT_DIR}"

find "$ROOT_DIR" -type f -name "run.sh" | while read -r FILE; do
  REL_PATH="${FILE#$ROOT_DIR/}"
  DIR_NAME="$(basename "$(dirname "$FILE")")"

  echo_blue "Updating: ${REL_PATH}"

  SED_INPLACE "s|^SCRIPT_DIR=.*|SCRIPT_DIR=\$(dirname \"\$(realpath \"\$0\")\")|" "$FILE"
  SED_INPLACE "s|^SCRIPT_NAME=.*|SCRIPT_NAME=\"$DIR_NAME\"|" "$FILE"
  
  echo_green "Updated $REL_PATH"

done

echo_green "\nAll run.sh files updated successfully."
echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
