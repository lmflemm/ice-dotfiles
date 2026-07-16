#!/bin/bash

# Start a new detached tmux session named 'dev' and name the first window 'Editor'
tmux new-session -d -s dev -n 'Editor'

# Send a command to the first window (e.g., launch LazyVim)
tmux send-keys -t dev:'Editor' 'nvim' C-m

# Create a second window named 'Terminal'
tmux new-window -t dev -n 'Terminal'

# Split the pane vertically (top/bottom)
tmux split-window -v -p 50 -t dev:'Terminal'

# Send specific commands to the newly created panes
# Pane 0 is top, Pane 2 is bottom
tmux send-keys -t dev:'Terminal'.1 'lazygit --path $HOME/Repos/github.com/lmflemm/zettelkasten/' C-m # Runs lazygit
tmux send-keys -t dev:'Terminal'.0 'pwd' C-m

# Create a second window named 'Terminal'
tmux new-window -t dev -n 'System'
tmux send-keys -t dev:'System'.0 'top' C-m # Runs your new btop alias

# Select the first window ('Editor') as the default view and attach
tmux select-window -t dev:'Terminal'
tmux attach-session -t dev
