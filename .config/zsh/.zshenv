# ~/.config/zsh/.zshenv
#
# --------------- XDG base directories ----------------
# Centralizes config/cache/data locations
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# --------------- Editor -----------------
# Default editor user by git, crontab, etc
export EDITOR="nvim"
export VISUAL="nvim"

# --------------- GPG ----------------
export GPG_TTY=$(tty)

# --------------- PATH ---------------
# Personal scripts/binaries
export PATH="$HOME/.local/bin:$PATH"

# --------------- Pager --------------
if command -v bat >/dev/null 2>&1; then
  export MANPAGER="bat -l man -p"
elif command -v batcat >/dev/null 2>&1; then
  export MANPAGER="batcat -l man -p"
fi

export REPOS="$HOME/Repos"
export GITUSER="lmflemm"
export GHREPOS="$REPOS/github.com/$GITUSER"
export DOTFILES="$GHREPOS/mydotfiles"
export ZDOTDIR="$DOTFILES/.config/zsh"

# --------------- Starship --------------
export STARSHIP_CONFIG="$ZDOTDIR/starship.toml"

# Rust/Cargo environment
if [[ -f "$HOME/.cargo/env" ]]; then
  source "$HOME/.cargo/env"
fi

# >>> cargo environment >>>
# Load Rust/Cargo environment when available.
if [[ -f "$HOME/.cargo/env" ]]; then
  source "$HOME/.cargo/env"
fi
# <<< cargo environment <<<
