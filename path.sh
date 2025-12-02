#!/usr/bin/env bash
# File path: path.sh
# Purpose: Cross-platform script (macOS + Linux) to update "# File path:" in all run.sh files.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="path"
SCRIPT_DESC="Update file paths and script names in all run.sh files"

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

  NEW_FILEPATH_LINE="# File path: $REL_PATH"
  SED_INPLACE "2s|.*|$NEW_FILEPATH_LINE|" "$FILE"
  SED_INPLACE "s|^SCRIPT_NAME=\".*\"|SCRIPT_NAME=\"$DIR_NAME\"|" "$FILE"
  
  echo_green "Updated"

done

echo_green "\nAll run.sh files updated successfully."
echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
