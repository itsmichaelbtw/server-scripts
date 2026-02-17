# 📊 04-monitoring

System and process monitoring tools for Ubuntu servers. This directory contains scripts for installing performance monitoring and statistics collection tools.

## Directory Overview

The `04-monitoring` directory contains the following scripts executed in sequence:

| Script | Purpose |
|--------|---------|
| `00-sysstat` | Install sysstat for system performance monitoring |
| `01-process-tools` | Install process and resource monitoring tools |
| `02-disk` | Install and configure disk monitoring tools (SMART, I/O stats) |
| `03-prometheus` | Deploy Prometheus metrics collection and time-series database |
| `04-loki` | Deploy Loki log aggregation and indexing |
| `05-alertmanager` | Deploy AlertManager for alert routing and notifications |
| `06-alloy` | Deploy Grafana Alloy to forward system and Docker logs to Loki |

---

## Scripts

### 00-sysstat: System Statistics Collection

**Purpose:** Install and configure sysstat for historical performance monitoring.

**What it does:**
- Installs sysstat package
- Enables periodic data collection
- Starts sysstat service
- Runs iostat, mpstat, and sar commands

**Usage:**

```bash
sudo /path/to/04-monitoring/00-sysstat/run.sh
```

---

### 01-process-tools: Process Monitoring Tools

**Purpose:** Install htop, atop, and glances for real-time monitoring.

**What it does:**
- Installs htop, atop, and glances
- Enables atop service for boot logging
- Verifies all installations

**Usage:**

```bash
sudo /path/to/04-monitoring/01-process-tools/run.sh
```

---

### 02-disk: Disk Health Monitoring

**Purpose:** Install and configure disk monitoring and SMART health checks.

**What it does:**
- Installs smartmontools, sysstat, and utilities
- Enables SMART monitoring on all disks
- Runs initial SMART health check
- Enables smartd service
- Runs initial disk usage and I/O stats
- Optionally schedules CRON job for periodic monitoring

**Usage:**

```bash
sudo /path/to/04-monitoring/02-disk/run.sh
```

---

### 03-prometheus: Metrics Collection

**Purpose:** Deploy Prometheus for metrics collection and time-series database.

**What it does:**
- Creates Prometheus configuration directory
- Deploys Prometheus configuration from template
- Creates data directory
- Removes existing Prometheus container if present
- Deploys Prometheus Docker container
- Configures UFW firewall rules for WireGuard access
- Displays service URL and configuration info

**Configuration:**
- Config file: `/etc/prometheus/prometheus.yml`
- Data directory: `/prometheus-data` (customizable)
- Web interface: `http://localhost:9090` (default)
- API endpoint: `http://localhost:9090/api/v1/query`

**Usage:**

```bash
sudo /path/to/04-monitoring/03-prometheus/run.sh
```

---

### 04-loki: Log Aggregation

**Purpose:** Deploy Loki for log aggregation and indexing.

**What it does:**
- Creates Loki configuration directory
- Deploys Loki configuration from template
- Creates data directory
- Removes existing Loki container if present
- Deploys Loki Docker container
- Configures UFW firewall rules for WireGuard access
- Displays service URL and configuration info

**Configuration:**
- Config file: `/etc/loki/loki-config.yml`
- Data directory: `/loki-data` (customizable)
- Web interface: `http://localhost:3100` (default)
- API endpoint: `http://localhost:3100/loki/api/v1/push` (for log ingestion)

**Usage:**

```bash
sudo /path/to/04-monitoring/04-loki/run.sh
```

---

### 05-alertmanager: Alert Routing

**Purpose:** Deploy AlertManager for alert routing and notification delivery.

**What it does:**
- Creates AlertManager configuration directory
- Deploys AlertManager configuration from template
- Creates data directory
- Removes existing AlertManager container if present
- Deploys AlertManager Docker container
- Configures UFW firewall rules for WireGuard access
- Displays service URL and configuration info

**Configuration:**
- Config file: `/etc/alertmanager/alertmanager.yml`
- Data directory: `/alertmanager-data` (customizable)
- Web interface: `http://localhost:9093` (default)
- API endpoint: `http://localhost:9093/api/v1/alerts`

**Usage:**

```bash
sudo /path/to/04-monitoring/05-alertmanager/run.sh
```

---

### 06-alloy: Log Forwarding with Grafana Alloy

**Purpose:** Deploy Grafana Alloy to forward all system and Docker container logs to Loki.

**What it does:**
- Creates Alloy configuration directory
- Deploys Alloy configuration from template
- Removes existing Alloy container if present
- Deploys Grafana Alloy Docker container with access to system logs
- Configures Docker daemon to use Loki logging driver for all new containers
- Restarts Docker daemon to apply changes
- Verifies Docker daemon health

**Log Sources:**
- System logs: `/var/log/syslog`
- Authentication logs: `/var/log/auth.log`
- Kernel logs: `/var/log/kern.log`
- Docker daemon logs: `/var/log/docker.log`
- Docker container logs: via journalctl (systemd integration)
- All future Docker containers: via Loki logging driver (automatic)

**Configuration:**
- Config file: `/etc/alloy/config.alloy`
- Loki URL: `http://loki:3100/loki/api/v1/push`

**Usage:**

```bash
sudo /path/to/04-monitoring/06-alloy/run.sh
```

**Note:** This script requires Docker and Loki to be already deployed. Run `03-orchestration/00-docker/run.sh` and `04-loki/run.sh` first.

---

## Master Script

The `run.sh` file in this directory orchestrates execution of all subscripts:

```bash
sudo /path/to/04-monitoring/run.sh
```

You will be prompted to confirm execution of each script.

---

## Environment Requirements

- **OS:** Ubuntu 18.04 LTS or later
- **Privileges:** Root access (run with `sudo`)
- **Internet:** Required for package downloads

---

## Execution Order

Scripts run in numerical order:

1. `00-sysstat` - Historical system statistics collection
2. `01-process-tools` - Real-time process and resource monitoring
3. `02-disk` - Disk health monitoring and SMART checks
4. `03-prometheus` - Metrics collection and time-series database
5. `04-loki` - Log aggregation and indexing
6. `05-alertmanager` - Alert routing and notifications
7. `06-alloy` - Log forwarding to Loki with Grafana Alloy (requires Loki and Docker)

---

## Recommended Deployment Order

For a complete observability stack:

```bash
# 1. Core monitoring
sudo /path/to/04-monitoring/00-sysstat/run.sh
sudo /path/to/04-monitoring/01-process-tools/run.sh
sudo /path/to/04-monitoring/02-disk/run.sh

# 2. Observability stack (requires Docker)
sudo /path/to/03-orchestration/00-docker/run.sh      # Docker
sudo /path/to/04-monitoring/03-prometheus/run.sh     # Metrics
sudo /path/to/04-monitoring/04-loki/run.sh           # Logs
sudo /path/to/04-monitoring/05-alertmanager/run.sh   # Alerts
sudo /path/to/04-monitoring/06-alloy/run.sh          # Log forwarding

# 3. Visualization (optional, requires Docker)
sudo /path/to/05-gui/05-grafana/run.sh               # Grafana dashboard
```

---

## Observability Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ System Logs & Docker Containers                             │
│ ├─ /var/log/syslog, /var/log/auth.log, /var/log/kern.log   │
│ ├─ Docker container logs (all services)                    │
│ └─ Systemd journal (CRON, SSH, Docker, etc.)               │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │     Promtail         │ ◄─ Reads logs from files
        │                      │    & journalctl
        └──────────┬───────────┘
                   │ Ships logs
                   ▼
        ┌──────────────────────┐
        │   Loki (3100)        │ ◄─ Aggregates & indexes logs
        │                      │    & Docker log driver
        └──────────┬───────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │  Grafana (3000)      │ ◄─ Visualizes logs & metrics
        │  ├─ Loki datasource  │
        │  ├─ Prometheus DS    │
        │  └─ Alerting         │
        └────────┬─────────────┘
                 │
                 ▼
        ┌──────────────────────┐
        │  AlertManager (9093) │ ◄─ Sends notifications
        └──────────────────────┘

Metrics flow:
    System metrics ──► Prometheus (9090) ──► Grafana
```
