export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"

# ---------- Simple Prompt ----------
ZSH_THEME=""
ZSH_THEME_GIT_PROMPT_PREFIX=""
ZSH_THEME_GIT_PROMPT_SUFFIX=" "
PROMPT='%F{blue}%~%f %F{green}$(git_prompt_info)%f> '

# ---------- Oh My Zsh ----------
export ZSH="$HOME/.oh-my-zsh"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

# ---------- Key bindings ----------
bindkey '^[f' forward-word
bindkey '^N' autosuggest-accept
bindkey -r '^l'
bindkey "^H" backward-kill-word
bindkey "^[[3;5~" kill-word

# ---------- History ----------
#HISTSIZE=10000
#SAVEHIST=10000
#HISTFILE=~/.zsh_history
#setopt HIST_IGNORE_ALL_DUPS
#setopt HIST_VERIFY
#setopt SHARE_HISTORY

# ---------- Completion ----------
#autoload -Uz compinit
#compinit -u

# ---------- Environment ----------
export EDITOR="nvim"
export CLICOLOR=1
export CHROME_EXECUTABLE=$(command -v brave)

# Android / Flutter
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
export PATH="$PATH:$HOME/flutter/bin"

# Go
export PATH="$PATH:$HOME/go/bin"

# RVM
export PATH="$PATH:$HOME/.rvm/bin"

# SDKMAN (must be near the end)
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

# ---------- FZF ----------
if command -v fzf >/dev/null; then
  source <(fzf --zsh)
fi

# ---------- Aliases ----------
alias ll='ls -alF'
alias gs='git status'
alias gp='git push'
alias gl='git pull'
alias cl='clear'
alias cnn='cd ~/.config/nvim && nvim .'
alias chn='cd ~/.config/hypr && nvim .'
alias con='cd ~/.config/omarchy && nvim .'
alias vf='nvim $(find . -type f | fzf)'
alias vp='nvim $(find . -type d | fzf)'
alias add-snaps='sudo grub-btrfsd --syslog /.snapshots & sleep 2 && sudo pkill -f grub-btrfsd && sudo grub-mkconfig -o /boot/grub/grub.cfg'
alias tmux-r='tmux new-session -d -s main 2>/dev/null; tmux run-shell "~/.tmux/plugins/tmux-resurrect/scripts/restore.sh"; tmux attach'

autoload -Uz add-zsh-hook
run_fastfetch_once() {
  # Check that we are NOT in Herdr (and NOT in Tmux, just in case)
  if [[ -z "$HERDR_ENV" ]] && [[ -z "$TMUX" ]] && command -v fastfetch >/dev/null; then
    fastfetch --config neofetch
  fi
  add-zsh-hook -d precmd run_fastfetch_once
}
add-zsh-hook precmd run_fastfetch_once

export TERMINAL=ghostty

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

. "$HOME/.local/share/../bin/env"
