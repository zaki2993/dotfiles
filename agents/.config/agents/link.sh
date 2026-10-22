#!/bin/bash
# Point every coding agent at ~/.config/agents/AGENTS.md.
# Safe to run again. Existing files are moved to *.bak, never deleted.

set -e
RULES="$HOME/.config/agents/AGENTS.md"

if [ ! -f "$RULES" ]; then
  echo "Missing $RULES. Run: cd ~/dotfiles && stow agents"
  exit 1
fi

link() {
  local target="$1"
  mkdir -p "$(dirname "$target")"
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$RULES" ]; then
    echo "ok      $target"
    return
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    mv "$target" "$target.bak"
    echo "backup  $target.bak"
  fi
  ln -s "$RULES" "$target"
  echo "linked  $target"
}

link "$HOME/.claude/CLAUDE.md"   # Claude Code
link "$HOME/.codex/AGENTS.md"    # Codex
link "$HOME/.gemini/AGENTS.md"   # Antigravity CLI (agy)

# OpenCode: ~/.config/opencode/AGENTS.md is often owned by plugins,
# so load our file through the "instructions" setting instead.
OC="$HOME/.config/opencode/opencode.json"
if [ ! -e "$OC" ]; then
  mkdir -p "$(dirname "$OC")"
  printf '{\n  "$schema": "https://opencode.ai/config.json",\n  "instructions": ["~/.config/agents/AGENTS.md"]\n}\n' > "$OC"
  echo "created $OC"
elif grep -q '~/.config/agents/AGENTS.md' "$OC"; then
  echo "ok      $OC"
elif jq -e . "$OC" >/dev/null 2>&1; then
  # Omarchy ships its own opencode.json, so add our line to it
  cp "$OC" "$OC.bak"
  jq '.instructions = ((.instructions // []) + ["~/.config/agents/AGENTS.md"])' "$OC.bak" > "$OC"
  echo "updated $OC (backup $OC.bak)"
else
  echo "todo    add this to $OC:"
  echo '        "instructions": ["~/.config/agents/AGENTS.md"],'
fi
