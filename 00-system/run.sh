#!/usr/bin/env bash
# File path: 00-system/run.sh
# Purpose: Run all system initialization and setup scripts

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="00-system"
SCRIPT_DESC="Run all system initialization and configuration scripts"

print_script_header
validate_environment
find_and_run_scripts "$SCRIPT_DIR"

echo -e "\n${GREEN}✓ System initialization complete.${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
