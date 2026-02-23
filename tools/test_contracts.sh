#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOD_SCRIPTS_ROOT="$REPO_ROOT/mod/mod_noble_plus/scripts"
LIVE_SCRIPTS_ROOT="/mnt/d/SteamLibrary/steamapps/common/Battle Brothers/data/scripts"
GAME_DATA_DIR="/mnt/d/SteamLibrary/steamapps/common/Battle Brothers/data"

ok() { echo "[contracts] $*"; }
err() { echo "[contracts][ERROR] $*" >&2; }

LIVE_TRACKED_FILES=(
  "!mods_preload/mod_noble_plus.nut"
  "ambitions/ambitions/noble_plus_hire_soldiers_ambition.nut"
  "ambitions/ambitions/noble_plus_earn_gold_ambition.nut"
  "ambitions/ambitions/noble_plus_find_allies_ambition.nut"
  "events/events/noble_plus/noble_plus_intro_event.nut"
  "events/events/noble_plus/noble_plus_chapter1_complete_event.nut"
  "scenarios/world/noble_plus_scenario.nut"
)

if [[ ! -d "$MOD_SCRIPTS_ROOT" ]]; then
  err "mod scripts root not found: $MOD_SCRIPTS_ROOT"
  exit 1
fi

if [[ ! -d "$LIVE_SCRIPTS_ROOT" ]]; then
  err "live scripts root not found: $LIVE_SCRIPTS_ROOT"
  exit 1
fi

if [[ ! -d "$GAME_DATA_DIR" ]]; then
  err "game data dir not found: $GAME_DATA_DIR"
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

REFERENCES_FILE="$TMP_DIR/this_new_refs.txt"
MISSING_FILE="$TMP_DIR/missing_refs.txt"

rg -n --no-heading -o 'this\.new\(\s*"scripts/[^"]+"' "$MOD_SCRIPTS_ROOT" \
  | sed -E 's/.*"([^"]+)"/\1/' \
  | sort -u > "$REFERENCES_FILE"

ref_count="$(wc -l < "$REFERENCES_FILE" | tr -d ' ')"
ok "this.new references found: $ref_count"

python3 - "$GAME_DATA_DIR" "$MOD_SCRIPTS_ROOT" "$LIVE_SCRIPTS_ROOT" "$REFERENCES_FILE" "$MISSING_FILE" <<'PY'
import glob
import os
import sys
import zipfile


def normalize(p: str) -> str:
    return p.replace('\\\\', '/').lstrip('./').lower()


def candidates(path: str):
    vals = [path]
    lower = path.lower()
    if not lower.endswith('.nut') and not lower.endswith('.cnut'):
        vals.append(path + '.nut')
        vals.append(path + '.cnut')
    return vals


game_data_dir, mod_scripts_root, live_scripts_root, refs_file, missing_file = sys.argv[1:]

with open(refs_file, 'r', encoding='utf-8') as f:
    refs = [line.strip() for line in f if line.strip()]

entries = set()
for archive in sorted(glob.glob(os.path.join(game_data_dir, '*.dat')) + glob.glob(os.path.join(game_data_dir, '*.zip'))):
    try:
        with zipfile.ZipFile(archive) as zf:
            entries.update(normalize(name) for name in zf.namelist())
    except Exception:
        # Skip broken or unsupported archives but keep checks deterministic.
        continue

missing = []
for ref in refs:
    rel = ref[len('scripts/'):] if ref.startswith('scripts/') else ref

    found = False
    for cand in candidates(ref):
        cand_rel = cand[len('scripts/'):] if cand.startswith('scripts/') else cand

        repo_path = os.path.join(mod_scripts_root, cand_rel)
        live_path = os.path.join(live_scripts_root, cand_rel)

        if os.path.isfile(repo_path) or os.path.isfile(live_path) or normalize(cand) in entries:
            found = True
            break

    if not found:
        missing.append(ref)

with open(missing_file, 'w', encoding='utf-8') as f:
    for item in missing:
        f.write(item + '\n')
PY

if [[ -s "$MISSING_FILE" ]]; then
  err "missing script targets for this.new():"
  while IFS= read -r missing; do
    err "  - $missing"
  done < "$MISSING_FILE"
  exit 1
fi
ok "this.new script target existence: OK"

sha_count=0
for rel in "${LIVE_TRACKED_FILES[@]}"; do
  repo_file="$MOD_SCRIPTS_ROOT/$rel"
  live_file="$LIVE_SCRIPTS_ROOT/$rel"

  if [[ ! -f "$repo_file" ]]; then
    err "missing repo script file: $rel"
    exit 1
  fi

  if [[ ! -e "$live_file" ]]; then
    err "missing live script file: $rel"
    exit 1
  fi

  if [[ -L "$live_file" ]]; then
    err "live script must not be symlink: $rel"
    exit 1
  fi

  repo_sha="$(sha1sum "$repo_file" | awk '{print $1}')"
  live_sha="$(sha1sum "$live_file" | awk '{print $1}')"
  if [[ "$repo_sha" != "$live_sha" ]]; then
    err "sha1 mismatch: $rel"
    err "  repo=$repo_sha"
    err "  live=$live_sha"
    exit 1
  fi

  sha_count=$((sha_count + 1))
done

ok "live SHA1 + no symlink checks: OK ($sha_count files)"
ok "PASS"
