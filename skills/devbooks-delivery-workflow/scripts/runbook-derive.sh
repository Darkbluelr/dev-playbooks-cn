#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: runbook-derive.sh <change-id> [--project-root <dir>] [--change-root <dir>] [--truth-root <dir>] [--dry-run]

从 SSOT + 变更包元数据派生（可丢弃可重建的缓存）并写回 RUNBOOK：
  - Cover View（封面视图）
  - Context Capsule（自动派生块，仅写入 RUNBOOK，不新增 context-capsule.md）

默认（可用 env 覆盖）：
  DEVBOOKS_PROJECT_ROOT: pwd
  DEVBOOKS_CHANGE_ROOT:  changes
  DEVBOOKS_TRUTH_ROOT:   specs

输出：
  <change-root>/<change-id>/RUNBOOK.md（插入/更新两个 managed block）

注意：
  - 这是派生缓存：允许过期，允许删除；但必须可通过本脚本重建。
  - 脚本不要求 yq；仅使用 bash/awk/sed/grep。
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

CHANGE_ID="$1"
shift

PROJECT_ROOT="${DEVBOOKS_PROJECT_ROOT:-$(pwd)}"
CHANGE_ROOT="${DEVBOOKS_CHANGE_ROOT:-changes}"
TRUTH_ROOT="${DEVBOOKS_TRUTH_ROOT:-specs}"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --project-root)
      PROJECT_ROOT="${2:-}"
      shift 2
      ;;
    --change-root)
      CHANGE_ROOT="${2:-}"
      shift 2
      ;;
    --truth-root)
      TRUTH_ROOT="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if [[ -z "${CHANGE_ID}" || "${CHANGE_ID}" == "-"* || "${CHANGE_ID}" =~ [[:space:]] ]]; then
  echo "error: invalid change-id: '${CHANGE_ID}'" >&2
  exit 2
fi

PROJECT_ROOT="${PROJECT_ROOT%/}"
CHANGE_ROOT="${CHANGE_ROOT%/}"
TRUTH_ROOT="${TRUTH_ROOT%/}"

timestamp_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# 读取嵌套键（一层深度）：parent.key
yaml_get_nested_value() {
  local file="$1" parent="$2" key="$3"
  awk -v parent="$parent" -v key="$key" '
    $0 ~ "^" parent ":" { in_parent = 1; next }
    in_parent && /^[a-zA-Z0-9_]/ { in_parent = 0 }
    in_parent && $0 ~ "^  " key ":" {
      gsub(/^[^:]*: */, "")
      gsub(/["'"'"']/, "")
      print
      exit
    }
  ' "$file" 2>/dev/null || true
}

extract_backticks() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  awk '
    {
      line=$0
      while (match(line, /`[^`]+`/)) {
        s=substr(line, RSTART+1, RLENGTH-2)
        print s
        line=substr(line, RSTART+RLENGTH)
      }
    }
  ' "$file" 2>/dev/null || true
}

registry_has_schema_version() {
  local registry="$1"
  [[ -f "$registry" ]] || return 1
  awk -F: '/^schema_version:/ { gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); gsub(/["'"'"']/, "", $2); if ($2 != "") { exit 0 } } END { exit 1 }' "$registry" 2>/dev/null
}

registry_has_capability() {
  local registry="$1" capability_id="$2"
  [[ -f "$registry" ]] || return 1
  grep -Eq "^  ${capability_id}:[[:space:]]*$" "$registry" 2>/dev/null
}

registry_capability_path() {
  local registry="$1" capability_id="$2"
  [[ -f "$registry" ]] || return 0
  awk -v id="$capability_id" '
    $0 ~ "^  " id ":[[:space:]]*$" { in_block=1; next }
    in_block && $0 ~ "^  [a-zA-Z0-9_-]+:[[:space:]]*$" { exit }
    in_block && $0 ~ "^    path:" {
      line=$0
      sub("^[^:]*:[[:space:]]*", "", line)
      gsub(/["'"'"']/, "", line)
      print line
      exit
    }
  ' "$registry" 2>/dev/null || true
}

ensure_file_ends_with_newline() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  # shellcheck disable=SC2016
  if [[ "$(tail -c 1 "$file" 2>/dev/null || true)" != $'\n' ]]; then
    printf '\n' >>"$file"
  fi
}

replace_managed_block() {
  local file="$1"
  local start_marker="$2"
  local end_marker="$3"
  local block_file="$4"

  local tmp="${file}.tmp.$$"
  awk -v start="$start_marker" -v end="$end_marker" -v block_file="$block_file" '
    BEGIN { in_block=0; replaced=0 }
    $0==start {
      in_block=1
      while ((getline line < block_file) > 0) print line
      close(block_file)
      replaced=1
      next
    }
    in_block==1 && $0==end { in_block=0; next }
    in_block==1 { next }
    { print }
    END { }
  ' "$file" >"$tmp"
  mv -f "$tmp" "$file"
  return 0
}

insert_block_after_heading() {
  local file="$1"
  local heading_prefix="$2"
  local block_file="$3"

  local tmp="${file}.tmp.$$"
  awk -v heading="$heading_prefix" -v block_file="$block_file" '
    BEGIN { inserted=0 }
    $0 ~ "^" heading {
      print
      if (inserted==0) {
        print ""
        while ((getline line < block_file) > 0) print line
        close(block_file)
        inserted=1
      }
      next
    }
    { print }
    END {
      if (inserted==0) {
        print ""
        while ((getline line < block_file) > 0) print line
        close(block_file)
      }
    }
  ' "$file" >"$tmp"
  mv -f "$tmp" "$file"
  return 0
}

insert_section_before_heading() {
  local file="$1"
  local target_heading_prefix="$2"
  local section_file="$3"

  local tmp="${file}.tmp.$$"
  awk -v heading="$target_heading_prefix" -v section_file="$section_file" '
    BEGIN { inserted=0 }
    $0 ~ "^" heading && inserted==0 {
      while ((getline line < section_file) > 0) print line
      close(section_file)
      inserted=1
    }
    { print }
    END {
      if (inserted==0) {
        print ""
        while ((getline line < section_file) > 0) print line
        close(section_file)
      }
    }
  ' "$file" >"$tmp"
  mv -f "$tmp" "$file"
  return 0
}

if [[ "$CHANGE_ROOT" = /* ]]; then
  CHANGE_DIR="${CHANGE_ROOT}/${CHANGE_ID}"
else
  CHANGE_DIR="${PROJECT_ROOT}/${CHANGE_ROOT}/${CHANGE_ID}"
fi

if [[ "$TRUTH_ROOT" = /* ]]; then
  TRUTH_DIR="$TRUTH_ROOT"
else
  TRUTH_DIR="${PROJECT_ROOT}/${TRUTH_ROOT}"
fi

RUNBOOK_PATH="${CHANGE_DIR}/RUNBOOK.md"
CONTRACT_PATH="${CHANGE_DIR}/completion.contract.yaml"

if [[ ! -f "$RUNBOOK_PATH" ]]; then
  echo "error: missing RUNBOOK: ${RUNBOOK_PATH}" >&2
  echo "hint: run change-scaffold.sh first" >&2
  exit 2
fi

CAP_REGISTRY="${TRUTH_DIR}/_meta/capabilities.yaml"
PROJECT_PROFILE="${TRUTH_DIR}/_meta/project-profile.md"
MODULE_GRAPH="${TRUTH_DIR}/architecture/module-graph.md"

CHANGE_DIR_DISPLAY="${CHANGE_ROOT}/${CHANGE_ID}"
TRUTH_DIR_DISPLAY="${TRUTH_ROOT}/"
PROJECT_PROFILE_DISPLAY="${TRUTH_ROOT}/_meta/project-profile.md"
FILE_SYSTEM_DISPLAY="${TRUTH_ROOT}/architecture/file-system.md"
MODULE_GRAPH_DISPLAY="${TRUTH_ROOT}/architecture/module-graph.md"
KEY_CONCEPTS_DISPLAY="${TRUTH_ROOT}/_meta/key-concepts.md"
CAP_REGISTRY_DISPLAY="${TRUTH_ROOT}/_meta/capabilities.yaml"
GLOSSARY_DISPLAY="${TRUTH_ROOT}/_meta/glossary.md"

DERIVE_TS="$(timestamp_utc)"

intent_summary=""
deliverable_quality=""
if [[ -f "$CONTRACT_PATH" ]]; then
  intent_summary="$(yaml_get_nested_value "$CONTRACT_PATH" "intent" "summary" || true)"
  deliverable_quality="$(yaml_get_nested_value "$CONTRACT_PATH" "intent" "deliverable_quality" || true)"
fi

entry_points=()
if [[ -f "$PROJECT_PROFILE" ]]; then
  while IFS= read -r v; do
    [[ -n "$v" ]] || continue
    # 只收集“像入口”的命令/路径（避免把无关 token 当入口）
    case "$v" in
      ./*|scripts/*|skills/*|tools/*|docs/*|dev-playbooks/*|mcp/*|templates/*|cd\ *)
        entry_points+=("$v")
        ;;
      *)
        ;;
    esac
  done < <(extract_backticks "$PROJECT_PROFILE" | awk 'NF{print}' | awk '!seen[$0]++' | head -n 6)
fi

if [[ ${#entry_points[@]} -eq 0 && -f "$MODULE_GRAPH" ]]; then
  while IFS= read -r v; do
    [[ -n "$v" ]] || continue
    case "$v" in
      ./*|scripts/*|skills/*|tools/*|docs/*|dev-playbooks/*|mcp/*|templates/*|cd\ *)
        entry_points+=("$v")
        ;;
      *)
        ;;
    esac
  done < <(extract_backticks "$MODULE_GRAPH" | awk 'NF{print}' | awk '!seen[$0]++' | head -n 6)
fi

if [[ ${#entry_points[@]} -gt 3 ]]; then
  entry_points=("${entry_points[@]:0:3}")
fi

core_capabilities=("delivery" "ssot" "change-package" "quality-gates" "sync-protocol" "traceability" "protocol-discovery" "skills-integration")
selected_capabilities=()
if registry_has_schema_version "$CAP_REGISTRY"; then
  for cap in "${core_capabilities[@]}"; do
    if registry_has_capability "$CAP_REGISTRY" "$cap"; then
      selected_capabilities+=("$cap")
    fi
  done
else
  selected_capabilities=("${core_capabilities[@]}")
fi

# 保底：至少 3 个
if [[ ${#selected_capabilities[@]} -lt 3 ]]; then
  fallback_caps=("protocol-core" "config-protocol" "change-types" "completion-contract-checker")
  for cap in "${fallback_caps[@]}"; do
    [[ ${#selected_capabilities[@]} -ge 3 ]] && break
    if registry_has_schema_version "$CAP_REGISTRY"; then
      registry_has_capability "$CAP_REGISTRY" "$cap" && selected_capabilities+=("$cap")
    else
      selected_capabilities+=("$cap")
    fi
  done
fi

# 硬约束：Cover View 的主干 capability 数必须保持在 3–7（超出即截断，确保可读性与稳定性）。
if [[ ${#selected_capabilities[@]} -gt 7 ]]; then
  selected_capabilities=("${selected_capabilities[@]:0:7}")
fi

dependency_edges=()
if [[ -f "$MODULE_GRAPH" ]]; then
  while IFS= read -r v; do
    [[ -n "$v" ]] || continue
    dependency_edges+=("$v")
  done < <(
    awk '
      {
        line=$0
        sub(/\r$/, "", line)
      }
      line ~ /→|->/ {
        gsub(/`/, "", line)
        sub(/^[[:space:]]*[-*][[:space:]]*/, "", line)
        sub(/^[[:space:]]*[0-9][0-9]*[.)][[:space:]]*/, "", line)
        gsub(/->/, "→", line)
        print line
      }
    ' "$MODULE_GRAPH" 2>/dev/null | awk 'NF{ $1=$1; print }' | awk '!seen[$0]++' | head -n 6
  )
fi

cover_start="<!-- DEVBOOKS_DERIVED_COVER_VIEW:START -->"
cover_end="<!-- DEVBOOKS_DERIVED_COVER_VIEW:END -->"
capsule_start="<!-- DEVBOOKS_DERIVED_CONTEXT_CAPSULE:START -->"
capsule_end="<!-- DEVBOOKS_DERIVED_CONTEXT_CAPSULE:END -->"

cover_block="$(mktemp -t devbooks_cover_view.XXXXXX)"
trap 'rm -f "$cover_block" >/dev/null 2>&1 || true' EXIT

{
  echo "$cover_start"
  echo "> 派生缓存（可丢弃可重建）。生成时间：${DERIVE_TS}。生成入口：\`skills/devbooks-delivery-workflow/scripts/runbook-derive.sh ${CHANGE_ID} --project-root ${PROJECT_ROOT} --change-root ${CHANGE_ROOT} --truth-root ${TRUTH_ROOT}\`"
  echo "> SSOT 来源（允许范围）：\`${PROJECT_PROFILE_DISPLAY}\`、\`${FILE_SYSTEM_DISPLAY}\`、\`${MODULE_GRAPH_DISPLAY}\`、\`${KEY_CONCEPTS_DISPLAY}\`、\`${CAP_REGISTRY_DISPLAY}\`"
  echo ""
  echo "### Entry（入口）"
  if [[ ${#entry_points[@]} -gt 0 ]]; then
    for ep in "${entry_points[@]}"; do
      echo "- \`${ep}\`"
    done
  else
    echo "- （未能从 SSOT 提取入口；请在 \`${PROJECT_PROFILE_DISPLAY}\` 补齐入口示例后再派生）"
  fi
  echo ""
  echo "### Main Capabilities（主干，3–7）"
  for cap in "${selected_capabilities[@]}"; do
    cap_path="$(registry_capability_path "$CAP_REGISTRY" "$cap")"
    if [[ -n "$cap_path" ]]; then
      echo "- \`${cap}\`（canonical: \`${cap_path}\`）"
    else
      echo "- \`${cap}\`"
    fi
  done
  echo ""
  echo "### Forbidden（禁区）"
  echo "- 禁止直写真理源：\`${TRUTH_DIR_DISPLAY}\`（必须走 Draft→Staged→Truth 同步）"
  echo "- 禁止把实现/证据写入控制面目录（只在变更包内写入 \`${CHANGE_DIR_DISPLAY}/\`）"
  echo ""
  echo "### Dependency Direction（依赖方向，压缩）"
  if [[ ${#dependency_edges[@]} -gt 0 ]]; then
    for edge in "${dependency_edges[@]}"; do
      echo "- ${edge}"
    done
  else
    echo "- （未能从 \`${MODULE_GRAPH_DISPLAY}\` 提取依赖方向；请在该文件补齐 \"A → B\" 的最小依赖边）"
  fi
  echo ""
  echo "### Artifact Flow（工件流）"
  echo "- 变更包（\`${CHANGE_DIR_DISPLAY}/\`）→ 校验/闸门 → \`evidence/green-final\` / \`evidence/gates\` / \`evidence/risks\` → G6 裁决/归档"
  echo "$cover_end"
} >"$cover_block"

capsule_block="$(mktemp -t devbooks_context_capsule.XXXXXX)"
{
  echo "$capsule_start"
  echo "> 自动派生块（可丢弃可重建，禁止当作 SSOT）。生成时间：${DERIVE_TS}。生成入口：\`skills/devbooks-delivery-workflow/scripts/runbook-derive.sh ${CHANGE_ID} ...\`"
  echo ""
  echo "- 1) summary（对齐 \`completion.contract.yaml: intent.summary\`）：${intent_summary:-<missing>}"
  if [[ -n "${deliverable_quality}" ]]; then
    echo "- deliverable_quality：${deliverable_quality}"
  fi
  echo "- 2) 不可变约束（示例，必要时补充/删减）："
  echo "  - 必须遵守 \`dev-playbooks/constitution.md\`（Role Isolation / Test Immutability / SSOT）"
  echo "  - 必须遵循术语约束：\`${GLOSSARY_DISPLAY}\`"
  echo "- 3) 影响边界（默认）："
  echo "  - Allowed: \`${CHANGE_DIR_DISPLAY}/\`（变更包产物与证据）"
  echo "  - Forbidden: \`${TRUTH_DIR_DISPLAY}\`（禁止直写 SSOT；需用 spec-stage/spec-promote）"
  echo "- 4) 必跑验证锚点（起步最小集合；以 RUNBOOK 与合同为准）："
  echo "  - \`skills/devbooks-delivery-workflow/scripts/change-check.sh ${CHANGE_ID} --project-root ${PROJECT_ROOT} --change-root ${CHANGE_ROOT} --truth-root ${TRUTH_ROOT} --mode strict\`"
  echo "- 5) 默认检索路线（必看最小闭包）："
  echo "  - Entry：\`RUNBOOK.md\`、\`completion.contract.yaml\`"
  echo "  - Config：\`.devbooks/config.yaml\`、\`dev-playbooks/constitution.md\`、\`${GLOSSARY_DISPLAY}\`"
  echo "  - Scripts：\`scripts/\`、\`skills/devbooks-delivery-workflow/scripts/\`"
  echo "  - Templates：\`templates/dev-playbooks/changes/\`"
  echo "  - SSOT：\`${TRUTH_DIR_DISPLAY}\`（尤其是 \`${PROJECT_PROFILE_DISPLAY}\`）"
  echo "- 6) 偷懒路径黑名单（默认）："
  echo "  - 不允许跳过 G6 裁决/归档链路就宣布完成"
  echo "  - 不允许把长日志/长输出粘贴到 Context Capsule（只写索引与约束）"
  echo "  - 不允许直写 \`${TRUTH_DIR_DISPLAY}\` 作为更新规格"
  echo "$capsule_end"
} >"$capsule_block"

if [[ "$DRY_RUN" == true ]]; then
  echo "[DRY-RUN] Would update: ${RUNBOOK_PATH}" >&2
  echo "" >&2
  echo "===== Cover View Block =====" >&2
  cat "$cover_block" >&2
  echo "" >&2
  echo "===== Context Capsule Block =====" >&2
  cat "$capsule_block" >&2
  rm -f "$capsule_block"
  exit 0
fi

ensure_file_ends_with_newline "$RUNBOOK_PATH"

# 1) Cover View：若已存在 managed block 则替换；否则插入到 Context Capsule 之前。
if grep -Fq "$cover_start" "$RUNBOOK_PATH" 2>/dev/null && grep -Fq "$cover_end" "$RUNBOOK_PATH" 2>/dev/null; then
  replace_managed_block "$RUNBOOK_PATH" "$cover_start" "$cover_end" "$cover_block"
else
  cover_section="$(mktemp -t devbooks_cover_section.XXXXXX)"
  {
    echo "## Cover View（派生缓存，可丢弃可重建）"
    echo ""
    cat "$cover_block"
    echo ""
  } >"$cover_section"
  insert_section_before_heading "$RUNBOOK_PATH" "## Context Capsule" "$cover_section"
  rm -f "$cover_section"
fi

# 2) Context Capsule：只更新/插入自动派生 block，不触碰后续人工模板。
if grep -Fq "$capsule_start" "$RUNBOOK_PATH" 2>/dev/null && grep -Fq "$capsule_end" "$RUNBOOK_PATH" 2>/dev/null; then
  replace_managed_block "$RUNBOOK_PATH" "$capsule_start" "$capsule_end" "$capsule_block"
else
  insert_block_after_heading "$RUNBOOK_PATH" "## Context Capsule" "$capsule_block"
fi

rm -f "$capsule_block"
exit 0
