# 🌐 02-network

Networking, VPN, time synchronization, and DNS management for Ubuntu servers. This directory contains scripts for WireGuard VPN setup, NTP/Chrony time synchronization, and Cloudflare Tunnel configuration.

## Directory Overview

The `02-network` directory contains the following scripts executed in sequence:

| Script | Purpose |
|--------|---------|
| `00-wireguard` | Install WireGuard VPN and configure server |
| `01-chrony` | Install and configure Chrony NTP service |
| `03-cloudflare` | Setup Cloudflare Tunnel for secure access |

---

## Scripts

### 00-wireguard: WireGuard VPN Setup

**Purpose:** Install WireGuard VPN server and manage client configurations.

**What it does:**
- Installs WireGuard and utilities
- Prompts for VPN subnet and listening port
- Generates server keys
- Creates server configuration from template
- Enables WireGuard service
- Optionally adds client configurations

**Usage:**

```bash
sudo /path/to/02-network/00-wireguard/run.sh
```

**Configuration Files:**

The following template files are located alongside `run.sh`:

- `wg0.conf` - Server configuration template
- `client.conf` - Client configuration template

Template variables:

| Variable | Description |
|----------|-------------|
| `{{WG_SUBNET}}` | VPN subnet (e.g., 10.0.0.1/24) |
| `{{WG_PORT}}` | WireGuard listening port |
| `{{SERVER_PRIVATE_KEY}}` | Server private key |
| `{{CLIENT_PRIVATE_KEY}}` | Client private key |
| `{{CLIENT_IP}}` | Client VPN IP |
| `{{SERVER_PUBLIC_KEY}}` | Server public key |
| `{{SERVER_ENDPOINT}}` | Server public IP/hostname |
| `{{SERVER_PORT}}` | Server WireGuard port |

---

### 01-chrony: NTP Time Synchronization

**Purpose:** Install and configure Chrony for NTP time synchronization.

**What it does:**
- Installs Chrony service
- Applies configuration from template
- Enables and starts Chrony service
- Verifies service status

**Usage:**

```bash
sudo /path/to/02-network/01-chrony/run.sh
```

**Configuration File:**

The `chrony.conf` template file is located alongside `run.sh`.

---

### 03-cloudflare: Cloudflare Tunnel Setup

**Purpose:** Setup Cloudflare Tunnel for secure access to internal services.

**What it does:**
- Installs Cloudflare Tunnel (cloudflared) daemon
- Prompts for Cloudflare API token
- Prompts for tunnel name and hostnames
- Maps hostnames to local service ports
- Creates tunnel configuration
- Enables systemd service

**Usage:**

```bash
sudo /path/to/02-network/03-cloudflare/run.sh
```

---

## Master Script

The `run.sh` file in this directory orchestrates execution of all subscripts:

```bash
sudo /path/to/02-network/run.sh
```

You will be prompted to confirm execution of each script.

---

## Environment Requirements

- **OS:** Ubuntu 18.04 LTS or later
- **Privileges:** Root access (run with `sudo`)
- **Internet:** Required for package downloads and Cloudflare connectivity

---

## Execution Order

Scripts run in numerical order:

1. `00-wireguard` - VPN setup
2. `01-chrony` - Time synchronization
3. `03-cloudflare` - Cloudflare Tunnel
