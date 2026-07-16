
########## Prompt ##########
#
#PURE_GIT_PULL=0

#if [[ "$OSTYPE" == darwin* ]]; then
#  fpath+=("$(brew --prefix)/share/zsh/site-functions")
#else
#  # Only add the home folderfallback if it actually exists
#  [[ -d "$HOME/.zsh/pure" ]] && fpath+=($HOME/.zsh/pure)
#fi

#fpath+=( /usr/local/share/zsh/site-functions )

# Load the prompt system safely
#autoload -U promptinit && promptinit

# Guard clause: Verify 'pure' is available before initializing it
#if prompt -l | grep -q "pure"; then
#  prompt pure
#else
#  # Graceful fallback so the shell terminal doesn't throw usage syntax errors
#  print "Warning: 'pure' prompt theme not found in fpath."
#fi
export STARSHIP_CONFIG="$ZDOTDIR/starship.toml"

eval "$(starship init zsh)"

