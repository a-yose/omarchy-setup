#!/bin/bash

# Run from the repo directory regardless of where this script was invoked from.
cd "$(dirname "$0")" || exit 1

SCRIPTS=(
  # install-hypr-overrides
  install-stow
  install-dotfiles
  install-ghosty
  install-herdr
  install-prettier
  install-sh-fmt
)

FAILED=()

for script in "${SCRIPTS[@]}"; do
  echo
  echo "=== $script ==="
  ./"$script".sh || FAILED+=("$script")
done

echo
if [ ${#FAILED[@]} -gt 0 ]; then
  echo "!!! these installs failed: ${FAILED[*]}" >&2
  exit 1
fi

echo "==> all installs completed"
