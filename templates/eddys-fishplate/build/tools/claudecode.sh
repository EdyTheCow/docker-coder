#!/usr/bin/env bash
set -euo pipefail
# Claude Code CLI installation

echo "Installing Claude Code CLI..."

# Install Claude Code
curl -fsSL https://claude.ai/install.sh | bash

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

# Configure MCP servers
if command -v claude >/dev/null 2>&1; then
  claude mcp add --transport stdio --scope user desktop-commander -- \
    bunx --yes @wonderwhy-er/desktop-commander@latest || true

  claude mcp add --transport stdio --scope user playwright -- \
    bunx --yes @playwright/mcp@latest --headless --isolated --no-sandbox || true
fi

echo "Claude Code CLI installation complete!"
