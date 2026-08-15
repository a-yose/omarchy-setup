#!/bin/bash

if command -v ghostty >/dev/null 2>&1; then
  echo "==> ghostty already installed. Skipping"
  exit 0
fi

if omarchy install terminal ghostty; then
  echo "==> ghostty installed"
  exit 0
fi

echo "!!! ghostty failed to install" >&2
exit 1
