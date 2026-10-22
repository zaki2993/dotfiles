# dotfiles

My setup for a fresh Omarchy machine.

## New machine (do this first)

```bash
git clone https://github.com/zaki2993/dotfiles ~/dotfiles
cd ~/dotfiles
chmod +x install.sh config.sh
./install.sh
./config.sh
```

That's it. `config.sh` reboots the machine at the end.

## What the scripts do

**`install.sh`** – installs packages
- Packages with pacman (zsh, stow, keyd, neovim, git, go, python, …)
- Oh My Zsh + zsh-autosuggestions + zsh-syntax-highlighting

**`config.sh`** – puts my configs in place
- Removes Omarchy's default nvim / herdr / bindings.lua / .zshrc so they don't clash
- `stow` links each folder below into `~`
- Connects all coding agents to my shared rules (`link.sh`)
- Sets up the Omarchy bar: installs my plugins from their repos and copies the bar layout
- Sets zsh as the default shell
- Copies the keyd config to `/etc/keyd` and starts keyd
- Reboots

## What's in here

| Folder   | Goes to                       | What it is                     |
|----------|-------------------------------|--------------------------------|
| `zsh`    | `~/.zshrc`                    | shell config                   |
| `nvim`   | `~/.config/nvim`              | Neovim                         |
| `hypr`   | `~/.config/hypr/bindings.lua` | Hyprland keybindings           |
| `herdr`  | `~/.config/herdr`             | herdr config                   |
| `agents` | `~/.config/agents`            | rules for all coding agents    |
| `keyd`   | `/etc/keyd` (copied)          | key remapping                  |
| `omarchy-plugins` | `~/.config/omarchy/plugins` | my clones of Omarchy's battery, sound, display, wifi and weather widgets (drawn icons) |
| `omarchy` | `~/.config/omarchy/shell.json` (copied) | bar layout          |

Bar plugins with their own repo (Islands, Prism, Agents, Notepad, Space) are
installed by `config.sh` with `omarchy plugin add`, not stored here.
If you change the bar layout, copy it back:
`cp ~/.config/omarchy/shell.json ~/dotfiles/omarchy/shell.json`

Files are **symlinks**, so editing `~/.zshrc` edits the file in this repo.
To save a change: `cd ~/dotfiles && git add -A && git commit -m "..." && git push`

## Agent rules

One file for all coding agents: `agents/.config/agents/AGENTS.md`.
Edit it once and every agent follows it.

`link.sh` connects each agent to it:

| Agent           | Reads                                                 |
|-----------------|-------------------------------------------------------|
| Claude Code     | `~/.claude/CLAUDE.md` → symlink                       |
| Codex           | `~/.codex/AGENTS.md` → symlink                        |
| Antigravity CLI | `~/.gemini/AGENTS.md` → symlink                       |
| OpenCode        | `"instructions"` in `~/.config/opencode/opencode.json` |

- `config.sh` runs it for you. Run it again any time: `~/.config/agents/link.sh`
- It never deletes anything. Old files are renamed to `*.bak`.
- If it prints `todo` for OpenCode, add this line to `~/.config/opencode/opencode.json`:
  ```json
  "instructions": ["~/.config/agents/AGENTS.md"],
  ```

Check it worked:

```bash
ls -l ~/.claude/CLAUDE.md ~/.codex/AGENTS.md ~/.gemini/AGENTS.md
```

All three should point to `~/.config/agents/AGENTS.md`.

## Rules for this repo

This repo is **public**. Never commit API keys, tokens, passwords, or auth files
(`~/.codex/auth.json`, `~/.gemini/oauth_creds.json`, etc.).
