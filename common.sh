#!/usr/bin/env bash
# common.sh
# Shared functions for system provisioning scripts

set -euo pipefail

GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
RED="\033[1;31m"
RESET="\033[0m"


## Function to check if running on macOS
# Usage: is_macos && echo "This is macOS"
# Example:
#   if is_macos; then echo "macOS detected"; fi
is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

## Function to check if running on Ubuntu
# Usage: is_ubuntu && echo "This is Ubuntu"
# Example:
#   if is_ubuntu; then echo "Ubuntu detected"; fi
is_ubuntu() {
  [[ -f /etc/os-release ]] && grep -qi 'ubuntu' /etc/os-release
}

## Function to check if script is run with root privileges
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

## Function to verify the system is running Ubuntu
# Usage: ensure_ubuntu
# Example:
#   ensure_ubuntu
# Exits with error message if not running on Ubuntu
ensure_ubuntu() {
  if ! grep -qi "ubuntu" /etc/os-release; then
    echo -e "${RED}[ERROR] This script is intended for Ubuntu systems only.${RESET}"
    exit 1
  fi
}

## Function to validate the execution environment
# Usage: validate_environment
# Example:
#   validate_environment
# Ensures script is run as root on an Ubuntu system
validate_environment() {
  ensure_root
  ensure_ubuntu
  echo -e "${GREEN}✓ Environment validated.${RESET}"
}

## Function to display service URL after deployment
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

## Function to prompt user for yes/no input
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
    read -rp "$prompt_text" REPLY
    REPLY=${REPLY:-$valid_default}
    case "${REPLY^^}" in
      Y|N) REPLY="${REPLY^^}"; break ;;
      *) echo -e "${YELLOW}Please enter Y or N.${RESET}" ;;
    esac
  done
}

## Function to check if Docker is installed
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

## Function to prompt for a valid network port number
# Usage: prompt_for_port "Enter port for service" [default_port]
# Example:
#   prompt_for_port "Enter port" 8080; echo $PORT_REPLY
# Returns: The valid port number in the variable $PORT_REPLY
prompt_for_port() {
  local prompt="$1"
  local default="${2:-8080}"
  local port_value
  
  while true; do
    read -rp "$prompt (default: $default): " port_value
    port_value="${port_value:-$default}"
    
    if [[ "$port_value" =~ ^[0-9]+$ ]] && (( port_value >= 1 && port_value <= 65535 )); then
      PORT_REPLY="$port_value"
      break
    else
      echo -e "${YELLOW}Invalid port. Please enter a number between 1-65535.${RESET}"
    fi
  done
}

## Function to print script name and description in color
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

## Function to schedule a task via crontab
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
    read -rp "Enter CRON schedule (minute hour day month day_of_week) or leave empty for default ($default_schedule): " cron_pattern
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

## Function to dynamically find and run scripts in a directory
# Usage: find_and_run_scripts base_directory
# Example:
#   find_and_run_scripts "./00-system"
# Parameters:
#   $1: Base directory to search for run.sh scripts
find_and_run_scripts() {
  local base_dir="$1"
  local scripts=()
  local script_count=0
  local scripts_run=0
  local errors_encountered=0
  
  echo -e "${YELLOW}Searching for run.sh scripts in: ${base_dir}${RESET}"
  
  while IFS= read -r script_path; do
    if [[ -x "$script_path" ]]; then
      scripts+=("$script_path")
      ((script_count++))
      
      echo -e "${BLUE}Executing: ${script_path}${RESET}"
      script_output=$(bash "$script_path" 2>&1)
      script_status=$?
      
      if [[ $script_status -eq 0 ]]; then
        echo -e "${GREEN}✓ Script ${script_path} completed successfully.${RESET}"
        ((scripts_run++))
      else
        echo -e "${RED}[ERROR] Script ${script_path} failed with exit status $script_status${RESET}"
        echo -e "${YELLOW}Script output:${RESET}"
        echo "$script_output"
        ((errors_encountered++))
      fi
    else
      echo -e "${RED}Found non-executable script: ${script_path} - cannot execute${RESET}"
      ((errors_encountered++))
    fi
  done < <(find "$base_dir" -mindepth 1 -maxdepth 2 -name "run.sh" | sort)
  
  echo -e "\n${BLUE}Script Execution Summary:${RESET}"
  echo -e "Total scripts found:    ${script_count}"
  echo -e "Scripts successfully run: ${scripts_run}"
  echo -e "Errors encountered:     ${errors_encountered}"
  
  if [[ $script_count -eq 0 ]]; then
    echo -e "${RED}[ERROR] No run.sh scripts found in ${base_dir}.${RESET}"
    return 1
  elif [[ $errors_encountered -gt 0 ]]; then
    echo -e "${RED}[WARNING] Some scripts failed during execution.${RESET}"
    return 1
  fi
  
  return 0
}
