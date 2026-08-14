#!/bin/bash

ORIGINAL_DIR=$(pwd)
REPO_URL="https://github.com/a-yose/dotfiles"
REPO_DIR="$HOME/dotfiles"

command -v stow >/dev/null || { echo "Install stow and run script again."; exit 1; }

# Check if the repository already exists
if [ -d "$REPO_DIR" ]; then
  echo "Repository '$REPO_DIR' already exists. Skipping clone"
else
  git clone "$REPO_URL" "$REPO_DIR" || exit 1
fi

echo "removing old configs"
rm -fr ~/.config/bash ~/.bashrc ~/.ssh/config ~/.config/nvim ~/.local/share/nvim ~/.cache/nvim

cd "$REPO_DIR"

stow bash
stow ssh
stow nvim
# stow zshrc
# stow ghostty
# stow tmux
# stow starship

cd "$ORIGINAL_DIR"
echo "dotfiles successully stowed"
