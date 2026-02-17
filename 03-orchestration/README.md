# 🐳 03-orchestration

Container orchestration and service management for Ubuntu servers. This directory contains scripts for Docker installation and container management.

## Directory Overview

The `03-orchestration` directory contains the following scripts executed in sequence:

| Script | Purpose |
|--------|----------|
| `00-docker` | Install Docker Engine and Docker Compose |

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
sudo /path/to/03-orchestration/00-docker/run.sh
```

---

## Master Script

The `run.sh` file in this directory orchestrates execution of all subscripts:

```bash
sudo /path/to/03-orchestration/run.sh
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
