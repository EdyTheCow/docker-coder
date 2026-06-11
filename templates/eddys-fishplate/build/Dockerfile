FROM ubuntu:24.04

RUN useradd -m -s /usr/local/bin/fish coder

USER root

# Base tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates git unzip tmux ripgrep sudo vim openssh-client \
    wget jq htop tree gnupg lsb-release xz-utils \
    python3 python3-pip python3-venv pipx build-essential \
  && rm -rf /var/lib/apt/lists/* \
  && echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/coder

# GitHub CLI (gh) — installed by default from GitHub's official apt repo
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
  && apt-get update && apt-get install -y --no-install-recommends gh \
  && rm -rf /var/lib/apt/lists/*

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

# T3 Code (pinned) — minimal web GUI for coding agents (Codex/Claude/Cursor/OpenCode).
# Native dep node-pty compiles using build-essential + python3 from the base layer above.
RUN npm install -g t3@0.0.25

# Copy tool installation scripts and config
COPY tools/ /opt/coder/tools/
COPY config/ /opt/coder/config/
RUN chmod +x /opt/coder/tools/*.sh

# `code` shim: lets T3 Code's "Open in editor" (and `code <path>`) open files in
# the code-server tab running in the browser. Harmless if code-server is absent.
COPY bin/code /usr/local/bin/code
RUN chmod +x /usr/local/bin/code

USER coder
WORKDIR /home/coder

# Bun
RUN curl -fsSL https://bun.sh/install | bash

# Python dev tools
RUN pipx install poetry && pipx install ruff && pipx install black && pipx install mypy

# Put per-user tool dirs on PATH for non-interactive processes too (the t3 daemon
# is launched via a coder_script and never sources fish config). OpenCode installs
# to ~/.opencode/bin and is otherwise only added to PATH via fish config, so t3's
# `opencode` provider detection fails without this. (.local/bin covers Claude/Codex/Cursor.)
ENV PATH="/home/coder/.opencode/bin:/home/coder/.bun/bin:/home/coder/.local/bin:${PATH}"
