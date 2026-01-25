# Eddy's Fishy Node

A Coder workspace template with Fish shell, Node.js, and optional development tools.

## Base Tools (Always Included)

- Fish shell 4.3.3 with Tide prompt (via Fisher)
- Node.js 24, Bun, pnpm, yarn, tsx
- Python 3, pipx, poetry, ruff, black, mypy
- Git, tmux, vim, ripgrep, jq, htop

## Optional Tools (Multi-Select)

- **Claude Code** - Claude Code CLI with MCP servers (Desktop Commander, Playwright)
- **Terraform** - Terraform CLI with fish aliases
- **Ansible** - Ansible via pipx with fish aliases
- **OpenCode** - OpenCode AI coding assistant

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
        ├── ansible.sh
        ├── claudecode.sh
        ├── opencode.sh
        └── terraform.sh
```

## Adding a New Tool

**Minimal (2 steps):**

1. Create `build/tools/newtool.sh` with installation commands
2. Add an `option` block to the `tools` parameter in `main.tf`

**Optional extras:**

3. Add `install_newtool = contains(local.selected_tools, "newtool")` to locals
4. Add a dynamic `metadata` block to show version in workspace dashboard
5. Add VS Code extension to the `extensions` list in code-server module
