#!/usr/bin/env bash
set -euo pipefail
# Workspace startup script

TOOLS_DIR="/opt/coder/tools"
CONFIG_DIR="/opt/coder/config"
MARKER_FILE="$HOME/.workspace_initialized"

# Skip if already initialized
if [ -f "$MARKER_FILE" ]; then
  echo "Workspace already initialized, skipping setup."
  exit 0
fi

# Create projects directory
mkdir -p "$HOME/projects"

# Set up fish config
mkdir -p "$HOME/.config/fish/conf.d"
cat > "$HOME/.config/fish/config.fish" << 'EOF'
fish_add_path $HOME/.bun/bin
fish_add_path $HOME/.local/bin

alias l "ls -la"
EOF

# Install Fisher and plugins
echo "Installing Fisher and plugins..."
fish -c '
curl -fsL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
and fisher install jorgebucaran/fisher
and fisher install ilancosman/tide@v6
and fisher install nickeb96/puffer-fish
' || { echo "Warning: Fisher installation failed, continuing anyway"; }

# Apply Tide configuration
cat "$CONFIG_DIR/tide_variables" >> "$HOME/.config/fish/fish_variables"

# Configure Claude settings
mkdir -p "$HOME/.claude"
cat > "$HOME/.claude/settings.json" << 'EOF'
{
  "permissions": {
    "allow": ["*"],
    "deny": []
  },
  "autoApprove": ["Bash(*)", "Read(*)", "Write(*)", "Edit(*)", "MultiEdit(*)"]
}
EOF

# Install selected tools
%{ if install_terraform ~}
bash "$TOOLS_DIR/terraform.sh"
%{ endif ~}

# Configure MCP servers
if command -v claude >/dev/null 2>&1; then
  claude mcp add --transport stdio --scope user desktop-commander -- \
    bunx --yes @wonderwhy-er/desktop-commander@latest || true

  claude mcp add --transport stdio --scope user playwright -- \
    bunx --yes @playwright/mcp@latest --headless --isolated --no-sandbox || true
fi

# Mark as initialized
touch "$MARKER_FILE"

echo "Workspace setup complete!"
