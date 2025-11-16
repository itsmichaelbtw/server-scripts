#!/usr/bin/env bash
# File path: 04-orchestration/02-traefik/run.sh
# Purpose: Install Traefik as ingress controller on k3s using Helm.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="02-traefik"
SCRIPT_DESC="Install Traefik ingress controller on k3s using Helm."

echo -e "\n${BLUE}Running script: ${SCRIPT_NAME}${RESET}"
echo -e "${BLUE}Description: ${SCRIPT_DESC}${RESET}\n"

validate_environment

if ! command -v k3s &>/dev/null; then
  echo -e "${RED}[ERROR] k3s not installed. Please run 01-k3s first.${RESET}"
  exit 1
fi

if ! systemctl is-active --quiet k3s; then
  echo -e "${RED}[ERROR] k3s service is not running. Please start k3s.${RESET}"
  exit 1
fi

read -rp "Do you want to enable the Traefik dashboard? [y/N]: " ENABLE_DASH
ENABLE_DASH=${ENABLE_DASH:-N}

read -rp "Enter namespace for Traefik [traefik]: " TRAEFIK_NS
TRAEFIK_NS=${TRAEFIK_NS:-traefik}

if ! command -v helm &>/dev/null; then
  echo -e "${YELLOW}Installing Helm...${RESET}"
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

kubectl get namespace "$TRAEFIK_NS" &>/dev/null || \
  kubectl create namespace "$TRAEFIK_NS"

helm repo add traefik https://traefik.github.io/charts
helm repo update

VALUES_FILE="$SCRIPT_DIR/traefik-values.yaml"

cat > "$VALUES_FILE" <<EOF
ports:
  web:
    expose: true
  websecure:
    expose: true
dashboard:
  enabled: ${ENABLE_DASH,,}  # converts Y/N to y/n
EOF

helm upgrade --install traefik traefik/traefik \
  --namespace "$TRAEFIK_NS" \
  -f "$VALUES_FILE"

echo -e "${GREEN}✓ Traefik installed/upgraded successfully in namespace $TRAEFIK_NS.${RESET}"

if [[ "${ENABLE_DASH^^}" == "Y" ]]; then
  echo -e "${YELLOW}Access the dashboard using port-forward:${RESET}"
  echo -e "kubectl --namespace $TRAEFIK_NS port-forward service/traefik 8080:80"
fi

echo -e "${GREEN}Script ${SCRIPT_NAME} finished successfully.${RESET}\n"
