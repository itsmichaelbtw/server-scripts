#!/usr/bin/env bash
# File path: 06-gui/03-crontab-ui/run.sh
# Purpose: Deploy Crontab-UI via Docker for GUI management of cron jobs (no authentication).

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="03-crontab-ui"
SCRIPT_DESC="Deploy Crontab-UI for GUI management of cron jobs via Docker (no authentication)."

print_script_header
validate_environment
ensure_docker

prompt_for_port "Enter port for Crontab-UI GUI" "8000"
CRON_UI_PORT="$PORT_REPLY"

read -rp "Enter host directory to store crontabs/logs (default: /srv/crontab-ui): " CRON_UI_DIR
CRON_UI_DIR="${CRON_UI_DIR:-/srv/crontab-ui}"
mkdir -p "$CRON_UI_DIR"

if docker ps -a --format '{{.Names}}' | grep -q '^crontab-ui$'; then
  echo -e "${YELLOW}Stopping and removing existing Crontab-UI container...${RESET}"
  docker stop crontab-ui
  docker rm crontab-ui
fi

echo -e "${YELLOW}Deploying Crontab-UI container...${RESET}"

docker run -d \
  --name crontab-ui \
  --restart=unless-stopped \
  -p "$CRON_UI_PORT:8000" \
  -v "$CRON_UI_DIR:/crontab-ui/crontabs" \
  alseambusher/crontab-ui

display_service_url "Crontab-UI" "$CRON_UI_PORT"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
