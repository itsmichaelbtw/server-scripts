#!/usr/bin/env bash
# File path: 01-security/04-sysctl/run.sh
# Purpose: Apply system-level hardening via sysctl on Ubuntu using a template.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="04-sysctl"
SCRIPT_DESC="Harden kernel/network parameters using sysctl template."

print_script_header
validate_environment

SYSCTL_FILE="/etc/sysctl.conf"
TEMPLATE_FILE="$SCRIPT_DIR/sysctl.conf"

render_template_config "$TEMPLATE_FILE" "$SYSCTL_FILE" 644

echo -e "${YELLOW}Reloading sysctl settings...${RESET}"
sysctl -p

echo -e "${GREEN}✓ sysctl hardening applied successfully.${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
