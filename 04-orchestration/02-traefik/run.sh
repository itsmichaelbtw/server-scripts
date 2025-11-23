#!/usr/bin/env bash
# File path: 04-orchestration/02-traefik/run.sh
# Purpose: Install Traefik as ingress controller on k3s using Helm with built-in ACME (Cloudflare DNS).

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="02-traefik"
SCRIPT_DESC="Install Traefik ingress controller on k3s using Helm with ACME/Cloudflare DNS for automatic TLS."

print_script_header
validate_environment

if ! command -v k3s &>/dev/null; then
  echo_red "[ERROR] k3s not installed. Please run 01-k3s first."
  exit 1
fi

if ! systemctl is-active --quiet k3s; then
  echo_red "[ERROR] k3s service is not running. Please start k3s."
  exit 1
fi

prompt_yes_no "Do you want to enable the Traefik dashboard?" "Y"
ENABLE_DASH=$REPLY

read_from_terminal -rp "Enter namespace for Traefik [traefik]: " TRAEFIK_NS
TRAEFIK_NS=${TRAEFIK_NS:-traefik}

read_from_terminal -rp "Enter your email for ACME certificate registration: " ACME_EMAIL
read_from_terminal -rsp "Enter Cloudflare API Token with DNS edit permissions: " CF_API_TOKEN
echo ""

export CF_API_TOKEN

if ! command -v helm &>/dev/null; then
  echo_yellow "Installing Helm..."
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

kubectl get namespace "$TRAEFIK_NS" &>/dev/null || kubectl create namespace "$TRAEFIK_NS"

helm repo add traefik https://traefik.github.io/charts
helm repo update

TEMPLATE_FILE="$SCRIPT_DIR/traefik.conf"
VALUES_FILE="$SCRIPT_DIR/traefik.conf"

render_template_config "$TEMPLATE_FILE" "$VALUES_FILE" 644 \
  -e "s|{{DASHBOARD_ENABLED}}|$(echo "$ENABLE_DASH" | tr '[:upper:]' '[:lower:]')|g" \
  -e "s|{{ACME_EMAIL}}|$ACME_EMAIL|g"

helm upgrade --install traefik traefik/traefik \
  --namespace "$TRAEFIK_NS" \
  -f "$VALUES_FILE"

echo_green "✓ Traefik installed/upgraded successfully in namespace $TRAEFIK_NS with ACME/Cloudflare DNS."

if [[ "${ENABLE_DASH^^}" == "Y" ]]; then
  echo_yellow "Access the dashboard using port-forward:"
  echo -e "kubectl --namespace $TRAEFIK_NS port-forward service/traefik 8080:80"
  
  echo_yellow "Note: After starting port-forward, the dashboard will be accessible at:"
  display_service_url "Traefik Dashboard" "8080"
fi

echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
