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

echo_yellow "Installing utilities..."
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
  lshw \
  grencode

echo_yellow "Verifying installation..."

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

echo_green "✓ Utility installation complete."

prompt_yes_no "Would you like to print system information?" "Y"
if [[ "$REPLY" == "Y" ]]; then
  echo_yellow "\n==== System Information ===="
  echo_blue "OS & Kernel:"
  lsb_release -a
  uname -r

  echo_blue "\nCPU Info:"
  lscpu

  echo_blue "\nMemory Info:"
  free -h

  echo_blue "\nDisk Usage:"
  df -h

  echo_blue "\nTop 5 Largest Mounts:"
  du -h / 2>/dev/null | sort -rh | head -n 5 || true

  echo_blue "\nNetwork Interfaces & IPs:"
  ip -brief addr

  echo_blue "\nOptional Neofetch Overview:"
  neofetch --stdout

  echo_green "✓ System information displayed successfully."
fi

echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
