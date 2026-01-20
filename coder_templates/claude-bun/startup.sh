#!/usr/bin/env bash

mkdir -p "$HOME/projects"

# Set up Fish config (only on first run)
mkdir -p "$HOME/.config/fish"
if [ ! -f "$HOME/.config/fish/config.fish" ]; then
  cat > "$HOME/.config/fish/config.fish" << 'EOF'
fish_add_path $HOME/.bun/bin
fish_add_path $HOME/.local/bin

alias l "ls -la"

# Initialize Starship prompt
starship init fish | source
EOF
fi

# Set up Starship config (only on first run)
if [ ! -f "$HOME/.config/starship.toml" ]; then
  starship preset gruvbox-rainbow -o "$HOME/.config/starship.toml"
fi

# Configure Claude settings (model + bypass permissions)
mkdir -p "$HOME/.claude"
if [ ! -f "$HOME/.claude/settings.json" ]; then
  cat > "$HOME/.claude/settings.json" << 'EOF'
{
  "model": "claude-opus-4-20250514",
  "permissions": {
    "allow": ["*"],
    "deny": []
  },
  "autoApprove": ["Bash(*)", "Read(*)", "Write(*)", "Edit(*)", "MultiEdit(*)"]
}
EOF
fi

# Configure MCP servers
if command -v claude >/dev/null 2>&1; then
  claude mcp list 2>/dev/null | awk '{print $1}' | grep -qx "playwright" || \
    claude mcp add --transport stdio --scope user playwright -- \
      bunx --yes @playwright/mcp@latest --headless --isolated --no-sandbox || true

  claude mcp list 2>/dev/null | awk '{print $1}' | grep -qx "desktop-commander" || \
    claude mcp add --transport stdio --scope user desktop-commander -- \
      bunx --yes @wonderwhy-er/desktop-commander@latest || true
fi