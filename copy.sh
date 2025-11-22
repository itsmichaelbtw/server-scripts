#!/usr/bin/env bash
# File path: copy.sh
# Purpose: Copy server scripts to a remote system using SCP

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="copy"
SCRIPT_DESC="Dynamically copy all server scripts to a remote server with verbose troubleshooting"

print_script_header

read -rp "Enter remote server IP address: " SERVER_IP
if [[ -z "$SERVER_IP" ]]; then
  echo -e "${RED}[ERROR] IP address cannot be empty.${RESET}"
  exit 1
fi

read -rp "Enter username for SSH connection (default: root): " SSH_USER
SSH_USER="${SSH_USER:-root}"

prompt_for_port "Enter SSH port" "22"
SSH_PORT="$PORT_REPLY"

DEFAULT_REMOTE_DIR="~/server-scripts"
read -rp "Enter remote directory path (default: $DEFAULT_REMOTE_DIR): " CUSTOM_REMOTE_DIR
REMOTE_DIR="${CUSTOM_REMOTE_DIR:-$DEFAULT_REMOTE_DIR}"

REMOTE_DIR="${REMOTE_DIR%/}"

SOURCE_DIR="$SCRIPT_DIR"

if [[ ! -d "$SOURCE_DIR" ]] || [[ -z "$(ls -A "$SOURCE_DIR")" ]]; then
  echo -e "${RED}[ERROR] Source directory is empty or does not exist.${RESET}"
  exit 1
fi

echo -e "\n${YELLOW}Will copy server scripts to ${SSH_USER}@${SERVER_IP}:${REMOTE_DIR} (port ${SSH_PORT})${RESET}"

echo -e "${BLUE}Files and directories to be copied:${RESET}"
find "$SOURCE_DIR" -maxdepth 1 -mindepth 1 \
  ! -name ".*" \
  ! -name "*.log" \
  | while read -r item; do
    echo "  - $(basename "$item")"
done

prompt_yes_no "Proceed with file transfer?" "Y"
if [[ "$REPLY" == "N" ]]; then
  echo -e "${YELLOW}Operation cancelled by user.${RESET}"
  exit 0
fi

echo -e "\n${YELLOW}Creating remote directory structure...${RESET}"
ssh -p "$SSH_PORT" "${SSH_USER}@${SERVER_IP}" "mkdir -p ${REMOTE_DIR}"
echo -e "${GREEN}✓ Created remote directory${RESET}"

echo -e "${YELLOW}Copying files to remote server...${RESET}"
tar -czvf transfer.tar.gz \
  --exclude='.git' \
  --exclude='.github' \
  --exclude='.gitignore' \
  .

scp -P "$SSH_PORT" transfer.tar.gz "${SSH_USER}@${SERVER_IP}:${REMOTE_DIR}/transfer.tar.gz"
ssh -p "$SSH_PORT" "${SSH_USER}@${SERVER_IP}" "cd ${REMOTE_DIR} && tar -xzvf transfer.tar.gz && rm transfer.tar.gz"

rm transfer.tar.gz

TRANSFER_EXIT_STATUS=$?
if [[ $TRANSFER_EXIT_STATUS -ne 0 ]]; then
  echo -e "${RED}[ERROR] File transfer failed with exit status $TRANSFER_EXIT_STATUS${RESET}"
  exit 1
fi

echo -e "${GREEN}✓ Server scripts successfully copied to ${SSH_USER}@${SERVER_IP}:${REMOTE_DIR}${RESET}"

prompt_yes_no "Make scripts executable on remote system?" "Y"
if [[ "$REPLY" == "Y" ]]; then
  echo -e "${YELLOW}Making scripts executable...${RESET}"
  ssh -p "$SSH_PORT" "${SSH_USER}@${SERVER_IP}" "chmod +x ${REMOTE_DIR}/*.sh ${REMOTE_DIR}/*/*.sh ${REMOTE_DIR}/*/*/*.sh 2>/dev/null || echo 'Some files could not be made executable'"
  echo -e "${GREEN}✓ Scripts are now executable${RESET}"
fi

echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
