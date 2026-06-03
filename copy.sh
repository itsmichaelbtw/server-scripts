#!/usr/bin/env bash
# File path: copy.sh
# Purpose: Copy server scripts to a remote system using rsync, preserving server-side edits.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="copy"
SCRIPT_DESC="Dynamically copy all server scripts to a remote server with rsync, preserving server-side edits"

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

echo_blue "Ignored files/patterns (will NOT be copied/overwritten):"
echo "  - .git"
echo "  - .env"
echo "  - .env.example"
echo "  - .github"
echo "  - .gitignore"
echo "  - .copyignore.example"
echo "  - LICENSE"

if [[ -f "$SOURCE_DIR/.copyignore" ]]; then
  echo "  - (patterns from .copyignore):"
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*$ ]] || [[ "$line" =~ ^# ]] && continue
    echo "      $line"
  done < "$SOURCE_DIR/.copyignore"
fi

prompt_yes_no "Proceed with file transfer?" "Y"
if [[ "$REPLY" == "N" ]]; then
  echo_yellow "Operation cancelled by user."
  exit 0
fi

ssh_open_session "$SSH_USER" "$SERVER_IP" "$SSH_PORT"
trap ssh_close_session EXIT

echo_yellow "\nEnsuring remote directory exists..."
ssh_run "mkdir -p $REMOTE_DIR"
echo_green "Remote directory ready"

require_cmd "rsync" "rsync"

echo_yellow "Syncing files to remote server with rsync..."

RSYNC_OPTS=(-avz --delete \
  --exclude='.git' \
  --exclude='.env' \
  --exclude='.env.example' \
  --exclude='.github' \
  --exclude='.gitignore' \
  --exclude='.copyignore.example' \
  --exclude='LICENSE' \
  --backup \
  --backup-dir=".copy-backups-$(date +%Y%m%d-%H%M%S)" \
)

if [[ -f "$SOURCE_DIR/.copyignore" ]]; then
  RSYNC_OPTS+=(--exclude-from="$SOURCE_DIR/.copyignore")
  echo_blue "Using .copyignore exclusions from $SOURCE_DIR/.copyignore"
fi

rsync "${RSYNC_OPTS[@]}" \
  -e "ssh -S $_SSH_CTL_PATH -p $_SSH_CTL_PORT" \
  "$SOURCE_DIR/" "${SSH_USER}@${SERVER_IP}:${REMOTE_DIR}/"

echo_green "Server scripts successfully synced to ${SSH_USER}@${SERVER_IP}:${REMOTE_DIR}"

prompt_yes_no "Make scripts executable on remote system?" "Y"
if [[ "$REPLY" == "Y" ]]; then
  echo_yellow "Making scripts executable..."
  ssh_run "chmod +x $REMOTE_DIR/*.sh $REMOTE_DIR/*/*.sh $REMOTE_DIR/*/*/*.sh 2>/dev/null || echo 'Some files could not be made executable'"
  echo_green "Scripts are now executable"
fi

echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
