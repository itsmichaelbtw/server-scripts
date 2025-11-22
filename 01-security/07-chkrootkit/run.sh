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
echo_yellow "Running initial Chkrootkit scan..."
chkrootkit | tee "$CHK_LOG"

echo_green "✓ Chkrootkit scan complete. Results saved to ${CHK_LOG}."

setup_cron_job "chkrootkit | tee -a $CHK_LOG" "0 3 * * *"

echo_green "Script ${SCRIPT_NAME} finished successfully.\n" 
