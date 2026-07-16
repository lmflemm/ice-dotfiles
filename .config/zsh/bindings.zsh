# ===================================================================
# Keybindings
# ===================================================================

# Cursor shape per vi mode
ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK

# Disable command mode line highlight
ZVM_VI_HIGHLIGHT_BACKGROUND=name
ZVM_VI_HIGHLIGHT_FOREGROUND=name
ZVM_VI_HIGHLIGHT_EXTRASTYLE=name

# zsh-vi-mode resets all bindings on init, so custom bindings
# must be registered via this hook to survive.
zvm_after_init() {
  # Ctrl+Right -> move forward one word (^[[1;5C is the terminal escape code)
  bindkey '^[[1;5C' forward-word

  # Ctrl+Left -> move backward one word (^[[1;5D is the terminal escape code)
  bindkey '^[[1;5D' backward-word

  # Ctrl+F -> fzf file picker (no hidden files) 
  bindkey '^F' _fzf_file_no_hidden

  # Ctrl+\ -> toggle autosuggestions (useful for screen recordings) 
  bindkey '^\' autosuggest-toggle

  # Up/Down -> history search bu substring (^[[A/^[[B are up/down arrow escape codes) 
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down

  # Ctrl+P / Ctrl}N -> history search inside zsh-vi-mode
  bindkey -M viins '^P' history-substring-search-up
  bindkey -M viins '^N' history-substring-search-down
  bindkey -M vicmd '^P' history-substring-search-up
  bindkey -M vicmd '^N' history-substring-search-down

}

