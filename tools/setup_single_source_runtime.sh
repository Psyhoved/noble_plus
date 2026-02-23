#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_ROOT="$REPO_ROOT/mod/mod_noble_plus/scripts"
LIVE_ROOT="/mnt/d/SteamLibrary/steamapps/common/Battle Brothers/data/scripts"

FILES=(
  "!mods_preload/mod_noble_plus.nut"
  "ambitions/ambitions/noble_plus_hire_soldiers_ambition.nut"
  "ambitions/ambitions/noble_plus_earn_gold_ambition.nut"
  "ambitions/ambitions/noble_plus_find_allies_ambition.nut"
  "events/events/noble_plus/noble_plus_intro_event.nut"
  "events/events/noble_plus/noble_plus_chapter1_complete_event.nut"
  "scenarios/world/noble_plus_scenario.nut"
)

if [[ "${ALLOW_SYMLINK_RUNTIME:-0}" != "1" ]]; then
  echo "[single-source][ERROR] WSL symlink runtime disabled for this project." >&2
  echo "[single-source][ERROR] Use ./tools/deploy_live_scripts.sh (copy runtime) instead." >&2
  echo "[single-source][ERROR] To force old behavior, run with ALLOW_SYMLINK_RUNTIME=1." >&2
  exit 1
fi

echo "[single-source] repo: $REPO_ROOT"
echo "[single-source] src : $SRC_ROOT"
echo "[single-source] live: $LIVE_ROOT"

for rel in "${FILES[@]}"; do
  src="$SRC_ROOT/$rel"
  dst="$LIVE_ROOT/$rel"
  mkdir -p "$(dirname "$dst")"
  rm -f "$dst"
  ln -s "$src" "$dst"
  echo "[single-source] linked: $dst -> $src"
done

echo "[single-source] done"
