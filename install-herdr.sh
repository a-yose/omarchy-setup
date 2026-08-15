#!/bin/bash

if command -v herdr >/dev/null 2>&1; then
  echo "==> herdr already installed. skipping"
  exit 0
fi

if mise use -g herdr; then
  echo "==> herdr insalled"
  exit 0
fi

echo "!!! herdr failed to install" >&2
exit 1
