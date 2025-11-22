# 📊 05-monitoring

System and process monitoring tools for Ubuntu servers. This directory contains scripts for installing performance monitoring and statistics collection tools.

## Directory Overview

The `05-monitoring` directory contains the following scripts executed in sequence:

| Script | Purpose |
|--------|---------|
| `00-sysstat` | Install sysstat for system performance monitoring |
| `01-process-tools` | Install process and resource monitoring tools |

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
sudo /path/to/05-monitoring/00-sysstat/run.sh
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
sudo /path/to/05-monitoring/01-process-tools/run.sh
```

---

## Master Script

The `run.sh` file in this directory orchestrates execution of all subscripts:

```bash
sudo /path/to/05-monitoring/run.sh
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
