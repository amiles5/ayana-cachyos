source /usr/share/cachyos-fish-config/cachyos-config.fish

# Replace CachyOS's default eza-based ls/la/ll/lt/l. aliases (defined in the
# sourced file above) with plain coreutils ls. No tree-view equivalent in ls,
# so lt falls back to a recursive listing instead.
alias ls='ls -alF --color=always --group-directories-first'
alias la='ls -a --color=always --group-directories-first'
alias ll='ls -latr --color=always'
alias lt='ls -R -a --color=always --group-directories-first'
alias l.="ls -a | grep -e '^\.'"

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# systemd user ssh-agent.service socket (ssh-agent.socket) — without this, ssh-add/ssh
# can't find the agent and fail with "Could not open a connection to your authentication agent"
export SSH_AUTH_SOCK="/run/user/1000/ssh-agent.socket"
