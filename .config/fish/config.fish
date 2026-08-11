source /usr/share/cachyos-fish-config/cachyos-config.fish

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
