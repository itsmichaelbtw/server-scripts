# 🎨 05-gui

Web-based GUI applications for server management and monitoring. This directory contains scripts for deploying NetData, FileBrowser, Homer dashboard, Crontab-UI, and Gatus status page.

## Directory Overview

The `05-gui` directory contains the following scripts executed in sequence:

| Script | Purpose |
|--------|---------|
| `00-netdata` | Deploy NetData real-time monitoring dashboard |
| `01-filebrowser` | Deploy FileBrowser web file manager |
| `02-homer` | Deploy Homer service dashboard |
| `03-crontab-ui` | Deploy Crontab-UI for cron job management |
| `04-gatus` | Deploy Gatus status page monitoring |

---

## Scripts

### 00-netdata: NetData Monitoring Dashboard

**Purpose:** Deploy NetData for real-time server monitoring.

**What it does:**
- Requires Docker installation
- Prompts for NetData port
- Creates Docker container with volumes
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
- Prompts for FileBrowser port
- Creates Docker container
- Disables authentication (requires Cloudflare Tunnel for security)
- Displays service access URL

**Usage:**

```bash
sudo /path/to/05-gui/01-filebrowser/run.sh
```

---

### 02-homer: Homer Service Dashboard

**Purpose:** Deploy Homer for centralized service dashboard.

**What it does:**
- Requires Docker installation
- Creates data and config directories
- Copies template configuration
- Prompts for Homer port
- Creates Docker container with persistent volumes
- Displays configuration file location and access URL

**Usage:**

```bash
sudo /path/to/05-gui/02-homer/run.sh
```

---

### 03-crontab-ui: Crontab-UI Cron Management

**Purpose:** Deploy Crontab-UI for web-based cron job management.

**What it does:**
- Requires Docker installation
- Prompts for Crontab-UI port
- Prompts for host directory for crontab storage
- Creates Docker container
- Displays service access URL

**Usage:**

```bash
sudo /path/to/05-gui/03-crontab-ui/run.sh
```

---

### 04-gatus: Gatus Status Page

**Purpose:** Deploy Gatus for service health monitoring and status page.

**What it does:**
- Requires Docker installation (future implementation)

**Usage:**

```bash
sudo /path/to/05-gui/04-gatus/run.sh
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
3. `02-homer` - Service dashboard
4. `03-crontab-ui` - Cron management
5. `04-gatus` - Status page
