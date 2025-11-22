#!/usr/bin/env bash
# File path: 06-gui/01-filebrowser/run.sh
# Purpose: Deploy FileBrowser web GUI via Docker for file management with authentication disabled (Cloudflare Tunnel manages access).

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="01-filebrowser"
SCRIPT_DESC="Deploy FileBrowser web GUI for file management via Docker (authentication disabled)."

print_script_header
validate_environment
ensure_docker

read -rp "Enter host directory to serve (default: /srv/files): " FILE_DIR
FILE_DIR="${FILE_DIR:-/srv/files}"
mkdir -p "$FILE_DIR"

prompt_for_port "Enter port for FileBrowser GUI" "8080"
FB_PORT="$PORT_REPLY"

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

display_service_url "FileBrowser" "$FB_PORT"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
