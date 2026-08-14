#!/bin/bash

REPO_URL="https://github.com/a-yose/dotfiles"
REPO_DIR="$HOME/dotfiles"

command -v stow >/dev/null || { echo "Install stow and run script again."; exit 1; }

# Check if the repository already exists
if [ -d "$REPO_DIR" ]; then
  echo "Repository '$REPO_DIR' already exists. Pulling latest changes"
  CLONED_REPO=false
  # --ff-only refuses to merge or rewrite anything, so local commits and
  # uncommitted edits are never overwritten -- the pull just fails instead.
  git -C "$REPO_DIR" pull --ff-only ||
    echo "!!! could not update $REPO_DIR, stowing the existing checkout" >&2
else
  git clone "$REPO_URL" "$REPO_DIR" || exit 1
  CLONED_REPO=true
fi

# ~/.local/share/nvim and ~/.cache/nvim hold downloaded plugins, treesitter
# parsers and Mason binaries.
# Only worth wiping when that data belongs to some *other* nvim config
NVIM_LINK="$(readlink -f ~/.config/nvim)"
NVIM_TARGET="$(readlink -f "$REPO_DIR/nvim/.config/nvim")"
if [ "$CLONED_REPO" = true ] || [ "$NVIM_LINK" != "$NVIM_TARGET" ]; then
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

cd "$REPO_DIR" || exit 1

STOW_FAILED=()

stow_package() {
  local package="$1"
  shift

  if stow "$package" "$@"; then
    echo "==> stowed $package"
  else
    echo "!!! failed to stow $package" >&2
    STOW_FAILED+=("$package")
  fi
}

stow_package bash
stow_package ssh --no-folding
stow_package nvim
stow_package herdr --no-folding
stow_package ghostty

# Omarchy owns ~/.config/ghostty/config and edits it during updates, so we don't
# stow over it -- we only make sure it pulls in our own overrides file.
GHOSTTY_CONFIG="$HOME/.config/ghostty/config"
GHOSTTY_INCLUDE='config-file = ?"~/.config/ghostty/overrides.conf"'
if [ -f "$GHOSTTY_CONFIG" ] && ! grep -qF "$GHOSTTY_INCLUDE" "$GHOSTTY_CONFIG"; then
  printf '\n# Personal overrides (dotfiles)\n%s\n' "$GHOSTTY_INCLUDE" >>"$GHOSTTY_CONFIG"
  echo "added ghostty overrides config include to $GHOSTTY_CONFIG"
fi

if [ ${#STOW_FAILED[@]} -gt 0 ]; then
  echo "!!! these packages failed to stow: ${STOW_FAILED[*]}" >&2
  exit 1
fi

echo "dotfiles successfully stowed"
