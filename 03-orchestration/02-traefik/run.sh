#!/usr/bin/env bash
# File path: 03-orchestration/02-traefik/run.sh
# Purpose: Install Traefik as ingress controller on k3s using Helm with built-in ACME (Cloudflare DNS)
#          and optionally expose the dashboard via a systemd port-forward service.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="02-traefik"
SCRIPT_DESC="Install Traefik ingress controller on k3s using Helm with ACME/Cloudflare DNS."

print_script_header
validate_environment

if ! does_cmd_exist "k3s" 2>/dev/null; then
  echo_red "[ERROR] k3s not installed. Please run 01-k3s first."
  exit 1
fi

if ! systemctl is-active --quiet k3s; then
  echo_red "[ERROR] k3s service is not running. Please start k3s."
  exit 1
fi

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo_yellow "Waiting for Kubernetes API to be available..."
until kubectl get nodes &>/dev/null; do
  echo -n "."
  sleep 2
done
echo_green "Kubernetes API is ready."

prompt_yes_no "Do you want to enable the Traefik dashboard?" "Y"
ENABLE_DASH=$REPLY

read_from_terminal -rp "Enter namespace for Traefik [traefik]: " TRAEFIK_NS
TRAEFIK_NS=${TRAEFIK_NS:-traefik}

read_from_terminal -rp "Enter your email for ACME certificate registration: " ACME_EMAIL
read_from_terminal -rsp "Enter Cloudflare API Token with DNS edit permissions: " CF_API_TOKEN
echo_newline

export CF_API_TOKEN

if ! does_cmd_exist "helm" 2>/dev/null; then
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
  read_from_terminal -rp "Enter local port to expose the Traefik dashboard [8080]: " DASH_PORT
  DASH_PORT=${DASH_PORT:-8080}

  echo_yellow "Creating systemd service for Traefik dashboard port-forward..."
  SERVICE_TEMPLATE="$SCRIPT_DIR/traefik.service.tmpl"
  SERVICE_FILE="/etc/systemd/system/traefik-dashboard-portforward.service"

  render_template_config "$SERVICE_TEMPLATE" "$SERVICE_FILE" 644 \
    -e "s|{{TRAEFIK_NS}}|$TRAEFIK_NS|g" \
    -e "s|{{DASH_PORT}}|$DASH_PORT|g"

  sudo systemctl daemon-reload
  sudo systemctl enable --now traefik-dashboard-portforward

  display_service_url "Traefik Dashboard" "$DASH_PORT"
  echo_green "✓ Systemd service created and started."
fi

echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
