#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_ROOT="$REPO_ROOT/mod/mod_noble_plus/scripts"
LIVE_ROOT="/mnt/d/SteamLibrary/steamapps/common/Battle Brothers/data/scripts"
LOG_FILE="/mnt/c/Users/Aleksander/Documents/Battle Brothers/log.html"

FILES=(
  "!mods_preload/mod_noble_plus.nut"
  "ambitions/ambitions/noble_plus_hire_soldiers_ambition.nut"
  "ambitions/ambitions/noble_plus_earn_gold_ambition.nut"
  "ambitions/ambitions/noble_plus_find_allies_ambition.nut"
  "events/events/noble_plus/noble_plus_intro_event.nut"
  "events/events/noble_plus/noble_plus_chapter1_complete_event.nut"
  "scenarios/world/noble_plus_scenario.nut"
)

ok() { echo "[preflight] $*"; }
err() { echo "[preflight][ERROR] $*" >&2; }

ok "repo: $REPO_ROOT"
ok "src : $SRC_ROOT"
ok "live: $LIVE_ROOT"

for rel in "${FILES[@]}"; do
  src="$SRC_ROOT/$rel"
  dst="$LIVE_ROOT/$rel"

  if [[ ! -e "$dst" ]]; then
    err "missing live file: $rel"
    exit 1
  fi

  if [[ -L "$dst" ]]; then
    err "live file is symlink (Windows runtime cannot reliably read WSL symlink targets): $rel"
    err "run ./tools/deploy_live_scripts.sh to switch live runtime to copied files"
    exit 1
  fi

  a="$(sha1sum "$src" | awk '{print $1}')"
  b="$(sha1sum "$dst" | awk '{print $1}')"
  if [[ "$a" != "$b" ]]; then
    err "sha1 mismatch: $rel"
    err " src=$a"
    err " dst=$b"
    err "run ./tools/deploy_live_scripts.sh and retest"
    exit 1
  fi

  ok "file sha1 ok: $rel"
done

if [[ ! -f "$LOG_FILE" ]]; then
  err "log file not found: $LOG_FILE"
  exit 1
fi

normalized="$(sed 's#</div><div#</div>\n<div#g' "$LOG_FILE")"
must_have=(
  "[NoblePlus] deploy check: preload config/runtime includes loaded"
  "[NoblePlus][Ambitions] initialized:"
  "[NoblePlus][Ambitions] suppressor targets:"
)

for marker in "${must_have[@]}"; do
  if ! grep -Fq "$marker" <<<"$normalized"; then
    err "missing log marker: $marker"
    exit 1
  fi
  ok "log marker ok: $marker"
done

must_not_have=(
  "Unable to open file \"scripts/scenarios/world/noble_plus_scenario.nut\""
  "Failed to load script file \"scripts/scenarios/world/noble_plus_scenario.nut\""
  "Unable to open file \"scripts/events/events/noble_plus/noble_plus_intro_event.nut\""
  "Failed to load script file \"scripts/events/events/noble_plus/noble_plus_intro_event.nut\""
)

for marker in "${must_not_have[@]}"; do
  if grep -Fq "$marker" <<<"$normalized"; then
    err "critical runtime load error found in log: $marker"
    exit 1
  fi
done
ok "log has no critical Noble Plus file-load errors"

ok "PASS"
