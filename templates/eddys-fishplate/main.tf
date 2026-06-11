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

data "coder_parameter" "ai_tools" {
  name         = "ai_tools"
  display_name = "AI Tools"
  description  = "Select AI coding CLIs to install (T3 Code integrates with these)"
  type         = "list(string)"
  form_type    = "multi-select"
  mutable      = false
  default      = jsonencode([])
  order        = 2

  option {
    name  = "Claude Code CLI"
    value = "claudecode"
    icon  = "https://cdn.simpleicons.org/claude"
  }

  option {
    name  = "OpenCode CLI"
    value = "opencode"
    icon  = "https://cdn.simpleicons.org/gnometerminal/white"
  }

  option {
    name  = "Codex CLI"
    value = "codex"
    icon  = "https://cdn.simpleicons.org/openai/white"
  }

  option {
    name  = "Cursor CLI"
    value = "cursor"
    icon  = "https://github.com/getcursor.png"
  }
}

data "coder_parameter" "tools" {
  name         = "tools"
  display_name = "Development Tools"
  description  = "Select additional tools to install"
  type         = "list(string)"
  form_type    = "multi-select"
  mutable      = false
  default      = jsonencode([])
  order        = 3

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
}

data "coder_parameter" "t3code" {
  name         = "t3code"
  display_name = "T3 Code"
  description  = "Run the T3 Code web GUI (Codex/Claude/Cursor/OpenCode) as a workspace app, gated by Coder auth"
  type         = "bool"
  form_type    = "switch"
  mutable      = true
  default      = true
  icon         = "https://github.com/pingdotgg.png"
  order        = 1
}

locals {
  username = "coder"

  owner_safe     = lower(replace(data.coder_workspace_owner.me.name, "/[^a-z0-9_.-]/", "-"))
  workspace_safe = lower(replace(data.coder_workspace.me.name, "/[^a-z0-9_.-]/", "-"))

  image_tag        = "eddys-fishplate:latest"
  container_name   = "coder-${local.owner_safe}-${local.workspace_safe}"
  home_volume_name = "${local.container_name}-home"

  # Parse selected tools from the two multi-select parameters. They are merged into
  # one list so startup.sh just runs "<tool>.sh" for each (the script names match
  # the option values), and the install_* flags below don't care which dropdown a
  # tool came from.
  selected_ai_tools  = try(jsondecode(data.coder_parameter.ai_tools.value), [])
  selected_dev_tools = try(jsondecode(data.coder_parameter.tools.value), [])
  selected_tools     = concat(local.selected_ai_tools, local.selected_dev_tools)
  install_terraform  = contains(local.selected_tools, "terraform")
  install_ansible    = contains(local.selected_tools, "ansible")

  # T3 Code: bound to loopback and exposed via a Coder subdomain app.
  # Loopback bind => server auth policy "loopback-browser" (pair once, persisted under ~/.t3).
  enable_t3code = tobool(data.coder_parameter.t3code.value)
  t3code_port   = 3773

  # Public URL of the T3 Code subdomain app, used to build a one-click /pair#token= link.
  # Coder serves subdomain apps at "{slug}--{agent}--{workspace}--{owner}.{wildcard-host}",
  # where the wildcard host is the access URL host (CODER_WILDCARD_ACCESS_URL = "*.DOMAIN").
  # "main" is the coder_agent resource label, which Coder uses as the agent name.
  t3code_app_host = replace(replace(data.coder_workspace.me.access_url, "https://", ""), "http://", "")
  t3code_app_url  = "https://t3code--main--${data.coder_workspace.me.name}--${data.coder_workspace_owner.me.name}.${local.t3code_app_host}"
}

resource "coder_agent" "main" {
  arch = data.coder_provisioner.me.arch
  os   = "linux"

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

  metadata {
    display_name = "Python"
    key          = "5_python_version"
    script       = "python3 --version | awk '{print $2}'"
    interval     = 120
    timeout      = 5
  }

  dynamic "metadata" {
    for_each = local.install_terraform ? [1] : []
    content {
      display_name = "Terraform"
      key          = "6_terraform_version"
      script       = "command -v terraform >/dev/null && terraform version -json | jq -r '.terraform_version' || echo 'Installing...'"
      interval     = 120
      timeout      = 5
    }
  }

  dynamic "metadata" {
    for_each = local.install_ansible ? [1] : []
    content {
      display_name = "Ansible"
      key          = "7_ansible_version"
      script       = "command -v ansible >/dev/null && ansible --version | head -1 | awk '{print $NF}' | tr -d '[]' || echo 'Installing...'"
      interval     = 120
      timeout      = 5
    }
  }

  dynamic "metadata" {
    for_each = local.enable_t3code ? [1] : []
    content {
      display_name = "T3 Code"
      key          = "8_t3code_version"
      script       = "t3 --version 2>/dev/null | sed 's/^t3 v//' || echo 'n/a'"
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
    local.install_ansible ? ["redhat.ansible"] : []
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
  # Push the git username/email fields to the bottom of the form. The module
  # places username at this order and email at order+1, so they land after the
  # t3 toggle (1), AI Tools (2) and Development Tools (3) parameters above.
  coder_parameter_order = 4
}

# Launch the T3 Code server on every workspace start (it is a long-running daemon,
# so it lives here rather than in the one-shot, marker-gated startup.sh).
resource "coder_script" "t3code" {
  count              = local.enable_t3code ? 1 : 0
  agent_id           = coder_agent.main.id
  display_name       = "T3 Code server"
  icon               = "https://github.com/pingdotgg.png"
  run_on_start       = true
  start_blocks_login = false
  script             = <<-EOT
    #!/usr/bin/env bash
    set -euo pipefail
    PORT=${local.t3code_port}
    mkdir -p "$HOME/projects"

    # Idempotent: a restart-on-start re-runs this; skip if already listening.
    if curl -fsS "http://127.0.0.1:$PORT/" >/dev/null 2>&1; then
      echo "T3 Code already running on port $PORT"
      exit 0
    fi

    echo "Starting T3 Code on 127.0.0.1:$PORT ..."
    nohup t3 serve --host 127.0.0.1 --port "$PORT" --no-browser "$HOME/projects" \
      >"$HOME/.t3-serve.log" 2>&1 &

    for i in $(seq 1 30); do
      if curl -fsS "http://127.0.0.1:$PORT/" >/dev/null 2>&1; then
        echo "T3 Code is up."
        break
      fi
      sleep 1
    done

    # The token `t3 serve` prints is single-use and expires in 5 minutes, so it is
    # almost always dead by the time you open the app. Mint a fresh, longer-lived
    # token on each cold start instead. Passing --base-url makes t3 print a ready
    # "/pair#token=..." link: one click redeems the token and sets the t3_session
    # cookie (httpOnly, 30-day TTL), so you only do this once per browser per month.
    BASE_URL="${local.t3code_app_url}"
    echo "==================== T3 Code pairing ===================="
    if PAIR_OUT="$(t3 auth pairing create --ttl 24h --label coder --base-url "$BASE_URL" 2>&1)"; then
      echo "$PAIR_OUT"
      PAIR_URL="$(printf '%s\n' "$PAIR_OUT" | grep -oE 'https?://[^[:space:]]+/pair#token=[^[:space:]]+' | head -1 || true)"
      echo ""
      if [ -n "$PAIR_URL" ]; then
        echo ">> One-click pair (valid 24h, single use):"
        echo ">>   $PAIR_URL"
      else
        echo "Paste the 12-char Token shown above into the T3 Code pairing screen."
      fi
      echo "(To re-issue later: t3 auth pairing create --ttl 1h --base-url \"$BASE_URL\")"
    else
      echo "Auto-issue failed; run manually:  t3 auth pairing create --ttl 1h --base-url \"$BASE_URL\""
    fi
    echo "========================================================="
  EOT
}

# Expose T3 Code as a Coder subdomain app — TLS, the wildcard host, and SSO are
# all provided by Coder, so nothing is bound to a public interface.
resource "coder_app" "t3code" {
  count        = local.enable_t3code ? 1 : 0
  agent_id     = coder_agent.main.id
  slug         = "t3code"
  display_name = "T3 Code"
  icon         = "https://github.com/pingdotgg.png"
  url          = "http://127.0.0.1:${local.t3code_port}"
  subdomain    = true
  share        = "owner"

  healthcheck {
    url       = "http://127.0.0.1:${local.t3code_port}/"
    interval  = 5
    threshold = 6
  }
}
