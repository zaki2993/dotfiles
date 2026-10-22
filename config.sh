#!/bin/bash

# 1. Fix the Line 100 error (Creates an empty dummy file)
echo "Fixing missing bin/env file..."
mkdir -p ~/.local/bin
touch ~/.local/bin/env

# 2. Delete defaults to prevent Stow conflicts
echo "Cleaning up default configurations..."
rm -rf ~/.config/nvim ~/.local/share/nvim ~/.state/nvim ~/.cache/nvim
rm -rf ~/.config/herdr ~/.config/hypr/bindings.lua
rm -f ~/.zshrc

# 3. Create shortcuts using Stow
echo "Stowing configurations..."
cd ~/dotfiles
# Make the plugins folder first so stow links each plugin, not the whole folder
mkdir -p ~/.config/omarchy/plugins
stow nvim herdr zsh hypr agents omarchy-plugins
~/.config/agents/link.sh

# 3b. Omarchy bar: plugins that live in their own repos, then the bar layout
echo "Setting up the Omarchy bar..."
plugins=(
  "zakarch.islands https://github.com/zaki2993/zakarch.islands.git"
  "zakarch.prism https://github.com/zaki2993/zakarch.prism.git"
  "zakarch.agents https://github.com/zaki2993/Agents.git"
  "zakarch.notepad https://github.com/zaki2993/notes.git"
  "zakarch.space https://github.com/zaki2993/zakarch.space.git"
)
for entry in "${plugins[@]}"; do
  read -r id url <<< "$entry"
  [[ -d ~/.config/omarchy/plugins/$id ]] || omarchy plugin add "$url" --yes
done
# Copied, not stowed: omarchy rewrites shell.json and would replace a symlink
[[ -f ~/.config/omarchy/shell.json ]] && cp ~/.config/omarchy/shell.json ~/.config/omarchy/shell.json.bak
cp ~/dotfiles/omarchy/shell.json ~/.config/omarchy/shell.json

# 4. Make Zsh the default shell
echo "Changing default shell to Zsh..."
chsh -s $(which zsh)

# 5. Apply Keyd configurations
echo "Setting up Keyd..."
sudo mkdir -p /etc/keyd
sudo cp ~/dotfiles/keyd/default.conf /etc/keyd/default.conf
sudo systemctl enable --now keyd
sudo keyd reload

# 6. Reboot
echo "Setup complete! Rebooting in 3 seconds..."
sleep 3
sudo reboot
