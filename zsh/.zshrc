export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"

# ---------- Prompt ----------
autoload -Uz vcs_info
autoload -Uz colors && colors
autoload -Uz add-zsh-hook
zmodload zsh/datetime
setopt PROMPT_SUBST

# Keep custom prompt (oh-my-zsh sources after this block)
ZSH_THEME=""

zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr ' %F{#9ece6a}+%F{#bb9af7}'
zstyle ':vcs_info:git:*' unstagedstr ' %F{#e0af68}~%F{#bb9af7}'
zstyle ':vcs_info:git:*' formats ' %F{#292e42}%K{#292e42}%F{#bb9af7} 󰊢 %b%c%u %k%F{#292e42}%f'
zstyle ':vcs_info:git:*' actionformats ' %F{#292e42}%K{#292e42}%F{#bb9af7} 󰊢 %b%c%u %F{#f7768e}· %a %k%F{#292e42}%f'
zstyle ':vcs_info:*' enable git

typeset -g _dotfiles_prompt_started='' _dotfiles_prompt_meta=''
typeset -g _dotfiles_prompt_color='#7dcfff'

_dotfiles_prompt_preexec() {
  _dotfiles_prompt_started=$EPOCHSECONDS
}

_dotfiles_prompt_precmd() {
  local last_status=$? elapsed minutes seconds
  _dotfiles_prompt_meta=''
  _dotfiles_prompt_color='#7dcfff'

  if (( last_status != 0 )); then
    _dotfiles_prompt_color='#f7768e'
    _dotfiles_prompt_meta="%F{#f7768e}✕ ${last_status}%f %F{#565f89}·%f "
  fi

  if [[ -n $_dotfiles_prompt_started ]]; then
    elapsed=$(( EPOCHSECONDS - _dotfiles_prompt_started ))
    if (( elapsed >= 2 )); then
      minutes=$(( elapsed / 60 ))
      seconds=$(( elapsed % 60 ))
      if (( minutes > 0 )); then
        _dotfiles_prompt_meta+="%F{#e0af68} ${minutes}m ${seconds}s%f "
      else
        _dotfiles_prompt_meta+="%F{#e0af68} ${seconds}s%f "
      fi
      _dotfiles_prompt_meta+='%F{#565f89}·%f '
    fi
  fi

  _dotfiles_prompt_started=''
  vcs_info
}

add-zsh-hook -d preexec _dotfiles_prompt_preexec
add-zsh-hook -d precmd _dotfiles_prompt_precmd
add-zsh-hook preexec _dotfiles_prompt_preexec
add-zsh-hook precmd _dotfiles_prompt_precmd

PROMPT=$'\n''%F{#565f89}╭─%f%F{#292e42}%K{#292e42}%F{#7aa2f7}%B 󰉋 %4~ %b%k%F{#292e42}%f${vcs_info_msg_0_}
%F{#565f89}╰─%f %(#.%F{#f7768e}#.%F{${_dotfiles_prompt_color}}❯)%f %b%k'
RPROMPT='${_dotfiles_prompt_meta}%F{#565f89} %F{#a9b1d6}%D{%H:%M}%f'
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

[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# Pi, node and other mise tools (shims don't break when versions change)
export PATH="$HOME/.local/share/mise/shims:$PATH"
