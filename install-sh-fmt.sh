#!/bin/bash

# Installs shfmt and shellcheck independently: a failure in one does not
# prevent the other from being attempted.
install_sh_fmt_tool() {
  local tool="$1"
  local spec="${2:-$1}"

  if command -v "$tool" >/dev/null 2>&1; then
    echo "==> $tool already installed, skipping"
    return 0
  fi

  if mise use -g "$spec"; then
    echo "==> $tool installed"
    return 0
  fi

  echo "!!! $tool failed to install" >&2
  return 1
}

install_sh_fmt_tool shfmt
install_sh_fmt_tool shellcheck
