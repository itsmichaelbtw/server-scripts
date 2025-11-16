#!/usr/bin/env bash
# Purpose: Create system users and optionally configure sudo privileges.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="01-users-groups"
SCRIPT_DESC="Create system users and configure optional sudo privileges."

echo -e "\n${BLUE}Running script: ${SCRIPT_NAME}${RESET}"
echo -e "${BLUE}Description: ${SCRIPT_DESC}${RESET}\n"

validate_environment

while true; do
  read -rp "Enter username to create: " USER_NAME

  if [[ -z "$USER_NAME" ]]; then
    echo -e "${RED}[ERROR] Username cannot be empty.${RESET}"
    continue
  fi

  if [[ "$USER_NAME" =~ [^a-zA-Z0-9._-] ]]; then
    echo -e "${RED}[ERROR] Username contains invalid characters. Allowed: a-z, 0-9, ., _, -${RESET}"
  else
    break
  fi
done

while true; do
  read -rp "Should this user have sudo privileges? (y/n): " SUDO_INPUT
  case "$SUDO_INPUT" in
    y|Y) ENABLE_SUDO="true"; break ;;
    n|N) ENABLE_SUDO="false"; break ;;
    *) echo -e "${RED}Please enter 'y' or 'n'.${RESET}" ;;
  esac
done

echo -e "\n${YELLOW}Step 1: Creating user '${USER_NAME}' if not exists...${RESET}"

if id "$USER_NAME" &>/dev/null; then
  echo -e "${GREEN}✓ User '${USER_NAME}' already exists. Skipping creation.${RESET}"
else
  adduser --disabled-password --gecos "" "$USER_NAME"
  echo -e "${GREEN}✓ User '${USER_NAME}' created.${RESET}"
fi

if [[ "$ENABLE_SUDO" == "true" ]]; then
  echo -e "${YELLOW}Step 2: Adding '${USER_NAME}' to sudo group...${RESET}"

  usermod -aG sudo "$USER_NAME"
  echo -e "${GREEN}✓ '${USER_NAME}' added to sudo group.${RESET}"

  SUDOERS_FILE="/etc/sudoers.d/90-${USER_NAME}"

  if [[ ! -f "$SUDOERS_FILE" ]]; then
    echo "${USER_NAME} ALL=(ALL) ALL" > "$SUDOERS_FILE"
    chmod 440 "$SUDOERS_FILE"
    echo -e "${GREEN}✓ Sudoers configuration created.${RESET}"
  else
    echo -e "${GREEN}✓ Sudoers file already exists. Skipping.${RESET}"
  fi
else
  echo -e "${YELLOW}Skipping sudo setup for '${USER_NAME}'.${RESET}"
fi

echo -e "\n${GREEN}✓ User and group configuration complete.${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
