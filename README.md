# docker-coder

Docker-based [Coder](https://coder.com/) deployment with Traefik reverse proxy and workspace templates.

## Structure

```
docker-coder/
├── deployment/
│   ├── traefik/          # Reverse proxy with SSL
│   └── coder/            # Coder server + PostgreSQL
└── templates/
    └── eddys-fishy-node/ # Fish + Node.js workspace template
```

## Prerequisites

- Docker with Docker Compose
- Domain with DNS pointing to your server
- Cloudflare API token (for wildcard SSL certs) or HTTP challenge for single-domain certs

## Deployment

### 1. Create the shared Docker network

```bash
docker network create coder-network
```

### 2. Deploy Traefik

```bash
cd deployment/traefik
```

Edit `.env`:
```
TRAEFIK_EMAIL=your-email@example.com
CF_DNS_API_TOKEN=your-cloudflare-api-token
```

Ensure `acme.json` has correct permissions:
```bash
chmod 600 acme.json
```

Start Traefik:
```bash
docker compose up -d
```

### 3. Deploy Coder

```bash
cd deployment/coder
```

Edit `.env`:
```
DOMAIN=coder.example.com
POSTGRES_PASSWORD=your-secure-password
```

Start Coder:
```bash
docker compose up -d
```

### 4. Initial Setup

1. Open `https://coder.example.com` in your browser
2. Create the first admin user
3. Add templates from the `templates/` directory

## Templates

### eddys-fishy-node

Fish shell + Node.js development environment.

**Includes:**
- Fish 4.3.3 with Tide prompt
- Node.js 24, Bun, pnpm, yarn, tsx
- Claude Code CLI with MCP servers (Desktop Commander, Playwright)
- Git, tmux, vim, ripgrep, jq, htop
- code-server (VS Code in browser)

**Optional:**
- Terraform CLI

See [templates/eddys-fishy-node/README.md](templates/eddys-fishy-node/README.md) for details.

## SSL Certificates

The Traefik configuration supports two certificate resolvers:

- **cloudflare** - DNS challenge via Cloudflare API (supports wildcard certs)
- **letsencrypt** - HTTP challenge (single domain only)

Wildcard certificates (`*.coder.example.com`) are required for workspace dev servers to work with HTTPS.

## Notes

- The Coder container mounts the Docker socket to spawn workspace containers on the host
- Workspace data persists in Docker volumes
- The `coder-network` must be created before starting either service
