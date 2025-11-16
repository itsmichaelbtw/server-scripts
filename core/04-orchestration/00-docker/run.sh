#!/usr/bin/env bash
# File path: 04-orchestration/00-docker/run.sh
# Purpose: Install Docker Engine, Docker Compose, and configure Docker service.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="00-docker"
SCRIPT_DESC="Install Docker Engine, Docker Compose, and configure Docker service."

echo -e "\n${BLUE}Running script: ${SCRIPT_NAME}${RESET}"
echo -e "${BLUE}Description: ${SCRIPT_DESC}${RESET}\n"

validate_environment

echo -e "${YELLOW}Installing required packages...${RESET}"
apt update -y
apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common

if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
  echo -e "${YELLOW}Adding Docker GPG key and repository...${RESET}"
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null
fi

apt update -y

echo -e "${YELLOW}Installing Docker Engine...${RESET}"
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

read -rp "Enter the username to add to docker group (leave empty to skip): " DOCKER_USER
if [[ -n "$DOCKER_USER" ]]; then
  usermod -aG docker "$DOCKER_USER"
  echo -e "${GREEN}Added $DOCKER_USER to docker group.${RESET}"
fi

echo -e "${YELLOW}Enabling and starting Docker service...${RESET}"
systemctl enable docker
systemctl restart docker

echo -e "${YELLOW}Verifying Docker installation...${RESET}"
docker --version
docker compose version

echo -e "${YELLOW}Running hello-world container...${RESET}"
docker run --rm hello-world

echo -e "${GREEN}✓ Docker installation and configuration complete.${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
