#!/usr/bin/env bash
set -euo pipefail
# OpenAI Codex CLI installation

echo "Installing Codex CLI..."

# Install into $HOME so it survives container restarts (the root FS is ephemeral;
# only the home volume persists). $HOME/.local/bin is already on PATH via fish config.
# The package pulls a prebuilt platform binary (@openai/codex-linux-x64), no compile.
npm install -g @openai/codex --prefix "$HOME/.local"

echo "Codex CLI installation complete!"
