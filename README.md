# server-scripts

Bash automation toolkit for Ubuntu server provisioning, hardening, and management. A collection of modular scripts for automating fresh server setup from system foundation through security, networking, storage, and monitoring.

## Table of Contents

- [Overview](#overview)
- [Usage](#usage)
- [Installation](#installation)
- [Scripts](#scripts)
- [Utilities](#utilities)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Overview

`server-scripts` is a collection of provisioning and hardening scripts designed for fresh VPS and dedicated servers. Best suited for custom server setup scenarios rather than cloud-managed instances. Each script prompts for configuration, validates inputs, applies changes, and backs up existing configurations.

Use this toolkit to automate server initialisation, security configuration, networking setup, and monitoring across system foundation, security hardening, networking, storage, orchestration, and dashboards.

## Usage

Scripts are designed to be executed in order, designated by their numeric prefixes (00, 01, 02, etc.). Start with `00-system` to establish the foundation, then proceed through categories in sequence.

**Requirements:**
- Ubuntu systems only (scripts will exit if run on other distributions)
- `sudo` privileges required for all scripts
- Run scripts individually or execute master scripts to prompt for subscripts

**Getting scripts to your server:**

Since fresh servers may not have `git` installed, use `copy.sh` to transfer the toolkit via SCP:

```bash
./copy.sh  # Interactive script to upload via SCP
```

This prompts for server IP, SSH credentials, and remote path, then uses tar to package and transfer all files. Once on the server, scripts are ready to execute.

**Using `.env` to auto-populate SSH details:**

To avoid re-entering SSH credentials for repeated copies, create a `.env` file with your server details:

```bash
cp .env.example .env
# Edit .env with your server details
nano .env
```

The `.env` file should contain:

```bash
COPY_SERVER_IP=192.168.1.100
COPY_SSH_USER=root
COPY_SSH_PORT=22
COPY_REMOTE_DIR='~/server-scripts'
```

When you run `./copy.sh`, it will load these defaults and show them in the prompts. You can still override them interactively. **Important:** Keep `.env` out of version control by never committing it (it's in `.gitignore`).

**Example execution order:**
```bash
sudo ./00-system/run.sh          # System foundation
sudo ./01-security/run.sh        # Security hardening
sudo ./02-network/run.sh         # Networking setup
sudo ./03-disk/run.sh            # Disk management
sudo ./04-orchestration/run.sh   # Container setup
sudo ./05-monitoring/run.sh      # Monitoring tools
sudo ./06-gui/run.sh             # Web dashboards
```

## Installation

Clone the repository:

```bash
git clone https://github.com/itsmichaelbtw/server-scripts.git
cd server-scripts
```

All scripts are executable by default. If needed, run:

```bash
./executable.sh  # Makes all run.sh files executable
```

## Scripts

| Category | Description | Docs |
|----------|-------------|------|
| **00-system** | System foundation (updates, utilities, user, SSH, cron) | [README](./00-system/README.md) |
| **01-security** | Security hardening (firewall, fail2ban, port-knocking, apparmor, sysctl, grub, rootkit detection, auditing) | [README](./01-security/README.md) |
| **02-network** | Networking & VPN (WireGuard, NTP, Cloudflare Tunnel) | [README](./02-network/README.md) |
| **03-disk** | Disk & storage (RAID, filesystem, monitoring) | [README](./03-disk/README.md) |
| **04-orchestration** | Container orchestration (Docker, k3s, Traefik) | [README](./04-orchestration/README.md) |
| **05-monitoring** | Performance monitoring (sysstat, process tools) | [README](./05-monitoring/README.md) |
| **06-gui** | Web dashboards (NetData, FileBrowser, Homer, Crontab-UI, Gatus) | [README](./06-gui/README.md) |

## Utilities

- **executable.sh** - Make all scripts executable
- **copy.sh** - Copy scripts to a remote server

## Troubleshooting

### Script fails to run
```bash
# Ensure scripts are executable
chmod +x *.sh */*.sh */*/*.sh

# Run with bash explicitly
sudo bash ./00-system/run.sh
```

### Configuration validation fails
- Review the backup file to see the previous working configuration
- Check script output for specific validation error messages
- Restore backup and try with different parameters

### SSH locked out after 03-ssh script
1. Use another SSH session or console access to recover
2. Restore SSH config backup: `sudo cp /etc/ssh/sshd_config.backup-* /etc/ssh/sshd_config`
3. Restart SSH: `sudo systemctl restart ssh`

### Port conflicts
Ensure selected ports don't conflict with existing services:
```bash
sudo netstat -tlnp | grep LISTEN
```

## License

MIT License - See [LICENSE](./LICENSE) for details.
