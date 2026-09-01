#!/bin/bash
#
# Installs the desktop launchers for the web apps ws-layout and the Hyprland
# keybindings expect.
#
# ~/.local/share/applications is not stowed, so without this a fresh machine has
# no launcher entry for them. The .desktop file is only for the app launcher
# (SUPER + SPACE) -- the Hyprland window class comes from chromium's --app mode,
# not from here, so ws-layout and the bindings work either way.
#
# Safe to re-run: an existing .desktop file is left alone.

set -uo pipefail

# name|url|icon -- one line per web app, in ws-layout's left-to-right order.
# icon is optional: leave it empty to fetch the site's own favicon. Set it when
# that can't work on a fresh machine -- the local Supabase URL is a 127.0.0.1
# port that won't be listening, and the Supabase dashboard is behind auth.
readonly SUPABASE_ICON="https://supabase.com/favicon/apple-icon-180x180.png"
WEBAPPS=(
  "Github - Profile|https://github.com/a-yose|"
  "Vercel CJ|https://vercel.com/brents-projects-14fb3145/climbing-journal|"
  "Supabase - Prod|https://supabase.com/dashboard/project/ytjfmlzpqriaxgizkuta|$SUPABASE_ICON"
  "Supabase CJ|http://127.0.0.1:54323/project/default/editor/20982?schema=public|$SUPABASE_ICON"
)

FAILED=()

for entry in "${WEBAPPS[@]}"; do
  IFS='|' read -r name url icon <<<"$entry"
  desktop="$HOME/.local/share/applications/$name.desktop"

  if [[ -e $desktop ]]; then
    echo "==> $name already installed. Skipping"
    continue
  fi

  # Three arguments keeps omarchy-webapp-install out of its interactive gum
  # prompts; an empty icon makes it fetch the site's own favicon.
  if omarchy-webapp-install "$name" "$url" "$icon"; then
    echo "==> $name installed"
  else
    echo "!!! $name failed to install" >&2
    FAILED+=("$name")
  fi
done

if ((${#FAILED[@]} > 0)); then
  echo "!!! these web apps failed to install: ${FAILED[*]}" >&2
  exit 1
fi

exit 0
