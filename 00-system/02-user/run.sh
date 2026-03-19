#!/usr/bin/env bash
# File path: 00-system/02-user/run.sh
# Purpose: Manage system users (create/remove) and configure sudo privileges.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="02-user"
SCRIPT_DESC="Manage system users and sudo privileges"

print_script_header
validate_environment

add_user() {
  echo_newline
  echo_blue "Add a new user"

  while true; do
    read_from_terminal -rp "Enter username to create: " USER_NAME

    if [[ -z "$USER_NAME" ]]; then
      echo_red "Username cannot be empty."
      continue
    fi

    if [[ "$USER_NAME" =~ [^a-zA-Z0-9._-] ]]; then
      echo_red "Username contains invalid characters. Allowed: a-z, 0-9, ., _, -"
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

  echo_newline
  echo_yellow "Step 1: Creating user '${USER_NAME}' if not exists..."

  if id "$USER_NAME" &>/dev/null; then
    echo_green "User '${USER_NAME}' already exists. Skipping creation."
  else
    adduser --disabled-password --gecos "" "$USER_NAME"
    echo_green "User '${USER_NAME}' created."
  fi

  echo_yellow "Step 2: Setting password..."
  prompt_yes_no "Do you want to set a password for '${USER_NAME}'?" "Y"
  if [[ "$REPLY" == "Y" ]]; then
    while true; do
      read_from_terminal -rsp "Enter password for '${USER_NAME}': " PASSWORD
      echo_newline
      read_from_terminal -rsp "Retype password: " PASSWORD_CONFIRM
      echo_newline
      
      if [[ "$PASSWORD" == "$PASSWORD_CONFIRM" ]]; then
        if echo "${USER_NAME}:${PASSWORD}" | chpasswd 2>/dev/null; then
          echo_green "Password set for '${USER_NAME}'."
        else
          echo_red "Failed to set password for '${USER_NAME}'. Please ensure the user exists."
        fi
        break
      else
        echo_red "Passwords do not match. Please try again."
      fi
    done
  else
    echo_yellow "Skipping password setup for '${USER_NAME}'."
  fi

  if [[ "$ENABLE_SUDO" == "true" ]]; then
    echo_yellow "Step 3: Adding '${USER_NAME}' to sudo group..."

    usermod -aG sudo "$USER_NAME"
    echo_green "'${USER_NAME}' added to sudo group."

    SUDOERS_FILE="/etc/sudoers.d/90-${USER_NAME}"

    if [[ ! -f "$SUDOERS_FILE" ]]; then
      echo "${USER_NAME} ALL=(ALL) ALL" > "$SUDOERS_FILE"
      chmod 440 "$SUDOERS_FILE"
      echo_green "Sudoers configuration created."
    else
      echo_green "Sudoers file already exists. Skipping."
    fi
  else
    echo_yellow "Skipping sudo setup for '${USER_NAME}'."
  fi

  echo_newline
  echo_green "User and group configuration complete."
  echo_newline
  echo_yellow "⚠️  IMPORTANT: Next steps"
  echo_yellow "Run the following command locally to set up SSH keys for '${USER_NAME}':"
  echo_yellow "  ./ssh-keygen.sh"
  echo_yellow "This ensures SSH key authentication is properly configured for all users."
  echo_newline
}

remove_user() {
  echo_newline
  echo_blue "Remove an existing user"

  echo_yellow "Current system users (excluding system accounts):"
  awk -F: '$3 >= 1000 && $3 < 65534 {print "  - " $1 " (UID: " $3 ")"}' /etc/passwd

  read_from_terminal -rp "Enter username to remove: " USER_NAME

  if [[ -z "$USER_NAME" ]]; then
    echo_red "Username cannot be empty."
    return
  fi

  if ! id "$USER_NAME" &>/dev/null; then
    echo_red "User '${USER_NAME}' does not exist."
    return
  fi

  USER_UID=$(id -u "$USER_NAME")
  if (( USER_UID < 1000 )); then
    echo_red "Cannot remove system user '${USER_NAME}' (UID < 1000)."
    return
  fi

  echo_yellow "This will remove:"
  echo_yellow "  - User account: ${USER_NAME}"
  echo_yellow "  - Home directory: /home/${USER_NAME}"
  echo_yellow "  - All group memberships"
  echo_yellow "  - Sudo configuration (if exists)"
  echo_yellow "  - SSH authorized_keys"
  echo_newline

  prompt_yes_no "Are you sure you want to remove user '${USER_NAME}'?" "N"
  if [[ "$REPLY" != "Y" ]]; then
    echo_yellow "User removal cancelled."
    return
  fi

  echo_yellow "Step 1: Removing sudo configuration..."
  SUDOERS_FILE="/etc/sudoers.d/90-${USER_NAME}"
  if [[ -f "$SUDOERS_FILE" ]]; then
    rm -f "$SUDOERS_FILE"
    echo_green "Sudoers configuration removed."
  else
    echo_yellow "No sudoers file found for ${USER_NAME}."
  fi

  echo_yellow "Step 2: Removing user from all groups..."
  USER_GROUPS=$(groups "$USER_NAME" 2>/dev/null | cut -d: -f2 | xargs)
  if [[ -n "$USER_GROUPS" ]]; then
    for GROUP in $USER_GROUPS; do
      if [[ "$GROUP" != "$USER_NAME" ]]; then
        gpasswd -d "$USER_NAME" "$GROUP" 2>/dev/null || echo_yellow "Could not remove from group: $GROUP"
      fi
    done
    echo_green "User removed from groups: $USER_GROUPS"
  fi

  echo_yellow "Step 3: Terminating any active processes..."
  if pgrep -u "$USER_NAME" > /dev/null 2>&1; then
    pkill -u "$USER_NAME" 2>/dev/null || echo_yellow "Some processes may still be running"
    sleep 2
    pkill -9 -u "$USER_NAME" 2>/dev/null || true
  fi
  echo_green "Processes terminated."

  echo_yellow "Step 4: Removing user account and home directory..."
  if deluser --remove-home "$USER_NAME" 2>/dev/null; then
    echo_green "User '${USER_NAME}' and home directory removed."
  else
    echo_yellow "Trying alternative removal method..."
    userdel -r "$USER_NAME" 2>/dev/null || echo_red "[WARNING] Could not fully remove user. Manual cleanup may be needed."
  fi

  echo_yellow "Step 5: Removing any remaining home directory..."
  if [[ -d "/home/${USER_NAME}" ]]; then
    rm -rf "/home/${USER_NAME}"
    echo_green "Home directory cleaned up."
  fi

  echo_newline
  echo_green "User '${USER_NAME}' has been completely removed."
  echo_newline
}

while true; do
  show_menu "User Management" \
    "Add a new user" \
    "Remove an existing user" \
    "Exit"
  case "$MENU_CHOICE" in
    1) add_user ;;
    2) remove_user ;;
    3) echo_green "Exiting."; exit 0 ;;
  esac
done
