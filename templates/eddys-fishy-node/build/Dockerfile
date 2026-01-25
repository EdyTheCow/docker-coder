FROM ubuntu:24.04

RUN useradd -m -s /usr/local/bin/fish coder

USER root

# Base tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates git unzip tmux ripgrep sudo vim openssh-client \
    wget jq htop tree build-essential gnupg lsb-release xz-utils \
    python3 python3-pip python3-venv pipx \
  && rm -rf /var/lib/apt/lists/* \
  && echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/coder

# Fish shell (pre-built from GitHub)
RUN curl -fLo /tmp/fish.tar.xz https://github.com/fish-shell/fish-shell/releases/download/4.3.3/fish-4.3.3-linux-x86_64.tar.xz \
  && tar -xJf /tmp/fish.tar.xz -C /usr/local/bin \
  && rm /tmp/fish.tar.xz \
  && echo "/usr/local/bin/fish" >> /etc/shells

# Node.js 24
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  && rm -rf /var/lib/apt/lists/* \
  && npm install -g pnpm yarn tsx

# Copy tool installation scripts and config
COPY tools/ /opt/coder/tools/
COPY config/ /opt/coder/config/
RUN chmod +x /opt/coder/tools/*.sh

USER coder
WORKDIR /home/coder

# Bun
RUN curl -fsSL https://bun.sh/install | bash

ENV PATH="/home/coder/.bun/bin:/home/coder/.local/bin:${PATH}"
