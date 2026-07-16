# ==============================================================================
# Modern CLI replacements
# ==============================================================================

# Better ls
alias ls='eza --icons'
#alias ls='gls --color=auto'

# Detailed listing
alias ll='eza -lh --icons --git'
#alias ll='gls -lathr --color=auto'

# Detailed listing including hidden files
alias la='eza -lah --icons --git'
#alias la='eza -laghm@ --all --icons --git --color=always'

# Tree view
alias tree='eza --tree --icons'

# Reuse ls completions for eza (avoids defining a separate completion function)
compdef eza=ls

# Better cat (bat on Arch, batcat on Ubuntu)
if command -v bat >/dev/null 2>&1; then
  alias cat='bat'
elif command -v batcat >/dev/null 2>&1; then
  alias bat='batcat'
  alias cat-'batcat'
fi

# fd (fdfind on Ubuntu)
if command -v fdfind >/dev/null 2>&1; then
  alias fd='fdfind'
fi

# finds all files recursively and sorts by last modification, ignore hidden files.
alias lastmod='find . -type f -not -path "*/\.*" -exec ls -lrt {} +'

# ==============================================================================
# Core utilities
# ==============================================================================

# Force the engine to blend into my Gruvbox profile paletttes
# (Placed outside the block so the aliases apply to both OS environments)
if [ -n "$GRC_ALIASES" ] || [ -f /etc/grc.zsh ] || { command -v brew &>/dev/null && [ -f $(brew --prefix)/etc/grc.zsh ]; }; then
  alias df="grc df -h"
  alias du="grc du -sh"
  alias ping="grc ping"
  alias ps="grc ps aux"
fi

alias grep='rg --color=auto'
alias diff='diff --color=auto'
alias top="btop"
alias t='tmux'
alias e='exit'
alias c="clear"

# Cross-Platform Clipboard Support
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS Native Command
  alias clip='pbcopy'
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Arch Linux Options
  if command -v wl-copy &> /dev/null; then
    alias pbcopy='wl-copy'
    alias pbpaste='wl-paste'
  elif command -v xclip &> /dev/null; then
    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'
  fi

  # Keep the universal 'clip' shorthand working
  alias clip='pbcopy'
fi

# ==============================================================================
# Navigation
# ==============================================================================

alias -- -='cd -' # -- prevents - being parsed as a flag; cd - jumps to previous directory

# ==============================================================================
# Editor
# ==============================================================================

alias v='nvim'
alias vi='nvim'
alias vim='nvim'

# ==============================================================================
# Git
# ==============================================================================

alias glog='PAGER="less -F -X" git log'
alias gadog='PAGER="less -F -X" git log --all ---decorate --oneline --graph'
alias gp='git pull'
alias gs='git status'
alias lg='lazygit'

# ==============================================================================
# Miscellaneous
# ==============================================================================

alias ide='$SCRIPTS/start_workspace.sh'
alias scripts='cd $SCRIPTS'

zinbox() {
  ls -lrt "$ZETTELKASTEN/0-Inbox"
}

znotes() {
  ls -lrt "$ZETTELKASTEN/notes"
}

# ==============================================================================
# Repos
# ==============================================================================

alias dot='cd $GHREPOS/dotfiles'
alias repos='cd $REPOS'
alias ghrepos='cd $GHREPOS'
alias gr='ghrepos'

# ==============================================================================
# Zettelkasten
# ==============================================================================

alias in="cd \$ZETTELKASTEN/0\ Inbox/"
alias cdzk="cd \$ZETTELKASTEN"

# ==============================================================================
# Kubernetes
# ==============================================================================

alias k='kubectl'
alias kgp='kubectl get pods'
alias kc='kubectx'
alias kn='kubens'

# ==============================================================================
# Fabric
# ==============================================================================

alias fabric='fabric-ai'

# >>> fabric alias >>>
# Homebrew installs the Fabric AI CLI as fabric-ai. Keep fabric as the muscle-memory command.
if command -v fabric-ai >/dev/null 2>&1; then
  alias fabric="fabric-ai"
fi
# <<< fabric alias <<<
