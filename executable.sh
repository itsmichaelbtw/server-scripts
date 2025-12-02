#!/usr/bin/env bash
# File path: executable.sh
# Purpose: Make all run.sh files in the project executable (chmod +x), cross-platform.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="executable"
SCRIPT_DESC="Make all run.sh files in the project executable (chmod +x)"

print_script_header

ROOT_DIR="$(pwd)"

echo_yellow "Scanning for run.sh files in: ${ROOT_DIR}"

find "$ROOT_DIR" -type f -name "run.sh" | while read -r FILE; do
	REL_PATH="${FILE#$ROOT_DIR/}"
	echo_blue "Making executable: ${REL_PATH}"
	if chmod +x "$FILE"; then
		echo_green "Now executable"
	else
		echo_red "[ERROR] Failed to chmod: $REL_PATH"
	fi
done

echo_green "\nAll run.sh files are now executable."
echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
