<p align="center">
  <img width="300" src="https://raw.githubusercontent.com/BeefBytes/Assets/refs/heads/master/Other/container_illustration/v2/docker-coder.svg">
</p>

# 📚 About

The point of this project is a production ready installation of Coder using Traefik as a reverse proxy.
Official Coder's docs did not include Traefik as an option, which is the main reason for this repository. This is mainly meant as personal documentation, but it could be useful for anyone trying to set this up using Traefik!

# 👓 Quick Overview

## Folder structure

```
docker-coder/
├── deploy/
│   ├── traefik/          # Reverse proxy
│   └── coder/            # Coder server + PostgreSQL
└── templates/
    └── eddys-fishy-node/ # Fish shell + Node.js workspace template
```

## Requirements

- Domain
- Cloudflare account (free)

# 🏗️ Installation

<b>Clone repository</b>

```
git clone https://github.com/EdyTheCow/docker-coder.git
```

## Traefik

<b>Set correct acme.json permissions</b><br />
Navigate to `deploy/traefik/` and run:

```
sudo chmod 600 acme.json
```

<b>Create docker network</b><br />

```
docker network create coder-network
```

<b>Set DNS records</b><br />
Navigate to Cloudflare's dashboard and set these DNS records for your domain:

| Record type | Name     | IP               | Proxy Status |
| ----------- | -------- | ---------------- | ------------ |
| A           | coder    | Your server's IP | Proxied      |
| A           | \*.coder | Your server's IP | DNS only     |

It is important that the wild card `*.coder` is set to `DNS only` (grey cloud icon).
Two level sub-domains will not work otherwise. This is a premium Cloudflare feature if you want to proxy two-level sub-domains.
However, in this case it doesn't really matter. You'll have to be logged into your Coder's dashboard to be able to access these links anyway.

These two level sub-domains will be used by Coder to automatically assign live dev servers to a fully valid domain. For example, when you launch a nodejs dev server from a terminal inside of workspace, it will auto port forward and launch the dev server under a generated two-level sub-domain. Coder's docs have more details on this.

<b>Set .env variables for Traefik</b><br />
Navigate to `deploy/traefik/.env` and set these variables:

| Variable         | Example           | Description                                         |
| ---------------- | ----------------- | --------------------------------------------------- |
| TRAEFIK_EMAIL    | admin@example.com | It's a Let's Encrypt requirement, any email will do |
| CF_DNS_API_TOKEN | -                 | Cloudflare API Token                                |

<b>Cloudflare API Token</b><br />
This API token will be used as DNS challenge by Let's Encrypt to generate wildcard certificate for `*.coder.example.com`.
Generating wildcard certificates with Let's Encrypt HTTP challenge is not possible. Which is why Cloudflare API token is required.

To generate Cloudflare API token:

- Navigate to `Cloudflare's dashboard` > `Profile` > `API Tokens`
- Click on `Create Token`, least possible permissions are `Zone:Read`, `DNS:Edit`
- For Zone Resources select the domain you'll be using
- Generate the API token and paste it to variable `CF_DNS_API_TOKEN` variable

<b>Start docker compose</b><br />
Inside of `deploy/traefik/` run the command below. This will start Traefik reverse proxy.

```
docker-compose up -d
```

## Coder

<b>Set docker group ID</b><br />
Navigate to `deploy/coder/docker-compose.yml` and set docker group's ID under `group_add`.
You can replace the one already set if yours is different. To find out your docker's group ID run command:

```
getent group docker | cut -d: -f3
```

<b>Set .env variables for Coder</b><br />
Navigate to `deploy/coder/.env` and set these variables:

| Variable          | Example           | Description                      |
| ----------------- | ----------------- | -------------------------------- |
| DOMAIN            | coder.example.com | Domain for your Coder's instance |
| POSTGRES_PASSWORD | -                 | Generate a strong password       |

<b>Start docker compose</b><br />
Inside of `deploy/coder/` run the command below. This will start Coder and Postgres DB.

```
docker-compose up -d
```

<b>Create your first account</b><br />
Coder should be now running under `coder.example.com`!
The first time you navigate there, you should be asked to create your first admin account.

# 📝 Templates

Coder offers a bunch of pre-made templates you can use. This repository includes my personal template `Eddy's Fishy Node` which I use for work.
Template includes Fish shell, NodeJs and Claude Code with some personal configs. Feel free to use it however you see fit or create your own.
