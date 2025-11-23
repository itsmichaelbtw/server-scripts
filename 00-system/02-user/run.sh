#!/usr/bin/env bash
# File path: 00-system/02-user/run.sh
# Purpose: Create system users and optionally configure sudo privileges.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="02-user"
SCRIPT_DESC="Create system users and configure optional sudo privileges."

print_script_header
validate_environment

while true; do
  read_from_terminal -rp "Enter username to create: " USER_NAME

  if [[ -z "$USER_NAME" ]]; then
    echo_red "[ERROR] Username cannot be empty."
    continue
  fi

  if [[ "$USER_NAME" =~ [^a-zA-Z0-9._-] ]]; then
    echo_red "[ERROR] Username contains invalid characters. Allowed: a-z, 0-9, ., _, -"
  else
    break
  fi
done

prompt_yes_no "Should this user have sudo privileges?" "N"
if [[ "$REPLY" == "Y" ]]; then
  ENABLE_SUDO="true"
else
  ENABLE_SUDO="false"
fi

echo ""
echo_yellow "Step 1: Creating user '${USER_NAME}' if not exists..."

if id "$USER_NAME" &>/dev/null; then
  echo_green "✓ User '${USER_NAME}' already exists. Skipping creation."
else
  adduser --disabled-password --gecos "" "$USER_NAME"
  echo_green "✓ User '${USER_NAME}' created."
fi

if [[ "$ENABLE_SUDO" == "true" ]]; then
  echo_yellow "Step 2: Adding '${USER_NAME}' to sudo group..."

  usermod -aG sudo "$USER_NAME"
  echo_green "✓ '${USER_NAME}' added to sudo group."

  SUDOERS_FILE="/etc/sudoers.d/90-${USER_NAME}"

  if [[ ! -f "$SUDOERS_FILE" ]]; then
    echo "${USER_NAME} ALL=(ALL) ALL" > "$SUDOERS_FILE"
    chmod 440 "$SUDOERS_FILE"
    echo_green "✓ Sudoers configuration created."
  else
    echo_green "✓ Sudoers file already exists. Skipping."
  fi
else
  echo_yellow "Skipping sudo setup for '${USER_NAME}'."
fi

echo ""
echo_green "✓ User and group configuration complete."
echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
