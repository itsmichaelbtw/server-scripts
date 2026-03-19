# server-scripts

Bash automation toolkit for Ubuntu server provisioning, hardening, and management. A collection of modular scripts for automating fresh server setup from system foundation through security, networking, storage, and monitoring.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Usage](#usage)
- [Ports](#ports)
- [Grafana](#grafana)
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
SERVER_IP=192.168.1.100
SSH_USER=root
SSH_PORT=22
REMOTE_DIR='~/server-scripts'
```

When you run `./copy.sh`, it will load these defaults and show them in the prompts. You can still override them interactively if needed.

**Example execution order:**
```bash
sudo ./00-system/run.sh          # System foundation
sudo ./01-security/run.sh        # Security hardening
sudo ./02-network/run.sh         # Networking setup
sudo ./03-orchestration/run.sh   # Container setup
sudo ./04-monitoring/run.sh      # Monitoring tools
sudo ./05-gui/run.sh             # Web dashboards
```

## Ports

The table below lists the default ports used by each service. All ports can be customised via [`ports.conf`](#customising-ports).

| Port | Service / Script |
|------:|-----------------|
| 80 | Homer (`05-gui/06-homer/run.sh`) — WireGuard interface only |
| 80 | nginx (`02-network/02-nginx/run.sh`) — WAN interface only |
| 443 | nginx (`02-network/02-nginx/run.sh`) — WAN interface only |
| 5000 | Grafana (`05-gui/05-grafana/run.sh`) |
| 5010 | Prometheus (`04-monitoring/03-prometheus/run.sh`) |
| 5020 | Loki (`04-monitoring/04-loki/run.sh`) |
| 5030 | Alertmanager (`04-monitoring/05-alertmanager/run.sh`) |
| 5040 | Grafana Alloy (`04-monitoring/06-alloy/run.sh`) |
| 5050 | FileBrowser (`05-gui/01-filebrowser/run.sh`) |
| 5060 | Crontab-UI (`05-gui/02-crontab-ui/run.sh`) |
| 5070 | Gatus (`05-gui/03-gatus/run.sh`) |
| 5080 | Vaultwarden (`05-gui/04-vaultwarden/run.sh`) |
| 5090 | Portainer (`05-gui/07-portainer/run.sh`) |
| 19999 | Netdata (`05-gui/00-netdata/run.sh`) |
| 51820/udp | WireGuard VPN listening port (default prompt in `02-network/00-wireguard/run.sh`) |
| 51893/tcp | Alloy auxiliary port (`04-monitoring/06-alloy/run.sh`) |
| 51898/udp | Alloy auxiliary port (`04-monitoring/06-alloy/run.sh`) |

### Customising Ports

All service ports are defined in `ports.conf` at the repository root. Edit this file before running a deployment script to use a different host port:

```bash
# ports.conf
GRAFANA_PORT=5000
PROMETHEUS_PORT=5010
LOKI_PORT=5020
# ... etc
```

`ports.conf` is automatically loaded by every script via `common.sh`. The file is **required** — scripts will exit with an error if it is missing or if a required variable is undefined. When you change a port, re-run the relevant deployment script to redeploy the container on the new port. Homer's dashboard links are also regenerated from `ports.conf` on each deploy.

## Grafana

Grafana (`05-gui/05-grafana`) is deployed with anonymous admin access enabled — no login is required when accessed over the VPN. The sections below cover connecting it to the monitoring stack deployed by `04-monitoring`.

### Adding Data Sources

Navigate to **Connections → Data Sources → Add new data source** in Grafana. All services share the same Docker bridge network, so use container names as hostnames.

**Prometheus**
- Type: `Prometheus`
- URL: `http://prometheus:9090`
- Scrape interval: `15s`

**Loki**
- Type: `Loki`
- URL: `http://loki:3100`

**Alertmanager**
- Type: `Alertmanager`
- URL: `http://alertmanager:9093`
- Implementation: `Prometheus`

### Alloy — Log & Metrics Collection

Grafana Alloy (`04-monitoring/06-alloy`) is a collector agent that runs alongside your services. It:

- **Collects Docker container logs** — discovers all running containers via the Docker socket and forwards their logs to Loki automatically. Any new container you start is picked up without configuration changes.
- **Tails system log files** — ships logs from `/var/log/auth.log`, `ufw.log`, `fail2ban.log`, `kern.log`, and others to Loki under named job labels.

Alloy's configuration lives at `/etc/alloy/config.alloy`. To add a new log source, append an entry to the `local.file_match` block and restart the container:

```bash
docker restart alloy
```

The Alloy UI is accessible at `http://<server>:3100` and shows the live pipeline graph and debug information.

### Alertmanager — Alert Routing

Alertmanager (`04-monitoring/05-alertmanager`) receives firing alerts from Prometheus and routes them to notification channels. Edit `/etc/alertmanager/alertmanager.yml` to configure receivers:

```yaml
route:
  receiver: 'default'

receivers:
  - name: 'default'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/...'
        channel: '#alerts'
    email_configs:
      - to: 'you@example.com'
        from: 'alerts@example.com'
        smarthost: 'smtp.example.com:587'
```

After editing, reload Alertmanager without restarting:

```bash
curl -X POST http://localhost:3075/-/reload
```

Prometheus is pre-configured to send alerts to Alertmanager. Add alert rules to `/etc/prometheus/` as separate `*.rules.yml` files and reference them in `prometheus.yml` under `rule_files`.

### Importing Dashboards

The Grafana community provides pre-built dashboards at [grafana.com/grafana/dashboards](https://grafana.com/grafana/dashboards). Import them via **Dashboards → Import → Enter dashboard ID**.

Recommended dashboards:

| Dashboard ID | Description |
|---|---|
| `1860` | Node Exporter Full (system metrics) |
| `13639` | Loki logs explorer |
| `9578` | Docker container metrics |
| `11074` | Alertmanager overview |

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

If the target server does not have `git` installed, you can transfer the repository using the interactive `copy.sh` script instead of cloning:

```bash
./copy.sh
```

## Scripts

| Category | Description | Docs |
|----------|-------------|------|
| **00-system** | System foundation (updates, utilities, user, SSH, cron) | [README](./00-system/README.md) |
| **01-security** | Security hardening (firewall, fail2ban, port-knocking, apparmor, sysctl, grub, rootkit detection, auditing) | [README](./01-security/README.md) |
| **02-network** | Networking & ingress (WireGuard VPN, NTP, nginx reverse proxy, Let's Encrypt via Cloudflare DNS) | [README](./02-network/README.md) |
| **03-orchestration** | Container orchestration (Docker, k3s, Traefik) | [README](./03-orchestration/README.md) |
| **04-monitoring** | Performance monitoring (sysstat, process tools, disk monitoring) | [README](./04-monitoring/README.md) |
| **05-gui** | Web dashboards (NetData, FileBrowser, Homer, Crontab-UI, Gatus) | [README](./05-gui/README.md) |

## Utilities

- **executable.sh** - Make all run.sh files executable
- **copy.sh** - Copy scripts to a remote server
- **ssh-keygen.sh** - Generate SSH keypair, copy to server and update local SSH config

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
