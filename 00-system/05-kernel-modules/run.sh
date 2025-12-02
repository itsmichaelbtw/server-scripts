#!/usr/bin/env bash
# File path: 00-system/05-kernel-modules/run.sh
# Purpose: Load and persist kernel modules required for Kubernetes.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="05-kernel-modules"
SCRIPT_DESC="Load and persist kernel modules (br_netfilter and overlay) required for Kubernetes"

print_script_header
validate_environment

MODULES=("br_netfilter" "overlay")
MODULES_FILE="/etc/modules-load.d/kubernetes.conf"

echo_yellow "Configuring kernel modules for Kubernetes..."

echo_yellow "Creating kernel modules configuration at: $MODULES_FILE"
cat > "$MODULES_FILE" << 'EOF'
# Kernel modules required for Kubernetes
br_netfilter
overlay
EOF

chmod 644 "$MODULES_FILE"
echo_green "✓ Kernel modules configuration created"

for module in "${MODULES[@]}"; do
  echo_yellow "Loading kernel module: $module"
  
  if modprobe "$module" 2>&1; then
    echo_green "✓ Loaded: $module"
  else
    echo_red "[ERROR] Failed to load module: $module"
    exit 1
  fi
done

echo_yellow "\nVerifying modules are loaded..."
for module in "${MODULES[@]}"; do
  if lsmod | grep -q "^$module"; then
    echo_green "✓ Module loaded: $module"
  else
    echo_red "[ERROR] Module verification failed: $module"
    exit 1
  fi
done

echo_green "Script ${SCRIPT_NAME} finished successfully.\n"
