# 💾 03-disk

Disk management, RAID configuration, filesystem setup, and disk monitoring for Ubuntu servers. This directory contains scripts for RAID arrays, filesystem partitioning, and SMART disk monitoring.

## Directory Overview

The `03-disk` directory contains the following scripts executed in sequence:

| Script | Purpose |
|--------|---------|
| `00-raid` | Create and configure software RAID for NVMe SSDs |
| `01-filesystem` | Detect, format, and mount additional disks |
| `02-monitoring` | Install and configure disk monitoring tools |

---

## Scripts

### 00-raid: Software RAID Setup

**Purpose:** Create and configure software RAID1 for NVMe SSDs.

**What it does:**
- Installs mdadm and partitioning tools
- Detects NVMe devices
- Creates RAID1 array if needed
- Partitions and formats RAID device
- Mounts RAID array
- Adds to fstab for persistence

**Usage:**

```bash
sudo /path/to/03-disk/00-raid/run.sh
```

---

### 01-filesystem: Filesystem Management

**Purpose:** Detect, format, and mount additional non-RAID disks.

**What it does:**
- Detects unmounted non-RAID disks
- Prompts for mount point for each disk
- Formats with ext4 filesystem
- Mounts disks
- Adds to fstab for persistence

**Usage:**

```bash
sudo /path/to/03-disk/01-filesystem/run.sh
```

---

### 02-monitoring: Disk Health Monitoring

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
sudo /path/to/03-disk/02-monitoring/run.sh
```

---

## Master Script

The `run.sh` file in this directory orchestrates execution of all subscripts:

```bash
sudo /path/to/03-disk/run.sh
```

You will be prompted to confirm execution of each script.

---

## Environment Requirements

- **OS:** Ubuntu 18.04 LTS or later
- **Privileges:** Root access (run with `sudo`)
- **Hardware:** At least 1 disk (RAID requires 2+ NVMe drives)

---

## Execution Order

Scripts run in numerical order:

1. `00-raid` - Setup RAID arrays
2. `01-filesystem` - Configure additional filesystems
3. `02-monitoring` - Enable disk monitoring
