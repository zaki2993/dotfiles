export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"

# ---------- Prompt ----------
autoload -Uz vcs_info
autoload -Uz colors && colors
autoload -Uz add-zsh-hook
zmodload zsh/datetime
zmodload -F zsh/stat b:zstat
setopt PROMPT_SUBST

# Keep custom prompt (oh-my-zsh sources after this block)
ZSH_THEME=""

zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:*' enable git

typeset -gA _dotfiles_prompt_c
typeset -g _dotfiles_prompt_theme_stamp=-

# Take prompt colors from the current Omarchy theme so it fits light and dark themes
_dotfiles_prompt_load_theme() {
  local dir=$HOME/.local/state/omarchy/current/theme stamp='' line
  local -A t
  [[ -d $dir ]] && zstat -A stamp +mtime $dir
  [[ $stamp == "$_dotfiles_prompt_theme_stamp" ]] && return
  _dotfiles_prompt_theme_stamp=$stamp

  if [[ -r $dir/colors.toml ]]; then
    while IFS= read -r line; do
      [[ $line =~ '^([a-z_]+) *= *"([^"]*)"' ]] && t[$match[1]]=$match[2]
    done < $dir/colors.toml
  fi

  # Pill background: a bit lighter than the terminal on dark themes, a bit darker on light ones
  local surface=${t[lighter_background]:-#292e42}
  [[ $t[mode] == light ]] && surface=${t[darker_background]:-$surface}

  # Fallbacks are Tokyo Night
  _dotfiles_prompt_c=(
    surface $surface
    muted   ${t[muted]:-#565f89}
    text    ${t[foreground]:-#a9b1d6}
    blue    ${t[blue]:-#7aa2f7}
    cyan    ${t[cyan]:-#7dcfff}
    magenta ${t[magenta]:-#bb9af7}
    green   ${t[green]:-#9ece6a}
    yellow  ${t[yellow]:-#e0af68}
    red     ${t[red]:-#f7768e}
  )

  zstyle ':vcs_info:git:*' stagedstr " %F{${_dotfiles_prompt_c[green]}}+%F{${_dotfiles_prompt_c[magenta]}}"
  zstyle ':vcs_info:git:*' unstagedstr " %F{${_dotfiles_prompt_c[yellow]}}~%F{${_dotfiles_prompt_c[magenta]}}"
  zstyle ':vcs_info:git:*' formats " %F{${_dotfiles_prompt_c[surface]}}%K{${_dotfiles_prompt_c[surface]}}%F{${_dotfiles_prompt_c[magenta]}} 󰊢 %b%c%u %k%F{${_dotfiles_prompt_c[surface]}}%f"
  zstyle ':vcs_info:git:*' actionformats " %F{${_dotfiles_prompt_c[surface]}}%K{${_dotfiles_prompt_c[surface]}}%F{${_dotfiles_prompt_c[magenta]}} 󰊢 %b%c%u %F{${_dotfiles_prompt_c[red]}}· %a %k%F{${_dotfiles_prompt_c[surface]}}%f"
}

typeset -g _dotfiles_prompt_started='' _dotfiles_prompt_meta=''
typeset -g _dotfiles_prompt_color=''

_dotfiles_prompt_preexec() {
  _dotfiles_prompt_started=$EPOCHSECONDS
}

_dotfiles_prompt_precmd() {
  local last_status=$? elapsed minutes seconds
  _dotfiles_prompt_load_theme
  _dotfiles_prompt_meta=''
  _dotfiles_prompt_color=$_dotfiles_prompt_c[cyan]

  if (( last_status != 0 )); then
    _dotfiles_prompt_color=$_dotfiles_prompt_c[red]
    _dotfiles_prompt_meta="%F{${_dotfiles_prompt_c[red]}}✕ ${last_status}%f %F{${_dotfiles_prompt_c[muted]}}·%f "
  fi

  if [[ -n $_dotfiles_prompt_started ]]; then
    elapsed=$(( EPOCHSECONDS - _dotfiles_prompt_started ))
    if (( elapsed >= 2 )); then
      minutes=$(( elapsed / 60 ))
      seconds=$(( elapsed % 60 ))
      if (( minutes > 0 )); then
        _dotfiles_prompt_meta+="%F{${_dotfiles_prompt_c[yellow]}} ${minutes}m ${seconds}s%f "
      else
        _dotfiles_prompt_meta+="%F{${_dotfiles_prompt_c[yellow]}} ${seconds}s%f "
      fi
      _dotfiles_prompt_meta+="%F{${_dotfiles_prompt_c[muted]}}·%f "
    fi
  fi

  _dotfiles_prompt_started=''
  vcs_info
}

add-zsh-hook -d preexec _dotfiles_prompt_preexec
add-zsh-hook -d precmd _dotfiles_prompt_precmd
add-zsh-hook preexec _dotfiles_prompt_preexec
add-zsh-hook precmd _dotfiles_prompt_precmd

PROMPT=$'\n''%F{${_dotfiles_prompt_c[muted]}}╭─%f%F{${_dotfiles_prompt_c[surface]}}%K{${_dotfiles_prompt_c[surface]}}%F{${_dotfiles_prompt_c[blue]}}%B 󰉋 %4~ %b%k%F{${_dotfiles_prompt_c[surface]}}%f${vcs_info_msg_0_}
%F{${_dotfiles_prompt_c[muted]}}╰─%f %(#.%F{${_dotfiles_prompt_c[red]}}#.%F{${_dotfiles_prompt_color}}❯)%f %b%k'
RPROMPT='${_dotfiles_prompt_meta}%F{${_dotfiles_prompt_c[muted]}} %F{${_dotfiles_prompt_c[text]}}%D{%H:%M}%f'
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
