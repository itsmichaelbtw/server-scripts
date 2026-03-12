# 🎨 05-gui

Web-based GUI applications for server management and monitoring. This directory contains scripts for deploying NetData, FileBrowser, Homer dashboard, Crontab-UI, and Gatus status page.

## Directory Overview

The `05-gui` directory contains the following scripts executed in sequence:

| Script | Purpose |
|--------|---------|
| `00-netdata` | Deploy NetData real-time monitoring dashboard |
| `01-filebrowser` | Deploy FileBrowser web file manager |
| `02-crontab-ui` | Deploy Crontab-UI for cron job management |
| `03-gatus` | Deploy Gatus status page monitoring |
| `04-vaultwarden` | Deploy Vaultwarden self-hosted password manager |
| `05-grafana` | Deploy Grafana dashboards and visualization |
| `06-homer` | Deploy Homer service dashboard |

---

## Scripts

### 00-netdata: NetData Monitoring Dashboard

**Purpose:** Deploy NetData for real-time server monitoring.

**What it does:**
- Requires Docker installation
- Reads port from `ports.conf` (`NETDATA_PORT`)
- Creates Docker container with host system mounts (proc, sys, passwd, docker.sock)
- Disables Netdata Cloud sign-in (`NETDATA_DISABLE_CLOUD=1`)
- Dashboard is accessible at the `/v3/` path (bypasses login screen in Netdata v2)
- Displays service access URL

**Usage:**

```bash
sudo /path/to/05-gui/00-netdata/run.sh
```

---

### 01-filebrowser: FileBrowser Web File Manager

**Purpose:** Deploy FileBrowser for web-based file management.

**What it does:**
- Requires Docker installation
- Prompts for host directory to serve
- Reads port from `ports.conf` (`FILEBROWSER_PORT`)
- Runs as root (`--user 0:0`) to ensure access to system-owned files and log directories
- Disables authentication (requires VPN or Cloudflare Tunnel for security)
- Displays service access URL

**Usage:**

```bash
sudo /path/to/05-gui/01-filebrowser/run.sh
```

---

### 02-crontab-ui: Crontab-UI Cron Management

**Purpose:** Deploy Crontab-UI for web-based cron job management.

**What it does:**
- Requires Docker installation
- Reads port from `ports.conf` (`CRONTAB_UI_PORT`)
- Prompts for host directory for crontab storage
- Creates Docker container
- Displays service access URL

**Usage:**

```bash
sudo /path/to/05-gui/02-crontab-ui/run.sh
```

---

### 03-gatus: Gatus Status Page

**Purpose:** Deploy Gatus for service health monitoring and status page.

**What it does:**
- Requires Docker installation
- Reads port from `ports.conf` (`GATUS_PORT`)
- Creates Docker container with health check configuration
- Displays service access URL

**Usage:**

```bash
sudo /path/to/05-gui/03-gatus/run.sh
```

---

### 04-vaultwarden: Vaultwarden Password Manager

**Purpose:** Deploy Vaultwarden self-hosted password manager via Docker.

**What it does:**
- Requires Docker installation
- Prompts for Vaultwarden data directory path
- Reads port from `ports.conf` (`VAULTWARDEN_PORT`)
- Generates secure admin token
- Automatically generates a self-signed RSA TLS certificate (stored in `$DATA_DIR/ssl/`) on first run
- Enables HTTPS via `ROCKET_TLS` — required for the WebCrypto API used by Bitwarden clients
- Creates Docker container with persistent volumes
- Displays service access URL (`https://`) and admin token

**Usage:**

```bash
sudo /path/to/05-gui/04-vaultwarden/run.sh
```

---

### 05-grafana: Grafana Dashboards

**Purpose:** Deploy Grafana dashboards and visualization platform.

**What it does:**
- Requires Docker installation
- Reads port from `ports.conf` (`GRAFANA_PORT`)
- Creates data directory for persistent storage
- Creates Docker container with anonymous admin access enabled — no login required when accessed over the VPN
- Pre-installs clock and worldmap panel plugins
- Displays service access URL

**Usage:**

```bash
sudo /path/to/05-gui/05-grafana/run.sh
```

---

### 06-homer: Homer Service Dashboard

**Purpose:** Deploy Homer for centralized service dashboard.

**What it does:**
- Requires Docker installation and an active WireGuard interface (`wg0`)
- Reads port from `ports.conf` (`HOMER_PORT`)
- Auto-detects the WireGuard server IP via `get_wireguard_ip()`
- Renders `config.yml` template — substitutes `{{WG_IP}}` and all `{{SERVICE_PORT}}` placeholders from `ports.conf`
- Creates Docker container with persistent assets volume
- Displays configuration file location and access URL

**Usage:**

```bash
sudo /path/to/05-gui/06-homer/run.sh
```

---

## Master Script

The `run.sh` file in this directory orchestrates execution of all subscripts:

```bash
sudo /path/to/05-gui/run.sh
```

You will be prompted to confirm execution of each script.

---

## Environment Requirements

- **OS:** Ubuntu 18.04 LTS or later
- **Privileges:** Root access (run with `sudo`)
- **Docker:** Must be installed (run 04-orchestration/00-docker first)
- **Internet:** Required for Docker image downloads

---

## Execution Order

Scripts run in numerical order:

1. `00-netdata` - Monitoring dashboard
2. `01-filebrowser` - File manager
3. `02-crontab-ui` - Cron management
4. `03-gatus` - Status page
5. `04-vaultwarden` - Password manager
6. `05-grafana` - Visualization and dashboards
7. `06-homer` - Service dashboard
