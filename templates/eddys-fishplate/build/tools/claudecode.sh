#!/usr/bin/env bash
set -euo pipefail
# Claude Code CLI installation

echo "Installing Claude Code CLI..."

# Install via npm (not the native installer) so the install method matches how
# T3 Code updates it: t3 runs `npm install -g @anthropic-ai/claude-code@latest`.
# The native installer puts a non-npm symlink at ~/.local/bin/claude, which makes
# that update fail with EEXIST. npm-managed install lets t3's update overwrite its
# own link cleanly. (NPM_CONFIG_PREFIX=~/.local from the Dockerfile keeps it on PATH
# and avoids the root-owned global prefix / EACCES.)
npm install -g @anthropic-ai/claude-code@latest

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
