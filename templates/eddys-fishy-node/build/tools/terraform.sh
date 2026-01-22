#!/usr/bin/env bash
set -euo pipefail
# Terraform installation

echo "Installing Terraform..."

# Add HashiCorp GPG key and repository
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update && sudo apt-get install -y terraform
sudo rm -rf /var/lib/apt/lists/*

# Add terraform aliases to fish
mkdir -p "$HOME/.config/fish/conf.d"
cat > "$HOME/.config/fish/conf.d/terraform.fish" << 'EOF'
alias tf "terraform"
alias tfi "terraform init"
alias tfp "terraform plan"
alias tfa "terraform apply"
alias tfd "terraform destroy"
alias tfv "terraform validate"
alias tff "terraform fmt"
EOF

echo "Terraform installation complete!"
