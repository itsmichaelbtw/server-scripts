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

load_env "$SCRIPT_DIR"

read_from_terminal -rp "Enter remote server IP address${SERVER_IP:+ [${SERVER_IP}]}: " INPUT_SERVER_IP
SERVER_IP="${INPUT_SERVER_IP:-${SERVER_IP}}"
if [[ -z "$SERVER_IP" ]]; then
  echo_red "IP address cannot be empty."
  exit 1
fi

read_from_terminal -rp "Enter username for SSH connection (default: ${SSH_USER:-root}): " INPUT_SSH_USER
SSH_USER="${INPUT_SSH_USER:-${SSH_USER:-root}}"

prompt_for_port "Enter SSH port" "${SSH_PORT:-22}"
SSH_PORT="$PORT_REPLY"

# Remove quotes from REMOTE_DIR if present (from .env file with single quotes)
REMOTE_DIR_CLEAN="${REMOTE_DIR//\'/}"

DEFAULT_REMOTE_DIR="${REMOTE_DIR_CLEAN:-~/server-scripts}"
read_from_terminal -rp "Enter remote directory path (default: $DEFAULT_REMOTE_DIR): " INPUT_REMOTE_DIR

REMOTE_DIR="${INPUT_REMOTE_DIR:-$DEFAULT_REMOTE_DIR}"
REMOTE_DIR="${REMOTE_DIR%/}"
SOURCE_DIR="$SCRIPT_DIR"

if [[ ! -d "$SOURCE_DIR" ]] || [[ -z "$(ls -A "$SOURCE_DIR")" ]]; then
  echo_red "Source directory is empty or does not exist."
  exit 1
fi

echo_yellow "\nWill copy server scripts to ${SSH_USER}@${SERVER_IP}:${REMOTE_DIR} (port ${SSH_PORT})"

echo_blue "Files and directories to be copied:"
find "$SOURCE_DIR" -maxdepth 1 -mindepth 1 \
  ! -name ".*" \
  ! -name "*.log" \
  ! -name "LICENSE" \
  | while read -r item; do
    echo "  - $(basename "$item")"
done

prompt_yes_no "Proceed with file transfer?" "Y"
if [[ "$REPLY" == "N" ]]; then
  echo_yellow "Operation cancelled by user."
  exit 0
fi

ssh_open_session "$SSH_USER" "$SERVER_IP" "$SSH_PORT"
trap ssh_close_session EXIT

echo_yellow "\nCreating remote directory structure..."
ssh_run "mkdir -p $REMOTE_DIR"
echo_green "Created remote directory"

echo_yellow "Copying files to remote server..."

rm -f transfer.tar.gz
tar -czvf transfer.tar.gz \
  --exclude='.git' \
  --exclude='.env' \
  --exclude='.env.example' \
  --exclude='.github' \
  --exclude='.gitignore' \
  --exclude='LICENSE' \
  --exclude='transfer.tar.gz' \
  .

scp_put transfer.tar.gz "$REMOTE_DIR/transfer.tar.gz"
ssh_run "cd $REMOTE_DIR && tar -xzvf transfer.tar.gz && rm transfer.tar.gz"

rm transfer.tar.gz

echo_green "Server scripts successfully copied to ${SSH_USER}@${SERVER_IP}:${REMOTE_DIR}"

prompt_yes_no "Make scripts executable on remote system?" "Y"
if [[ "$REPLY" == "Y" ]]; then
  echo_yellow "Making scripts executable..."
  ssh_run "chmod +x $REMOTE_DIR/*.sh $REMOTE_DIR/*/*.sh $REMOTE_DIR/*/*/*.sh 2>/dev/null || echo 'Some files could not be made executable'"
  echo_green "Scripts are now executable"
fi

echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
