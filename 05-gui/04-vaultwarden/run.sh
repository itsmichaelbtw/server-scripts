#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="04-vaultwarden"
SCRIPT_DESC="Deploy and manage Vaultwarden self-hosted password manager via Docker."

CONTAINER_NAME=vaultwarden
require_env "VAULTWARDEN_PORT"
CONTAINER_PORT="$VAULTWARDEN_PORT"
VAULTWARDEN_DATA_DIR="${VAULTWARDEN_DATA_DIR:-/vw-data}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/vaultwarden}"
BACKUP_KEEP_DAYS="${BACKUP_KEEP_DAYS:-30}"

print_script_header
validate_environment

deploy_vaultwarden() {
  require_cmd "argon2" "argon2"
  local ADMIN_TOKEN_PLAIN ADMIN_TOKEN_SALT ADMIN_TOKEN SSL_DIR
  ADMIN_TOKEN_PLAIN=$(openssl rand -base64 48)
  ADMIN_TOKEN_SALT=$(openssl rand -base64 32)
  ADMIN_TOKEN=$(echo -n "$ADMIN_TOKEN_PLAIN" | argon2 "$ADMIN_TOKEN_SALT" -id -t 1 -m 16 -p 4 -l 32 -e)

  ensure_docker
  ensure_docker_network

  remove_docker_container "$CONTAINER_NAME"
  echo_deploying_container "$CONTAINER_NAME" "$CONTAINER_PORT"
  configure_ufw_for_wireguard "$CONTAINER_PORT" tcp

  ensure_directory "$VAULTWARDEN_DATA_DIR" 700

  SSL_DIR="$VAULTWARDEN_DATA_DIR/ssl"
  ensure_directory "$SSL_DIR" 700

  if [[ ! -f "$SSL_DIR/vw.crt" ]]; then
    echo_blue "Generating self-signed TLS certificate for Vaultwarden..."
    openssl genpkey -algorithm RSA -out "$SSL_DIR/vw.key" -pkeyopt rsa_keygen_bits:2048 2>/dev/null
    openssl req -new -x509 -key "$SSL_DIR/vw.key" -out "$SSL_DIR/vw.crt" -days 730 -sha256 \
      -subj "/CN=vaultwarden" 2>/dev/null
    echo_green "TLS certificate generated."
  fi

  docker run -d \
    --name="$CONTAINER_NAME" \
    --network="$DOCKER_NETWORK_NAME" \
    --restart=unless-stopped \
    -p "$CONTAINER_PORT:80" \
    -v "$VAULTWARDEN_DATA_DIR:/data/" \
    -v "$SSL_DIR:/ssl" \
    -e ADMIN_TOKEN="$ADMIN_TOKEN" \
    -e ROCKET_TLS='{certs="/ssl/vw.crt",key="/ssl/vw.key"}' \
    -e DOMAIN="https://localhost:$CONTAINER_PORT" \
    -e LOG_LEVEL=info \
    vaultwarden/server:latest

  sleep 3

  if verify_container_is_running "$CONTAINER_NAME"; then
    echo_green "$CONTAINER_NAME container is running"
    echo_blue "Admin panel token (use this to log in): $ADMIN_TOKEN_PLAIN"
    echo_blue "Data persisted in: $VAULTWARDEN_DATA_DIR"
    echo_blue "Access at: https://localhost:$CONTAINER_PORT"
  else
    echo_red "$CONTAINER_NAME container failed to start"
    echo_yellow "Check logs with: docker logs $CONTAINER_NAME"
  fi
}

run_backup() {
  if [[ ! -d "$VAULTWARDEN_DATA_DIR" ]]; then
    echo_red "Vaultwarden data directory not found: $VAULTWARDEN_DATA_DIR"
    echo_yellow "Set VAULTWARDEN_DATA_DIR to override the default (/vw-data)."
    return 1
  fi

  ensure_directory "$BACKUP_DIR" 700

  stop_docker_container "$CONTAINER_NAME"

  local TIMESTAMP BACKUP_FILE BACKUP_SIZE
  TIMESTAMP=$(date +%Y%m%d-%H%M%S)
  BACKUP_FILE="$BACKUP_DIR/vaultwarden-$TIMESTAMP.tar.gz"

  echo_blue "Creating backup: $BACKUP_FILE"
  tar -czf "$BACKUP_FILE" -C "$(dirname "$VAULTWARDEN_DATA_DIR")" "$(basename "$VAULTWARDEN_DATA_DIR")"
  chmod 600 "$BACKUP_FILE"
  BACKUP_SIZE=$(du -sh "$BACKUP_FILE" | cut -f1)
  echo_green "Backup created: $BACKUP_FILE ($BACKUP_SIZE)"

  if [[ "$CONTAINER_WAS_RUNNING" == true ]]; then
    echo_yellow "Restarting $CONTAINER_NAME..."
    docker start "$CONTAINER_NAME" >/dev/null
    echo_green "$CONTAINER_NAME restarted."
  fi

  if [[ "$BACKUP_KEEP_DAYS" -gt 0 ]]; then
    echo_blue "Removing backups older than $BACKUP_KEEP_DAYS days..."
    find "$BACKUP_DIR" -name "vaultwarden-*.tar.gz" -mtime +"$BACKUP_KEEP_DAYS" -delete
    echo_green "Old backups pruned."
  fi

  if [[ -n "${BACKUP_REMOTE_DEST:-}" ]]; then
    echo_blue "Syncing backups to remote: $BACKUP_REMOTE_DEST"
    require_cmd "rsync" "rsync"
    rsync -az --delete "$BACKUP_DIR/" "$BACKUP_REMOTE_DEST"
    echo_green "Remote sync complete."
  fi

  echo_green "Vaultwarden backup finished."

  local BACKUP_CMD
  BACKUP_CMD="bash $(realpath "$0") --backup"
  setup_cron_job "$BACKUP_CMD" "0 3 * * *" "vaultwarden-backup"
}

restore_backup() {
  if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls "$BACKUP_DIR"/vaultwarden-*.tar.gz 2>/dev/null)" ]]; then
    echo_red "No backups found in $BACKUP_DIR."
    return 1
  fi

  # Build numbered list of backups (newest first)
  local -a BACKUPS
  mapfile -t BACKUPS < <(ls -t "$BACKUP_DIR"/vaultwarden-*.tar.gz 2>/dev/null)

  local MENU_OPTIONS=()
  local i
  for (( i=0; i<${#BACKUPS[@]}; i++ )); do
    local FNAME SIZE
    FNAME=$(basename "${BACKUPS[$i]}")
    SIZE=$(du -sh "${BACKUPS[$i]}" | cut -f1)
    MENU_OPTIONS+=("$FNAME  ($SIZE)")
  done
  MENU_OPTIONS+=("Cancel")

  show_menu "Select a backup to restore" "${MENU_OPTIONS[@]}"

  local CANCEL_IDX=$(( ${#BACKUPS[@]} + 1 ))
  if [[ "$MENU_CHOICE" -eq "$CANCEL_IDX" ]]; then
    echo_yellow "Restore cancelled."
    return 0
  fi

  local CHOSEN_FILE="${BACKUPS[$(( MENU_CHOICE - 1 ))]}"
  echo_yellow "Selected: $(basename "$CHOSEN_FILE")"

  prompt_yes_no "This will OVERWRITE $VAULTWARDEN_DATA_DIR. Continue?" "N"
  if [[ "$REPLY" != "Y" ]]; then
    echo_yellow "Restore cancelled."
    return 0
  fi

  # Stop container if running
  stop_docker_container "$CONTAINER_NAME"

  # Snapshot existing data before overwriting
  if [[ -d "$VAULTWARDEN_DATA_DIR" ]]; then
    local PRE_RESTORE_BACKUP
    PRE_RESTORE_BACKUP="$BACKUP_DIR/vaultwarden-pre-restore-$(date +%Y%m%d-%H%M%S).tar.gz"
    echo_blue "Snapshotting current data to: $PRE_RESTORE_BACKUP"
    tar -czf "$PRE_RESTORE_BACKUP" -C "$(dirname "$VAULTWARDEN_DATA_DIR")" "$(basename "$VAULTWARDEN_DATA_DIR")"
    chmod 600 "$PRE_RESTORE_BACKUP"
    echo_green "Snapshot created."
  fi

  echo_blue "Restoring from $(basename "$CHOSEN_FILE")..."
  rm -rf "$VAULTWARDEN_DATA_DIR"
  tar -xzf "$CHOSEN_FILE" -C "$(dirname "$VAULTWARDEN_DATA_DIR")"
  chmod 700 "$VAULTWARDEN_DATA_DIR"
  echo_green "Restore complete: $VAULTWARDEN_DATA_DIR"

  if [[ "$CONTAINER_WAS_RUNNING" == true ]]; then
    echo_yellow "Restarting $CONTAINER_NAME..."
    docker start "$CONTAINER_NAME" >/dev/null
    echo_green "$CONTAINER_NAME restarted."
  fi
}

# ── Menu ──────────────────────────────────────────────────────────────────────

while true; do
  show_menu "Vaultwarden Management" \
    "Deploy Vaultwarden" \
    "Backup data now" \
    "Restore from backup" \
    "Exit"
  case "$MENU_CHOICE" in
    1) deploy_vaultwarden ;;
    2) run_backup ;;
    3) restore_backup ;;
    4) echo_green "Exiting."; exit 0 ;;
  esac
done

