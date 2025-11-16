#!/usr/bin/env bash
# common.sh
# Shared functions for system provisioning scripts

set -euo pipefail

GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
RED="\033[1;31m"
RESET="\033[0m"

# Function to check if script is run with root privileges
# Usage: ensure_root
# Exits with error message if not run as root
ensure_root() {
  if [[ "$EUID" -ne 0 ]]; then
    echo -e "${RED}[ERROR] This script must be run as root.${RESET}"
    echo "Try: sudo $0"
    exit 1
  fi
}

# Function to verify the system is running Ubuntu
# Usage: ensure_ubuntu
# Exits with error message if not running on Ubuntu
ensure_ubuntu() {
  if ! grep -qi "ubuntu" /etc/os-release; then
    echo -e "${RED}[ERROR] This script is intended for Ubuntu systems only.${RESET}"
    exit 1
  fi
}

# Function to validate the execution environment
# Usage: validate_environment
# Ensures script is run as root on an Ubuntu system
validate_environment() {
  ensure_root
  ensure_ubuntu
  echo -e "${GREEN}✓ Environment validated.${RESET}"
}

# Function to display service URL after deployment
# Usage: display_service_url "Service Name" port_number
# Determines server IP and displays formatted access URL
display_service_url() {
  local service_name="$1"
  local port="$2"
  
  local server_ip
  server_ip=$(ip route get 1 | awk '{print $7; exit}')

  echo -e "${GREEN}✓ $service_name deployed successfully.${RESET}"
  echo -e "${YELLOW}Access the service at: http://$server_ip:$port${RESET}"
}

# Function to prompt user for yes/no input
# Usage: prompt_yes_no "Do you want to enable feature X?" [Y|N]
# Returns: Uppercase Y or N in the variable $REPLY
prompt_yes_no() {
  local prompt="$1"
  local default="${2:-Y}"
  local valid_default="${default^^}"
  
  if [[ "$valid_default" != "Y" && "$valid_default" != "N" ]]; then
    valid_default="Y"
  fi
  
  local prompt_text="$prompt [$([[ $valid_default == Y ]] && echo "Y/n" || echo "y/N")]: "
  
  while true; do
    read -rp "$prompt_text" REPLY
    REPLY=${REPLY:-$valid_default}
    case "${REPLY^^}" in
      Y|N) REPLY="${REPLY^^}"; break ;;
      *) echo -e "${YELLOW}Please enter Y or N.${RESET}" ;;
    esac
  done
}
