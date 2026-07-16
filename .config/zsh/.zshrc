
########## Environment Variables ##########

export VISUAL=nvim
export EDITOR=nvim

#export TERM="tmux-256color"
#export TERM="screen-my256color"

export BROWSER="firefox"

# Directories
export REPOS="$HOME/Repos"
export GITUSER="lmflemm"
export GHREPOS="$REPOS/github.com/$GITUSER"
export DOTFILES="$GHREPOS/mydotfiles"
export SCRIPTS="$DOTFILES/scripts"
export ZDOTDIR="$DOTFILES/.config/zsh"

# zettelkasten-cli env vars
export ZETTELKASTEN="$HOME/Zettelkasten"

# Optional: customize inbox directory
export ZETTELKASTEN_INBOX_DIR="0-Inbox"

# Optional: customize periodic notes directories
export ZETTELKASTEN_DAILY_DIR="$HOME/Zettelkasten/periodic-notes/daily-notes"
export ZETTELKASTEN_WEEKLY_DIR="$HOME/Zettelkasten/periodic-notes/weekly-notes"

# Optional: customize template locations
export ZETTELKASTEN_DAILY_TEMPLATE="templates/daily.md"
export ZETTELKASTEN_WEEKLY_TEMPLATE="templates/weekly.md"
export ZETTELKASTEN_NOTE_TEMPLATE="templates/note.md"

# Optional: use a different editor
export ZETTELKASTEN_EDITOR="nvim"  # or vim, code, etc.

# Optional: customize Neovim behavior (only applies when using nvim)
export ZETTELKASTEN_NVIM_ARGS="+ normal Gzzo"
export ZETTELKASTEN_NVIM_COMMANDS=":NoNeckPain,:set wrap"

########## Path Configurations ##########
#
setopt extended_glob null_glob

path=(
  $path                           # Keep existing PATH entries
  $HOME/bin
  $HOME/.local/bin
  $HOME/dotnet
  $SCRIPTS
  $HOME/.rd/bin                   # Rancher Desktop
  /home/vscode/.local/bin         # Dev Container Specifics
  /root/.local/bin                # Dev Container Specifics
  /Users/lee/.local/bin
  /Library/Frameworks/Python.framework/Versions/3.11/bin
)

# Remove duplicate entries and non-existent Directories
typeset -U path
path=($^path(N-/))

export PATH

# Generate Gruvbox-Material semantic highlighting for directory listings
export LS_COLORS="$(vivid generate gruvbox-dark)"

# Source automatic colorization hooks for command commands
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS / Homebrew Path
  if [ -f $(brew --prefix)/etc/grc.zsh ]; then
    source $(brew --prefix)/etc/grc.zsh
  fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Arch Linux / Pacman Path
  # Since Arch doesn't use a zsh hook file, we just check if the binary exists
  if [ -x /usr/bin/grc ]; then
    GRC_ALIASES=true
  fi
fi

zinbox() {
  ls -lrt "$ZETTELKASTEN/0-Inbox"
}

znotes() {
  ls -lrt "$ZETTELKASTEN/notes"
}

########## Dev Container Specifics ##########
#
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

########## History ##########
#
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000

setopt APPEND_HISTORY     # Append history between sessions.bbin/
setopt SHARE_HISTORY      # Share history between sessions.bbin/
setopt HIST_IGNORE_DUPS   # Don't save duplicate lines.
setopt HIST_IGNORE_SPACE  # Don't save when prefixed with a space.
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS

# ===========================
# Shell Behavior
# ===========================

setopt AUTOCD
setopt NOBEEP
setopt NUMERIC_GLOB_SORT # sort file10 after file9, not after file1

# ===========================
# Smart directory navigation
# ===========================

# Initialize zoxide
eval "$(zoxide init zsh)"

# ===========================
# Completion
# ===========================

# Load completion system
autoload -Uz compinit

# Initialize completion with cached metadata file
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

# Enable interactive completion menu selection
zstyle ':completion:*' menu select

# Make completion case-insensitive
# Example: "doc" can complete to "Documents"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# ===========================
# Fuzzy finder
# ===========================

# macOS / Homebrew (Apple Silicon)
if [[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]]; then
  source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
  source /opt/homebrew/opt/fzf/shell/completion.zsh
fi

# macOS / Homebrew (Intel)
if [[ -f /usr/local/opt/fzf/shell/key-bindings.zsh ]]; then
  source /usr/local/opt/fzf/shell/key-bindings.zsh
  source /usr/local/opt/fzf/shell/completion.zsh
  source ~/.cargo/env
fi

# Arch
if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh 
  source /usr/share/fzf/completion.zsh 
fi

# Ubuntu
if [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
  source /usr/share/doc/fzf/example/completion.zsh
fi

# ===========================
# Modular Config Files
# ===========================

# fzf configuration
source "$ZDOTDIR/fzf.zsh"

# Aliases
source "$ZDOTDIR/aliases.zsh"

# Custom keybindings
source "$ZDOTDIR/bindings.zsh"

# Plugins and plugin manager
source "$ZDOTDIR/plugins.zsh"

# Prompt/theme
source "$ZDOTDIR/prompt.zsh"

#Automatically start hyprland if logging into TTY1
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
  exec start-hyprland
fi


