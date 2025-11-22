#!/usr/bin/env bash
# File path: 04-orchestration/01-k3s/run.sh
# Purpose: Install k3s lightweight Kubernetes cluster without Traefik, and configure kubectl for an existing deployment user.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="01-k3s"
SCRIPT_DESC="Install k3s lightweight Kubernetes cluster. Traefik will be installed separately. Configure kubectl for an existing deployment user."

print_script_header
validate_environment

while true; do
  read -rp "Install as server (control plane) or agent? [server/agent]: " K3S_ROLE
  if [[ "$K3S_ROLE" == "server" || "$K3S_ROLE" == "agent" ]]; then break; fi
  echo "Please enter 'server' or 'agent'."
done

read -rp "Enter node name (hostname) [$(hostname)]: " NODE_NAME
NODE_NAME="${NODE_NAME:-$(hostname)}"

echo_yellow "Installing k3s..."

if [[ "$K3S_ROLE" == "server" ]]; then
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik --node-name $NODE_NAME" sh -
else
  read -rp "Enter K3S_SERVER_URL (server URL) for agent: " K3S_SERVER_URL
  read -rp "Enter K3S_TOKEN (server token) for agent: " K3S_TOKEN
  curl -sfL https://get.k3s.io | K3S_URL="$K3S_SERVER_URL" K3S_TOKEN="$K3S_TOKEN" sh -
fi

read -rp "Enter the deployment user to use for kubectl (existing user with SSH access): " DEPLOY_USER
if id "$DEPLOY_USER" &>/dev/null; then
  KUBECONFIG_DIR="/home/$DEPLOY_USER/.kube"
  mkdir -p "$KUBECONFIG_DIR"
  cp /etc/rancher/k3s/k3s.yaml "$KUBECONFIG_DIR/config"
  chown -R "$DEPLOY_USER":"$DEPLOY_USER" "$KUBECONFIG_DIR"
  chmod 600 "$KUBECONFIG_DIR/config"
  echo "export KUBECONFIG=$KUBECONFIG_DIR/config" >> "/home/$DEPLOY_USER/.bashrc"
  echo_green "✓ kubectl configured for user $DEPLOY_USER"
else
  echo_red "[WARNING] User $DEPLOY_USER does not exist. Skipping kubectl setup."
fi

echo_yellow "Verifying k3s installation..."
systemctl status k3s --no-pager
k3s kubectl get nodes

echo_green "✓ k3s installation complete. Traefik can be installed separately."
echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
