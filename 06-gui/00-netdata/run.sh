#!/usr/bin/env bash
# File path: 06-gui/00-netdata/run.sh
# Purpose: Deploy NetData monitoring dashboard in Docker.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="00-netdata"
SCRIPT_DESC="Deploy NetData real-time monitoring via Docker."

print_script_header
validate_environment
ensure_docker

if docker ps -a --format '{{.Names}}' | grep -q '^netdata$'; then
  echo -e "${YELLOW}Stopping and removing existing NetData container...${RESET}"
  docker stop netdata
  docker rm netdata
fi

echo -e "${YELLOW}Deploying NetData container...${RESET}"

prompt_for_port "Enter port for NetData dashboard" "19999"
NETDATA_PORT="$PORT_REPLY"

docker run -d \
  --name=netdata \
  --restart=unless-stopped \
  -p "$NETDATA_PORT:19999" \
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

display_service_url "NetData" "$NETDATA_PORT"
echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
