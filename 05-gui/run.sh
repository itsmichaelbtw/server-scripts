#!/usr/bin/env bash
# File path: 05-gui/run.sh
# Purpose: Master script to search and optionally execute all run.sh files in this directory tree.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="05-gui"
SCRIPT_DESC="Master script to find and optionally run all run.sh scripts in this directory tree."

print_script_header
validate_environment
execute_run_sh
