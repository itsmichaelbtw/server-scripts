# Copilot Instructions

## Repository Purpose

Modular Bash automation toolkit for provisioning, hardening, and managing Ubuntu servers. Designed for sequential execution on fresh VPS/dedicated servers.

## Architecture

Scripts are organized in a two-level numbered hierarchy:

```
[NN]-[category]/          # 00-system through 05-gui
└── [NN]-[script-name]/
    ├── run.sh            # The executable script
    └── [config templates]
```

Each category directory has a master `run.sh` that uses `execute_run_sh()` from `common.sh` to discover and interactively prompt the user to run each subscript in order.

**Execution order:** `00-system` → `01-security` → `02-network` → `03-orchestration` → `04-monitoring` → `05-gui`

### Key Files

- **`common.sh`** — Shared library sourced by every script. Contains all utility functions (output/logging, prompts, environment checks, Docker helpers, cron management, config templating). Always source with `source "$ROOT_DIR/common.sh"`.
- **`run.sh`** (root) — Top-level wrapper that delegates to the first child directory's `run.sh`.
- **`copy.sh`** — SCP transfer utility; packages and deploys scripts to a remote server. Reads defaults from `.env`.
- **`executable.sh`** — Runs `chmod +x` on all `run.sh` files project-wide.
- **`path.sh`** — Updates `SCRIPT_NAME` and `SCRIPT_DIR` variables in all `run.sh` files.
- **`ssh-keygen.sh`** — Generates ed25519 keypair, deploys to server, and updates `~/.ssh/config`.

## Script Conventions

### Required Header

Every `run.sh` must begin with:

```bash
#!/usr/bin/env bash
# File path: relative/path/to/run.sh
# Purpose: One-line description of what this script does.

set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
ROOT_DIR=$(realpath "$SCRIPT_DIR/../..")  # adjust depth as needed
source "$ROOT_DIR/common.sh"

SCRIPT_NAME="NN-script-name"   # matches directory name
SCRIPT_DESC="Description shown in the header."
```

### Standard Startup

All scripts call these two functions at the start of execution:

```bash
print_script_header    # Displays SCRIPT_NAME + SCRIPT_DESC with color
validate_environment   # Enforces: must be root + Ubuntu
```

### Naming

- Directories and `SCRIPT_NAME`: `NN-kebab-case` (zero-padded, e.g. `03-ssh`)
- Functions: `snake_case`
- Constants/globals: `UPPER_SNAKE_CASE`

### Key `common.sh` Functions

| Function | Purpose |
|---|---|
| `validate_environment` | Assert root + Ubuntu; exit otherwise |
| `echo_green/yellow/red/blue` | Colored terminal output |
| `prompt_yes_no "Msg" "Y"` | Y/N prompt with default |
| `prompt_for_port "Msg"` | Validated port input (1–65535) |
| `read_from_terminal` | Read input from `/dev/tty` |
| `require_cmd "cmd" "pkg"` | Check command exists; install if missing |
| `does_cmd_exist "cmd"` | Boolean command check |
| `ensure_docker` | Assert Docker is installed and running |
| `ensure_docker_network` | Create/verify bridge network |
| `does_container_exist "name"` | Check Docker container existence |
| `remove_docker_container "name"` | Stop and remove container |
| `verify_container_is_running "name"` | Health-check container |
| `echo_deploying_container "name" "port"` | Log deployment info |
| `backup_config_file "/path"` | Timestamped backup before editing |
| `render_template_config "src" "dest"` | Variable substitution into config |
| `validate_and_cleanup "service"` | Validate config and apply |
| `ensure_directory "/path" "owner" "perms"` | mkdir with ownership/permissions |
| `cron_job_exists "name"` | Check `/etc/cron.d/` for job |
| `setup_cron_job "cmd" "schedule" "name"` | Interactively create cron job |
| `execute_run_sh` | Discover and prompt-execute child `run.sh` files |
| `display_service_url "name" "port"` | Print service access URL |
| `get_actual_user` | Get real username even under sudo |
| `load_env "/path/.env"` | Source `.env` file variables |

### Dependency Pattern

```bash
require_cmd "docker" "docker.io"   # auto-installs if missing
ensure_docker                       # confirm running
ensure_docker_network               # bridge network ready
```

### Config Template Pattern

Place config templates alongside `run.sh`, then deploy them:

```bash
backup_config_file "/etc/service/config.conf"
render_template_config "$SCRIPT_DIR/config.conf" "/etc/service/config.conf"
validate_and_cleanup "service"
```

### Docker Container Deployment Pattern

```bash
ensure_docker
ensure_docker_network
remove_docker_container "$CONTAINER_NAME"
echo_deploying_container "$CONTAINER_NAME" "$PORT"
docker run -d \
  --name "$CONTAINER_NAME" \
  --network="$DOCKER_NETWORK_NAME" \
  --restart unless-stopped \
  -p "$PORT:$PORT" \
  ...
verify_container_is_running "$CONTAINER_NAME"
display_service_url "$CONTAINER_NAME" "$PORT"
```

## Adding a New Script

1. Create `NN-category/NN-script-name/run.sh` following the header convention above.
2. Set `SCRIPT_NAME` to the directory name (e.g. `"02-my-tool"`).
3. Call `print_script_header` and `validate_environment` at the top.
4. Run `./executable.sh` to make the new `run.sh` executable.
5. Run `./path.sh` to sync `SCRIPT_NAME`/`SCRIPT_DIR` variables.

## Deployment Workflow

```bash
# On local machine — transfer scripts to server
./copy.sh

# On the server (run in order)
sudo ./00-system/run.sh
sudo ./01-security/run.sh
sudo ./02-network/run.sh
sudo ./03-orchestration/run.sh
sudo ./04-monitoring/run.sh
sudo ./05-gui/run.sh
```
