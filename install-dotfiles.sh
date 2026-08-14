#!/bin/bash

ORIGINAL_DIR=$(pwd)
REPO_URL="https://github.com/a-yose/dotfiles"
REPO_DIR="$HOME/dotfiles"

command -v stow >/dev/null || { echo "Install stow and run script again."; exit 1; }

# Check if the repository already exists
if [ -d "$REPO_DIR" ]; then
  echo "Repository '$REPO_DIR' already exists. Skipping clone"
  CLONED_REPO=false
else
  git clone "$REPO_URL" "$REPO_DIR" || exit 1
  CLONED_REPO=true
fi

# ~/.local/share/nvim and ~/.cache/nvim hold downloaded plugins, treesitter
# parsers and Mason binaries.
# Only worth wiping when that data belongs to some *other* nvim config
if [ "$CLONED_REPO" = true ] || [ "$(readlink -f ~/.config/nvim)" != "$REPO_DIR/nvim/.config/nvim" ]; then
  NVIM_DATA_STALE=true
else
  NVIM_DATA_STALE=false
fi

echo "removing old configs"
rm -fr ~/.config/bash ~/.bashrc ~/.ssh/config ~/.config/nvim ~/.config/herdr/config.toml

if [ "$NVIM_DATA_STALE" = true ]; then
  echo "removing nvim plugin/cache data (belongs to a different nvim config)"
  rm -fr ~/.local/share/nvim ~/.cache/nvim
else
  echo "keeping existing nvim plugin/cache data"
fi

cd "$REPO_DIR"

stow bash
stow ssh --no-folding
stow nvim
stow herdr --no-folding
stow ghostty

# Omarchy owns ~/.config/ghostty/config and edits it during updates, so we don't
# stow over it -- we only make sure it pulls in our own overrides file.
GHOSTTY_CONFIG="$HOME/.config/ghostty/config"
GHOSTTY_INCLUDE='config-file = ?"~/.config/ghostty/overrides.conf"'
if [ -f "$GHOSTTY_CONFIG" ] && ! grep -qF "$GHOSTTY_INCLUDE" "$GHOSTTY_CONFIG"; then
  printf '\n# Personal overrides (dotfiles)\n%s\n' "$GHOSTTY_INCLUDE" >>"$GHOSTTY_CONFIG"
  echo "added overrides include to $GHOSTTY_CONFIG"
fi

# stow zshrc
# stow tmux
# stow starship

cd "$ORIGINAL_DIR"
echo "dotfiles successully stowed"
