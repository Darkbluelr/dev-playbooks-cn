#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
Usage: devbooks-embedding.sh <command> [options]

Commands:
  build             Build a minimal embedding index (local placeholder)
  update            Update index (alias of build)
  status            Show index status
  clean             Remove index
  search            Run a placeholder search and return empty results

Options:
  --project-root DIR  Project root directory (default: current dir)
  --format FORMAT     Output format for search (text|json, default: text)
  --query TEXT        Query for search (required for search)
  -h, --help          Show this help message
EOF
}

if [[ $# -eq 0 ]]; then
  usage
  exit 2
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

command="$1"
shift

project_root="${DEVBOOKS_PROJECT_ROOT:-$(pwd)}"
format="text"
query=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root)
      project_root="${2:-}"
      shift 2
      ;;
    --format)
      format="${2:-}"
      shift 2
      ;;
    --query)
      query="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

project_root="${project_root%/}"
index_dir="${project_root}/.devbooks/embeddings"

case "$command" in
  build|update)
    mkdir -p "$index_dir"
    printf "file\tline\n" >"${index_dir}/index.tsv"
    printf '{"schema_version":"1.0.0","generated_at":"%s"}\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" >"${index_dir}/metadata.json"
    echo "ok: embeddings index generated at ${index_dir}"
    ;;
  status)
    if [[ -d "$index_dir" ]]; then
      echo "status: ready (${index_dir})"
      exit 0
    fi
    echo "status: missing (${index_dir})"
    exit 1
    ;;
  clean)
    rm -rf "$index_dir"
    echo "ok: embeddings index removed"
    ;;
  search)
    if [[ -z "$query" ]]; then
      echo "ERROR: --query is required for search" >&2
      exit 2
    fi
    if [[ "$format" == "json" ]]; then
      printf '{"query":"%s","results":[]}\n' "$query"
    else
      echo "query: ${query}"
      echo "results: 0"
    fi
    ;;
  *)
    echo "ERROR: unknown command: ${command}" >&2
    usage >&2
    exit 2
    ;;
esac

exit 0
