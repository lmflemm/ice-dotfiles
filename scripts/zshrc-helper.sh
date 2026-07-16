# ---------------------------------------------------------------------
# RELEASE ENGINEERING & JFROG COMPLIANCE ENGINE CONFIGURATION
# ---------------------------------------------------------------------

# 1. Environment Initializations
# Works in both ~/.zshrc and ~/.bashrc.
_mise_activate() {
  local mise_bin=""

  if command -v mise >/dev/null 2>&1; then
    mise_bin="$(command -v mise)"
  elif [ -x "$HOME/.local/bin/mise" ]; then
    mise_bin="$HOME/.local/bin/mise"
    export PATH="$HOME/.local/bin:$PATH"
  else
    return 0
  fi

  if [ -n "${ZSH_VERSION:-}" ]; then
    eval "$("$mise_bin" activate zsh)"
  elif [ -n "${BASH_VERSION:-}" ]; then
    eval "$("$mise_bin" activate bash)"
  fi
}

_mise_activate
unset -f _mise_activate

# 2. JFrog CLI Compatibility Wrapper
# Prefer modern `jf`, but fall back to `jfrog` if that is what is installed.
_jf_cli() {
  if command -v jf >/dev/null 2>&1; then
    command jf "$@"
  elif command -v jfrog >/dev/null 2>&1; then
    command jfrog "$@"
  else
    echo "Error: JFrog CLI not found. Install jfrog-cli first." >&2
    return 127
  fi
}

# 3. JFrog Artifactory Productivity Shortcuts
jf-auth() {
  # Interactively add or rotate Artifactory credentials.
  _jf_cli config add "$@"
}

jf-login() {
  # Browser-based local login where supported by the target JFrog platform.
  _jf_cli login "$@"
}

jf-use() {
  # Set default configured JFrog server.
  _jf_cli config use "$@"
}

jf-show() {
  # Show configured JFrog servers.
  _jf_cli config show "$@"
}

jf-ping() {
  # Instantly check Artifactory availability.
  _jf_cli rt ping "$@"
}

jf-search() {
  # Usage:
  #   jf-search "libs-release-local/*.jar"
  #   jf-search "my-repo/" --include="name;size;modified"
  _jf_cli rt search "$@" --format=json | jq .
}

# 4. Structural Artifactory Query Language, AQL Fast Search
# Usage:
#   jf-query 'items.find({"repo":"libs-release-local"}).include("name","repo")'
#
# Also supports passing a file:
#   jf-query ./query.aql
jf-query() {
  local aql=""
  local response=""

  if [ -z "${1:-}" ]; then
    echo "Error: Pass raw AQL inside quotes or provide a path to an .aql file." >&2
    return 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required for jf-query output parsing." >&2
    return 127
  fi

  if [ -f "$1" ]; then
    aql="$(cat "$1")"
  else
    aql="$1"
  fi

  response="$(_jf_cli rt curl -s -XPOST "/api/search/aql" \
    -H "Content-Type: text/plain" \
    --data-binary "$aql")"

  printf '%s\n' "$response" | jq .

  # jf rt curl may return 0 even for HTTP/API errors, so fail if Artifactory returned an errors array.
  if printf '%s\n' "$response" | jq -e 'type == "object" and has("errors")' >/dev/null 2>&1; then
    return 1
  fi
}

# 5. Local Infrastructure & Pipeline Validation Shorthands
tf-fmt() {
  # Format Terraform recursively from the target directory.
  # Usage:
  #   tf-fmt
  #   tf-fmt ./infra
  local dir="${1:-.}"
  terraform -chdir="$dir" fmt -recursive
}

tf-check() {
  # Non-mutating Terraform check suitable before commit/PR.
  # Usage:
  #   tf-check
  #   tf-check ./infra
  local dir="${1:-.}"

  terraform -chdir="$dir" fmt -recursive -check
  terraform -chdir="$dir" init -backend=false
  terraform -chdir="$dir" validate
}

tf-validate() {
  # Mutating convenience workflow: format, init without backend, then validate.
  # Usage:
  #   tf-validate
  #   tf-validate ./infra
  local dir="${1:-.}"

  terraform -chdir="$dir" fmt -recursive
  terraform -chdir="$dir" init -backend=false
  terraform -chdir="$dir" validate
}

h-lint() {
  # Usage:
  #   h-lint
  #   h-lint ./charts/my-chart
  #   h-lint .
  local target="${1:-}"
  local chart=""
  local found=0
  local rc=0

  if [ -n "$target" ]; then
    helm lint "$target"
    return
  fi

  if [ -f "./Chart.yaml" ]; then
    helm lint .
    return
  fi

  if [ ! -d "./charts" ]; then
    echo "Error: No Chart.yaml or ./charts directory found." >&2
    return 1
  fi

  for chart in ./charts/*; do
    [ -d "$chart" ] || continue
    found=1
    helm lint "$chart" || rc=1
  done

  if [ "$found" -eq 0 ]; then
    echo "Error: ./charts exists but contains no chart directories." >&2
    return 1
  fi

  return "$rc"
}

my-top() {
  if command -v btop >/dev/null 2>&1; then
    btop
  else
    top
  fi
}

# 6. JFrog Package Manager Helpers
jf-npm-config() {
  # Interactive npm resolver/deployer configuration through Artifactory.
  _jf_cli npm-config "$@"
}

jf-npm-ci() {
  # Usage:
  #   jf-npm-ci my-build-name 123
  local build_name="${1:-local-npm-build}"
  local build_number="${2:-$(date +%Y%m%d%H%M%S)}"

  _jf_cli npm ci --build-name="$build_name" --build-number="$build_number"
}

jf-build-publish() {
  # Usage:
  #   jf-build-publish my-build-name 123
  local build_name="${1:-}"
  local build_number="${2:-}"

  if [ -z "$build_name" ] || [ -z "$build_number" ]; then
    echo "Usage: jf-build-publish <build-name> <build-number>" >&2
    return 1
  fi

  _jf_cli rt build-publish "$build_name" "$build_number" \
    --collect-env \
    --collect-git-info
}

# 7. Persistent Terminal Sessions Management
# Attaches to an existing tmux session or creates a structured release engineering workspace.
jfrog-workspace() {
  local session="${1:-release-eng}"
  local window="pipeline-dev"

  if tmux has-session -t "$session" 2>/dev/null; then
    if [ -n "${TMUX:-}" ]; then
      tmux switch-client -t "$session"
    else
      tmux attach-session -t "$session"
    fi
    return
  fi

  tmux new-session -d -s "$session" -n "$window"

  # Right pane: system monitor.
  tmux split-window -h -t "$session:$window"
  if command -v btop >/dev/null 2>&1; then
    tmux send-keys -t "$session:$window.1" "btop" C-m
  else
    tmux send-keys -t "$session:$window.1" "top" C-m
  fi

  # Bottom-left pane: secondary shell.
  tmux split-window -v -t "$session:$window.0"

  # Start in top-left pane.
  tmux select-pane -t "$session:$window.0"

  if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "$session"
  else
    tmux attach-session -t "$session"
  fi
}
