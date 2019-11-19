# General settings
set -g default-terminal "screen-256color"
set -g history-limit 20000                          # scrollback buffer n lines
set -g base-index 1                                 # start indexing windows at 1 (instead of 0)
set -g pane-base-index 1
set -g display-time 2000
set-environment -g CHERE_INVOKING 1

# Bindings
unbind C-b
set -g prefix C-a
bind a send-prefix
bind r source-file ~/.tmux.conf \; display-message "configuration reloaded"

# Act like vim
set-window-option -g mode-keys vi
unbind %
bind v split-window -h -c '#{pane_current_path}'
bind s split-window -v -c '#{pane_current_path}'
bind h select-pane -L
bind l select-pane -R
bind j select-pane -D
bind k select-pane -U
# key bindings for vi-like copy/paste
bind Escape copy-mode
changequote(`[', `]')dnl
ifdef([DF_TMUX_VERSION_24], [dnl
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi y if-shell "hash xclip" "send -X copy-pipe 'xclip -i'" "send -X copy-selection"
], [])dnl

# Display pane numbers longer
set -g display-panes-time 2000

# Use xclip to load X clipboard into tmux paste buffer
bind C-p run-shell "xclip -o | tmux load-buffer - ; tmux paste-buffer"

# Avoid "escape + <key>" behaviour, e.g. in vim, escape to normal mode and move
set escape-time 0
bind -n M-h select-pane -L
bind -n M-j select-pane -D
bind -n M-k select-pane -U
bind -n M-l select-pane -R
ifdef([DF_TMUX_VERSION_24], [dnl
bind -T copy-mode-vi C-h select-pane -L
bind -T copy-mode-vi C-j select-pane -D
bind -T copy-mode-vi C-k select-pane -U
bind -T copy-mode-vi C-l select-pane -R
bind -T copy-mode-vi C-\ select-pane -l
], [])dnl

bind S set-window-option synchronize-panes
bind A set-window-option monitor-activity
bind 0 select-window -t :10

# open man, git-help or pydoc pages in full horizontal split
bind m command-prompt -p "man page: " "split-window -f -h 'exec man %%'"
bind g command-prompt -p "git help: " "split-window -f -h 'exec git help %%'"
bind p command-prompt -p "pydoc page: " "split-window -f -h 'exec pydoc2 %%'"

# Open new windows in current directory
bind c new-window -c "#{pane_current_path}"

# easy resizing of panes
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r H resize-pane -L 5
bind -r L resize-pane -R 5

# Enter copy mode on Shift+PageUp to better emulate normal terminal scrolling.
# Allow Shift+PageDown to be used to scroll down for convenience.
bind -n S-PageUp copy-mode -u
bind -n S-PageDown send-keys PageDown

# Break out pane to window
# default: ! = break-pane
bind o command-prompt -p "create pane (horisontal) from:"  "join-pane -s ':%%'"
bind @ command-prompt -p "create pane (vertical) from:"  "join-pane -h -s ':%%'"

# Toggle fullscreen pane (zoomed)
bind -n f3 resize-pane -Z

# Cycle through windows and panes
bind -n f6 previous-window
bind -n f7 last-window
bind -n f8 next-window

# Switch sessions and redraw status bar
bind ( switch-client -p\; refresh -S
bind ) switch-client -n\; refresh -S

# Swap current pane with target pane
bind y command-prompt -p "swap-pane (target):"  "swap-pane -t '%%'"

# window title string (uses statusbar variables)
set -g set-titles-string '#T'

# status bar

# List sessions in status bar
set -g status-left "#S [#(tmux ls | cut -d: -f1 | xargs echo)] "
set -g status-left-length 80
set -g status-right '%H:%M, %a %h %e '

ifdef([DF_TMUX_VERSION_29], [dnl
source-file $HOME/.dotfiles/.tmux-themepack/powerline/block/gray.tmuxtheme
], [dnl
source-file $HOME/.dotfiles/.old.tmuxtheme
])dnl