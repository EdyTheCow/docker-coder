#!/usr/bin/env bash
set -euo pipefail
# Cursor CLI installation
#
# Installs the Cursor Agent CLI. The installer drops symlinks `agent` and
# `cursor-agent` into ~/.local/bin (already on PATH), and `agent` is exactly the
# binary T3 Code's Cursor provider probes (`agent about`).

echo "Installing Cursor CLI..."

# Install via the official install script
curl https://cursor.com/install -fsS | bash

echo "Cursor CLI installation complete!"
