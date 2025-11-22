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

echo -e "${YELLOW}Scanning for run.sh files in: ${ROOT_DIR}${RESET}"

find "$ROOT_DIR" -type f -name "run.sh" | while read -r FILE; do
	REL_PATH="${FILE#$ROOT_DIR/}"
	echo -e "${BLUE}Making executable: ${REL_PATH}${RESET}"
	if chmod +x "$FILE"; then
		echo -e "${GREEN}✓ Now executable${RESET}"
	else
		echo -e "${RED}[ERROR] Failed to chmod: $REL_PATH${RESET}"
	fi
done

echo -e "\n${GREEN}✓ All run.sh files are now executable.${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
