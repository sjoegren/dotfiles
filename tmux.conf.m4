dnl Macros to insert nested quote characters in strings.
define(`LQ',`changequote(<,>)`dnl'
changequote`'')
define(`RQ',`changequote(<,>)dnl`
'changequote`'')
changecom()dnl
syscmd(`tmux -V | check_version -q -r "tmux ([0-9]+\.[0-9]+)" -c 3.1')dnl
define(`HAVE_NOTE', ifelse(sysval, `0', `yes', `no'))dnl
# Generated by from __file__ at syscmd(`LC_TIME=C date')

# General settings
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",xterm-256color:Tc"
set -g focus-events on
set -g history-limit 20000
set -g base-index 1
set -g pane-base-index 1
set -g display-time 2000
set -g status-keys emacs
set-environment -g CHERE_INVOKING 1
set -s command-alias[0] alarm="command-prompt -p \"alarm time:\" \"run -b RQ()tmux_alarm.sh --set %%RQ()\""
set -s command-alias[1] alarmclear="confirm -p \"clear current alarm?\" \"run RQ()tmux_alarm.sh --kill RQ()\""



# Bindings
unbind C-b
set -g prefix C-a
bind a send-prefix
bind r source-file ~/.tmux.conf \; display-message "configuration reloaded"
bind w choose-tree -Z
bind ? list-keys

# Act like vim
set-window-option -g mode-keys vi
unbind %
bind v split-window -h -c "#{pane_current_path}"
bind s split-window -v -c "#{pane_current_path}"
# key bindings for vi-like copy/paste
bind Escape copy-mode
syscmd(`tmux -V | check_version -q -r "tmux ([0-9]+\.[0-9]+)" -c 2.4')dnl
ifelse(sysval, `0', `dnl
bind -T copy-mode-vi v send -X begin-selection
ifdef(`HAVE_xclip', `
bind -T copy-mode-vi y "send -X copy-pipe RQ()xclip -i`'RQ()"
', `
bind -T copy-mode-vi y "send -X copy-selection"
')
bind -T copy-mode-vi C-h select-pane -L
bind -T copy-mode-vi C-j select-pane -D
bind -T copy-mode-vi C-k select-pane -U
bind -T copy-mode-vi C-l select-pane -R
')dnl

# Display pane numbers longer
set -g display-panes-time 2000

# Use xclip to load X clipboard into tmux paste buffer
ifdef(`HAVE_xclip', `
bind ifelse(HAVE_NOTE, `yes', `-N "paste from X clipboard"') \
	C-p run-shell "xclip -o | tmux load-buffer - ; tmux paste-buffer"
', `
bind C-p display-message "xclip is not installed"
')

# Avoid "escape + <key>" behaviour, e.g. in vim, escape to normal mode and move
set escape-time 0
bind -n M-h select-pane -L
bind -n M-j select-pane -D
bind -n M-k select-pane -U
bind -n M-l select-pane -R

bind S set-window-option synchronize-panes
bind A set-window-option monitor-activity
bind 0 select-window -t :10

# open man, git-help or pydoc pages in full horizontal split
bind m command-prompt -p "man page: " "split-window -f -h RQ()exec man %%RQ()"
bind g command-prompt -p "git help: " "split-window -f -h RQ()exec git help %%RQ()"
bind p command-prompt -p "pydoc page: " "split-window -f -h RQ()exec pydoc3 %%RQ()"

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

syscmd(`tmux -V | check_version -q -r "tmux ([0-9]+\.[0-9]+)" -c 3.0')dnl
ifelse(sysval, `0', `source-file DOTFILES_DIR/tmux/tmux-3.0.conf')
bind \' switch-client -t "{marked}"

#showenv -g _TMUX_LAST_PANE" \

bind -n f1 selectw -T -t :1
bind -n f2 selectw -T -t :2
bind -n f3 selectw -T -t :3
bind -n f4 selectw -T -t :4
bind -n f5 selectw -T -t :5
bind -n f6 selectw -T -t :6
bind -n f7 selectw -T -t :7
bind -n f8 selectw -T -t :8
bind -n f9 selectw -T -t :9
bind -n f10 selectw -T -t :10
bind -n f11 previous-window
bind -n f12 next-window
bind -n C-Space last-window

# Switch sessions and redraw status bar
bind -n S-f1 switch-client -t $1\; refresh -S
bind -n S-f2 switch-client -t $2\; refresh -S
bind -n S-f3 switch-client -t $3\; refresh -S
bind -n S-f4 switch-client -t $4\; refresh -S
bind -n S-f5 switch-client -t $5\; refresh -S
bind -n S-f6 switch-client -t $6\; refresh -S
bind -n S-f7 switch-client -t $7\; refresh -S
bind -n S-f8 switch-client -t $8\; refresh -S
bind -n S-f9 switch-client -t $9\; refresh -S
# last, previous, next sessions
bind -n S-f10 switch-client -l\; refresh -S
bind -n S-f11 switch-client -p\; refresh -S
bind -n S-f12 switch-client -n\; refresh -S

# Swap current pane with target pane
bind y command-prompt -p "swap-pane (target):"  "swap-pane -t RQ()%%RQ()"

# window title string (uses statusbar variables)
set -g set-titles-string "#T"

setw -g automatic-rename on
syscmd(`tmux -V | check_version -q -r "tmux ([0-9]+\.[0-9]+)" -c 2.9')dnl
define(`FANCY_FORMAT', ifelse(sysval, `0', `yes', `no'))
# `FANCY_FORMAT': FANCY_FORMAT
ifelse(FANCY_FORMAT, `yes', `
ifdef(`HAVE_pidcmd', ` dnl format with pidcmd
source-file DOTFILES_DIR/tmux/tmux-2.9.conf
', ` dnl format without pidcmd
setw -g automatic-rename-format RQ()#{?#{m:*|ssh|*,#{P:|#{pane_current_command}|}},\
#[fg=blue],#{?#{m/r:vi(mx?)?,#{pane_current_command}},#[fg=green],}\
#{?#{==:#{pane_current_path},/home/aksel},~,#{b:pane_current_path}}}RQ()
')dnl end of ifelse HAVE_pidcmd
', `dnl  FANCY_FORMAT=no
setw -g automatic-rename-format RQ()#{b:pane_current_path}RQ()
')dnl end of ifelse FANCY_FORMAT
bind * setw automatic-rename on

set -g status-left "#S "
set -g status-left-length 80
set -g status-right "%H:%M, %a %h %e "

ifelse(FANCY_FORMAT, `yes', `
source-file DOTFILES_DIR/.tmux-themepack/powerline/double/orange.tmuxtheme

# List tmux sessions
set -g status-left-length 60
set -g status-left "#[bg=colour240] #{S:#{?session_attached,#[fg=colour007#,bold],#[fg=black#,nobold]}#{s/[^0-9]//:session_id}:#{=4:session_name} } #[fg=colour240,bg=colour233]"
', `dnl
source-file DOTFILES_DIR/.old.tmuxtheme
')dnl
