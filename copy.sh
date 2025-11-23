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

if [[ -f "$SCRIPT_DIR/.env" ]]; then
  echo_blue "Loading configuration from .env file..."
  source "$SCRIPT_DIR/.env"
fi

read_from_terminal -rp "Enter remote server IP address${COPY_SERVER_IP:+ [${COPY_SERVER_IP}]}: " SERVER_IP
SERVER_IP="${SERVER_IP:-${COPY_SERVER_IP}}"
if [[ -z "$SERVER_IP" ]]; then
  echo_red "[ERROR] IP address cannot be empty."
  exit 1
fi

read_from_terminal -rp "Enter username for SSH connection (default: ${COPY_SSH_USER:-root}): " SSH_USER
SSH_USER="${SSH_USER:-${COPY_SSH_USER:-root}}"

prompt_for_port "Enter SSH port" "${COPY_SSH_PORT:-22}"
SSH_PORT="$PORT_REPLY"

# Remove quotes from COPY_REMOTE_DIR if present (from .env file with single quotes)
COPY_REMOTE_DIR_CLEAN="${COPY_REMOTE_DIR//\'/}"

DEFAULT_REMOTE_DIR="${COPY_REMOTE_DIR_CLEAN:-~/server-scripts}"
read_from_terminal -rp "Enter remote directory path (default: $DEFAULT_REMOTE_DIR): " CUSTOM_REMOTE_DIR

REMOTE_DIR="${CUSTOM_REMOTE_DIR:-$DEFAULT_REMOTE_DIR}"
REMOTE_DIR="${REMOTE_DIR%/}"
SOURCE_DIR="$SCRIPT_DIR"

if [[ ! -d "$SOURCE_DIR" ]] || [[ -z "$(ls -A "$SOURCE_DIR")" ]]; then
  echo_red "[ERROR] Source directory is empty or does not exist."
  exit 1
fi

echo_yellow "\nWill copy server scripts to ${SSH_USER}@${SERVER_IP}:${REMOTE_DIR} (port ${SSH_PORT})"

echo_blue "Files and directories to be copied:"
find "$SOURCE_DIR" -maxdepth 1 -mindepth 1 \
  ! -name ".*" \
  ! -name "*.log" \
  | while read -r item; do
    echo "  - $(basename "$item")"
done

prompt_yes_no "Proceed with file transfer?" "Y"
if [[ "$REPLY" == "N" ]]; then
  echo_yellow "Operation cancelled by user."
  exit 0
fi

echo_yellow "\nCreating remote directory structure..."
ssh -p "$SSH_PORT" "${SSH_USER}@${SERVER_IP}" "mkdir -p $REMOTE_DIR"
echo_green "✓ Created remote directory"

echo_yellow "Copying files to remote server..."

rm -f transfer.tar.gz
tar -czvf transfer.tar.gz \
  --exclude='.git' \
  --exclude='.github' \
  --exclude='.gitignore' \
  --exclude='transfer.tar.gz' \
  .

scp -P "$SSH_PORT" transfer.tar.gz "${SSH_USER}@${SERVER_IP}:$REMOTE_DIR/transfer.tar.gz"
ssh -p "$SSH_PORT" "${SSH_USER}@${SERVER_IP}" "cd $REMOTE_DIR && tar -xzvf transfer.tar.gz && rm transfer.tar.gz"

rm transfer.tar.gz

TRANSFER_EXIT_STATUS=$?
if [[ $TRANSFER_EXIT_STATUS -ne 0 ]]; then
  echo_red "[ERROR] File transfer failed with exit status $TRANSFER_EXIT_STATUS"
  exit 1
fi

echo_green "✓ Server scripts successfully copied to ${SSH_USER}@${SERVER_IP}:${REMOTE_DIR}"

prompt_yes_no "Make scripts executable on remote system?" "Y"
if [[ "$REPLY" == "Y" ]]; then
  echo_yellow "Making scripts executable..."
  ssh -p "$SSH_PORT" "${SSH_USER}@${SERVER_IP}" "chmod +x $REMOTE_DIR/*.sh $REMOTE_DIR/*/*.sh $REMOTE_DIR/*/*/*.sh 2>/dev/null || echo 'Some files could not be made executable'"
  echo_green "✓ Scripts are now executable"
fi

echo_green "✓ Script ${SCRIPT_NAME} finished successfully.\n"
