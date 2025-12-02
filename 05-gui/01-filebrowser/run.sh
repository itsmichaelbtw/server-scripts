#!/usr/bin/env bash
# File path: 05-gui/01-filebrowser/run.sh
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

read_from_terminal -rp "Enter host directory to serve (default: /srv/files): " FILE_DIR
FILE_DIR="${FILE_DIR:-/srv/files}"
mkdir -p "$FILE_DIR"

prompt_for_port "Enter port for FileBrowser GUI" "8080"
FB_PORT="$PORT_REPLY"

if docker ps -a --format '{{.Names}}' | grep -q '^filebrowser$'; then
  echo_yellow "Stopping and removing existing FileBrowser container..."
  docker stop filebrowser
  docker rm filebrowser
fi

echo_yellow "Deploying FileBrowser container..."

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
echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
