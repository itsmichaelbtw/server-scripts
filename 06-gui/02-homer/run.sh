#!/usr/bin/env bash
# File path: 06-gui/02-homer/run.sh
# Purpose: Install Homer dashboard via Docker and configure persistence using template config.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="02-homer"
SCRIPT_DESC="Install Homer (dashboard for self-hosted services) via Docker using template-based configuration."

print_script_header
validate_environment
ensure_docker

echo -e "${YELLOW}Preparing Homer directory structure...${RESET}"
DATA_DIR="/opt/homer"
CONFIG_DIR="$DATA_DIR/config"
ASSETS_DIR="$DATA_DIR/assets"

mkdir -p "$DATA_DIR" "$CONFIG_DIR" "$ASSETS_DIR"

TEMPLATE_FILE="$SCRIPT_DIR/config.yml"
CONFIG_FILE="$CONFIG_DIR/config.yml"

if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo -e "${RED}Error: Missing template file at: $TEMPLATE_FILE${RESET}"
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo -e "${YELLOW}Copying Homer template configuration...${RESET}"
  cp "$TEMPLATE_FILE" "$CONFIG_FILE"
else
  echo -e "${GREEN}Existing Homer config.yml found — not overwriting.${RESET}"
fi

echo -e "${YELLOW}Pulling and running Homer Docker container...${RESET}"

if docker ps -a --format '{{.Names}}' | grep -q '^homer$'; then
  echo -e "${YELLOW}Existing Homer container detected — rebuilding...${RESET}"
  docker rm -f homer >/dev/null 2>&1 || true
fi

prompt_for_port "Enter port for Homer dashboard" "8080"
HOMER_PORT="$PORT_REPLY"

docker run -d \
  --name homer \
  -p "$HOMER_PORT:8080" \
  -v "$ASSETS_DIR":/www/assets \
  -v "$CONFIG_DIR":/www/config \
  --restart unless-stopped \
  b4bz/homer:latest

display_service_url "Homer" "$HOMER_PORT"
echo -e "${GREEN}Editable configuration: $CONFIG_FILE${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
