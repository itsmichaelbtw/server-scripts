# 📊 04-monitoring

System and process monitoring tools for Ubuntu servers. This directory contains scripts for installing performance monitoring and statistics collection tools.

## Directory Overview

The `04-monitoring` directory contains the following scripts executed in sequence:

| Script | Purpose |
|--------|---------|
| `00-sysstat` | Install sysstat for system performance monitoring |
| `01-process-tools` | Install process and resource monitoring tools |
| `03-disk` | Install and configure disk monitoring tools (SMART, I/O stats) |

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

### 03-disk: Disk Health Monitoring

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
sudo /path/to/04-monitoring/03-disk/run.sh
```

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

1. `00-sysstat` - Historical monitoring
2. `01-process-tools` - Real-time monitoring
3. `03-disk` - Disk health monitoring
