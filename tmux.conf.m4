# vim: ft=tmux
changecom()dnl
changequote(`@@', `@@')dnl
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
syscmd(@@tmux -V | check_version -q -r 'tmux ([0-9]+\.[0-9]+)' -c 2.4@@)dnl
ifelse(sysval, @@0@@, @@dnl
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi y if-shell "hash xclip" "send -X copy-pipe 'xclip -i'" "send -X copy-selection"
@@)dnl

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
ifelse(sysval, @@0@@, @@dnl
bind -T copy-mode-vi C-h select-pane -L
bind -T copy-mode-vi C-j select-pane -D
bind -T copy-mode-vi C-k select-pane -U
bind -T copy-mode-vi C-l select-pane -R
bind -T copy-mode-vi C-\ select-pane -l
@@)dnl

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

bind -n f1 selectw -T -t :1
bind -n f2 selectw -T -t :2
bind -n f3 selectw -T -t :3
bind -n f4 selectw -T -t :4
bind -n f5 selectw -T -t :5
bind -n f6 selectw -T -t :6
bind -n f7 selectw -T -t :7
bind -n f8 selectw -T -t :8
bind -n f9 selectw -T -t :9
bind -n f10 previous-window
bind -n f11 last-window
bind -n f12 next-window

# Switch sessions and redraw status bar
bind ( switch-client -p\; refresh -S
bind ) switch-client -n\; refresh -S

# Swap current pane with target pane
bind y command-prompt -p "swap-pane (target):"  "swap-pane -t '%%'"

# window title string (uses statusbar variables)
set -g set-titles-string '#T'

setw -g automatic-rename on
syscmd(@@pidcmd -V &> /dev/null@@)
ifelse(sysval, @@0@@, @@dnl   # format with pidcmd available.
# if #{pane_current_command} == ssh in any pane in a window;
# - set window name to the ssh target (last ssh cmdline argument)
# - blue fg color
# if vim runs in the active pane;
# - green fg color of the window name
# if #{pane_current_path} is $HOME;
# - set window name to '~'
# else;
# - set window name to basename of #{pane_current_path}
setw -g automatic-rename-format '#{?#{m:*|ssh|*,#{P:|#{pane_current_command}|}},#[fg=blue]#(pidcmd --arg -1 --tmux-cmd ssh "#{P:#{pane_current_command}:#{pane_pid}|}"),#{?#{==:#{pane_current_command},vim},#[fg=green],}#{?#{==:#{pane_current_path},/home/aksel},~,#{b:pane_current_path}}}'
# debug with: tmux display-message -p -v 'FORMAT'
@@, @@dnl  # format without pidcmd
setw -g automatic-rename-format '#{?#{m:*|ssh|*,#{P:|#{pane_current_command}|}},#[fg=blue],#{?#{==:#{pane_current_command},vim},#[fg=green],}#{?#{==:#{pane_current_path},/home/aksel},~,#{b:pane_current_path}}}'
@@)
bind * setw automatic-rename on

# status bar

# List sessions in status bar
set -g status-left "#S [#(tmux ls | cut -d: -f1 | xargs echo)] "
set -g status-left-length 80
set -g status-right '%H:%M, %a %h %e '

syscmd(@@tmux -V | check_version -q -r 'tmux ([0-9]+\.[0-9]+)' -c 2.9@@)dnl
ifelse(sysval, @@0@@, @@dnl
source-file DOTFILES_DIR/.tmux-themepack/powerline/double/orange.tmuxtheme
@@, @@dnl
source-file DOTFILES_DIR/.old.tmuxtheme
@@)dnl
