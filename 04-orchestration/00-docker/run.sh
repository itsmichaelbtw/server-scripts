#!/usr/bin/env bash
# File path: 04-orchestration/00-docker/run.sh
# Purpose: Install Docker Engine, Docker Compose, and configure Docker service.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="00-docker"
SCRIPT_DESC="Install Docker Engine, Docker Compose, and configure Docker service."

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
  usermod -aG docker "$DOCKER_USER"
  echo_green "Added $DOCKER_USER to docker group."
fi

echo_yellow "Enabling and starting Docker service..."
systemctl enable docker
systemctl restart docker

echo_yellow "Verifying Docker installation..."
docker --version
docker compose version

echo_yellow "Running hello-world container..."
docker run --rm hello-world

echo_green "✓ Docker installation and configuration complete."
echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
