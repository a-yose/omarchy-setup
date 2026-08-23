#!/bin/sh

if command -v bazecor >/dev/null 2>&1; then
  echo "bazecor already installed. Skipping"
  exit 0
fi

if yay -S --noconfirm --needed bazecor; then
  echo "bazecor installed"
  exit 0
fi

echo "!!! bazecor failed to install" >&2
exit 1
