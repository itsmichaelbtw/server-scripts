#!/usr/bin/env bash
# File path: 03-orchestration/00-docker/run.sh
# Purpose: Install Docker Engine, Docker Compose, configure Docker service, and fix UFW-Docker integration.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="00-docker"
SCRIPT_DESC="Install Docker Engine, Docker Compose, configure Docker service, and apply UFW-Docker fix."

print_script_header
validate_environment

echo_yellow "Installing required packages..."
apt update -y
apt install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  software-properties-common

if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
  echo_yellow "Adding Docker GPG key and repository..."
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null
fi

apt update -y

echo_yellow "Installing Docker Engine..."
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

read_from_terminal -rp "Enter the username to add to docker group (leave empty to skip): " DOCKER_USER
if [[ -n "$DOCKER_USER" ]]; then
  if usermod -aG docker "$DOCKER_USER" 2>/dev/null; then
    echo_green "Added $DOCKER_USER to docker group."
  else
    echo_yellow "[WARNING] Failed to add $DOCKER_USER to docker group. User may not exist or there was an error. Continuing anyway..."
  fi
fi

echo_yellow "Configuring Docker log rotation..."
render_template_config "$SCRIPT_DIR/daemon.json" "/etc/docker/daemon.json" 644
systemctl restart docker

echo_yellow "Enabling and starting Docker service..."
systemctl enable docker

echo_yellow "Verifying Docker installation..."
docker --version
docker compose version

echo_yellow "Running hello-world container..."
docker run --rm hello-world

if does_cmd_exist "ufw" 2>/dev/null; then
  TEMPLATE_RULES_FILE="$SCRIPT_DIR/after.rules"
  AFTER_RULES_FILE="/etc/ufw/after.rules"

  echo_yellow "Applying UFW-Docker integration fix..."

  if [[ ! -f "$TEMPLATE_RULES_FILE" ]]; then
    echo_red "[ERROR] Template UFW rules file not found at: $TEMPLATE_RULES_FILE"
    echo_yellow "Skipping UFW-Docker fix. Please ensure after.rules exists in the script directory."
  else
    if ! grep -q "BEGIN UFW AND DOCKER" "$AFTER_RULES_FILE" 2>/dev/null; then
      echo_yellow "Appending UFW-Docker rules from template..."
      cat "$TEMPLATE_RULES_FILE" >> "$AFTER_RULES_FILE"
      echo_green "UFW-Docker rules added to $AFTER_RULES_FILE"
    else
      echo_yellow "UFW-Docker rules already present, skipping..."
    fi
  fi

  echo_yellow "Reloading UFW..."
  ufw reload || echo_yellow "UFW reload failed, you may need to reboot to apply rules"
else
  echo_yellow "UFW is not installed. Skipping UFW-Docker integration fix."
fi

echo_green "Docker installation, configuration, and UFW-Docker fix complete."
echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
