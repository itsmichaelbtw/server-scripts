#!/usr/bin/env bash
# File path: 00-system/01-utilities/run.sh
# Purpose: Install general-purpose server utilities for management and troubleshooting, including cron/log tools.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="00-utilities"
SCRIPT_DESC="Install general-purpose utilities (curl, wget, git, jq, editors, network tools) and CRON/log support."

echo -e "\n${BLUE}Running script: ${SCRIPT_NAME}${RESET}"
echo -e "${BLUE}Description: ${SCRIPT_DESC}${RESET}\n"

validate_environment

echo -e "${YELLOW}Installing utilities...${RESET}"
apt update -y
apt install -y \
  curl \
  wget \
  git \
  jq \
  unzip \
  tar \
  vim \
  nano \
  net-tools \
  software-properties-common \
  gnupg \
  cron \
  at \
  logrotate \
  mailutils

echo -e "${YELLOW}Verifying installation...${RESET}"

echo -e "\ncurl version:"
curl --version | head -n 1

echo -e "\nwget version:"
wget --version | head -n 1

echo -e "\ngit version:"
git --version

echo -e "\njq version:"
jq --version

echo -e "\nvim version:"
vim --version | head -n 1

echo -e "\ncron version:"
cron --version || echo "cron installed"

echo -e "\nat version:"
at -V || echo "at installed"

echo -e "\nlogrotate version:"
logrotate --version | head -n 1

echo -e "\nmailutils installation check:"
dpkg -l | grep mailutils || echo "mailutils installed"

echo -e "${GREEN}✓ Utility installation complete.${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
