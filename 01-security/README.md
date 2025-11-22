# 🔐 01-security

Security hardening and access control for Ubuntu servers. This directory contains scripts for firewall configuration, intrusion detection, rootkit scanning, system hardening, and security auditing.

## Directory Overview

The `01-security` directory contains the following scripts executed in sequence:

| Script | Purpose |
|--------|---------|
| `00-firewall` | Configure UFW firewall with custom rules |
| `01-fail2ban` | Install Fail2Ban for brute-force protection |
| `02-port-knocking` | Configure port-knocking with knockd |
| `03-apparmor` | Install and enable AppArmor mandatory access control |
| `04-sysctl` | Apply kernel/network hardening via sysctl |
| `05-grub` | Harden GRUB bootloader |
| `06-rkhunter` | Install RKHunter for rootkit detection |
| `07-chkrootkit` | Install and run Chkrootkit rootkit scanner |
| `08-lynis` | Install Lynis for security auditing |

---

## Scripts

### 00-firewall: UFW Firewall Configuration

**Purpose:** Configure and enable UFW firewall with custom rules.

**What it does:**
- Prompts for SSH port and which ports to allow (HTTP, HTTPS, custom)
- Sets default deny/allow policies
- Configures rate limiting for SSH
- Enables UFW firewall

**Usage:**

```bash
sudo /path/to/01-security/00-firewall/run.sh
```

---

### 01-fail2ban: Fail2Ban Brute-Force Protection

**Purpose:** Install and configure Fail2Ban with custom ban settings.

**What it does:**
- Prompts for SSH port, ban time, find time, and max retries
- Installs Fail2Ban service
- Applies jail configuration from template
- Enables service

**Usage:**

```bash
sudo /path/to/01-security/01-fail2ban/run.sh
```

**Configuration File:**

The `jail.local` template file is located alongside `run.sh`. Template variables are replaced during execution:

| Variable | Description |
|----------|-------------|
| `{{SSH_PORT}}` | SSH port to protect |
| `{{BAN_TIME}}` | Seconds to ban after failed attempts |
| `{{FIND_TIME}}` | Time window for counting failures |
| `{{MAX_RETRIES}}` | Failed attempts before ban |

---

### 02-port-knocking: Knockd Port-Knocking

**Purpose:** Install and configure knockd for port-knocking protection.

**What it does:**
- Prompts for three knock sequence ports and target port
- Installs knockd service
- Configures knock sequence using template
- Enables service

**Usage:**

```bash
sudo /path/to/01-security/02-port-knocking/run.sh
```

**Configuration File:**

The `knockd.conf` template file is located alongside `run.sh`. Template variables:

| Variable | Description |
|----------|-------------|
| `{{KNOCK_1}}, {{KNOCK_2}}, {{KNOCK_3}}` | Port sequence to knock |
| `{{TARGET_PORT}}` | Port to open after successful knock |

---

### 03-apparmor: AppArmor Mandatory Access Control

**Purpose:** Install and enable AppArmor for mandatory access control.

**What it does:**
- Installs AppArmor and utilities
- Enables AppArmor service
- Loads default profiles
- Verifies service status

**Usage:**

```bash
sudo /path/to/01-security/03-apparmor/run.sh
```

---

### 04-sysctl: Kernel & Network Hardening

**Purpose:** Apply system-level hardening via sysctl configuration.

**What it does:**
- Applies sysctl parameters from template
- Hardens network stack (IP spoofing, redirects, etc.)
- Enables SYN cookies
- Reloads kernel parameters

**Usage:**

```bash
sudo /path/to/01-security/04-sysctl/run.sh
```

**Configuration File:**

The `sysctl.conf` template file is located alongside `run.sh` and contains hardening parameters.

---

### 05-grub: GRUB Bootloader Hardening

**Purpose:** Harden GRUB bootloader configuration.

**What it does:**
- Applies GRUB hardening from template
- Disables recovery mode
- Hides GRUB menu
- Updates GRUB configuration

**Usage:**

```bash
sudo /path/to/01-security/05-grub/run.sh
```

**Configuration File:**

The `grub` template file is located alongside `run.sh`.

---

### 06-rkhunter: RKHunter Rootkit Detection

**Purpose:** Install RKHunter and perform rootkit scanning.

**What it does:**
- Installs RKHunter
- Applies configuration from template
- Updates RKHunter database
- Runs initial rootkit scan
- Optionally schedules CRON job

**Usage:**

```bash
sudo /path/to/01-security/06-rkhunter/run.sh
```

**Configuration File:**

The `rkhunter.conf` template file is located alongside `run.sh`.

---

### 07-chkrootkit: Chkrootkit Rootkit Scanner

**Purpose:** Install and run Chkrootkit for rootkit detection.

**What it does:**
- Installs Chkrootkit
- Runs initial rootkit scan
- Saves results to log file
- Optionally schedules CRON job

**Usage:**

```bash
sudo /path/to/01-security/07-chkrootkit/run.sh
```

---

### 08-lynis: Security Auditing & Hardening Suggestions

**Purpose:** Install Lynis and perform comprehensive security audit.

**What it does:**
- Installs Lynis
- Runs full system security audit
- Saves audit results to log file
- Optionally schedules CRON job

**Usage:**

```bash
sudo /path/to/01-security/08-lynis/run.sh
```

---

## Master Script

The `run.sh` file in this directory orchestrates execution of all subscripts:

```bash
sudo /path/to/01-security/run.sh
```

You will be prompted to confirm execution of each script.

---

## Environment Requirements

- **OS:** Ubuntu 18.04 LTS or later
- **Privileges:** Root access (run with `sudo`)
- **Internet:** Required for package downloads

---

## Execution Order

Scripts run in numerical order to ensure proper security layering:

1. `00-firewall` - Enable firewall first
2. `01-fail2ban` - Protect against brute-force
3. `02-port-knocking` - Hide SSH port
4. `03-apparmor` - Mandatory access control
5. `04-sysctl` - Kernel hardening
6. `05-grub` - Bootloader hardening
7. `06-rkhunter` - Rootkit detection
8. `07-chkrootkit` - Additional rootkit scanning
9. `08-lynis` - Security audit
