#!/usr/bin/env bash
set -euo pipefail
# OpenCode installation

echo "Installing OpenCode..."

# Install via the official install script
curl -fsSL https://opencode.ai/install | bash

echo "OpenCode installation complete!"
