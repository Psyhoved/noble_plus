#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_ROOT="$REPO_ROOT/mod/mod_noble_plus/scripts"
LIVE_ROOT="/mnt/d/SteamLibrary/steamapps/common/Battle Brothers/data/scripts"

copy_one() {
  local rel="$1"
  local src="$SRC_ROOT/$rel"
  local dst="$LIVE_ROOT/$rel"
  mkdir -p "$(dirname "$dst")"
  if [[ -L "$dst" ]]; then
    rm -f "$dst"
  fi
  cp -f "$src" "$dst"
  if [[ -L "$dst" ]]; then
    echo "[deploy][ERROR] destination remained symlink after copy: $rel" >&2
    return 1
  fi
  echo "[deploy] copied: $rel"
}

check_one() {
  local rel="$1"
  local src="$SRC_ROOT/$rel"
  local dst="$LIVE_ROOT/$rel"
  local a b
  a="$(sha1sum "$src" | awk '{print $1}')"
  b="$(sha1sum "$dst" | awk '{print $1}')"
  if [[ "$a" != "$b" ]]; then
    echo "[deploy][ERROR] sha1 mismatch: $rel" >&2
    echo "  src=$a" >&2
    echo "  dst=$b" >&2
    return 1
  fi
  echo "[deploy] sha1 ok: $rel"
}

FILES=(
  "!mods_preload/mod_noble_plus.nut"
  "ambitions/ambitions/noble_plus_hire_soldiers_ambition.nut"
  "ambitions/ambitions/noble_plus_earn_gold_ambition.nut"
  "ambitions/ambitions/noble_plus_find_allies_ambition.nut"
  "events/events/noble_plus/noble_plus_intro_event.nut"
  "events/events/noble_plus/noble_plus_chapter1_complete_event.nut"
  "scenarios/world/noble_plus_scenario.nut"
)

echo "[deploy] repo: $REPO_ROOT"
echo "[deploy] src : $SRC_ROOT"
echo "[deploy] live: $LIVE_ROOT"

for rel in "${FILES[@]}"; do
  copy_one "$rel"
done

for rel in "${FILES[@]}"; do
  check_one "$rel"
done

echo "[deploy] done"
