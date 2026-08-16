#!/bin/bash
#
# Stows the dotfiles repo into $HOME.
#
# Safe to re-run: every step either checks before acting, or removes and
# recreates exactly the paths the repo owns.

set -euo pipefail

# SSH, so pushes work without a token. Requires an SSH key already registered
# with GitHub -- on a brand-new machine, set that up before running this.
readonly REPO_URL="git@github.com:a-yose/dotfiles.git"
readonly REPO_DIR="$HOME/dotfiles"

command -v stow >/dev/null || {
  printf 'Install stow and run script again.\n' >&2
  exit 1
}

# Check if the repository already exists
if [[ -d $REPO_DIR ]]; then
  printf "Repository '%s' already exists. Pulling latest changes\n" "$REPO_DIR"
  CLONED_REPO=false
  # --ff-only refuses to merge or rewrite anything, so local commits and
  # uncommitted edits are never overwritten -- the pull just fails instead.
  git -C "$REPO_DIR" pull --ff-only \
    || printf '!!! could not update %s, stowing the existing checkout\n' "$REPO_DIR" >&2
else
  git clone "$REPO_URL" "$REPO_DIR" || exit 1
  CLONED_REPO=true
fi

# ~/.local/share/nvim and ~/.cache/nvim hold downloaded plugins, treesitter
# parsers and Mason binaries.
# Only worth wiping when that data belongs to some *other* nvim config
NVIM_LINK="$(readlink -f "$HOME/.config/nvim")" || NVIM_LINK=""
NVIM_TARGET="$(readlink -f "$REPO_DIR/nvim/.config/nvim")" || NVIM_TARGET=""
if [[ $CLONED_REPO == true || $NVIM_LINK != "$NVIM_TARGET" ]]; then
  NVIM_DATA_STALE=true
else
  NVIM_DATA_STALE=false
fi

printf 'removing old configs\n'
OLD_CONFIGS=(
  "$HOME/.config/bash"
  "$HOME/.bashrc"
  "$HOME/.ssh/config"
  "$HOME/.config/nvim"
  "$HOME/.config/herdr/config.toml"
)
rm -rf "${OLD_CONFIGS[@]}"

if [[ $NVIM_DATA_STALE == true ]]; then
  printf 'removing nvim plugin/cache data (belongs to a different nvim config)\n'
  rm -rf "$HOME/.local/share/nvim" "$HOME/.cache/nvim"
else
  printf 'keeping existing nvim plugin/cache data\n'
fi

cd "$REPO_DIR" || exit 1

STOW_FAILED=()

stow_package() {
  local package="$1"
  shift

  if stow "$package" "$@"; then
    printf '==> stowed %s\n' "$package"
  else
    printf '!!! failed to stow %s\n' "$package" >&2
    STOW_FAILED+=("$package")
  fi
}

stow_package bash
stow_package ssh --no-folding
stow_package hypr --no-folding --adopt
stow_package nvim
stow_package herdr --no-folding
stow_package ghostty

# --adopt overwrites the repo's copy with whatever was on this machine, so show
# what changed. On a fresh install that will be Omarchy's stock templates
# landing on top of your config -- restore yours with, from "$REPO_DIR":
#   git checkout -- hypr/     (keeps the symlinks; only the contents revert)
ADOPTED="$(git -C "$REPO_DIR" status --short -- hypr/)"
if [[ -n $ADOPTED ]]; then
  printf '==> stow --adopt pulled these into %s/hypr:\n%s\n' "$REPO_DIR" "$ADOPTED"
  printf '    review with: git -C %s diff -- hypr/\n' "$REPO_DIR"
fi

# Omarchy owns ~/.config/ghostty/config and edits it during updates, so we don't
# stow over it -- we only make sure it pulls in our own overrides file.
GHOSTTY_CONFIG="$HOME/.config/ghostty/config"
GHOSTTY_INCLUDE='config-file = ?"~/.config/ghostty/overrides.conf"'
if [[ -f $GHOSTTY_CONFIG ]] && ! grep -qF "$GHOSTTY_INCLUDE" "$GHOSTTY_CONFIG"; then
  printf '\n# Personal overrides (dotfiles)\n%s\n' "$GHOSTTY_INCLUDE" >>"$GHOSTTY_CONFIG"
  printf 'added ghostty overrides config include to %s\n' "$GHOSTTY_CONFIG"
fi

if ((${#STOW_FAILED[@]})); then
  printf '!!! these packages failed to stow: %s\n' "${STOW_FAILED[*]}" >&2
  exit 1
fi

printf 'dotfiles successfully stowed\n'
