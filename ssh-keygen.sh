#!/usr/bin/env bash
# File path: ssh-keygen.sh
# Purpose: Generate SSH key for a provided user, copy to server, and update local SSH config.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="ssh-keygen"
SCRIPT_DESC="Generate SSH key for a user, copy to server, and update local SSH config"

print_script_header

load_env "$SCRIPT_DIR"

echo_blue "SSH Key Generator - Local Machine Setup"
echo_yellow "\nThis script will:"
echo_yellow "  1. Generate an SSH key pair for a specified user"
echo_yellow "  2. Copy the public key to your server"
echo_yellow "  3. Add/update an entry in your local SSH config\n"

read_from_terminal -rp "Enter server hostname or IP${SERVER_IP:+ [${SERVER_IP}]}: " INPUT_SERVER_HOST
SERVER_HOST="${INPUT_SERVER_HOST:-${SERVER_IP}}"
if [[ -z "$SERVER_HOST" ]]; then
  echo_red "[ERROR] Server hostname/IP cannot be empty."
  exit 1
fi

read_from_terminal -rp "Enter SSH username for key generation (default: 'id_rsa'): " KEY_NAME
KEY_NAME="${KEY_NAME:-id_rsa}"

read_from_terminal -rp "Enter remote server username to add SSH key to${SSH_USER:+ [${SSH_USER}]}: " INPUT_REMOTE_USER
REMOTE_USER="${INPUT_REMOTE_USER:-${SSH_USER}}"
if [[ -z "$REMOTE_USER" ]]; then
  echo_red "[ERROR] Remote username cannot be empty."
  exit 1
fi

read_from_terminal -rp "Enter username to authenticate with (leave empty to use '$REMOTE_USER'): " AUTH_USER
AUTH_USER="${AUTH_USER:-$REMOTE_USER}"

read_from_terminal -rp "Enter remote server port (default: ${SSH_PORT:-22}): " INPUT_REMOTE_PORT
REMOTE_PORT="${INPUT_REMOTE_PORT:-${SSH_PORT:-22}}"

read_from_terminal -rp "Enter local SSH config alias name (default: same as hostname): " CONFIG_ALIAS
CONFIG_ALIAS="${CONFIG_ALIAS:-$SERVER_HOST}"

read_from_terminal -rp "Enter SSH key comment (default: username@hostname): " KEY_COMMENT
KEY_COMMENT="${KEY_COMMENT:-$REMOTE_USER@$SERVER_HOST}"

ACTUAL_USER=$(get_actual_user)
SSH_DIR=$(eval echo "~${ACTUAL_USER}/.ssh")
if [[ ! -d "$SSH_DIR" ]]; then
  echo_yellow "Creating SSH directory: $SSH_DIR"
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
fi

PRIVATE_KEY="$SSH_DIR/$KEY_NAME"
PUBLIC_KEY="$SSH_DIR/$KEY_NAME.pub"

if [[ -f "$PRIVATE_KEY" ]]; then
  echo_yellow "Key already exists at: $PRIVATE_KEY"
  prompt_yes_no "Overwrite existing key?" "N"
  if [[ "$REPLY" != "Y" ]]; then
    echo_yellow "Skipping key generation. Using existing key."
  else
    echo_yellow "Removing existing key..."
    rm -f "$PRIVATE_KEY" "$PUBLIC_KEY"
  fi
fi

if [[ ! -f "$PRIVATE_KEY" ]]; then
  echo_yellow "\nGenerating SSH key pair..."
  ssh-keygen -t ed25519 -f "$PRIVATE_KEY" -C "$KEY_COMMENT" -N "" 2>&1
  
  if [[ $? -eq 0 ]]; then
    echo_green "SSH key generated successfully"
    echo_green "  Private key: $PRIVATE_KEY"
    echo_green "  Public key: $PUBLIC_KEY"
  else
    echo_red "[ERROR] Failed to generate SSH key."
    exit 1
  fi
else
  echo_green "Using existing SSH key"
fi

echo_yellow "Setting correct permissions on SSH key files..."
chmod 600 "$PRIVATE_KEY"
chmod 644 "$PUBLIC_KEY"
if [[ -n "${SUDO_USER:-}" ]]; then
  USER_GROUP=$(id -gn "$SUDO_USER" 2>/dev/null || echo "$SUDO_USER")
  chown "$SUDO_USER:$USER_GROUP" "$PRIVATE_KEY" "$PUBLIC_KEY"
fi

add_public_key_to_remote() {
  local TARGET_USER="$1"
  local AUTH_USER="$2"
  local PUBKEY_CONTENT="$3"
  
  local SSH_OPTS="-o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=$(eval echo \"~${ACTUAL_USER}/.ssh/known_hosts\")"
  
  if [[ "$AUTH_USER" == "$TARGET_USER" ]]; then
    if ssh $SSH_OPTS -p "$REMOTE_PORT" "$AUTH_USER@$SERVER_HOST" "mkdir -p ~/.ssh && echo '$PUBKEY_CONTENT' >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys" 2>&1; then
      return 0
    fi
  else
    if ssh $SSH_OPTS -p "$REMOTE_PORT" "$AUTH_USER@$SERVER_HOST" "echo '$PUBKEY_CONTENT' | sudo -u $TARGET_USER sh -c 'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'" 2>&1; then
      return 0
    fi
  fi
  
  return 1
}

echo_yellow "\nPreparing to copy public key to server..."

echo_yellow "Clearing old host key entry (if it exists)..."
ssh-keygen -R "$SERVER_HOST" 2>/dev/null || true

echo_yellow "Accepting new host key..."
ssh-keyscan -p "$REMOTE_PORT" "$SERVER_HOST" >> "$SSH_DIR/known_hosts" 2>/dev/null || true

echo_yellow "\nCopying public key to server..."
echo_yellow "Attempting connection (will try public key first, then password).\n"

PUBKEY_CONTENT=$(cat "$PUBLIC_KEY")

if add_public_key_to_remote "$REMOTE_USER" "$AUTH_USER" "$PUBKEY_CONTENT"; then
  if [[ "$AUTH_USER" == "$REMOTE_USER" ]]; then
    echo_green "Public key added to $REMOTE_USER's authorized_keys"
  else
    echo_green "Public key added to $REMOTE_USER's authorized_keys via $AUTH_USER account"
    echo_yellow "\nNote: You authenticated with '$AUTH_USER', and used sudo to add the key to $REMOTE_USER's account."
  fi
else
  echo_red "[ERROR] Failed to add public key to server."
  echo_yellow "\nYou can add it manually by running:"
  if [[ "$AUTH_USER" == "$REMOTE_USER" ]]; then
    echo_yellow "  ssh -p $REMOTE_PORT $AUTH_USER@$SERVER_HOST"
    echo_yellow "  mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys << 'EOF'"
    echo_yellow "  $PUBKEY_CONTENT"
    echo_yellow "  EOF"
  else
    echo_yellow "  ssh -p $REMOTE_PORT $AUTH_USER@$SERVER_HOST"
    echo_yellow "  cat << 'EOF' | sudo -u $REMOTE_USER sh -c 'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'"
    echo_yellow "  $PUBKEY_CONTENT"
    echo_yellow "  EOF"
  fi
  exit 1
fi

SSH_CONFIG="$SSH_DIR/config"
echo_yellow "\nUpdating local SSH config..."

if [[ ! -f "$SSH_CONFIG" ]]; then
  touch "$SSH_CONFIG"
  chmod 600 "$SSH_CONFIG"
  echo_yellow "Created SSH config: $SSH_CONFIG"
fi

if grep -q "^Host $CONFIG_ALIAS$" "$SSH_CONFIG"; then
  echo_yellow "SSH config entry already exists for: $CONFIG_ALIAS"
  prompt_yes_no "Update existing config entry?" "Y"
  
  if [[ "$REPLY" == "Y" ]]; then
    START_LINE=$(grep -n "^Host $CONFIG_ALIAS$" "$SSH_CONFIG" | cut -d: -f1 | head -1)
    END_LINE=$((START_LINE + 1))
    
    NEXT_HOST=$(tail -n +$((END_LINE + 1)) "$SSH_CONFIG" | grep -n "^Host " | head -1 | cut -d: -f1)
    if [[ -n "$NEXT_HOST" ]]; then
      END_LINE=$((END_LINE + NEXT_HOST - 1))
    else
      END_LINE=$(wc -l < "$SSH_CONFIG")
    fi
    
    sed -i '' "${START_LINE},${END_LINE}d" "$SSH_CONFIG"
  else
    echo_yellow "Skipping SSH config update."
    echo_green "Script completed."
    exit 0
  fi
fi

{
  echo_newline
  echo "Host $CONFIG_ALIAS"
  echo "    HostName $SERVER_HOST"
  echo "    User $REMOTE_USER"
  echo "    Port $REMOTE_PORT"
  echo "    IdentityFile $PRIVATE_KEY"
  echo "    AddKeysToAgent yes"
  echo "    UseKeychain $(is_macos && echo 'yes' || echo 'no')"
} >> "$SSH_CONFIG"

echo_green "SSH config updated"
echo_green "  Alias: $CONFIG_ALIAS"
echo_green "  Host: $SERVER_HOST:$REMOTE_PORT"
echo_green "  User: $REMOTE_USER"
echo_green "  Identity: $PRIVATE_KEY"

echo_yellow "\nTesting SSH connection..."
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new -i "$PRIVATE_KEY" -p "$REMOTE_PORT" "$REMOTE_USER@$SERVER_HOST" "echo 'SSH connection successful!'" 2>&1; then
  echo_green "SSH connection test passed"
else
  echo_yellow "[WARNING] SSH connection test failed. Please verify server details and try connecting manually."
  echo_yellow "You can test manually with: ssh -i $PRIVATE_KEY -p $REMOTE_PORT $REMOTE_USER@$SERVER_HOST"
fi

echo_green "\nScript ${SCRIPT_NAME} finished successfully.\n"
echo_green "You can now connect to your server with:"
echo_green "  ssh $CONFIG_ALIAS"
