#!/usr/bin/env bash
# File path: 04-monitoring/01-process-tools/run.sh
# Purpose: Install system and process monitoring utilities (htop, atop, glances).

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="01-process-tools"
SCRIPT_DESC="Install htop, atop, and glances for system process and performance monitoring."

print_script_header
validate_environment

echo_yellow "Installing process monitoring tools..."
echo_newline

prompt_yes_no "Do you want to install htop?" "Y"
if [[ "$REPLY" == "Y" ]]; then
  apt update -y
  apt install -y htop
  echo_yellow "Verifying htop installation..."
  htop --version
  echo_green "htop installed and verified successfully"
else
  echo_yellow "htop installation skipped"
fi
echo_newline

prompt_yes_no "Do you want to install atop?" "Y"
if [[ "$REPLY" == "Y" ]]; then
  apt update -y
  apt install -y atop
  echo_yellow "Verifying atop installation..."
  atop -V
  echo_yellow "Enabling atop service for boot logging..."
  systemctl enable atop
  systemctl restart atop
  echo_green "atop installed, verified, and enabled successfully"
else
  echo_yellow "atop installation skipped"
fi
echo_newline

prompt_yes_no "Do you want to install glances?" "Y"
if [[ "$REPLY" == "Y" ]]; then
  apt update -y
  apt install -y python3-pip
  pip3 install --upgrade glances
  echo_yellow "Verifying glances installation..."
  glances -V
  echo_green "glances installed and verified successfully"
else
  echo_yellow "glances installation skipped"
fi
echo_newline

echo_green "Process monitoring tools installed and configured."
echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
