#!/usr/bin/env bash
# File path: 01-security/00-firewall/run.sh
# Purpose: Configure and enable the UFW firewall with basic hardening.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="03-firewall"
SCRIPT_DESC="Configure UFW firewall rules and enable firewall with basic hardening."

echo -e "\n${BLUE}Running script: ${SCRIPT_NAME}${RESET}"
echo -e "${BLUE}Description: ${SCRIPT_DESC}${RESET}\n"

validate_environment

while true; do
  read -rp "Enter SSH port used by the server (default 22): " SSH_PORT
  SSH_PORT="${SSH_PORT:-22}"

  if [[ "$SSH_PORT" =~ ^[0-9]+$ ]] && (( SSH_PORT >= 1 && SSH_PORT <= 65535 )); then
    break
  else
    echo -e "${RED}Invalid port. Must be an integer 1–65535.${RESET}"
  fi
done

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

read -rp "Enter any additional ports to allow (comma-separated, or leave blank): " EXTRA_PORTS_RAW
IFS=',' read -ra EXTRA_PORTS <<< "${EXTRA_PORTS_RAW}"

echo -e "\n${YELLOW}Installing UFW if not installed...${RESET}"
apt install -y ufw

echo -e "${YELLOW}Resetting existing UFW rules...${RESET}"
ufw --force reset

echo -e "${YELLOW}Setting default policies...${RESET}"
ufw default deny incoming
ufw default allow outgoing

echo -e "${YELLOW}Allowing SSH port ${SSH_PORT}...${RESET}"
ufw allow "${SSH_PORT}/tcp"

if [[ "$ALLOW_HTTP" == "true" ]]; then
  echo -e "${YELLOW}Allowing HTTP (port 80)...${RESET}"
  ufw allow 80/tcp
fi

if [[ "$ALLOW_HTTPS" == "true" ]]; then
  echo -e "${YELLOW}Allowing HTTPS (port 443)...${RESET}"
  ufw allow 443/tcp
fi

for PORT in "${EXTRA_PORTS[@]}"; do
  PORT_CLEAN="$(echo "$PORT" | xargs)"
  if [[ -n "$PORT_CLEAN" ]]; then
    if [[ "$PORT_CLEAN" =~ ^[0-9]+$ ]] && (( PORT_CLEAN >= 1 && PORT_CLEAN <= 65535 )); then
      echo -e "${YELLOW}Allowing additional port ${PORT_CLEAN}...${RESET}"
      ufw allow "${PORT_CLEAN}/tcp"
    else
      echo -e "${RED}Skipping invalid port: ${PORT_CLEAN}${RESET}"
    fi
  fi
done

echo -e "${YELLOW}Applying UFW hardening rules...${RESET}"
ufw logging on
ufw limit "${SSH_PORT}/tcp"

echo -e "${YELLOW}Enabling firewall...${RESET}"
ufw --force enable

echo -e "\n${GREEN}✓ Firewall configuration complete.${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
