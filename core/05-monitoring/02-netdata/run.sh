#!/usr/bin/env bash
# File path: 05-monitoring/02-netdata/run.sh
# Purpose: Deploy NetData monitoring dashboard in Docker.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="02-netdata"
SCRIPT_DESC="Deploy NetData real-time monitoring via Docker."

echo -e "\n${BLUE}Running script: ${SCRIPT_NAME}${RESET}"
echo -e "${BLUE}Description: ${SCRIPT_DESC}${RESET}\n"

validate_environment

if ! command -v docker &>/dev/null; then
  echo -e "${RED}[ERROR] Docker is required for NetData. Please install Docker first.${RESET}"
  exit 1
fi

if docker ps -a --format '{{.Names}}' | grep -q '^netdata$'; then
  echo -e "${YELLOW}Stopping and removing existing NetData container...${RESET}"
  docker stop netdata
  docker rm netdata
fi

echo -e "${YELLOW}Deploying NetData container...${RESET}"

docker run -d \
  --name=netdata \
  --restart=unless-stopped \
  -p 19999:19999 \
  -v netdataconfig:/etc/netdata \
  -v netdatalib:/var/lib/netdata \
  -v netdatacache:/var/cache/netdata \
  -v /etc/passwd:/host/etc/passwd:ro \
  -v /etc/group:/host/etc/group:ro \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /etc/os-release:/host/etc/os-release:ro \
  --cap-add=SYS_PTRACE \
  --security-opt apparmor=unconfined \
  netdata/netdata

SERVER_IP=$(ip route get 1 | awk '{print $7; exit}')

echo -e "${GREEN}✓ NetData deployed successfully.${RESET}"
echo -e "${YELLOW}Access the dashboard at: http://$SERVER_IP:19999${RESET}"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
