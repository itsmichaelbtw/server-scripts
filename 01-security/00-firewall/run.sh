#!/usr/bin/env bash
# File path: 01-security/00-firewall/run.sh
# Purpose: Configure and enable the UFW firewall with basic hardening.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="00-firewall"
SCRIPT_DESC="Configure UFW firewall rules and enable firewall with basic hardening."

print_script_header
validate_environment

prompt_for_port "Enter SSH port used by the server" 22
SSH_PORT="$PORT_REPLY"

prompt_yes_no "Allow HTTP (port 80)?" "N"
if [[ "$REPLY" == "Y" ]]; then
  ALLOW_HTTP="true"
else
  ALLOW_HTTP="false"
fi

prompt_yes_no "Allow HTTPS (port 443)?" "N"
if [[ "$REPLY" == "Y" ]]; then
  ALLOW_HTTPS="true"
else
  ALLOW_HTTPS="false"
fi

read_from_terminal -rp "Enter any additional ports to allow (comma-separated, or leave blank): " EXTRA_PORTS_RAW
IFS=',' read -ra EXTRA_PORTS <<< "${EXTRA_PORTS_RAW}"

echo_newline
echo_yellow "Installing UFW if not installed..."
apt install -y ufw

echo_yellow "Resetting existing UFW rules..."
ufw --force reset

echo_yellow "Setting default policies..."
ufw default deny incoming
ufw default allow outgoing

echo_yellow "Allowing SSH port ${SSH_PORT}..."
ufw allow "${SSH_PORT}/tcp"

if [[ "$ALLOW_HTTP" == "true" ]]; then
  echo_yellow "Allowing HTTP (port 80)..."
  ufw allow 80/tcp
fi

if [[ "$ALLOW_HTTPS" == "true" ]]; then
  echo_yellow "Allowing HTTPS (port 443)..."
  ufw allow 443/tcp
fi

for PORT in "${EXTRA_PORTS[@]}"; do
  PORT_CLEAN="$(echo "$PORT" | xargs)"
  if [[ -n "$PORT_CLEAN" ]]; then
    if [[ "$PORT_CLEAN" =~ ^[0-9]+$ ]] && (( PORT_CLEAN >= 1 && PORT_CLEAN <= 65535 )); then
      echo_yellow "Allowing additional port ${PORT_CLEAN}..."
      ufw allow "${PORT_CLEAN}/tcp"
    else
      echo_red "Skipping invalid port: ${PORT_CLEAN}"
    fi
  fi
done

echo_yellow "Applying UFW hardening rules..."
ufw logging on
ufw limit "${SSH_PORT}/tcp"

echo_yellow "Enabling firewall..."
ufw --force enable

echo_newline
echo_green "Firewall configuration complete."
echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
