#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scanner.sh --scan-mode <incremental|full> [--cwd <path>]
EOF
}

SCAN_MODE=""
CWD=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scan-mode)
      SCAN_MODE="$2"
      shift 2
      ;;
    --cwd)
      CWD="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$SCAN_MODE" ]]; then
  echo "Missing --scan-mode" >&2
  usage >&2
  exit 2
fi

if [[ -n "$CWD" ]]; then
  cd "$CWD" || {
    echo "invalid cwd: $CWD" >&2
    exit 2
  }
fi

list_full_files() {
  if command -v git >/dev/null 2>&1; then
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      {
        git ls-files
        git ls-files --others --exclude-standard
      } | sort -u
      return 0
    fi
  fi
  find . -type f -print
}

if [[ "$SCAN_MODE" == "incremental" ]]; then
  if ! command -v git >/dev/null 2>&1; then
    echo "incremental scan failed, fallback to full scan" >&2
    list_full_files
    exit 0
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "incremental scan failed, fallback to full scan" >&2
    list_full_files
    exit 0
  fi

  if ! git diff --name-only HEAD~1 >/dev/null 2>&1; then
    echo "incremental scan failed, fallback to full scan" >&2
    list_full_files
    exit 0
  fi

  {
    git diff --name-only HEAD~1
    git ls-files --others --exclude-standard
  } | sort -u
  exit 0
fi

if [[ "$SCAN_MODE" == "full" ]]; then
  list_full_files
  exit 0
fi

echo "invalid scan mode: $SCAN_MODE" >&2
exit 2
