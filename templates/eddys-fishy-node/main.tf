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

data "coder_parameter" "tools" {
  name         = "tools"
  display_name = "Development Tools"
  description  = "Select additional tools to install"
  type         = "list(string)"
  form_type    = "multi-select"
  mutable      = false
  default      = jsonencode([])

  option {
    name  = "Terraform"
    value = "terraform"
    icon  = "https://cdn.simpleicons.org/terraform"
  }

  option {
    name  = "Ansible"
    value = "ansible"
    icon  = "https://cdn.simpleicons.org/ansible"
  }

  option {
    name  = "Python"
    value = "python"
    icon  = "https://cdn.simpleicons.org/python"
  }

  option {
    name  = "OpenCode"
    value = "opencode"
    icon  = "https://cdn.simpleicons.org/gnometerminal/white"
  }
}

locals {
  username = "coder"

  owner_safe     = lower(replace(data.coder_workspace_owner.me.name, "/[^a-z0-9_.-]/", "-"))
  workspace_safe = lower(replace(data.coder_workspace.me.name, "/[^a-z0-9_.-]/", "-"))

  image_tag        = "eddys-fishy-node:latest"
  container_name   = "coder-${local.owner_safe}-${local.workspace_safe}"
  home_volume_name = "${local.container_name}-home"

  # Parse selected tools from multi-select parameter
  selected_tools    = try(jsondecode(data.coder_parameter.tools.value), [])
  install_terraform = contains(local.selected_tools, "terraform")
  install_ansible   = contains(local.selected_tools, "ansible")
  install_python    = contains(local.selected_tools, "python")
  install_opencode  = contains(local.selected_tools, "opencode")
}

resource "coder_agent" "main" {
  arch = data.coder_provisioner.me.arch
  os   = "linux"
  dir  = "/home/${local.username}/projects"

  startup_script_behavior = "blocking"
  startup_script = templatefile("${path.module}/startup.sh", {
    selected_tools = local.selected_tools
  })

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
    script       = "bash -c 'coder stat disk --path $HOME'"
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
    script       = "bun --version"
    interval     = 120
    timeout      = 5
  }

  dynamic "metadata" {
    for_each = local.install_terraform ? [1] : []
    content {
      display_name = "Terraform"
      key          = "5_terraform_version"
      script       = "terraform version -json | jq -r '.terraform_version'"
      interval     = 120
      timeout      = 5
    }
  }

  dynamic "metadata" {
    for_each = local.install_ansible ? [1] : []
    content {
      display_name = "Ansible"
      key          = "6_ansible_version"
      script       = "ansible --version | head -1 | awk '{print $NF}' | tr -d '[]'"
      interval     = 120
      timeout      = 5
    }
  }

  dynamic "metadata" {
    for_each = local.install_python ? [1] : []
    content {
      display_name = "Python"
      key          = "7_python_version"
      script       = "python3 --version | awk '{print $2}'"
      interval     = 120
      timeout      = 5
    }
  }
}

resource "docker_image" "workspace" {
  name         = local.image_tag
  keep_locally = true
  build {
    context    = "${path.module}/build"
    dockerfile = "Dockerfile"
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

  extensions = concat(
    [
      "esbenp.prettier-vscode",
      "eamodio.gitlens",
      "redhat.vscode-yaml",
      "bradlc.vscode-tailwindcss",
      "dbaeumer.vscode-eslint",
    ],
    local.install_terraform ? ["hashicorp.terraform"] : [],
    local.install_ansible ? ["redhat.ansible"] : [],
    local.install_python ? ["ms-python.python"] : []
  )

  settings = {
    "workbench.colorTheme"                     = "Default Dark Modern"
    "editor.formatOnSave"                      = true
    "files.trimTrailingWhitespace"             = true
    "git.autofetch"                            = true
    "terminal.integrated.defaultProfile.linux" = "fish"
    "terminal.integrated.fontFamily"           = "'MesloLGS NF','Hack Nerd Font Mono','Hack Nerd Font',monospace"
    "workbench.startupEditor"                  = "none"

    # Disable AI/Copilot features
    "chat.disableAIFeatures"                     = true
    "chat.agent.enabled"                         = false
    "chat.commandCenter.enabled"                 = false
    "github.copilot.enable"                      = { "*" = false }
    "github.copilot.editor.enableCodeActions"    = false
    "github.copilot.nextEditSuggestions.enabled" = false
    "github.copilot.chat.codesearch.enabled"     = false
    "inlineChat.accessibleDiffView"              = "off"
    "terminal.integrated.initialHint"            = false
  }

  use_cached_extensions = true
}

module "git-config" {
  source                = "registry.coder.com/coder/git-config/coder"
  version               = "1.0.32"
  agent_id              = coder_agent.main.id
  allow_username_change = true
  allow_email_change    = true
}
