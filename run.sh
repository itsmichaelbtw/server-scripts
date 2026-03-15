#!/usr/bin/env bash
# File path: run.sh
# Purpose: Top-level wrapper to sequentially run all category module scripts.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR="$SCRIPT_DIR"
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="run"
SCRIPT_DESC="Top-level wrapper to sequentially run all category modules"

print_script_header
validate_environment

echo_blue "Searching for category modules..."
echo_newline

MODULES=$(find "$SCRIPT_DIR" -mindepth 2 -maxdepth 2 -name "run.sh" | sort)

if [[ -z "$MODULES" ]]; then
  echo_red "No category modules found."
  exit 1
fi

echo_blue "Found the following category modules:"
while IFS= read -r file; do
  REL_PATH="${file#$SCRIPT_DIR/}"
  echo_yellow "  - $REL_PATH"
done <<< "$MODULES"
echo_newline

while IFS= read -r file; do
  REL_PATH="${file#$SCRIPT_DIR/}"
  prompt_yes_no "Run '$REL_PATH'?" "Y"
  if [[ "$REPLY" == "Y" ]]; then
    echo_yellow "Executing $REL_PATH..."
    set +e
    bash "$file"
    EXIT_CODE=$?
    set -e
    if [[ $EXIT_CODE -ne 0 ]]; then
      echo_yellow "Warning: $REL_PATH exited with status $EXIT_CODE, continuing..."
    fi
  else
    echo_yellow "Skipping $REL_PATH."
  fi
  echo_newline
done <<< "$MODULES"

echo_green "All category modules complete."
