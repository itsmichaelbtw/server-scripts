#!/usr/bin/env bash
# common.sh
# Shared functions for system provisioning scripts

set -euo pipefail

GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
RED="\033[1;31m"
RESET="\033[0m"

DOCKER_NETWORK_NAME="server_network"

# Function to print a newline
# Usage: echo_newline
# Example:
#   echo_newline
echo_newline() {
  echo ""
}

# Function to print text in green
# Usage: echo_green "Success message"
# Example:
#   echo_green "Operation completed"
echo_green() {
  echo -e "${GREEN}$*${RESET}"
}

# Function to print text in yellow
# Usage: echo_yellow "Warning message"
# Example:
#   echo_yellow "Please review this"
echo_yellow() {
  echo -e "${YELLOW}$*${RESET}"
}

# Function to print text in blue
# Usage: echo_blue "Info message"
# Example:
#   echo_blue "ℹ Processing..."
echo_blue() {
  echo -e "${BLUE}$*${RESET}"
}

# Function to print text in red
# Usage: echo_red "Error message"
# Example:
#   echo_red "[ERROR] Something failed"
echo_red() {
  echo -e "${RED}✗ $*${RESET}"
}

# Function to read input from terminal, ensuring stdin is /dev/tty
# Usage: read_from_terminal [-p "prompt"] [-r] [variable_name]
# Example:
#   read_from_terminal -p "Enter value: " -r user_input
#   echo $user_input
read_from_terminal() {
  read "$@" </dev/tty
}

# Function to check if running on macOS
# Usage: is_macos && echo "This is macOS"
# Example:
#   if is_macos; then echo "macOS detected"; fi
is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

# Function to check if running on Ubuntu
# Usage: is_ubuntu && echo "This is Ubuntu"
# Example:
#   if is_ubuntu; then echo "Ubuntu detected"; fi
is_ubuntu() {
  [[ -f /etc/os-release ]] && grep -qi 'ubuntu' /etc/os-release 2>/dev/null
}

# Function to check if script is run with root privileges
# Usage: ensure_root
# Example:
#   ensure_root
# Exits with error message if not run as root
ensure_root() {
  if [[ "$EUID" -ne 0 ]]; then
    echo_red "[ERROR] This script must be run as root."
    echo_yellow "Try: sudo $0"
    exit 1
  fi
}

# Function to verify the system is running Ubuntu
# Usage: ensure_ubuntu
# Example:
#   ensure_ubuntu
# Exits with error message if not running on Ubuntu
ensure_ubuntu() {
  if ! is_ubuntu; then
    echo_red "[ERROR] This script is intended for Ubuntu systems only."
    exit 1
  fi
}

# Function to validate the execution environment
# Usage: validate_environment
# Example:
#   validate_environment
# Ensures script is run as root on an Ubuntu system
validate_environment() {
  ensure_root
  ensure_ubuntu
  echo_green "Environment validated."
}

# Function to load environment variables from .env file
# Usage: load_env
# Example:
#   load_env
# Loads .env file from the script's directory if it exists
load_env() {
  local SCRIPT_DIR="${1:-.}"
  local ENV_FILE="$SCRIPT_DIR/.env"
  
  if [[ -f "$ENV_FILE" ]]; then
    echo_blue "Loading configuration from .env file..."
    source "$ENV_FILE"
  fi
}

# Function to check if a command exists
# Usage: does_cmd_exist "command_name"
# Example:
#   if does_cmd_exist "docker"; then echo "Docker is installed"; fi
does_cmd_exist() {
  local CMD_NAME="$1"
  if command -v "$CMD_NAME" &>/dev/null; then
    echo_green "$CMD_NAME is installed"
    return 0
  else
    echo_yellow "$CMD_NAME is not installed"
    return 1
  fi
}

# Function to require a command and attempt to install if not exists
# Usage: require_cmd "command_name" [package_name]
# Example:
#   require_cmd "docker" "docker.io"
#   require_cmd "git"
require_cmd() {
  local CMD_NAME="$1"
  local PKG_NAME="${2:-$CMD_NAME}"
  
  if command -v "$CMD_NAME" &>/dev/null; then
    echo_green "$CMD_NAME is already installed"
    return 0
  fi
  
  echo_yellow "$CMD_NAME is not installed. Attempting to install $PKG_NAME..."
  
  if command -v apt-get &>/dev/null; then
    apt-get update -qq
    apt-get install -y "$PKG_NAME" >/dev/null 2>&1 || {
      echo_red "[ERROR] Failed to install $PKG_NAME via apt-get"
      return 1
    }
  else
    echo_red "[ERROR] No package manager found (apt-get, yum, or brew). Please install $PKG_NAME manually."
    return 1
  fi
  
  if command -v "$CMD_NAME" &>/dev/null; then
    echo_green "$CMD_NAME installed successfully"
    return 0
  else
    echo_red "[ERROR] $CMD_NAME installation verification failed"
    return 1
  fi
}

# Function to get the actual user (handles sudo)
# Usage: ACTUAL_USER=$(get_actual_user)
# Example:
#   USER_HOME=$(eval echo "~$(get_actual_user)")
get_actual_user() {
  if [[ -n "${SUDO_USER:-}" ]]; then
    echo "$SUDO_USER"
  else
    echo "${USER:-root}"
  fi
}

# Function to display service URL after deployment
# Usage: display_service_url "Service Name" port_number [path]
# Example:
#   display_service_url "MyApp" 8080
#   display_service_url "Loki" 3100 "/loki/api/v1/query"
# Displays formatted localhost access URL with optional path
display_service_url() {
  local SERVICE_NAME="$1"
  local PORT="$2"
  local PATH="${3:-}"

  echo_green "$SERVICE_NAME deployed successfully."
  echo_yellow "Access the service at: http://localhost:$PORT$PATH"
}

# Function to prompt user for yes/no input
# Usage: prompt_yes_no "Do you want to enable feature X?" [Y|N]
# Example:
#   prompt_yes_no "Continue?" "N"; echo $REPLY
# Returns: Uppercase Y or N in the variable $REPLY
prompt_yes_no() {
  local PROMPT="$1"
  local DEFAULT="${2:-Y}"
  local VALID_DEFAULT="${DEFAULT^^}"
  
  if [[ "$VALID_DEFAULT" != "Y" && "$VALID_DEFAULT" != "N" ]]; then
    VALID_DEFAULT="Y"
  fi
  
  local PROMPT_TEXT="$PROMPT [$([[ $VALID_DEFAULT == Y ]] && echo_yellow "Y/n" || echo_yellow "y/N")]: "
  
  while true; do
    read_from_terminal -rp "$PROMPT_TEXT" REPLY
    REPLY=${REPLY:-$VALID_DEFAULT}
    case "${REPLY^^}" in
      Y|N) REPLY="${REPLY^^}"; break ;;
      *) echo_yellow "Please enter Y or N." ;;
    esac
  done
}

# Function to prompt for a valid network port number
# Usage: prompt_for_port "Enter port for service" [default_port]
# Example:
#   prompt_for_port "Enter port" 8080; echo $PORT_REPLY
# Returns: The valid port number in the variable $PORT_REPLY
prompt_for_port() {
  local PROMPT="$1"
  local DEFAULT="${2:-8080}"
  local PORT_VALUE
  
  while true; do
    read_from_terminal -rp "$PROMPT (default: $DEFAULT): " PORT_VALUE
    PORT_VALUE="${PORT_VALUE:-$DEFAULT}"
    
    if [[ "$PORT_VALUE" =~ ^[0-9]+$ ]] && (( PORT_VALUE >= 1 && PORT_VALUE <= 65535 )); then
      PORT_REPLY="$PORT_VALUE"
      break
    else
      echo_yellow "Invalid port. Please enter a number between 1-65535."
    fi
  done
}

# Function to print script name and description in color
# Usage: print_script_header
# Example:
#   print_script_header
print_script_header() {
  if [[ -n "${SCRIPT_NAME:-}" ]]; then
    echo_newline
    echo_blue "Running script: ${SCRIPT_NAME}"
  fi

  if [[ -n "${SCRIPT_DESC:-}" ]]; then
    echo_blue "Description: ${SCRIPT_DESC}"
    echo_newline
  fi
}

# Function to check if a cron job already exists in the system crontab
# Usage: cron_job_exists "command_to_check"
# Example:
#   if cron_job_exists "rkhunter"; then echo "Already scheduled"; fi
# Returns: 0 if job exists, 1 if not
# Notes:
#   - Checks both global cron files in /etc/cron.d/ and user-level crontab
cron_job_exists() {
  local CRON_CMD="$1"
  
  if grep -r -F "$CRON_CMD" /etc/cron.d/ 2>/dev/null | grep -v '^#' | grep -q .; then
    return 0
  fi

  if crontab -l 2>/dev/null | grep -q -F "$CRON_CMD"; then
    return 0
  fi
  
  return 1
}

# Function to schedule a task as a global system cron job (stored in /etc/cron.d/)
# Usage: setup_cron_job "Command to run" ["default schedule"] ["job_identifier"]
# Example:
#   setup_cron_job "rkhunter --propupd && rkhunter --check --skip-keypress" "30 2 * * *" "rkhunter-daily"
#   setup_cron_job "lynis audit system" "0 4 * * *" "lynis-daily"
# Parameters:
#   $1: The command to schedule in crontab
#   $2: Default schedule (optional, defaults to "0 3 * * *" - 3 AM daily)
#   $3: Job identifier/name (optional, used as filename in /etc/cron.d/)
# Notes:
#   - Stores jobs in /etc/cron.d/ for GLOBAL SYSTEM-WIDE access
#   - Prevents duplicate entries by checking before adding
#   - Requires root privileges (validated by ensure_root in setup)
#   - Jobs run as root and are visible from any user account
#   - Sets $CRON_SETUP_SUCCESS to true/false for caller to check
setup_cron_job() {
  local CRON_CMD="$1"
  local DEFAULT_SCHEDULE="${2:-0 3 * * *}"
  local JOB_IDENTIFIER="${3:-provisioning}"
  local CRON_PATTERN
  local CRON_FILE
  local ERROR_OUTPUT

  JOB_IDENTIFIER=$(echo "$JOB_IDENTIFIER" | sed 's/[^a-zA-Z0-9_-]/-/g')
  CRON_FILE="/etc/cron.d/${JOB_IDENTIFIER}-cron"

  if cron_job_exists "$CRON_CMD"; then
    echo_yellow "This job already exists in cron. Skipping duplicate..."
    CRON_SETUP_SUCCESS=true
    return 0
  fi

  prompt_yes_no "Do you want to schedule this job via CRON?" "Y"
  
  if [[ "$REPLY" == "Y" ]]; then
    read_from_terminal -rp "Enter CRON schedule (minute hour day month day_of_week) or leave empty for default ($DEFAULT_SCHEDULE): " CRON_PATTERN
    CRON_PATTERN="${CRON_PATTERN:-$DEFAULT_SCHEDULE}"
    ERROR_OUTPUT=$(mktemp)

    local CRON_LINE="$CRON_PATTERN root $CRON_CMD"
    
    if echo "$CRON_LINE" > "$CRON_FILE" 2>"$ERROR_OUTPUT"; then
      chmod 644 "$CRON_FILE"
      
      if cron_job_exists "$CRON_CMD"; then
        echo_green "Job scheduled in $CRON_FILE"
        echo_green "  Schedule: $CRON_PATTERN"
        echo_green "  Command: $CRON_CMD"
        CRON_SETUP_SUCCESS=true
      else
        echo_red "[ERROR] Failed to verify job was added to cron."
        CRON_SETUP_SUCCESS=false
      fi
    else
      echo_red "[ERROR] Failed to write cron job file."
      if [[ -s "$ERROR_OUTPUT" ]]; then
        echo_red "Error details:"
        cat "$ERROR_OUTPUT" | sed "s/^/  /"
      fi
      CRON_SETUP_SUCCESS=false
    fi
    rm -f "$ERROR_OUTPUT"
  else
    echo_yellow "CRON scheduling skipped."
    CRON_SETUP_SUCCESS=false
  fi
}

# Function to dynamically find and run scripts in a directory
# Usage: find_and_run_scripts base_directory
# Example:
#   find_and_run_scripts "./00-system"
# Parameters:
#   $1: Base directory to search for run.sh scripts
execute_run_sh() {
  local BASE_DIR SCRIPT_PATH RUN_FILES REL_PATH

  SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)/$(basename "${BASH_SOURCE[1]}")"
  BASE_DIR="$(dirname "$SCRIPT_PATH")"

  local REL_BASE_DIR REL_SCRIPT_PATH
  REL_BASE_DIR="$BASE_DIR"
  REL_SCRIPT_PATH="$SCRIPT_PATH"
  [[ "$BASE_DIR" == "$PWD"* ]] && REL_BASE_DIR=".${BASE_DIR#$PWD}"
  [[ "$SCRIPT_PATH" == "$PWD"* ]] && REL_SCRIPT_PATH=".${SCRIPT_PATH#$PWD}"

  echo_yellow "Searching for 'run.sh' files in $REL_BASE_DIR (excluding $REL_SCRIPT_PATH)..."
  echo_newline
  RUN_FILES=$(find "$BASE_DIR" -type f -name "run.sh" ! -path "$SCRIPT_PATH" | sort)
  if [[ -z "$RUN_FILES" ]]; then
    echo_red "No run.sh files found."
    return
  fi

  echo_blue "Found the following run.sh files:"
  while IFS= read -r file; do
    REL_PATH="${file#$BASE_DIR/}"
    echo_yellow "  - $REL_PATH"
  done <<< "$RUN_FILES"
  echo_newline

  while IFS= read -r file; do
    REL_PATH="${file#$BASE_DIR/}"
    prompt_yes_no "Do you want to execute '$REL_PATH'?" "Y"
    if [[ "$REPLY" == "Y" ]]; then
      echo_yellow "Executing $REL_PATH ..."

      set +e
      bash "$file"
      local EXIT_CODE=$?
      set -e
      if [[ $EXIT_CODE -ne 0 ]]; then
        echo_yellow "Warning: $REL_PATH exited with status $EXIT_CODE, continuing..."
      fi
    else
      echo_yellow "Skipping $REL_PATH."
    fi
  done <<< "$RUN_FILES"

  echo_green "All done."
}

# Function to backup a config file if it exists
# Usage: backup_config_file "/etc/ssh/sshd_config"
# Example:
#   backup_config_file "/etc/ssh/sshd_config"
backup_config_file() {
  local TARGET_FILE="$1"
  if [[ -f "$TARGET_FILE" ]]; then
    local BACKUP_FILE="${TARGET_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
    cp "$TARGET_FILE" "$BACKUP_FILE"
    echo_green "Backup created at: $BACKUP_FILE"
  fi
}

# Function to validate a config file and clean up temp files
# Usage: validate_and_cleanup <temp_file> <target_file> <perms> [<validate_cmd>]
# Example:
#   validate_and_cleanup "$temp_output" "/etc/ssh/sshd_config" 600 "sshd -t -f"
validate_and_cleanup() {
  local TEMP_FILE="$1"
  local TARGET_FILE="$2"
  local PERMS="$3"
  local VALIDATE_CMD="$4"

  if [[ -n "$VALIDATE_CMD" ]]; then
    if ! $VALIDATE_CMD "$TEMP_FILE"; then
      echo_red "[ERROR] Validation failed for $TEMP_FILE. Not applying config."
      rm -f "$TEMP_FILE"
      exit 1
    fi
    echo_green "Config validated successfully."
  fi

  cp "$TEMP_FILE" "$TARGET_FILE"
  chmod "$PERMS" "$TARGET_FILE"
  rm -f "$TEMP_FILE"
  echo_green "Applied new config: $TARGET_FILE"
}

# Function to ensure a directory exists with proper permissions
# Usage: ensure_directory "/path/to/dir" [permissions]
# Example:
#   ensure_directory "/etc/prometheus" 755
#   ensure_directory "/data/config" 700
# Parameters:
#   $1: Directory path to create/ensure exists
#   $2: Permissions (optional, defaults to 755)
ensure_directory() {
  local DIR_PATH="$1"
  local PERMS="${2:-755}"
  
  if [[ ! -d "$DIR_PATH" ]]; then
    echo_yellow "Creating directory at $DIR_PATH..."
    mkdir -p "$DIR_PATH"
  fi

  chmod "$PERMS" "$DIR_PATH"
}

# Function to get the IPv4 address of the WireGuard interface (wg0)
# Usage: get_wireguard_ip
# Example:
#   WG_IP=$(get_wireguard_ip)
# Returns:
#   Prints the IP address (e.g. 10.8.0.1) to stdout, or empty string if unavailable
get_wireguard_ip() {
  if ! ip link show "wg0" &>/dev/null; then
    echo ""
    return 0
  fi
  ip -4 addr show "wg0" 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -1 || true
}

# Function to get the IPv4 subnet (with CIDR) of the WireGuard interface (wg0)
# Usage: get_wireguard_subnet
# Example:
#   WG_SUBNET=$(get_wireguard_subnet)
# Returns:
#   Prints the subnet (e.g. 10.8.0.0/24) to stdout, or empty string if unavailable
get_wireguard_subnet() {
  if ! ip link show "wg0" &>/dev/null; then
    echo ""
    return 0
  fi
  ip -4 addr show "wg0" 2>/dev/null | grep -oP 'inet \K[\d.]+/\d+' | head -1 || true
}

# Function to configure UFW to allow WireGuard subnet access to a specific port
# Usage: configure_ufw_for_wireguard port_number [proto]
# Example:
#   configure_ufw_for_wireguard 8080 tcp
#   configure_ufw_for_wireguard 53 udp
# Notes:
#   - Checks if both ufw and WireGuard are installed
#   - Detects WireGuard subnet automatically
#   - Always allows localhost access
#   - Proto defaults to "tcp" if not specified
configure_ufw_for_wireguard() {
  local PORT="$1"
  local PROTO="${2:-tcp}"
  
  if ! does_cmd_exist "ufw"; then
    return 0
  fi
  
  # Allow localhost access (always)
  if ufw allow from 127.0.0.1 to any port "$PORT" proto "$PROTO" 2>/dev/null; then
    echo_green "UFW: Allowed $PROTO/$PORT from localhost (127.0.0.1)"
  fi
  
  if ! does_cmd_exist "wg"; then
    ufw reload 2>/dev/null || true
    return 0
  fi
  
  if ! ip link show "wg0" &>/dev/null; then
    echo_yellow "WireGuard interface not yet active. Localhost access enabled."
    ufw reload 2>/dev/null || true
    return 0
  fi
  
  local WG_SUBNET
  WG_SUBNET=$(get_wireguard_subnet)
  
  if [[ -z "$WG_SUBNET" ]]; then
    echo_yellow "WireGuard subnet not yet configured. Localhost access enabled."
    ufw reload 2>/dev/null || true
    return 0
  fi
  
  if ufw allow from "$WG_SUBNET" to any port "$PORT" proto "$PROTO" 2>/dev/null; then
    echo_green "UFW: Allowed $PROTO/$PORT from WireGuard subnet ($WG_SUBNET)"
  else
    echo_yellow "UFW rule may already exist or failed to add"
  fi
  
  ufw reload 2>/dev/null || true
}

# Function to render a template config, apply sed substitutions, backup, and install
# Usage: render_template_config <template> <target> <chmod> [<sed_expr1> ...] [--validate "validate_cmd"]
# Example:
#   render_template_config "$SCRIPT_DIR/sshd_config" "/etc/ssh/sshd_config" 600 \
#     -e "s|{{SSH_PORT}}|$SSH_PORT|g" -e "s|{{DISABLE_PASSWORD}}|$DISABLE_PASSWORD|g" --validate "sshd -t -f"
# Notes:
#   - Silently returns if template file doesn't exist (no error)
#   - Only deploys if target file doesn't already exist
#   - Backs up existing config before overwriting
render_template_config() {
  local TEMPLATE_FILE="$1"
  local TARGET_FILE="$2"
  local PERMS="$3"
  shift 3

  if [[ ! -f "$TEMPLATE_FILE" ]]; then
    return 0
  fi

  if [[ -f "$TARGET_FILE" ]]; then
    echo_yellow "Updating existing config $TARGET_FILE..."
  fi

  echo_yellow "Deploying default configuration to $TARGET_FILE..."

  local VALIDATE_CMD=""
  local SED_ARGS=()

  while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--validate" ]]; then
      VALIDATE_CMD="$2"
      shift 2
    else
      SED_ARGS+=("$1")
      shift
    fi
  done

  backup_config_file "$TARGET_FILE"

  local TEMP_OUTPUT
  TEMP_OUTPUT=$(mktemp)

  if [[ ${#SED_ARGS[@]} -gt 0 ]]; then
    sed "${SED_ARGS[@]}" "$TEMPLATE_FILE" > "$TEMP_OUTPUT"
  else
    cp "$TEMPLATE_FILE" "$TEMP_OUTPUT"
  fi

  validate_and_cleanup "$TEMP_OUTPUT" "$TARGET_FILE" "$PERMS" "$VALIDATE_CMD"
}

# Function to check if Docker is installed
# Usage: ensure_docker
# Example:
#   ensure_docker
# Exits with error message if Docker is not installed
ensure_docker() {
  if ! does_cmd_exist "docker"; then
    echo_red "[ERROR] Docker is not installed. Please run 04-orchestration/00-docker first."
    exit 1
  fi
  
  if ! systemctl is-active --quiet docker; then
    echo_red "[ERROR] Docker service is not running. Please start Docker service."
    exit 1
  fi
  
  echo_green "Docker is installed and running."
}

# Function to ensure Docker network exists
# Usage: ensure_docker_network
# Example:
#   DOCKER_NETWORK_NAME="monitoring"
#   ensure_docker_network
# Notes:
#   - Uses DOCKER_NETWORK_NAME variable (must be set before calling)
#   - Creates the network if it doesn't exist
#   - Silently succeeds if network already exists
ensure_docker_network() {
  if [[ -z "$DOCKER_NETWORK_NAME" ]]; then
    echo_red "[ERROR] DOCKER_NETWORK_NAME is not set"
    return 1
  fi
  
  if docker network ls --format '{{.Name}}' | grep -q "^${DOCKER_NETWORK_NAME}$"; then
    echo_green "Docker network '$DOCKER_NETWORK_NAME' already exists"
  else
    echo_yellow "Creating Docker network '$DOCKER_NETWORK_NAME'..."
    docker network create "$DOCKER_NETWORK_NAME" >/dev/null 2>&1
    echo_green "Docker network '$DOCKER_NETWORK_NAME' created successfully"
  fi
}

# Function to check if a Docker container exists
# Usage: does_container_exist "container_name"
# Returns 0 if exists, 1 if not
does_container_exist() {
  local CONTAINER_NAME="$1"

  docker inspect "$CONTAINER_NAME" >/dev/null 2>&1
}

# Function to remove an existing Docker container
# Silently succeeds if container doesn't exist
remove_docker_container() {
  local CONTAINER_NAME="$1"

  if does_container_exist "$CONTAINER_NAME"; then
    echo_yellow "Stopping and removing existing $CONTAINER_NAME container..."
    docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
    docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
  else
    echo_yellow "Container '$CONTAINER_NAME' does not exist"
  fi
}

# Function to verify if a Docker container is running
# Returns 0 if running, 1 if not
verify_container_is_running() {
  local CONTAINER_NAME="$1"

  if does_container_exist "$CONTAINER_NAME"; then
    if docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null | grep -q "true"; then
      return 0
    fi
  fi

  return 1
}

# Function to display deployment initiation message
# Usage: echo_deploying_container "container_name" "port"
# Example:
#   echo_deploying_container "loki" "3100"
#   echo_deploying_container "prometheus" "9090"
# Notes:
#   - Call before docker run command
#   - Provides consistent messaging across all deployment scripts
echo_deploying_container() {
  local CONTAINER_NAME="$1"
  local PORT="$2"
  
  echo_yellow "Deploying $CONTAINER_NAME container on port $PORT..."
}
