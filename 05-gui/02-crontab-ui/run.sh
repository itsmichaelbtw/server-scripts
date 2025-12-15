#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="02-crontab-ui"
SCRIPT_DESC="Deploy Crontab-UI for GUI management of cron jobs via Docker."

CONTAINER_NAME=crontab-ui
CONTAINER_PORT=4050
CRON_SYSTEM_DIR="/var/spool/cron/crontabs"

print_script_header
validate_environment
ensure_docker
ensure_docker_network

remove_docker_container "$CONTAINER_NAME"
echo_deploying_container "$CONTAINER_NAME" "$CONTAINER_PORT"
configure_ufw_for_wireguard "$CONTAINER_PORT" tcp

ensure_directory "$CRON_SYSTEM_DIR" 700

echo_blue "Crontab-UI will manage system crontabs from: $CRON_SYSTEM_DIR"
echo_blue "Jobs added via GUI will be executed by the system cron daemon"
echo_newline

docker run -d \
  --name="$CONTAINER_NAME" \
  --network="$DOCKER_NETWORK_NAME" \
  --restart=unless-stopped \
  -p "$CONTAINER_PORT:8000" \
  -v "$CRON_SYSTEM_DIR:/crontab-ui/crontabs" \
  alseambusher/crontab-ui

sleep 3

if verify_container_is_running "$CONTAINER_NAME"; then
  echo_green "$CONTAINER_NAME container is running"
  echo_blue "Access at: http://localhost:$CONTAINER_PORT"
  exit 0
else
  echo_red "$CONTAINER_NAME container failed to start"
  echo_yellow "Check logs with: docker logs $CONTAINER_NAME"
  exit 1
fi
