# 🖥 00-system

System foundation setup for Ubuntu server provisioning. This directory contains scripts that establish the base system configuration, including package updates, utility installation, user management, SSH hardening, and cron setup.

## Directory Overview

The `00-system` directory contains the following initialization scripts executed in sequence:

| Script | Purpose |
|--------|---------|
| `00-updates` | Update packages and enable automatic security updates |
| `01-utilities` | Install essential system utilities and tools |
| `02-user` | Create system users with optional sudo privileges |
| `03-ssh` | Harden SSH configuration with custom settings |
| `04-cron` | Enable and configure cron service |
| `05-kernel-modules` | Load and persist kernel modules required for Kubernetes |

---

## Scripts

### 00-updates: System Updates & Unattended Upgrades

**Purpose:** Update all system packages and enable automatic security updates.

**What it does:**
- Updates package lists and installed packages
- Installs and enables `unattended-upgrades` for automatic security patching

**Usage:**

```bash
sudo /path/to/00-system/00-updates/run.sh
```

---

### 01-utilities: Essential System Utilities

**Purpose:** Install general-purpose server utilities, system information tools, and CRON/log support.

**What it does:**
- Installs essential tools: curl, wget, git, jq, vim, nano, net-tools
- Installs system info tools: neofetch, dmidecode, lshw
- Installs task/log management: cron, at, logrotate

**Usage:**

```bash
sudo /path/to/00-system/01-utilities/run.sh
```

---

### 02-user: User Creation & Sudo Configuration

**Purpose:** Create system users with optional sudo privileges.

**What it does:**
- Prompts for username (validates format)
- Creates user if not exists
- Optionally adds to sudo group and configures sudoers file

**Usage:**

```bash
sudo /path/to/00-system/02-user/run.sh
```

---

### 03-ssh: SSH Hardening & Configuration

**Purpose:** Configure and harden SSH using a template-based `sshd_config`.

**What it does:**
- Prompts for SSH port (default: 22)
- Prompts to disable password authentication
- Prompts to disable root login
- Validates and applies new SSH configuration
- Backs up existing config before changes

**Usage:**

```bash
sudo /path/to/00-system/03-ssh/run.sh
```

**Configuration File:**

The `sshd_config` template file is located alongside `run.sh`. Template variables are replaced during execution:

| Variable | Description |
|----------|-------------|
| `{{SSH_PORT}}` | SSH listening port |
| `{{DISABLE_PASSWORD}}` | Disable password auth (yes/no) |
| `{{DISABLE_ROOT}}` | Disable root login (yes/no) |

---

### 04-cron: Cron Service Setup

**Purpose:** Ensure cron service is installed, enabled, and running.

**What it does:**
- Installs cron if missing
- Enables cron to start on boot
- Starts/restarts cron service

**Usage:**

```bash
sudo /path/to/00-system/04-cron/run.sh
```

---

### 05-kernel-modules: Kubernetes Kernel Modules

**Purpose:** Load and persist kernel modules required for Kubernetes networking and container operations.

**What it does:**
- Creates `/etc/modules-load.d/kubernetes.conf` with required modules
- Loads `br_netfilter` kernel module for bridge network filtering
- Loads `overlay` kernel module for container storage
- Verifies modules are loaded via `lsmod`
- Configures sysctl settings for Kubernetes networking:
  - `net.bridge.bridge-nf-call-iptables=1`
  - `net.bridge.bridge-nf-call-ip6tables=1`
  - `net.ipv4.ip_forward=1`
- Persists sysctl settings to `/etc/sysctl.d/99-kubernetes.conf`

**Usage:**

```bash
sudo /path/to/00-system/05-kernel-modules/run.sh
```

**Prerequisites:** None - can run after system updates

**Notes:** This script should be run before container orchestration setup (Docker, Kubernetes, etc.) to ensure networking and storage modules are available.

---

## Master Script

The `run.sh` file in this directory orchestrates execution of all subscripts:

```bash
sudo /path/to/00-system/run.sh
```

You will be prompted to confirm execution of each script.

---

## Environment Requirements

- **OS:** Ubuntu 18.04 LTS or later
- **Privileges:** Root access (run with `sudo`)
- **Internet:** Required for package downloads

---

## Execution Order

Scripts run in numerical order to ensure dependencies are met:

1. `00-updates` - System updates
2. `01-utilities` - Install base utilities
3. `02-user` - Create users
4. `03-ssh` - Configure SSH
5. `04-cron` - Enable cron
6. `05-kernel-modules` - Load Kubernetes kernel modules
