#!/usr/bin/env bash
set -euo pipefail

command="${1:-}"

if [[ -z "$command" ]]; then
  echo "usage: git-adapter.sh <getChangedFiles|getDiff> [ref]" >&2
  exit 2
fi

case "$command" in
  getChangedFiles)
    ref="${2:-HEAD~1}"
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "git not available" >&2
      exit 1
    fi
    git diff --name-only "$ref"
    ;;
  getDiff)
    ref="${2:-HEAD~1}"
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "git not available" >&2
      exit 1
    fi
    git diff "$ref"
    ;;
  *)
    echo "unknown command: $command" >&2
    exit 2
    ;;
esac
