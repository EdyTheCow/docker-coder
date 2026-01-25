#!/usr/bin/env bash
set -euo pipefail
# Python development environment setup

echo "Installing Python development tools..."

# Install common development tools via pipx
pipx install poetry
pipx install ruff
pipx install black
pipx install mypy

# Add python aliases to fish
mkdir -p "$HOME/.config/fish/conf.d"
cat > "$HOME/.config/fish/conf.d/python.fish" << 'EOF'
alias py "python3"
alias pip "pip3"
alias venv "python3 -m venv"
EOF

echo "Python development environment setup complete!"