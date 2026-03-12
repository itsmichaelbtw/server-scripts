#!/usr/bin/env bash
# Top-level wrapper: execute the run.sh in the first child directory

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR="$SCRIPT_DIR"
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="run"
SCRIPT_DESC="Top-level wrapper to run the first module"

print_script_header
validate_environment

echo_yellow "Locating first child directory..."

FIRST_DIR=""
for d in "$SCRIPT_DIR"/*/; do
  if [[ -d "$d" ]]; then
    FIRST_DIR="$d"
    break
  fi
done

if [[ -z "$FIRST_DIR" ]]; then
  echo_red "No child directories found in $SCRIPT_DIR"
  exit 1
fi

echo_green "Found first directory: ${FIRST_DIR%/}"

CHILD_RUN="$FIRST_DIR/run.sh"

if [[ -f "$CHILD_RUN" && -x "$CHILD_RUN" ]]; then
  echo_yellow "Executing: $CHILD_RUN"
  exec "$CHILD_RUN" "$@"
elif [[ -f "$CHILD_RUN" ]]; then
  echo_yellow "Found $CHILD_RUN but it is not executable — running with bash"
  bash "$CHILD_RUN" "$@"
else
  echo_red "No run.sh found in first directory: $FIRST_DIR"
  exit 1
fi
