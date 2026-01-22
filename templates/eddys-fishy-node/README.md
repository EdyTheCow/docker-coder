# Eddy's Fishy Node

A Coder workspace template with Fish shell, Node.js, and optional Terraform.

## Base Tools (Always Included)

- Fish shell 4.3.3 with Tide prompt (via Fisher)
- Node.js 24, Bun, pnpm, yarn, tsx
- Claude Code CLI with MCP servers (Desktop Commander, Playwright)
- Git, tmux, vim, ripgrep, jq, htop

## Optional Tools

- **Terraform** - Terraform CLI with aliases

## Structure

```
eddys-fishy-node/
├── main.tf             # Terraform config
├── startup.sh          # Startup script (runs once)
└── build/
    ├── .dockerignore   # Excludes files from Docker build
    ├── Dockerfile      # Base image
    ├── config/
    │   └── tide_variables
    └── tools/
        └── terraform.sh
```

## Adding a New Tool

1. Create `build/tools/newtool.sh` with installation commands
2. Add a `coder_parameter` in `main.tf` (type = "bool")
3. Add the install block to `startup.sh`
4. Add any VS Code extensions and metadata in `main.tf`
