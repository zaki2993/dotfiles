#!/bin/bash
# Small shell setup for servers (Ubuntu/Debian).
# Run: curl -fsSL https://raw.githubusercontent.com/zaki2993/dotfiles/main/server/install.sh | bash
set -e

echo "Installing packages..."
sudo apt-get update
sudo apt-get install -y zsh git curl fzf zsh-autosuggestions zsh-syntax-highlighting

# Keep the old .zshrc in case there was one
[ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.bak
curl -fsSL https://raw.githubusercontent.com/zaki2993/dotfiles/main/server/.zshrc -o ~/.zshrc

sudo chsh -s "$(command -v zsh)" "$USER"
echo "Done. Log out and back in (or run: zsh)."
