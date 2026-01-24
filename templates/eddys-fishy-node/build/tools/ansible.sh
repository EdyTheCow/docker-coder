#!/usr/bin/env bash
set -euo pipefail
# Ansible installation

echo "Installing Ansible..."

# Install via pipx for isolated environment
pipx install --include-deps ansible

# Add ansible aliases to fish
mkdir -p "$HOME/.config/fish/conf.d"
cat > "$HOME/.config/fish/conf.d/ansible.fish" << 'EOF'
alias ap "ansible-playbook"
alias ai "ansible-inventory"
alias ag "ansible-galaxy"
alias av "ansible-vault"
EOF

echo "Ansible installation complete!"
