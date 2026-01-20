terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

provider "coder" {}
provider "docker" {}

data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

locals {
  username = "coder"

  owner_safe     = lower(replace(data.coder_workspace_owner.me.name, "/[^a-z0-9_.-]/", "-"))
  workspace_safe = lower(replace(data.coder_workspace.me.name, "/[^a-z0-9_.-]/", "-"))

  image_tag = "coder-claude-bun:${local.owner_safe}-${local.workspace_safe}"

  container_name   = "coder-${local.owner_safe}-${local.workspace_safe}"
  home_volume_name = "${local.container_name}-home"
}

resource "coder_agent" "main" {
  arch = data.coder_provisioner.me.arch
  os   = "linux"
  dir  = "/home/${local.username}/projects"

  startup_script = replace(file("${path.module}/startup.sh"), "\r\n", "\n")

  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Home Disk"
    key          = "2_home_disk"
    script       = "coder stat disk --path $${HOME}"
    interval     = 60
    timeout      = 1
  }

  metadata {
    display_name = "Node.js"
    key          = "3_node_version"
    script       = "node --version"
    interval     = 120
    timeout      = 5
  }

  metadata {
    display_name = "Bun"
    key          = "4_bun_version"
    script       = "export PATH=\"$HOME/.bun/bin:$PATH\" && bun --version"
    interval     = 120
    timeout      = 5
  }
}

resource "docker_image" "workspace" {
  name = local.image_tag
  build {
    context = "${path.module}/build"
  }
}

resource "docker_volume" "home" {
  name = local.home_volume_name
  lifecycle {
    ignore_changes = all
  }
}

resource "docker_container" "workspace" {
  count    = data.coder_workspace.me.start_count
  image    = docker_image.workspace.name
  name     = local.container_name
  hostname = data.coder_workspace.me.name

  entrypoint = [
    "sh",
    "-c",
    replace(
      replace(coder_agent.main.init_script, "localhost", "host.docker.internal"),
      "127.0.0.1",
      "host.docker.internal"
    )
  ]

  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
  ]

  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }

  volumes {
    container_path = "/home/${local.username}"
    volume_name    = docker_volume.home.name
    read_only      = false
  }
}

module "code-server" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/code-server/coder"
  version  = "1.4.2"
  agent_id = coder_agent.main.id
  folder   = "/home/${local.username}/projects"

  extensions = [
    "bradlc.vscode-tailwindcss",
    "esbenp.prettier-vscode",
    "eamodio.gitlens",
  ]

  settings = {
    "workbench.colorTheme"                     = "Default Dark Modern"
    "editor.formatOnSave"                      = true
    "editor.defaultFormatter"                  = "esbenp.prettier-vscode"
    "files.trimTrailingWhitespace"             = true
    "git.autofetch"                            = true
    "tailwindCSS.emmetCompletions"             = true
    "terminal.integrated.defaultProfile.linux" = "fish"
    "terminal.integrated.fontFamily"           = "'Hack Nerd Font Mono','Hack Nerd Font',monospace"
    "workbench.startupEditor"                  = "none"
  }

  # optional but nice so restarts don't reinstall constantly
  use_cached_extensions = true
}