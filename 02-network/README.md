# 🌐 02-network

Networking, VPN, time synchronization, and HTTP ingress for Ubuntu servers. This directory contains scripts for WireGuard VPN setup, NTP/Chrony time synchronization, nginx reverse proxy, and Let's Encrypt certificate management.

## Directory Overview

The `02-network` directory contains the following scripts executed in sequence:

| Script | Purpose |
|--------|---------|
| `00-wireguard` | Install WireGuard VPN and configure server |
| `01-chrony` | Install and configure Chrony NTP service |
| `02-nginx` | Deploy nginx reverse proxy via Docker on the WAN interface |
| `03-certbot` | Manage Let's Encrypt TLS certificates with Cloudflare DNS challenge |

**Note:** Kernel module setup is handled in `00-system/05-kernel-modules` as it's foundational system configuration.

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

### 02-nginx: nginx Reverse Proxy

**Purpose:** Deploy nginx as a Dockerised reverse proxy bound exclusively to the WAN interface, leaving the WireGuard interface free for Homer and internal services.

**What it does:**
- Detects the primary WAN IP automatically via `get_wan_ip()`
- Binds nginx to `$WAN_IP:80` and `$WAN_IP:443` only — WireGuard clients are unaffected
- Mounts `/opt/nginx/conf.d` for site configuration files (read-only inside container)
- Mounts `/etc/letsencrypt` for TLS certificates issued by certbot (read-only inside container)
- Installs a default catch-all config if no configs exist yet
- Opens UFW rules for ports 80 and 443

**Usage:**

```bash
sudo /path/to/02-network/02-nginx/run.sh
```

**Site configuration files** are placed in `/opt/nginx/conf.d/` on the host. Add a `*.conf` file per site, then reload nginx:

```bash
docker exec nginx nginx -s reload
```

---

### 03-certbot: Let's Encrypt Certificate Management

**Purpose:** Issue and auto-renew TLS certificates using Certbot with Cloudflare DNS challenge. Certificates are stored in `/etc/letsencrypt` and shared with nginx via bind mount.

**Menu options:**
1. **Install Certbot** — first-time setup: pulls `certbot/dns-cloudflare` image, prompts for Cloudflare API token and email, stores credentials in `/etc/letsencrypt/cloudflare.ini` (chmod 600), configures daily auto-renewal cron job
2. **Add domain / issue certificate** — prompts for domain name, optionally includes wildcard (`*.domain`), runs certbot via Docker with Cloudflare DNS challenge
3. **List certificates and expiry** — shows all installed certificates and their expiry dates
4. **Renew certificates now** — immediately runs `certbot renew` against all certificates due for renewal, then prompts to reload nginx

**Usage:**

```bash
sudo /path/to/02-network/03-certbot/run.sh
```

**Cloudflare API token requirements:**
- Create at: https://dash.cloudflare.com/profile/api-tokens
- Required permission: `Zone > DNS > Edit`

**After issuing a certificate**, add the following to your nginx site config:

```nginx
ssl_certificate     /etc/letsencrypt/live/example.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
```

**Auto-renewal** runs daily at 03:00 via cron (`/etc/cron.d/certbot-renew-cron`).

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
- **Internet:** Required for package downloads
- **Docker:** Required for `02-nginx` and `03-certbot` — run `03-orchestration/00-docker` first

---

## Execution Order

Scripts run in numerical order:

1. `00-wireguard` - VPN setup
2. `01-chrony` - Time synchronization
3. `02-nginx` - HTTP/HTTPS reverse proxy
4. `03-certbot` - TLS certificate management

**Prerequisites:** Kernel modules should be loaded via `00-system/05-kernel-modules` before networking setup. Docker must be installed before running `02-nginx` or `03-certbot`.

