# 🐳 04-orchestration

Container orchestration and service management for Ubuntu servers. This directory contains scripts for Docker installation, k3s lightweight Kubernetes, and Traefik ingress controller setup.

## Directory Overview

The `04-orchestration` directory contains the following scripts executed in sequence:

| Script | Purpose |
|--------|---------|
| `00-docker` | Install Docker Engine and Docker Compose |
| `01-k3s` | Install k3s lightweight Kubernetes cluster |
| `02-traefik` | Install Traefik ingress controller on k3s |

---

## Scripts

### 00-docker: Docker Installation

**Purpose:** Install Docker Engine and Docker Compose with service configuration.

**What it does:**
- Installs required packages
- Adds Docker GPG key and repository
- Installs Docker Engine, Docker CLI, and plugins
- Optionally adds user to docker group
- Enables and starts Docker service
- Verifies installation

**Usage:**

```bash
sudo /path/to/04-orchestration/00-docker/run.sh
```

---

### 01-k3s: k3s Kubernetes Installation

**Purpose:** Install k3s lightweight Kubernetes cluster (server or agent).

**What it does:**
- Prompts for role (server/agent)
- Prompts for node name
- Installs k3s without Traefik
- Configures kubectl for a deployment user
- Verifies k3s installation

**Usage:**

```bash
sudo /path/to/04-orchestration/01-k3s/run.sh
```

---

### 02-traefik: Traefik Ingress Controller

**Purpose:** Install Traefik ingress controller on k3s with ACME/Cloudflare DNS.

**What it does:**
- Checks k3s installation
- Prompts for dashboard enablement
- Prompts for ACME email and Cloudflare API token
- Installs Helm if needed
- Applies Traefik configuration from template
- Installs/upgrades Traefik via Helm

**Usage:**

```bash
sudo /path/to/04-orchestration/02-traefik/run.sh
```

**Configuration File:**

The `traefik.conf` template file is located alongside `run.sh`. Template variables:

| Variable | Description |
|----------|-------------|
| `{{DASHBOARD_ENABLED}}` | Enable Traefik dashboard (true/false) |
| `{{ACME_EMAIL}}` | Email for ACME certificate registration |

---

## Master Script

The `run.sh` file in this directory orchestrates execution of all subscripts:

```bash
sudo /path/to/04-orchestration/run.sh
```

You will be prompted to confirm execution of each script.

---

## Environment Requirements

- **OS:** Ubuntu 18.04 LTS or later
- **Privileges:** Root access (run with `sudo`)
- **Internet:** Required for package downloads and Cloudflare connectivity
- **Memory:** At least 1GB RAM recommended (more for k3s/Traefik)

---

## Execution Order

Scripts run in numerical order:

1. `00-docker` - Container runtime
2. `01-k3s` - Kubernetes cluster
3. `02-traefik` - Ingress controller
