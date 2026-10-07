#!/bin/bash
# Omawall: advance to the next wallpaper, rolling into the next theme
# once the current theme's wallpapers are exhausted.
#
# Behaviour:
# - If the current wallpaper is not the last one in the current theme,
#   behave exactly like `omarchy-theme-bg-next`.
# - If the current wallpaper IS the last one (sorted order, same as
#   `omarchy-theme-bg-next`), switch to the next eligible theme instead.
#   `omarchy-theme-set` picks the new theme's first wallpaper automatically.
# - Skipped themes are never selected: white, rose-pine, catppuccin-latte,
#   flexoki-light, lupine.
#
# No arguments. Exit 0 on success, non-zero when nothing could be changed.

set -uo pipefail

SKIP_THEMES=(white rose-pine catppuccin-latte flexoki-light lupine)

OMARCHY_THEMES_PATH="${OMARCHY_PATH:-/usr/share/omarchy}/themes"
USER_THEMES_PATH="$HOME/.config/omarchy/themes"
USER_BG_PATH="$HOME/.config/omarchy/backgrounds"
THEME_NAME_FILE="$HOME/.local/state/omarchy/current/theme.name"
THEME_BACKGROUNDS_PATH="$HOME/.local/state/omarchy/current/theme/backgrounds/"
CURRENT_BACKGROUND_LINK="$HOME/.local/state/omarchy/current/background"

IMAGE_FIND_ARGS=(-iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.webp')

is_skipped() {
  local slug="$1" skip
  for skip in "${SKIP_THEMES[@]}"; do
    [[ $slug == "$skip" ]] && return 0
  done
  return 1
}

theme_has_backgrounds() {
  local slug="$1"
  local dir
  for dir in "$USER_BG_PATH/$slug" "$USER_THEMES_PATH/$slug/backgrounds" "$OMARCHY_THEMES_PATH/$slug/backgrounds"; do
    if [[ -d $dir ]] && find -L "$dir" -maxdepth 1 -type f \( "${IMAGE_FIND_ARGS[@]}" \) -print -quit 2>/dev/null | grep -q .; then
      return 0
    fi
  done
  return 1
}

THEME_NAME="$(cat "$THEME_NAME_FILE" 2>/dev/null || true)"
USER_THEME_BACKGROUNDS_PATH="$USER_BG_PATH/$THEME_NAME/"

mapfile -d '' -t BACKGROUNDS < <(
  find -L "$USER_THEME_BACKGROUNDS_PATH" "$THEME_BACKGROUNDS_PATH" -maxdepth 1 -type f \
    \( "${IMAGE_FIND_ARGS[@]}" \) \
    -print0 2>/dev/null | sort -z
)
TOTAL=${#BACKGROUNDS[@]}

if ((TOTAL == 0)); then
  # Current theme has no wallpapers: jump straight to the next eligible theme.
  :
else
  if [[ -L $CURRENT_BACKGROUND_LINK ]]; then
    CURRENT_BACKGROUND="$(readlink "$CURRENT_BACKGROUND_LINK")"
  else
    CURRENT_BACKGROUND=""
  fi

  INDEX=-1
  for i in "${!BACKGROUNDS[@]}"; do
    if [[ ${BACKGROUNDS[$i]} == "$CURRENT_BACKGROUND" ]]; then
      INDEX=$i
      break
    fi
  done

  if ((INDEX == -1)) || ((INDEX < TOTAL - 1)); then
    # Still wallpapers left in this theme (or unknown position):
    # advance within the theme.
    exec omarchy-theme-bg-next
  fi
  # else: on the last wallpaper -> fall through to theme switch.
fi

# --- Pick the next eligible theme (sorted, wrap around) ---
declare -a ALL_THEMES=()
while IFS= read -r slug; do
  [[ -n $slug ]] || continue
  is_skipped "$slug" && continue
  ALL_THEMES+=("$slug")
done < <(
  {
    find "$USER_THEMES_PATH" -mindepth 1 -maxdepth 1 \( -type d -o -type l \) -printf '%f\n' 2>/dev/null
    find "$OMARCHY_THEMES_PATH" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null
  } | sort -u
)

if ((${#ALL_THEMES[@]} == 0)); then
  omarchy-notification-send "No eligible theme found" -t 2000
  exit 1
fi

# Find current position. If the current theme is skipped/unknown, start at the
# first eligible theme alphabetically after it (wrapping to the first).
START=0
FOUND=-1
for i in "${!ALL_THEMES[@]}"; do
  if [[ ${ALL_THEMES[$i]} == "$THEME_NAME" ]]; then
    FOUND=$i
    break
  fi
done

if ((FOUND != -1)); then
  START=$(((FOUND + 1) % ${#ALL_THEMES[@]}))
else
  START=0
  for i in "${!ALL_THEMES[@]}"; do
    if [[ ${ALL_THEMES[$i]} > $THEME_NAME ]]; then
      START=$i
      break
    fi
  done
fi

# Walk from START (wrapping) and take the first theme that has wallpapers.
for ((offset = 0; offset < ${#ALL_THEMES[@]}; offset++)); do
  CANDIDATE="${ALL_THEMES[$(((START + offset) % ${#ALL_THEMES[@]}))]}"
  if theme_has_backgrounds "$CANDIDATE"; then
    exec omarchy-theme-set "$CANDIDATE"
  fi
done

# No eligible theme ships wallpapers: fall back to plain next-background.
exec omarchy-theme-bg-next
