#!/usr/bin/env bash
# common.sh
# Shared functions for system provisioning scripts

set -euo pipefail

GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
RED="\033[1;31m"
RESET="\033[0m"

ensure_root() {
  if [[ "$EUID" -ne 0 ]]; then
    echo -e "${RED}[ERROR] This script must be run as root.${RESET}"
    echo "Try: sudo $0"
    exit 1
  fi
}

ensure_ubuntu() {
  if ! grep -qi "ubuntu" /etc/os-release; then
    echo -e "${RED}[ERROR] This script is intended for Ubuntu systems only.${RESET}"
    exit 1
  fi
}

validate_environment() {
  ensure_root
  ensure_ubuntu
  echo -e "${GREEN}✓ Environment validated.${RESET}"
}

display_service_url() {
  local service_name="$1"
  local port="$2"
  
  local server_ip
  server_ip=$(ip route get 1 | awk '{print $7; exit}')

  echo -e "${GREEN}✓ $service_name deployed successfully.${RESET}"
  echo -e "${YELLOW}Access the service at: http://$server_ip:$port${RESET}"
}
