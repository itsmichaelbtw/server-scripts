#!/usr/bin/env bash
# File path: 06-tools/01-filebrowser/run.sh
# Purpose: Deploy FileBrowser web GUI via Docker for file management with authentication disabled (Cloudflare Tunnel manages access).

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="01-filebrowser"
SCRIPT_DESC="Deploy FileBrowser web GUI for file management via Docker (authentication disabled)."

echo -e "\n${BLUE}Running script: ${SCRIPT_NAME}${RESET}"
echo -e "${BLUE}Description: ${SCRIPT_DESC}${RESET}\n"

validate_environment

if ! command -v docker &>/dev/null; then
  echo -e "${RED}[ERROR] Docker is required. Please install Docker first.${RESET}"
  exit 1
fi

read -rp "Enter host directory to serve (default: /srv/files): " FILE_DIR
FILE_DIR="${FILE_DIR:-/srv/files}"
mkdir -p "$FILE_DIR"

read -rp "Enter port for FileBrowser GUI (default: 8080): " FB_PORT
FB_PORT="${FB_PORT:-8080}"

if docker ps -a --format '{{.Names}}' | grep -q '^filebrowser$'; then
  echo -e "${YELLOW}Stopping and removing existing FileBrowser container...${RESET}"
  docker stop filebrowser
  docker rm filebrowser
fi

echo -e "${YELLOW}Deploying FileBrowser container...${RESET}"

docker run -d \
  --name filebrowser \
  --restart=unless-stopped \
  -p "$FB_PORT:80" \
  -v "$FILE_DIR:/srv" \
  -v filebrowser_config:/config \
  -e PUID=$(id -u) \
  -e PGID=$(id -g) \
  filebrowser/filebrowser \
  --root /srv \
  --no-auth

SERVER_IP=$(ip route get 1 | awk '{print $7; exit}')
echo -e "${GREEN}✓ FileBrowser deployed successfully.${RESET}"
echo -e "${YELLOW}Access the GUI at: http://$SERVER_IP:$FB_PORT${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
