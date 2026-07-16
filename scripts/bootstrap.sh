#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# ICE Release Engineering Bootstrap
# Target tooling from JD: Jenkins, Bitbucket, GitHub, JFrog Artifactory,
# Ansible, Chef, Terraform.
#
# Defaults are intentionally conservative for a company laptop:
# - Installs local CLI tooling only.
# - Does not configure credentials, tokens, SSH keys, or company URLs.
# - Chef Workstation is optional because it can be large and policy/licensing-gated.
#
# Optional flags:
#   INSTALL_CHEF_WORKSTATION=1 ./bootstrap-ice-release-eng.sh
#   INSTALL_GIT_CREDENTIAL_MANAGER=0 ./bootstrap-ice-release-eng.sh
# -----------------------------------------------------------------------------

info() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
success() { echo -e "\033[1;32m[SUCCESS]\033[0m $1"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $1" >&2; }

has() {
  command -v "$1" >/dev/null 2>&1
}

append_once() {
  local line="$1"
  local file="$2"

  mkdir -p "$(dirname "$file")"
  touch "$file"

  if ! grep -Fqx "$line" "$file"; then
    echo "$line" >>"$file"
  fi
}

install_dir() {
  mkdir -p "$HOME/.local/bin" "$HOME/.local/share/jenkins-cli"
}

HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
JFROG_CLI_INSTALL_URL="https://install-cli.jfrog.io"
MISE_INSTALL_URL="https://mise.run"
GH_CLI_KEYRING_URL="https://cli.github.com/packages/githubcli-archive-keyring.gpg"
GH_CLI_APT_REPO="https://cli.github.com/packages"

INSTALL_CHEF_WORKSTATION="${INSTALL_CHEF_WORKSTATION:-0}"
INSTALL_GIT_CREDENTIAL_MANAGER="${INSTALL_GIT_CREDENTIAL_MANAGER:-1}"

OS_TYPE="$(uname -s)"
ARCH_TYPE="$(uname -m)"

SUDO=()
if [[ "${EUID}" -ne 0 ]]; then
  SUDO=(sudo)
fi

setup_homebrew_path() {
  # Make brew available immediately after installation in this running script.
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  elif [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
}

install_macos_packages() {
  if ! has brew; then
    info "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "$HOMEBREW_INSTALL_URL")"
  fi

  setup_homebrew_path

  if ! has brew; then
    error "Homebrew was installed, but brew is still not available on PATH."
    exit 1
  fi

  info "Installing macOS base and release engineering utilities via Homebrew..."
  brew install \
    btop \
    curl \
    git \
    gh \
    jq \
    jfrog-cli \
    openjdk@17 \
    pipx \
    ripgrep \
    shellcheck \
    tmux \
    yq

  if [[ "$INSTALL_GIT_CREDENTIAL_MANAGER" = "1" ]]; then
    brew install git-credential-manager || warn "git-credential-manager install failed or is unavailable."
  fi

  # Homebrew's openjdk@17 can be keg-only. Add it to this shell and future shells.
  if brew --prefix openjdk@17 >/dev/null 2>&1; then
    local java17_bin
    java17_bin="$(brew --prefix openjdk@17)/bin"
    export PATH="$java17_bin:$PATH"

    case "$(basename "${SHELL:-}")" in
    zsh)
      append_once "export PATH=\"$java17_bin:\$PATH\"" "${ZDOTDIR:-$HOME}/.zshrc"
      ;;
    bash)
      append_once "export PATH=\"$java17_bin:\$PATH\"" "$HOME/.bashrc"
      ;;
    esac
  fi

  if [[ "$INSTALL_CHEF_WORKSTATION" = "1" ]]; then
    info "Installing Chef Workstation via Homebrew cask..."
    brew install --cask chef-workstation || warn "Chef Workstation install failed. Check company policy/licensing before retrying."
  else
    warn "Skipping Chef Workstation. Re-run with INSTALL_CHEF_WORKSTATION=1 after confirming company policy."
  fi
}

install_github_cli_linux() {
  if has gh; then
    return 0
  fi

  info "Installing GitHub CLI for Debian/Ubuntu..."
  "${SUDO[@]}" mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL "$GH_CLI_KEYRING_URL" | "${SUDO[@]}" tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  "${SUDO[@]}" chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] $GH_CLI_APT_REPO stable main" |
    "${SUDO[@]}" tee /etc/apt/sources.list.d/github-cli.list >/dev/null

  "${SUDO[@]}" apt-get update
  "${SUDO[@]}" apt-get install -y gh
}

install_linux_packages() {
  if ! has apt-get; then
    error "This script currently supports Debian/Ubuntu-style Linux systems with apt-get."
    exit 1
  fi

  info "Installing Linux base and release engineering utilities..."
  "${SUDO[@]}" apt-get update

  "${SUDO[@]}" apt-get install -y \
    apt-transport-https \
    build-essential \
    ca-certificates \
    curl \
    git \
    gnupg \
    jq \
    lsb-release \
    openjdk-17-jre-headless \
    pipx \
    pkg-config \
    python3-pip \
    ripgrep \
    shellcheck \
    tmux \
    unzip \
    xz-utils

  if apt-cache show btop >/dev/null 2>&1; then
    "${SUDO[@]}" apt-get install -y btop
  else
    warn "btop is not available from this apt repository. Skipping btop."
  fi

  install_github_cli_linux

  # Install JFrog CLI V2 as `jf` if it is not already present.
  if ! has jf; then
    info "Installing JFrog CLI..."
    curl -fsSL "$JFROG_CLI_INSTALL_URL" | sh
  fi

  if [[ "$INSTALL_GIT_CREDENTIAL_MANAGER" = "1" ]]; then
    warn "Git Credential Manager was not installed automatically on Linux. Install the company-approved package if HTTPS auth is required."
  fi

  if [[ "$INSTALL_CHEF_WORKSTATION" = "1" ]]; then
    warn "Chef Workstation Linux install is policy/licensing dependent. Prefer employer-provided instructions or internal software center."
  else
    warn "Skipping Chef Workstation. Re-run with INSTALL_CHEF_WORKSTATION=1 only after confirming company policy."
  fi
}

install_mise() {
  if ! has mise; then
    info "Installing mise..."
    curl -fsSL "$MISE_INSTALL_URL" | sh
  fi

  # mise's default binary location and shims.
  export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

  if ! has mise; then
    error "mise installation completed, but mise is still not available on PATH."
    exit 1
  fi
}

configure_mise_shell_activation() {
  local user_shell
  user_shell="$(basename "${SHELL:-}")"

  case "$user_shell" in
  zsh)
    append_once 'eval "$(mise activate zsh)"' "${ZDOTDIR:-$HOME}/.zshrc"
    ;;
  bash)
    append_once 'eval "$(mise activate bash)"' "$HOME/.bashrc"
    ;;
  *)
    warn "Shell '$user_shell' not automatically configured. Add the appropriate 'mise activate' line manually."
    ;;
  esac

  # Activate mise for this bootstrap script's current Bash process.
  eval "$(mise activate bash)"
}

install_mise_tools() {
  info "Provisioning language runtimes and IaC tooling via mise..."

  mise use --global python@3.11
  mise use --global node@20
  mise use --global terraform@1.8.0
  mise use --global terraform-docs@latest
  mise use --global helm@3.21.0
  mise use --global tfenv@latest

  # Extra IaC hygiene tools useful in release engineering workflows.
  # These may fail if a backend/plugin is unavailable; keep them non-fatal.
  mise use --global tflint@latest || warn "Could not install tflint via mise."

  mise reshim || true
}

install_ansible_tools() {
  info "Installing Ansible tooling via pipx..."

  export PATH="$HOME/.local/bin:$PATH"
  pipx ensurepath >/dev/null 2>&1 || true

  if ! has ansible; then
    pipx install --include-deps ansible
  else
    info "Ansible already installed."
  fi

  if ! has ansible-lint; then
    pipx install ansible-lint || warn "ansible-lint install failed. You can install it later with: pipx install ansible-lint"
  fi
}

configure_git_credential_manager() {
  if [[ "$INSTALL_GIT_CREDENTIAL_MANAGER" != "1" ]]; then
    return 0
  fi

  if has git-credential-manager; then
    info "Configuring Git Credential Manager..."
    git-credential-manager configure || warn "Git Credential Manager configure failed."
  elif has git-credential-manager-core; then
    info "Configuring Git Credential Manager Core..."
    git-credential-manager-core configure || warn "Git Credential Manager Core configure failed."
  else
    warn "Git Credential Manager not found. For Bitbucket/GitHub HTTPS auth, use company-approved install instructions or SSH keys."
  fi
}

install_jenkins_cli_wrapper() {
  info "Installing Jenkins CLI wrapper..."
  install_dir

  cat >"$HOME/.local/bin/jcli" <<'JCLI'
#!/usr/bin/env bash
set -euo pipefail

JENKINS_CLI_DIR="${JENKINS_CLI_DIR:-$HOME/.local/share/jenkins-cli}"
JENKINS_CLI_JAR="$JENKINS_CLI_DIR/jenkins-cli.jar"

usage() {
  cat >&2 <<'USAGE'
Usage:
  export JENKINS_URL="https://jenkins.example.com"
  jcli help
  jcli who-am-i
  jcli build <job-name> [-p KEY=VALUE]

Optional:
  export JENKINS_USER_ID="your-user"
  export JENKINS_API_TOKEN="your-api-token"

Notes:
  - This wrapper downloads jenkins-cli.jar from $JENKINS_URL/jnlpJars/jenkins-cli.jar.
  - Do not hardcode company URLs or credentials in this file.
USAGE
}

if [[ -z "${JENKINS_URL:-}" ]]; then
  echo "Error: JENKINS_URL is not set." >&2
  usage
  exit 1
fi

mkdir -p "$JENKINS_CLI_DIR"

if [[ ! -s "$JENKINS_CLI_JAR" || "${1:-}" == "--refresh" ]]; then
  curl -fsSL "${JENKINS_URL%/}/jnlpJars/jenkins-cli.jar" -o "$JENKINS_CLI_JAR"
  if [[ "${1:-}" == "--refresh" ]]; then
    shift
  fi
fi

AUTH_ARGS=()
if [[ -n "${JENKINS_USER_ID:-}" && -n "${JENKINS_API_TOKEN:-}" ]]; then
  AUTH_ARGS=(-auth "${JENKINS_USER_ID}:${JENKINS_API_TOKEN}")
fi

exec java -jar "$JENKINS_CLI_JAR" -s "${JENKINS_URL%/}" "${AUTH_ARGS[@]}" "$@"
JCLI

  chmod +x "$HOME/.local/bin/jcli"
}

install_shell_helpers() {
  info "Installing local release engineering helper functions..."
  install_dir

  cat >"$HOME/.local/bin/release-tool-check" <<'CHECK'
#!/usr/bin/env bash
set -euo pipefail

tools=(
  git
  gh
  jf
  jq
  rg
  tmux
  terraform
  terraform-docs
  helm
  ansible
  ansible-playbook
  ansible-lint
  java
  jcli
)

missing=0
for tool in "${tools[@]}"; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf 'OK   %s -> %s\n' "$tool" "$(command -v "$tool")"
  else
    printf 'MISS %s\n' "$tool"
    missing=1
  fi
done

exit "$missing"
CHECK

  chmod +x "$HOME/.local/bin/release-tool-check"
}

verify_installation() {
  info "Verifying installed tools..."

  local required=(curl git jq rg tmux mise terraform helm terraform-docs gh java ansible ansible-playbook)
  local tool
  local missing=0

  for tool in "${required[@]}"; do
    if ! has "$tool"; then
      warn "$tool is missing or not currently on PATH."
      missing=1
    fi
  done

  if has jf; then
    jf --version || true
  elif has jfrog; then
    jfrog --version || true
  else
    warn "JFrog CLI was not found as 'jf' or 'jfrog'."
    missing=1
  fi

  if [[ "$INSTALL_CHEF_WORKSTATION" = "1" ]]; then
    if has chef; then
      chef --version || true
    else
      warn "Chef Workstation was requested but 'chef' was not found on PATH."
      missing=1
    fi
  fi

  mise doctor || true

  if [[ "$missing" -ne 0 ]]; then
    warn "Bootstrap finished with one or more missing optional/required tools. Run release-tool-check after reloading your shell."
  fi
}

info "Detecting Operating System..."
case "$OS_TYPE" in
Darwin)
  install_macos_packages
  ;;
Linux)
  install_linux_packages
  ;;
*)
  error "Unsupported OS: $OS_TYPE"
  exit 1
  ;;
esac

install_dir
install_mise
configure_mise_shell_activation
install_mise_tools
install_ansible_tools
configure_git_credential_manager
install_jenkins_cli_wrapper
install_shell_helpers
verify_installation

success "Bootstrap complete. Restart your shell, then run: mise doctor && release-tool-check"
