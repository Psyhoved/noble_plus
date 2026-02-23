#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE=""

usage() {
  cat <<USAGE
Usage: ./tools/test_all.sh --mode <quick|full|ui|non_ui|custom>
USAGE
}

err() { echo "[test_all][ERROR] $*" >&2; }
ok() { echo "[test_all] $*"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      [[ $# -ge 2 ]] || { err "--mode requires a value"; usage; exit 2; }
      MODE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      err "unknown argument: $1"
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$MODE" ]]; then
  err "mode is required"
  usage
  exit 2
fi

case "$MODE" in
  quick)
    ok "running quick suite"
    "$REPO_ROOT/tools/test_contracts.sh"
    ;;
  full|ui|non_ui|custom)
    err "mode '$MODE' is reserved for later stages and is not implemented yet"
    exit 3
    ;;
  *)
    err "unsupported mode: $MODE"
    usage
    exit 2
    ;;
esac

ok "PASS (mode=$MODE)"
