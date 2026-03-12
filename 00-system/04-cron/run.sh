#!/usr/bin/env bash
# File path: 00-system/04-cron/run.sh
# Purpose: Ensure cron service is enabled, started, and running on the system.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="04-cron"
SCRIPT_DESC="Ensure cron service is installed, enabled, and running."

print_script_header
validate_environment

if ! dpkg -l | grep -q cron; then
  echo_yellow "Cron not found. Installing..."
  apt update -y
  apt install -y cron
fi

echo_yellow "Enabling cron service..."
systemctl enable cron

echo_yellow "Starting cron service..."
systemctl restart cron

if systemctl is-active --quiet cron; then
  echo_green "Cron service is running."
else
  echo_red "Cron service is not running."
fi

echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
