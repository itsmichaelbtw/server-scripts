#!/usr/bin/env bash
# File path: 06-tools/00-system-info/run.sh
# Purpose: Install and display system information utilities and a summary of the server.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="00-system-info"
SCRIPT_DESC="Install system info tools and display OS, hardware, and resource summary."

echo -e "\n${BLUE}Running script: ${SCRIPT_NAME}${RESET}"
echo -e "${BLUE}Description: ${SCRIPT_DESC}${RESET}\n"

validate_environment

echo -e "${YELLOW}Installing system info utilities...${RESET}"
apt update -y
apt install -y lsb-release neofetch dmidecode lshw

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
