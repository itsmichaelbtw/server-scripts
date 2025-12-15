#!/usr/bin/env bash
# File path: 01-security/06-rkhunter/run.sh
# Purpose: Install RKHunter, configure it, run initial rootkit scan, and optionally schedule via CRON (using default bundled database).

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="06-rkhunter"
SCRIPT_DESC="Install RKHunter, configure it, run initial rootkit scan, and optionally schedule via CRON using the default database."

print_script_header
validate_environment

echo_yellow "Installing RKHunter..."
apt update -y
apt install -y rkhunter

if [[ ! -f /etc/rkhunter.conf ]]; then
  echo_yellow "RKHunter config missing, restoring default..."
  apt install --reinstall -y rkhunter
fi

mkdir -p /var/lib/rkhunter/db
chown root:root /var/lib/rkhunter/db
chmod 755 /var/lib/rkhunter/db

prompt_yes_no "Run initial RKHunter scan now? (This may take several minutes)" "Y"
if [[ "$REPLY" == "Y" ]]; then
  echo_yellow "Running initial RKHunter scan using the default bundled database..."
  if rkhunter --propupd 2>&1 && rkhunter --check --skip-keypress 2>&1; then
    echo_green "RKHunter installation, configuration, and initial scan complete."
  else
    echo_yellow "[WARNING] RKHunter scan encountered an error, but continuing with the rest of the script..."
  fi
else
  echo_yellow "RKHunter scan skipped. You can run it manually later with: sudo rkhunter --check"
fi

setup_cron_job "sudo rkhunter --propupd && sudo rkhunter --check --skip-keypress" "30 2 * * *" "rkhunter"

echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
