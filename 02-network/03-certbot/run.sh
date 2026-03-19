#!/usr/bin/env bash
# File path: 02-network/03-certbot/run.sh
# Purpose: Manage Let's Encrypt certificates via Certbot with Cloudflare DNS challenge.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="03-certbot"
SCRIPT_DESC="Manage Let's Encrypt certificates with Cloudflare DNS challenge."

CERTBOT_IMAGE="certbot/dns-cloudflare"
LETSENCRYPT_DIR="/etc/letsencrypt"
LIB_DIR="/var/lib/letsencrypt"
CLOUDFLARE_CREDS="$LETSENCRYPT_DIR/cloudflare.ini"
EMAIL_FILE="$LETSENCRYPT_DIR/.email"

print_script_header
validate_environment
ensure_docker

install_certbot() {
  echo_newline
  echo_blue "First-time Certbot setup with Cloudflare DNS"

  ensure_directory "$LETSENCRYPT_DIR" 755
  ensure_directory "$LIB_DIR" 755

  echo_yellow "Pulling $CERTBOT_IMAGE image..."
  docker pull "$CERTBOT_IMAGE"
  echo_green "Certbot image ready."

  echo_newline
  echo_yellow "A Cloudflare API token is required for DNS challenge validation."
  echo_yellow "Create one at: https://dash.cloudflare.com/profile/api-tokens"
  echo_yellow "Required permission: Zone > DNS > Edit (for all zones or specific zone)"
  echo_newline

  while true; do
    read_from_terminal -rsp "Enter your Cloudflare API token: " CF_TOKEN
    echo_newline
    [[ -n "$CF_TOKEN" ]] && break
    echo_red "Token cannot be empty."
  done

  while true; do
    read_from_terminal -rp "Enter your email address (used for Let's Encrypt account): " CF_EMAIL
    [[ -n "$CF_EMAIL" ]] && break
    echo_red "Email cannot be empty."
  done

  # Write credentials file with strict permissions (certbot requires 600 or 400)
  cat > "$CLOUDFLARE_CREDS" <<EOF
# Cloudflare API token — generated at https://dash.cloudflare.com/profile/api-tokens
dns_cloudflare_api_token = $CF_TOKEN
EOF
  chmod 600 "$CLOUDFLARE_CREDS"
  echo_green "Cloudflare credentials saved to $CLOUDFLARE_CREDS"

  # Persist email for future certificate requests
  echo "$CF_EMAIL" > "$EMAIL_FILE"
  chmod 600 "$EMAIL_FILE"

  local RENEW_CMD="docker run --rm \
    -v ${LETSENCRYPT_DIR}:/etc/letsencrypt \
    -v ${LIB_DIR}:/var/lib/letsencrypt \
    ${CERTBOT_IMAGE} renew --quiet"
  setup_cron_job "$RENEW_CMD" "0 3 * * *" "certbot-renew"

  echo_green "Certbot is configured. Use 'Add domain' to issue your first certificate."
}

add_domain() {
  echo_newline
  echo_blue "Issue a Let's Encrypt certificate"

  if [[ ! -f "$CLOUDFLARE_CREDS" ]]; then
    echo_red "Certbot is not configured. Run 'Install Certbot' first."
    return
  fi

  if [[ ! -f "$EMAIL_FILE" ]]; then
    echo_red "Email not found. Run 'Install Certbot' first."
    return
  fi

  local CF_EMAIL
  CF_EMAIL=$(cat "$EMAIL_FILE")

  while true; do
    read_from_terminal -rp "Enter domain name (e.g. example.com): " DOMAIN
    [[ -n "$DOMAIN" ]] && break
    echo_red "Domain cannot be empty."
  done

  prompt_yes_no "Include wildcard certificate (*.${DOMAIN})?" "Y"
  local INCLUDE_WILDCARD="$REPLY"

  local DOMAIN_ARGS=("-d" "$DOMAIN")
  if [[ "$INCLUDE_WILDCARD" == "Y" ]]; then
    DOMAIN_ARGS+=("-d" "*.${DOMAIN}")
  fi

  echo_yellow "Requesting certificate for $DOMAIN — this may take up to 60 seconds..."

  docker run --rm \
    -v "$LETSENCRYPT_DIR:/etc/letsencrypt" \
    -v "$LIB_DIR:/var/lib/letsencrypt" \
    "$CERTBOT_IMAGE" certonly \
    --dns-cloudflare \
    --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
    --dns-cloudflare-propagation-seconds 30 \
    "${DOMAIN_ARGS[@]}" \
    --agree-tos \
    --email "$CF_EMAIL" \
    --non-interactive

  echo_green "Certificate issued successfully for $DOMAIN"
  echo_newline
  echo_yellow "Certificate paths (use in your nginx config):"
  echo_blue "  ssl_certificate     /etc/letsencrypt/live/$DOMAIN/fullchain.pem;"
  echo_blue "  ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;"
}

list_certificates() {
  echo_newline
  echo_blue "Installed certificates and expiry dates"

  if [[ ! -d "$LETSENCRYPT_DIR/live" ]]; then
    echo_yellow "No certificates found in $LETSENCRYPT_DIR/live"
    return
  fi

  docker run --rm \
    -v "$LETSENCRYPT_DIR:/etc/letsencrypt" \
    -v "$LIB_DIR:/var/lib/letsencrypt" \
    "$CERTBOT_IMAGE" certificates
}

revoke_certificate() {
  echo_newline
  echo_blue "Revoke and delete a certificate"

  if [[ ! -f "$CLOUDFLARE_CREDS" ]]; then
    echo_red "Certbot is not configured. Run 'Install Certbot' first."
    return
  fi

  if [[ ! -d "$LETSENCRYPT_DIR/live" ]]; then
    echo_yellow "No certificates found in $LETSENCRYPT_DIR/live"
    return
  fi

  echo_yellow "Available certificates:"
  echo_newline
  for cert_dir in "$LETSENCRYPT_DIR/live"/*/; do
    [[ -d "$cert_dir" ]] || continue
    echo_blue "  $(basename "$cert_dir")"
  done
  echo_newline

  while true; do
    read_from_terminal -rp "Enter the domain name to revoke (e.g. example.com): " DOMAIN
    [[ -n "$DOMAIN" ]] && break
    echo_red "Domain cannot be empty."
  done

  local CERT_PATH="/etc/letsencrypt/live/$DOMAIN/cert.pem"

  if [[ ! -f "$LETSENCRYPT_DIR/live/$DOMAIN/cert.pem" ]]; then
    echo_red "No certificate found for $DOMAIN"
    return
  fi

  echo_newline
  echo_red "WARNING: This will revoke and permanently delete the certificate for $DOMAIN."
  prompt_yes_no "Are you sure you want to continue?" "N"
  if [[ "$REPLY" != "Y" ]]; then
    echo_yellow "Aborted."
    return
  fi

  echo_yellow "Revoking certificate for $DOMAIN..."

  docker run --rm \
    -v "$LETSENCRYPT_DIR:/etc/letsencrypt" \
    -v "$LIB_DIR:/var/lib/letsencrypt" \
    "$CERTBOT_IMAGE" revoke \
    --cert-path "$CERT_PATH" \
    --delete-after-revoke \
    --non-interactive

  echo_green "Certificate for $DOMAIN has been revoked and deleted."
}

renew_now() {
  echo_newline
  echo_blue "Renewing all certificates now"

  if [[ ! -f "$CLOUDFLARE_CREDS" ]]; then
    echo_red "Certbot is not configured. Run 'Install Certbot' first."
    return
  fi

  echo_yellow "Running certbot renew — certificates due for renewal will be updated..."

  docker run --rm \
    -v "$LETSENCRYPT_DIR:/etc/letsencrypt" \
    -v "$LIB_DIR:/var/lib/letsencrypt" \
    "$CERTBOT_IMAGE" renew \
    --dns-cloudflare \
    --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
    --dns-cloudflare-propagation-seconds 30

  echo_green "Renewal complete."
  echo_yellow "Reload nginx to apply any updated certificates:"
  echo_blue "  docker exec nginx nginx -s reload"
}

while true; do
  show_menu "Certbot Management" \
    "Install Certbot (first-time setup)" \
    "Add domain / issue certificate" \
    "List certificates and expiry" \
    "Renew certificates now" \
    "Revoke and delete a certificate" \
    "Exit"
  case "$MENU_CHOICE" in
    1) install_certbot ;;
    2) add_domain ;;
    3) list_certificates ;;
    4) renew_now ;;
    5) revoke_certificate ;;
    6) echo_green "Exiting."; exit 0 ;;
  esac
done
