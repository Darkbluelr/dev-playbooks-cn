#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: detect-mcp.sh [--dry-run]

Detect MCP server configuration from local user config files.

Environment:
  MCP_CONFIG_PATH  Override config file path (JSON).

Output:
  Writes key=value lines. Always exits 0 in --dry-run mode.
EOF
}

dry_run=false

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ "${1:-}" == "--dry-run" ]]; then
  dry_run=true
  shift
fi

if [[ $# -gt 0 ]]; then
  usage
  exit 2
fi

config_path="${MCP_CONFIG_PATH:-}"

if [[ -z "$config_path" ]]; then
  for candidate in \
    "${HOME}/.claude.json" \
    "${HOME}/.claude/mcp.json"; do
    if [[ -f "$candidate" ]]; then
      config_path="$candidate"
      break
    fi
  done
fi

echo "mcp_detected=false"

if [[ -z "$config_path" ]]; then
  echo "mcp_config_path="
  echo "mcp_server_count=0"
  echo "mcp_note=no_config_found"
  exit 0
fi

echo "mcp_config_path=${config_path}"

if [[ ! -f "$config_path" ]]; then
  echo "mcp_server_count=0"
  echo "mcp_note=config_not_found"
  exit 0
fi

if command -v jq >/dev/null 2>&1; then
  servers="$(jq -r '(.mcpServers // {}) | keys[]' "$config_path" 2>/dev/null || true)"
  if [[ -z "$servers" ]]; then
    echo "mcp_server_count=0"
    echo "mcp_note=no_mcpServers_key"
    exit 0
  fi

  count="$(printf "%s\n" "$servers" | wc -l | tr -d ' ')"
  echo "mcp_detected=true"
  echo "mcp_server_count=${count}"
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    echo "mcp_server=${name}"
  done <<<"$servers"
  exit 0
fi

echo "mcp_server_count=0"
echo "mcp_note=jq_not_found"
exit 0

