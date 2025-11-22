#!/usr/bin/env bash
# File path: 00-system/01-utilities/run.sh
# Purpose: Install general-purpose server utilities and system information tools for management and troubleshooting, including cron/log tools.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="01-utilities"
SCRIPT_DESC="Install general-purpose utilities, system information tools, and CRON/log support."

print_script_header
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
  lsb-release \
  neofetch \
  dmidecode \
  lshw

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

echo -e "\nneofetch installation check:"
dpkg -l | grep neofetch || echo "neofetch installed"

echo -e "${GREEN}✓ Utility installation complete.${RESET}"

echo -e "${YELLOW}\n==== System Information ====${RESET}"
echo -e "${BLUE}OS & Kernel:${RESET}"
lsb_release -a
uname -r

echo -e "${BLUE}\nCPU Info:${RESET}"
lscpu

echo -e "${BLUE}\nMemory Info:${RESET}"
free -h

echo -e "${BLUE}\nDisk Usage:${RESET}"
df -h

echo -e "${BLUE}\nTop 5 Largest Mounts:${RESET}"
du -h / 2>/dev/null | sort -rh | head -n 5

echo -e "${BLUE}\nNetwork Interfaces & IPs:${RESET}"
ip -brief addr

echo -e "${BLUE}\nOptional Neofetch Overview:${RESET}"
neofetch --stdout

echo -e "${GREEN}✓ System information displayed successfully.${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
