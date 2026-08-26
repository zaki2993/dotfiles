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
stow nvim herdr zsh hypr

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
