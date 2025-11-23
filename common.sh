#!/usr/bin/env bash
# common.sh
# Shared functions for system provisioning scripts

set -euo pipefail

GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
RED="\033[1;31m"
RESET="\033[0m"

# Function to print text in green
# Usage: echo_green "Success message"
# Example:
#   echo_green "✓ Operation completed"
echo_green() {
  echo -e "${GREEN}$*${RESET}"
}

# Function to print text in yellow
# Usage: echo_yellow "Warning message"
# Example:
#   echo_yellow "⚠ Please review this"
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
  echo -e "${RED}$*${RESET}"
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
    echo -e "${RED}[ERROR] This script must be run as root.${RESET}"
    echo "Try: sudo $0"
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
    echo -e "${RED}[ERROR] This script is intended for Ubuntu systems only.${RESET}"
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
  echo -e "${GREEN}✓ Environment validated.${RESET}"
}

# Function to display service URL after deployment
# Usage: display_service_url "Service Name" port_number
# Example:
#   display_service_url "MyApp" 8080
# Determines server IP and displays formatted access URL
display_service_url() {
  local service_name="$1"
  local port="$2"
  
  local server_ip
  server_ip=$(ip route get 1 | awk '{print $7; exit}')

  echo -e "${GREEN}✓ $service_name deployed successfully.${RESET}"
  echo -e "${YELLOW}Access the service at: http://$server_ip:$port${RESET}"
}

# Function to prompt user for yes/no input
# Usage: prompt_yes_no "Do you want to enable feature X?" [Y|N]
# Example:
#   prompt_yes_no "Continue?" "N"; echo $REPLY
# Returns: Uppercase Y or N in the variable $REPLY
prompt_yes_no() {
  local prompt="$1"
  local default="${2:-Y}"
  local valid_default="${default^^}"
  
  if [[ "$valid_default" != "Y" && "$valid_default" != "N" ]]; then
    valid_default="Y"
  fi
  
  local prompt_text="$prompt [$([[ $valid_default == Y ]] && echo "Y/n" || echo "y/N")]: "
  
  while true; do
    read_from_terminal -rp "$prompt_text" REPLY
    REPLY=${REPLY:-$valid_default}
    case "${REPLY^^}" in
      Y|N) REPLY="${REPLY^^}"; break ;;
      *) echo -e "${YELLOW}Please enter Y or N.${RESET}" ;;
    esac
  done
}

# Function to check if Docker is installed
# Usage: ensure_docker
# Example:
#   ensure_docker
# Exits with error message if Docker is not installed
ensure_docker() {
  if ! command -v docker &>/dev/null; then
    echo -e "${RED}[ERROR] Docker is not installed. Please run 04-orchestration/00-docker first.${RESET}"
    exit 1
  fi
  
  if ! systemctl is-active --quiet docker; then
    echo -e "${RED}[ERROR] Docker service is not running. Please start Docker service.${RESET}"
    exit 1
  fi
  
  echo -e "${GREEN}✓ Docker is installed and running.${RESET}"
}

# Function to prompt for a valid network port number
# Usage: prompt_for_port "Enter port for service" [default_port]
# Example:
#   prompt_for_port "Enter port" 8080; echo $PORT_REPLY
# Returns: The valid port number in the variable $PORT_REPLY
prompt_for_port() {
  local prompt="$1"
  local default="${2:-8080}"
  local port_value
  
  while true; do
    read_from_terminal -rp "$prompt (default: $default): " port_value
    port_value="${port_value:-$default}"
    
    if [[ "$port_value" =~ ^[0-9]+$ ]] && (( port_value >= 1 && port_value <= 65535 )); then
      PORT_REPLY="$port_value"
      break
    else
      echo -e "${YELLOW}Invalid port. Please enter a number between 1-65535.${RESET}"
    fi
  done
}

# Function to print script name and description in color
# Usage: print_script_header
# Example:
#   print_script_header
print_script_header() {
  if [[ -n "${SCRIPT_NAME:-}" ]]; then
    echo -e "\n${BLUE}Running script: ${SCRIPT_NAME}${RESET}"
  fi
  if [[ -n "${SCRIPT_DESC:-}" ]]; then
    echo -e "${BLUE}Description: ${SCRIPT_DESC}${RESET}\n"
  fi
}

# Function to schedule a task via crontab
# Usage: setup_cron_job "Command to run" ["default schedule"]
# Example:
#   setup_cron_job "echo hello" "0 1 * * *"
# Parameters:
#   $1: The command to schedule in crontab
#   $2: Default schedule (optional, defaults to "0 3 * * *" - 3 AM daily)
setup_cron_job() {
  local cron_cmd="$1"
  local default_schedule="${2:-0 3 * * *}"
  local cron_pattern
  
  prompt_yes_no "Do you want to schedule this job via CRON?" "Y"
  
  if [[ "$REPLY" == "Y" ]]; then
    read_from_terminal -rp "Enter CRON schedule (minute hour day month day_of_week) or leave empty for default ($default_schedule): " cron_pattern
    cron_pattern="${cron_pattern:-$default_schedule}"
    
    (crontab -l 2>/dev/null; echo "$cron_pattern $cron_cmd") | crontab -
    
    if crontab -l 2>/dev/null | grep -q -F "$cron_cmd"; then
      echo -e "${GREEN}✓ Job scheduled via CRON: ${cron_pattern}${RESET}"
      CRON_SETUP_SUCCESS=true
    else
      echo -e "${RED}[ERROR] Failed to add job to crontab.${RESET}"
      CRON_SETUP_SUCCESS=false
    fi
  else
    echo -e "${YELLOW}CRON scheduling skipped.${RESET}"
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
  local base_dir script_path run_files rel_path

  script_path="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)/$(basename "${BASH_SOURCE[1]}")"
  base_dir="$(dirname "$script_path")"

  local rel_base_dir rel_script_path
  rel_base_dir="$base_dir"
  rel_script_path="$script_path"
  [[ "$base_dir" == "$PWD"* ]] && rel_base_dir=".${base_dir#$PWD}"
  [[ "$script_path" == "$PWD"* ]] && rel_script_path=".${script_path#$PWD}"

  echo -e "${YELLOW}Searching for 'run.sh' files in $rel_base_dir (excluding $rel_script_path)...${RESET}\n"

  run_files=$(find "$base_dir" -type f -name "run.sh" ! -path "$script_path" | sort)
  if [[ -z "$run_files" ]]; then
    echo -e "${RED}No run.sh files found.${RESET}"
    return
  fi

  echo -e "${BLUE}Found the following run.sh files:${RESET}\n"
  while IFS= read -r file; do
    rel_path="${file#$base_dir/}"
    echo -e "${YELLOW}- $rel_path${RESET}"
  done <<< "$run_files"
  echo ""

  while IFS= read -r file; do
    rel_path="${file#$base_dir/}"
    prompt_yes_no "Do you want to execute '$rel_path'?" "N"
    if [[ "$REPLY" == "Y" ]]; then
      echo -e "${YELLOW}Executing $rel_path ...${RESET}"
      bash "$file"
    else
      echo -e "${YELLOW}Skipping $rel_path.${RESET}"
    fi
  done <<< "$run_files"

  echo -e "${GREEN}All done.${RESET}"
}

# Function to backup a config file if it exists
# Usage: backup_config_file "/etc/ssh/sshd_config"
# Example:
#   backup_config_file "/etc/ssh/sshd_config"
backup_config_file() {
  local target_file="$1"
  if [[ -f "$target_file" ]]; then
    local backup_file="${target_file}.backup-$(date +%Y%m%d-%H%M%S)"
    cp "$target_file" "$backup_file"
    echo -e "${GREEN}✓ Backup created at: $backup_file${RESET}"
  fi
}

# Function to validate a config file and clean up temp files
# Usage: validate_and_cleanup <temp_file> <target_file> <perms> [<validate_cmd>]
# Example:
#   validate_and_cleanup "$temp_output" "/etc/ssh/sshd_config" 600 "sshd -t -f"
validate_and_cleanup() {
  local temp_file="$1"
  local target_file="$2"
  local perms="$3"
  local validate_cmd="$4"

  if [[ -n "$validate_cmd" ]]; then
    if ! $validate_cmd "$temp_file"; then
      echo -e "${RED}[ERROR] Validation failed for $temp_file. Not applying config.${RESET}"
      rm -f "$temp_file"
      exit 1
    fi
    echo -e "${GREEN}✓ Config validated successfully.${RESET}"
  fi

  cp "$temp_file" "$target_file"
  chmod "$perms" "$target_file"
  rm -f "$temp_file"
  echo -e "${GREEN}✓ Applied new config: $target_file${RESET}"
}

# Function to render a template config, apply sed substitutions, backup, and install
# Usage: render_template_config <template> <target> <chmod> <sed_expr1> [<sed_expr2> ...] [--validate "validate_cmd"]
# Example:
#   render_template_config "$SCRIPT_DIR/sshd_config" "/etc/ssh/sshd_config" 600 \
#     -e "s|{{SSH_PORT}}|$SSH_PORT|g" -e "s|{{DISABLE_PASSWORD}}|$DISABLE_PASSWORD|g" --validate "sshd -t -f"
render_template_config() {
  local template_file="$1"
  local target_file="$2"
  local perms="$3"
  shift 3

  local validate_cmd=""
  local sed_args=()
  while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--validate" ]]; then
      validate_cmd="$2"
      shift 2
    else
      sed_args+=("$1")
      shift
    fi
  done

  if [[ ! -f "$template_file" ]]; then
    echo -e "${RED}[ERROR] Template file not found: $template_file${RESET}"
    exit 1
  fi

  backup_config_file "$target_file"

  local temp_output
  temp_output=$(mktemp)

  sed "${sed_args[@]}" "$template_file" > "$temp_output"

  validate_and_cleanup "$temp_output" "$target_file" "$perms" "$validate_cmd"
}
