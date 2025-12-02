#!/usr/bin/env bash
# File path: 01-security/08-lynis/run.sh
# Purpose: Install Lynis, perform an initial security audit, and optionally schedule via CRON.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="08-lynis"
SCRIPT_DESC="Install Lynis, run an initial security audit, and optionally schedule via CRON."

print_script_header
validate_environment

echo_yellow "Installing Lynis..."
apt update -y
apt install -y lynis

LYNIS_LOG="/var/log/lynis.log"

prompt_yes_no "Run initial Lynis security audit now? (This may take several minutes)" "Y"
if [[ "$REPLY" == "Y" ]]; then
  echo_yellow "Running initial Lynis security audit..."
  if lynis audit system | tee "$LYNIS_LOG" 2>&1; then
    echo_green "✓ Lynis audit complete. Results saved to ${LYNIS_LOG}."
  else
    echo_yellow "[WARNING] Lynis audit encountered an error, but continuing with the rest of the script..."
  fi
else
  echo_yellow "Lynis audit skipped. You can run it manually later with: sudo lynis audit system"
fi

setup_cron_job "lynis audit system | tee -a $LYNIS_LOG" "0 4 * * *"

echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
