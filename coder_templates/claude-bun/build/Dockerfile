FROM ubuntu:24.04

# Create coder user
RUN useradd -m -s /bin/bash coder

USER root

# Base tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates git unzip tmux ripgrep fish sudo vim openssh-client \
  && rm -rf /var/lib/apt/lists/* \
  && echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/coder

# Node.js 24 (Active LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  && rm -rf /var/lib/apt/lists/*

USER coder
WORKDIR /home/coder

# Bun
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/home/coder/.bun/bin:/home/coder/.local/bin:${PATH}"

# Starship prompt
RUN curl -fsSL https://starship.rs/install.sh | sh -s -- --yes

# Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash