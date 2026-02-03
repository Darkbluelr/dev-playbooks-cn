#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: platform-sync.sh <change-id> [options]

Platform Sync (Delivery hook): when platform_targets[] is configured, sync
platform artifacts (instructions/commands/rules/ignore) in an idempotent way.

Current supported targets:
  - claude: sync CLAUDE.md + .claude/agents + .claude/commands/devbooks from templates/
  - codex:  sync AGENTS.md from templates/ (or validate it exists)
  - cursor: sync .cursor/rules/* from templates/cursor-rules/
  - github-copilot: sync .github/copilot-instructions.md from templates/.github/copilot-instructions.md
  - gemini: sync GEMINI.md from templates/GEMINI.md

Targets discovery:
  - preferred: .devbooks/config.yaml platform_targets[] (via scripts/config-discovery.sh)
  - override:  --targets "<csv>"

Options:
  --project-root <dir>     Project root (default: pwd)
  --change-root <dir>      Change root (default: changes)
  --targets <csv>          Override targets (comma-separated)
  --out <path>             Output report path (default: evidence/gates/platform-sync.json)
  --dry-run                Do not write files; only report intended changes
  -h, --help               Show help

Exit codes:
  0 - success (or targets empty -> no-op)
  1 - failure (invalid config or sync errors)
  2 - usage error
EOF
}

errorf() {
  printf '%s\n' "ERROR: $*" >&2
}

if [[ $# -eq 0 ]]; then
  usage
  exit 2
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

change_id="$1"
shift

project_root="${DEVBOOKS_PROJECT_ROOT:-$(pwd)}"
change_root="${DEVBOOKS_CHANGE_ROOT:-changes}"
targets_csv="${DEVBOOKS_PLATFORM_TARGETS_CSV:-}"
truth_mapping_json=""
skill_injection_csv=""
out_path=""
dry_run=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --project-root)
      project_root="${2:-}"
      shift 2
      ;;
    --change-root)
      change_root="${2:-}"
      shift 2
      ;;
    --targets)
      targets_csv="${2:-}"
      shift 2
      ;;
    --out)
      out_path="${2:-}"
      shift 2
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    *)
      errorf "unknown option: $1"
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$change_id" || "$change_id" == "-"* || "$change_id" =~ [[:space:]] ]]; then
  errorf "invalid change-id: '$change_id'"
  exit 2
fi

project_root="${project_root%/}"
change_root="${change_root%/}"

if [[ "$change_root" = /* ]]; then
  change_root_dir="$change_root"
else
  change_root_dir="${project_root}/${change_root}"
fi

change_dir="${change_root_dir}/${change_id}"
if [[ ! -d "$change_dir" ]]; then
  errorf "change directory not found: ${change_dir}"
  exit 1
fi

mkdir -p "${change_dir}/evidence/gates"

out_file="${change_dir}/evidence/gates/platform-sync.json"
if [[ -n "$out_path" ]]; then
  if [[ "$out_path" = /* ]]; then
    out_file="$out_path"
  else
    out_file="${change_dir}/${out_path}"
  fi
fi

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

json_array() {
  local first=1
  local item
  printf '['
  for item in "$@"; do
    if [[ $first -eq 0 ]]; then
      printf ','
    fi
    first=0
    printf '"%s"' "$(json_escape "$item")"
  done
  printf ']'
}

timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

discover_targets_csv() {
  if [[ -n "$targets_csv" ]]; then
    return 0
  fi
  local discovery="${project_root}/scripts/config-discovery.sh"
  if [[ -f "$discovery" ]]; then
    local out
    out="$(bash "$discovery" "$project_root" 2>/dev/null || true)"
    targets_csv="$(printf '%s\n' "$out" | awk -F= '$1=="PLATFORM_TARGETS_CSV" && !found { print $2; found=1 }')"
    truth_mapping_json="$(printf '%s\n' "$out" | awk -F= '$1=="TRUTH_MAPPING_JSON" && !found { print $2; found=1 }')"
    skill_injection_csv="$(printf '%s\n' "$out" | awk -F= '$1=="SKILL_INJECTION_CSV" && !found { print $2; found=1 }')"

    # config-discovery outputs TRUTH_MAPPING_JSON as a single-quoted JSON string; keep only the inner JSON.
    if [[ -n "$truth_mapping_json" ]]; then
      truth_mapping_json="${truth_mapping_json#\'}"
      truth_mapping_json="${truth_mapping_json%\'}"
    fi
  fi
}

split_csv_to_lines() {
  local csv="$1"
  if [[ -z "$csv" ]]; then
    return 0
  fi
  IFS=',' read -r -a parts <<<"$csv"
  for part in "${parts[@]}"; do
    part="$(trim "$part")"
    [[ -n "$part" ]] || continue
    printf '%s\n' "$part"
  done
}

sync_file_if_needed() {
  local src="$1"
  local dst="$2"
  local rel="$3"
  local changed_ref="$4"

  if [[ ! -f "$src" ]]; then
    return 1
  fi

  if [[ -f "$dst" ]]; then
    if cmp -s "$src" "$dst"; then
      return 0
    fi
  fi

  if [[ "$dry_run" == true ]]; then
    printf '%s\n' "$rel" >>"$changed_ref"
    return 0
  fi

  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  printf '%s\n' "$rel" >>"$changed_ref"
  return 0
}

has_target() {
  local needle="$1"
  local t
  for t in "${targets[@]}"; do
    if [[ "$t" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

update_managed_block() {
  local file="$1"
  local rel="$2"
  local start_marker="$3"
  local end_marker="$4"
  local content_file="$5"
  local changed_ref="$6"

  if [[ "$dry_run" == true ]]; then
    printf '%s\n' "$rel" >>"$changed_ref"
    return 0
  fi

  local tmp
  tmp="$(mktemp -t devbooks_platform_sync_ignore.XXXXXX)"
  if [[ ! -f "$file" ]]; then
    cat "$content_file" >"$tmp"
    mv -f "$tmp" "$file"
    printf '%s\n' "$rel" >>"$changed_ref"
    return 0
  fi

  if grep -Fq "$start_marker" "$file" 2>/dev/null && grep -Fq "$end_marker" "$file" 2>/dev/null; then
    awk -v start="$start_marker" -v end="$end_marker" -v block_file="$content_file" '
      BEGIN { in_block=0 }
      $0==start { in_block=1; while ((getline line < block_file) > 0) print line; close(block_file); next }
      in_block==1 && $0==end { in_block=0; next }
      in_block==1 { next }
      { print }
    ' "$file" >"$tmp"
  else
    cat "$file" >"$tmp"
    printf '\n' >>"$tmp"
    cat "$content_file" >>"$tmp"
  fi

  if cmp -s "$file" "$tmp"; then
    rm -f "$tmp"
    return 0
  fi

  mv -f "$tmp" "$file"
  printf '%s\n' "$rel" >>"$changed_ref"
  return 0
}

write_ignore_block_file() {
  local out="$1"
  shift || true

  local start="$IGNORE_MARKERS_START"
  local end="$IGNORE_MARKERS_END"

  {
    echo "$start"
    while [[ $# -gt 0 ]]; do
      echo "$1"
      shift
    done
    echo "$end"
  } >"$out"
}

update_ignore_files_if_needed() {
  # Only enforce ignore syncing when targets are enabled.
  if [[ ${#targets[@]} -eq 0 ]]; then
    return 0
  fi

  local start="$IGNORE_MARKERS_START"
  local end="$IGNORE_MARKERS_END"

  local ignore_tmp
  ignore_tmp="$(mktemp -t devbooks_platform_sync_ignore_block.XXXXXX)"
  trap 'rm -f "$ignore_tmp" >/dev/null 2>&1 || true' RETURN

  local -a git_entries=()
  git_entries+=("# DevBooks 本地运行时数据（不应提交）")
  git_entries+=(".devbooks/embeddings/")
  git_entries+=(".devbooks/backup/")
  git_entries+=(".devbooks/*.log")
  git_entries+=("")
  git_entries+=("# AI 工具目录（按 platform_targets）")
  has_target "claude" && git_entries+=(".claude/")
  has_target "codex" && git_entries+=(".codex/")
  has_target "code" && git_entries+=(".code/")
  has_target "cursor" && git_entries+=(".cursor/")
  has_target "windsurf" && git_entries+=(".windsurf/")
  has_target "gemini" && git_entries+=(".gemini/")

  write_ignore_block_file "$ignore_tmp" "${git_entries[@]}"
  update_managed_block "${repo_root}/.gitignore" ".gitignore" "$start" "$end" "$ignore_tmp" "$changed_list" || true

  local -a npm_entries=()
  npm_entries+=("# DevBooks 开发文档（运行时不需要）")
  npm_entries+=("dev-playbooks/")
  npm_entries+=(".devbooks/")
  npm_entries+=("")
  npm_entries+=("# AI 工具配置目录")
  npm_entries+=(".claude/")
  npm_entries+=(".cursor/")
  npm_entries+=(".factory/")
  npm_entries+=(".windsurf/")
  npm_entries+=(".gemini/")
  npm_entries+=(".agent/")
  npm_entries+=(".opencode/")
  npm_entries+=(".continue/")
  npm_entries+=(".qoder/")
  npm_entries+=(".code/")
  npm_entries+=(".codex/")
  npm_entries+=(".github/instructions/")
  npm_entries+=(".github/copilot-instructions.md")
  npm_entries+=("")
  npm_entries+=("# DevBooks 指令文件")
  npm_entries+=("CLAUDE.md")
  npm_entries+=("AGENTS.md")
  npm_entries+=("GEMINI.md")

  write_ignore_block_file "$ignore_tmp" "${npm_entries[@]}"
  update_managed_block "${repo_root}/.npmignore" ".npmignore" "$start" "$end" "$ignore_tmp" "$changed_list" || true
}

update_runbook_block_if_needed() {
  local runbook="$1"
  local targets_line="$2"
  local changed_list_file="$3"

  local start="<!-- DEVBOOKS_PLATFORM_SYNC:START -->"
  local end="<!-- DEVBOOKS_PLATFORM_SYNC:END -->"

  if [[ ! -f "$runbook" ]]; then
    return 0
  fi

  local has_changes=false
  if [[ -s "$changed_list_file" ]]; then
    has_changes=true
  fi

  local block_file
  block_file="$(mktemp -t devbooks_platform_sync_block.XXXXXX)"
  {
    echo "$start"
    echo "- targets: ${targets_line}"
    if [[ "$has_changes" == true ]]; then
      echo "- synced_files:"
      while IFS= read -r f || [[ -n "$f" ]]; do
        [[ -n "$f" ]] || continue
        echo "  - ${f}"
      done <"$changed_list_file"
      echo "- note: changes applied only when templates differ"
    else
      echo "- synced_files: []"
      echo "- note: no changes (already up-to-date)"
    fi
    echo "$end"
  } >"$block_file"

  # Idempotency: only write block when:
  #  - block is missing, OR
  #  - there are actual changes.
  if ! grep -Fq "$start" "$runbook" 2>/dev/null; then
    if [[ "$dry_run" == true ]]; then
      rm -f "$block_file"
      return 0
    fi
    cat >>"$runbook" <<EOF

## Platform Sync

$(cat "$block_file")
EOF
    rm -f "$block_file"
    return 0
  fi

  if [[ "$has_changes" != true ]]; then
    rm -f "$block_file"
    return 0
  fi

  if [[ "$dry_run" == true ]]; then
    rm -f "$block_file"
    return 0
  fi

  # Replace existing block
  local tmp="${runbook}.tmp.$$"
  awk -v start="$start" -v end="$end" -v block_file="$block_file" '
    BEGIN { in_block=0; printed=0 }
    $0==start { in_block=1; while ((getline line < block_file) > 0) print line; close(block_file); printed=1; next }
    in_block==1 && $0==end { in_block=0; next }
    in_block==1 { next }
    { print }
    END { }
  ' "$runbook" >"$tmp"
  mv -f "$tmp" "$runbook"
  rm -f "$block_file"
}

discover_targets_csv

targets=()
while IFS= read -r t; do
  targets+=("$t")
done < <(split_csv_to_lines "$targets_csv")

checks=("targets")
artifacts=()
failure_reasons=()

required=false
if [[ ${#targets[@]} -gt 0 ]]; then
  required=true
fi

changed_list="$(mktemp -t devbooks_platform_sync_changes.XXXXXX)"
trap 'rm -f "$changed_list" >/dev/null 2>&1 || true' EXIT

targets_line=""
if [[ ${#targets[@]} -gt 0 ]]; then
  targets_line="$(IFS=,; echo "${targets[*]}")"
fi

repo_root="$project_root"

IGNORE_MARKERS_START="# DevBooks managed - DO NOT EDIT"
IGNORE_MARKERS_END="# End DevBooks managed"

for t in "${targets[@]}"; do
  case "$t" in
    claude)
      checks+=("claude")
      # Sync Claude agents and commands from templates
      if [[ ! -d "${repo_root}/templates/claude-agents" ]]; then
        failure_reasons+=("missing templates/claude-agents (required for claude target)")
        continue
      fi
      if [[ ! -d "${repo_root}/templates/claude-commands/devbooks" ]]; then
        failure_reasons+=("missing templates/claude-commands/devbooks (required for claude target)")
        continue
      fi

      while IFS= read -r src; do
        [[ -n "$src" ]] || continue
        rel_src="${src#${repo_root}/}"
        base="$(basename "$src")"
        dst="${repo_root}/.claude/agents/${base}"
        sync_file_if_needed "$src" "$dst" ".claude/agents/${base}" "$changed_list" || true
      done < <(find "${repo_root}/templates/claude-agents" -type f -name '*.md' 2>/dev/null | sort)

      while IFS= read -r src; do
        [[ -n "$src" ]] || continue
        rel="${src#${repo_root}/templates/claude-commands/}"
        dst="${repo_root}/.claude/commands/${rel}"
        sync_file_if_needed "$src" "$dst" ".claude/commands/${rel}" "$changed_list" || true
      done < <(find "${repo_root}/templates/claude-commands/devbooks" -type f -name '*.md' 2>/dev/null | sort)

      # Instruction file (optional template; fallback to existence check)
      if [[ -f "${repo_root}/templates/CLAUDE.md" ]]; then
        sync_file_if_needed "${repo_root}/templates/CLAUDE.md" "${repo_root}/CLAUDE.md" "CLAUDE.md" "$changed_list" || true
      elif [[ ! -f "${repo_root}/CLAUDE.md" ]]; then
        failure_reasons+=("missing CLAUDE.md (and templates/CLAUDE.md not found) for claude target")
      else
        artifacts+=("CLAUDE.md")
      fi
      ;;
    codex)
      checks+=("codex")
      # Instruction file (prefer template, fallback to existence check)
      if [[ -f "${repo_root}/templates/AGENTS.md" ]]; then
        sync_file_if_needed "${repo_root}/templates/AGENTS.md" "${repo_root}/AGENTS.md" "AGENTS.md" "$changed_list" || true
      elif [[ ! -f "${repo_root}/AGENTS.md" ]]; then
        failure_reasons+=("missing AGENTS.md (and templates/AGENTS.md not found) for codex target")
      else
        artifacts+=("AGENTS.md")
      fi
      ;;
    cursor)
      checks+=("cursor")
      if [[ ! -d "${repo_root}/templates/cursor-rules" ]]; then
        failure_reasons+=("missing templates/cursor-rules (required for cursor target)")
        continue
      fi
      if [[ "$dry_run" != true ]]; then
        mkdir -p "${repo_root}/.cursor/rules"
      fi
      while IFS= read -r src; do
        [[ -n "$src" ]] || continue
        rel="${src#${repo_root}/templates/cursor-rules/}"
        dst="${repo_root}/.cursor/rules/${rel}"
        sync_file_if_needed "$src" "$dst" ".cursor/rules/${rel}" "$changed_list" || true
      done < <(find "${repo_root}/templates/cursor-rules" -type f 2>/dev/null | sort)
      ;;
    github-copilot|copilot)
      checks+=("github-copilot")
      copilot_tpl="${repo_root}/templates/.github/copilot-instructions.md"
      copilot_dst="${repo_root}/.github/copilot-instructions.md"
      if [[ ! -f "$copilot_tpl" ]]; then
        failure_reasons+=("missing templates/.github/copilot-instructions.md (required for github-copilot target)")
        continue
      fi
      if [[ "$dry_run" != true ]]; then
        mkdir -p "${repo_root}/.github"
      fi
      sync_file_if_needed "$copilot_tpl" "$copilot_dst" ".github/copilot-instructions.md" "$changed_list" || true
      ;;
    gemini)
      checks+=("gemini")
      if [[ -f "${repo_root}/templates/GEMINI.md" ]]; then
        sync_file_if_needed "${repo_root}/templates/GEMINI.md" "${repo_root}/GEMINI.md" "GEMINI.md" "$changed_list" || true
      elif [[ ! -f "${repo_root}/GEMINI.md" ]]; then
        failure_reasons+=("missing GEMINI.md (and templates/GEMINI.md not found) for gemini target")
      else
        artifacts+=("GEMINI.md")
      fi
      ;;
    *)
      checks+=("unsupported:${t}")
      failure_reasons+=("unsupported platform target: ${t}")
      ;;
  esac
done

update_ignore_files_if_needed || true

# Update RUNBOOK summary block when needed.
update_runbook_block_if_needed "${change_dir}/RUNBOOK.md" "${targets_line:-}" "$changed_list"

status="pass"
if [[ ${#failure_reasons[@]} -gt 0 ]]; then
  status="fail"
fi

targets_json="[]"
if [[ ${#targets[@]} -gt 0 ]]; then
  targets_json="$(json_array "${targets[@]}")"
fi
checks_json="$(json_array "${checks[@]}")"
artifacts_json="[]"
if [[ ${#artifacts[@]} -gt 0 ]]; then
  artifacts_json="$(json_array "${artifacts[@]}")"
fi
reasons_json="[]"
if [[ ${#failure_reasons[@]} -gt 0 ]]; then
  reasons_json="$(json_array "${failure_reasons[@]}")"
fi

changed_files=()
if [[ -s "$changed_list" ]]; then
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    changed_files+=("$f")
  done <"$changed_list"
fi
changed_json="[]"
if [[ ${#changed_files[@]} -gt 0 ]]; then
  changed_json="$(json_array "${changed_files[@]}")"
fi

tmp="${out_file}.tmp.$$"
cat >"$tmp" <<EOF
{
  "schema_version": "1.0.0",
  "gate_id": "G2",
  "mode": "start",
  "check_id": "platform-sync",
  "status": "$(json_escape "$status")",
  "timestamp": "$(json_escape "$(timestamp)")",
  "inputs": {
    "change_id": "$(json_escape "$change_id")",
    "required": $( [[ "$required" == true ]] && echo "true" || echo "false" ),
    "targets": ${targets_json},
    "dry_run": $( [[ "$dry_run" == true ]] && echo "true" || echo "false" ),
    "truth_mapping_json": "$(json_escape "$truth_mapping_json")",
    "skill_injection_csv": "$(json_escape "$skill_injection_csv")"
  },
  "checks": ${checks_json},
  "artifacts": ${artifacts_json},
  "changed_files": ${changed_json},
  "failure_reasons": ${reasons_json},
  "next_action": "DevBooks"
}
EOF
mv -f "$tmp" "$out_file"

if [[ "$status" != "pass" ]]; then
  errorf "platform sync failed: $out_file"
  printf '%s\n' "${failure_reasons[@]}" >&2
  exit 1
fi

exit 0
