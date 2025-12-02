#!/usr/bin/env bash
# File path: 01-security/07-chkrootkit/run.sh
# Purpose: Install Chkrootkit, run initial rootkit scan, and optionally schedule via CRON.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="07-chkrootkit"
SCRIPT_DESC="Install Chkrootkit, run initial rootkit scan, and optionally schedule via CRON."

print_script_header
validate_environment

echo_yellow "Installing chkrootkit..."
apt update -y
apt install -y chkrootkit

CHK_LOG="/var/log/chkrootkit.log"

prompt_yes_no "Run initial Chkrootkit scan now? (This may take several minutes)" "Y"
if [[ "$REPLY" == "Y" ]]; then
  echo_yellow "Running initial Chkrootkit scan..."
  if chkrootkit | tee "$CHK_LOG" 2>&1; then
    echo_green "✓ Chkrootkit scan complete. Results saved to ${CHK_LOG}."
  else
    echo_yellow "[WARNING] Chkrootkit scan encountered an error, but continuing with the rest of the script..."
  fi
else
  echo_yellow "Chkrootkit scan skipped. You can run it manually later with: sudo chkrootkit"
fi

# this failed for some reason
# ✓ Chkrootkit scan complete. Results saved to /var/log/chkrootkit.log.
# Do you want to schedule this job via CRON? [Y/n]: y
# Enter CRON schedule (minute hour day month day_of_week) or leave empty for default (0 3 * * *): 
# Warning: 07-chkrootkit/run.sh exited with status 1, continuing...
setup_cron_job "chkrootkit | tee -a $CHK_LOG" "0 3 * * *"

echo_green "Script ${SCRIPT_NAME} finished successfully.\n" 
