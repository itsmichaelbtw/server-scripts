#!/usr/bin/env bash
# File path: 02-network/02-nginx/run.sh
# Purpose: Deploy nginx reverse proxy via Docker, bound to the WAN interface.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="02-nginx"
SCRIPT_DESC="Deploy nginx reverse proxy via Docker on the WAN interface."

CONTAINER_NAME="nginx"
CONF_DIR="/opt/nginx/conf.d"
LETSENCRYPT_DIR="/etc/letsencrypt"

print_script_header
validate_environment
ensure_docker
ensure_docker_network

WAN_IP=$(get_wan_ip)
if [[ -z "$WAN_IP" ]]; then
  echo_red "Could not detect WAN IP address."
  exit 1
fi
echo_green "Detected WAN IP: $WAN_IP"

ensure_directory "$CONF_DIR" 755
ensure_directory "$LETSENCRYPT_DIR" 755

# Install default catch-all config only if no configs exist yet
if [[ -z "$(ls -A "$CONF_DIR" 2>/dev/null)" ]]; then
  echo_yellow "No nginx configs found — installing default catch-all config..."
  cp "$SCRIPT_DIR/default.conf" "$CONF_DIR/default.conf"
  chmod 644 "$CONF_DIR/default.conf"
  echo_green "Default config installed at $CONF_DIR/default.conf"
fi

# Allow public HTTP/HTTPS through UFW.
# 'ufw route allow' is required (not 'ufw allow') because Docker container traffic
# passes through the FORWARD chain via ufw-docker integration, not the INPUT chain.
if command -v ufw &>/dev/null; then
  ufw route allow proto tcp to any port 80  >/dev/null 2>&1 || true
  ufw route allow proto tcp to any port 443 >/dev/null 2>&1 || true
  ufw reload                                >/dev/null 2>&1 || true
  echo_green "UFW: allowed route 80/tcp and 443/tcp"
fi

remove_docker_container "$CONTAINER_NAME"
echo_deploying_container "$CONTAINER_NAME" "80/443"

docker run -d \
  --name="$CONTAINER_NAME" \
  --network="$DOCKER_NETWORK_NAME" \
  --restart=unless-stopped \
  -p "$WAN_IP:80:80" \
  -p "$WAN_IP:443:443" \
  -v "$CONF_DIR:/etc/nginx/conf.d:ro" \
  -v "$LETSENCRYPT_DIR:/etc/letsencrypt:ro" \
  nginx:alpine

sleep 3

if verify_container_is_running "$CONTAINER_NAME"; then
  echo_green "$CONTAINER_NAME container is running"
  echo_blue "nginx is bound to $WAN_IP:80 and $WAN_IP:443"
  echo_yellow "Site configs: $CONF_DIR"
  echo_yellow "Certificates: $LETSENCRYPT_DIR"
  exit 0
else
  echo_red "$CONTAINER_NAME container failed to start"
  echo_yellow "Check logs with: docker logs $CONTAINER_NAME"
  exit 1
fi
