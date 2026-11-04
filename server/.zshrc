# Small zsh setup for servers. No plugin manager, no fonts needed.

# ---------- History ----------
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY

# ---------- Completion ----------
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'  # case-insensitive

# ---------- Prompt ----------
# user@host first so you always know which machine you're on
autoload -Uz vcs_info add-zsh-hook
setopt PROMPT_SUBST
zstyle ':vcs_info:git:*' formats ' %F{magenta}(%b)%f'
add-zsh-hook precmd vcs_info

PROMPT=$'\n''%F{yellow}%n@%m%f %F{blue}%B%4~%b%f${vcs_info_msg_0_}
%(?.%F{cyan}.%F{red}[%?] )%(#.#.❯)%f '
RPROMPT='%F{8}%D{%H:%M}%f'

# ---------- Plugins (from the package manager, if installed) ----------
for f in \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
do
  [[ -f $f ]] && source $f
done

# Old fzf (Ubuntu) has no `fzf --zsh`, so fall back to the shipped file
if fzf --zsh &>/dev/null; then
  source <(fzf --zsh)
elif [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
fi

# ---------- Key bindings ----------
bindkey -e
bindkey '^[f' forward-word
bindkey '^N' autosuggest-accept
bindkey '^H' backward-kill-word
bindkey '^[[3;5~' kill-word

# ---------- Environment ----------
export EDITOR=$(command -v nvim || command -v vim || echo nano)
export PATH="$HOME/.local/bin:$PATH"

# ---------- Aliases ----------
alias ll='ls -alF --color=auto'
alias ls='ls --color=auto'
alias gs='git status'
alias gp='git push'
alias gl='git pull'
alias cl='clear'
alias ..='cd ..'
alias df='df -h'
alias du='du -h'
alias ports='ss -tulpn'
alias logs='journalctl -f'
