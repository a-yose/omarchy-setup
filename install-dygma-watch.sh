#!/bin/bash
#
# Enables the user service that syncs the newest Dygma backup into the dotfiles
# repo whenever Bazecor writes one.
#
# Run after install-dotfiles.sh -- that is what stows the unit and the watcher.
# Safe to re-run.

set -uo pipefail

readonly UNIT="dygma-watch.service"
readonly UNIT_PATH="$HOME/.config/systemd/user/$UNIT"

if ! pacman -Q inotify-tools >/dev/null 2>&1; then
  if yay -S --noconfirm --needed inotify-tools; then
    echo "inotify-tools installed"
  else
    echo "!!! inotify-tools failed to install" >&2
    exit 1
  fi
else
  echo "inotify-tools already installed. Skipping"
fi

if [[ ! -e $UNIT_PATH ]]; then
  echo "!!! $UNIT_PATH missing -- run install-dotfiles.sh first" >&2
  exit 1
fi

systemctl --user daemon-reload || exit 1

if systemctl --user enable --now "$UNIT"; then
  echo "==> $UNIT enabled"
else
  echo "!!! could not enable $UNIT" >&2
  exit 1
fi

# enable --now leaves an already-running service on the old unit file, so pick up
# any edits that came in with this run of the dotfiles install.
systemctl --user restart "$UNIT" || exit 1

if systemctl --user is-active --quiet "$UNIT"; then
  echo "==> $UNIT is running"
  exit 0
fi

echo "!!! $UNIT is not running, check: journalctl --user -u $UNIT" >&2
exit 1
