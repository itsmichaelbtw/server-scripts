#!/usr/bin/env bash
# File path: 01-security/04-sysctl/run.sh
# Purpose: Apply system-level hardening via sysctl on Ubuntu using a template.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="04-sysctl"
SCRIPT_DESC="Harden kernel/network parameters using sysctl template."

echo -e "\n${BLUE}Running script: ${SCRIPT_NAME}${RESET}"
echo -e "${BLUE}Description: ${SCRIPT_DESC}${RESET}\n"

validate_environment

SYSCTL_FILE="/etc/sysctl.conf"
BACKUP_FILE="/etc/sysctl.conf.backup-$(date +%Y%m%d-%H%M%S)"

if [[ -f "$SYSCTL_FILE" ]]; then
  echo -e "${YELLOW}Backing up existing sysctl.conf...${RESET}"
  cp "$SYSCTL_FILE" "$BACKUP_FILE"
  echo -e "${GREEN}✓ Backup created at ${BACKUP_FILE}${RESET}"
fi

TEMPLATE_FILE="$SCRIPT_DIR/sysctl.conf.template"

if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo -e "${RED}[ERROR] Template file missing: $TEMPLATE_FILE${RESET}"
  exit 1
fi

echo -e "${YELLOW}Applying sysctl template...${RESET}"
cp "$TEMPLATE_FILE" "$SYSCTL_FILE"

echo -e "${YELLOW}Reloading sysctl settings...${RESET}"
sysctl -p

echo -e "${GREEN}✓ sysctl hardening applied successfully.${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
