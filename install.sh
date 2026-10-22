#!/bin/bash
set -e  # stop at the first error instead of carrying on half-installed

# 1. Install all system, terminal, and development packages
echo "Installing packages..."
sudo env OMARCHY_ALLOW_DIRECT_PACMAN=1 pacman -Syu --needed \
  zsh stow keyd neovim pyenv fzf fastfetch curl git \
  unzip wget npm jdk-openjdk go python python-pip ghostty

# 2. Install Oh My Zsh directly via Git (Bulletproof method)
echo "Installing Oh My Zsh..."
rm -rf ~/.oh-my-zsh  # Deletes any corrupted previous downloads
git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh

# 3. Download custom Zsh plugins
echo "Installing Zsh plugins..."
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
mkdir -p "$ZSH_CUSTOM/plugins"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting

echo "Installation complete! If you saw no errors, please run ./config.sh"
