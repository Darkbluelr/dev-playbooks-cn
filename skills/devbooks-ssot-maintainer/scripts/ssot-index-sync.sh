#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
用法: ssot-index-sync.sh [options]

应用一个最小 ssot delta 文件，确定性地更新 requirements.index.yaml。

选项:
  --project-root <dir>     项目根目录（默认: pwd）
  --truth-root <dir>       真理根目录（fallback；默认: specs）
  --change-root <dir>      变更包根目录（--refresh-ledger 时使用；默认: changes）
  --delta <path>           inputs/ssot.delta.yaml 路径（必填）
  --set-ref <truth://...>  覆盖 target_set_ref（默认: 取 delta；fallback: truth://ssot/requirements.index.yaml）
  --apply                  执行写入（默认仅 dry-run 摘要）
  --refresh-ledger         同步后刷新 requirements.ledger.yaml（派生缓存）
  -h, --help               显示帮助

Delta 合同（支持子集）:
  schema_version: 1.0.0
  target_set_ref: truth://ssot/requirements.index.yaml   # 可选
  ops:
    - op: add|update|remove
      id: <add 可选；update/remove 必填>
      severity: must|should            # 可选
      anchor: "<path>#<anchor>"        # 可选
      statement: "<单行文本>"          # add 必填；update 可选

注意:
- 无外部依赖（不需要 yq）。字段必须是单行标量。
- 失败是非破坏性的：脚本会拒绝写坏已有索引。
EOF
}

die_usage() {
  echo "error: $*" >&2
  usage
  exit 2
}

project_root="${DEVBOOKS_PROJECT_ROOT:-$(pwd)}"
truth_root="${DEVBOOKS_TRUTH_ROOT:-specs}"
change_root="${DEVBOOKS_CHANGE_ROOT:-changes}"
delta_path=""
set_ref_override=""
apply=false
refresh_ledger=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --project-root) project_root="${2:-}"; shift 2 ;;
    --truth-root) truth_root="${2:-}"; shift 2 ;;
    --change-root) change_root="${2:-}"; shift 2 ;;
    --delta) delta_path="${2:-}"; shift 2 ;;
    --set-ref) set_ref_override="${2:-}"; shift 2 ;;
    --apply) apply=true; shift ;;
    --refresh-ledger) refresh_ledger=true; shift ;;
    *) die_usage "未知选项: $1" ;;
  esac
done

project_root="${project_root%/}"
truth_root="${truth_root%/}"
change_root="${change_root%/}"

if [[ -z "$project_root" ]]; then
  die_usage "必须提供 --project-root"
fi
if [[ -z "$delta_path" ]]; then
  die_usage "必须提供 --delta"
fi

if [[ "$delta_path" != /* ]]; then
  delta_path="${project_root}/${delta_path}"
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/ssot-delta.sh
source "${script_dir}/lib/ssot-delta.sh"

discovery="${project_root}/scripts/config-discovery.sh"
truth_dir=""
change_dir_root=""
truth_mapping_json=""

if [[ -f "$discovery" ]]; then
  truth_dir="$(bash "$discovery" "$project_root" 2>/dev/null | awk -F= '$1=="SPECS_DIR" && !found { print $2; found=1 }')"
  change_dir_root="$(bash "$discovery" "$project_root" 2>/dev/null | awk -F= '$1=="CHANGES_DIR" && !found { print $2; found=1 }')"
  truth_mapping_json="$(bash "$discovery" "$project_root" 2>/dev/null | awk -F= '$1=="TRUTH_MAPPING_JSON" && !found { print $2; found=1 }')"
fi

if [[ -z "$truth_dir" ]]; then
  if [[ "$truth_root" = /* ]]; then
    truth_dir="$truth_root"
  else
    truth_dir="${project_root}/${truth_root}"
  fi
else
  if [[ "$truth_dir" != /* ]]; then
    truth_dir="${project_root}/${truth_dir}"
  fi
fi

if [[ -z "$change_dir_root" ]]; then
  if [[ "$change_root" = /* ]]; then
    change_dir_root="$change_root"
  else
    change_dir_root="${project_root}/${change_root}"
  fi
else
  if [[ "$change_dir_root" != /* ]]; then
    change_dir_root="${project_root}/${change_dir_root}"
  fi
fi

extract_top_scalar() {
  local file="$1"
  local key="$2"
  awk -v k="$key" '
    $0 ~ "^" k ":[[:space:]]*" {
      line=$0
      sub("^" k ":[[:space:]]*", "", line)
      sub(/[[:space:]]+#.*$/, "", line)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      gsub(/^["'"'"']|["'"'"']$/, "", line)
      print line
      exit 0
    }
  ' "$file" 2>/dev/null || true
}

index_schema_ok() {
  local file="$1"
  local v
  v="$(extract_top_scalar "$file" "schema_version")"
  [[ "$v" == "1.0.0" ]]
}

collect_index_ids() {
  local file="$1"
  awk '
    BEGIN { in_req=0 }
    {
      line=$0
      sub(/\r$/, "", line)
      if (line ~ /^[ \t]*#/) next
      if (!in_req && line ~ /^requirements:[ \t]*$/) { in_req=1; next }
      if (in_req && line ~ /^[^ \t-][A-Za-z0-9_.-]*:/) { exit }
      if (!in_req) next
      if (line ~ /^[ \t]*-[ \t]*id:[ \t]*/) {
        v=line
        sub(/^[ \t]*-[ \t]*id:[ \t]*/, "", v)
        sub(/[ \t]+#.*$/, "", v)
        gsub(/^[ \t]+|[ \t]+$/, "", v)
        gsub(/^["'"'"']|["'"'"']$/, "", v)
        if (v != "") print v
      }
    }
  ' "$file" 2>/dev/null
}

default_set_ref="truth://ssot/requirements.index.yaml"

meta_schema=""
meta_target=""

tmp_ops="$(mktemp)"
cleanup() {
  rm -f "$tmp_ops" >/dev/null 2>&1 || true
}
trap cleanup EXIT

existing_ids_pipe="|"
max_r_num=0

set_ref="${default_set_ref}"

while IFS=$'\x1f' read -r rec a b c d e f g h i j; do
  case "$rec" in
    META)
      if [[ "$a" == "SCHEMA_VERSION" ]]; then
        meta_schema="${b:-}"
      elif [[ "$a" == "TARGET_SET_REF" ]]; then
        meta_target="${b:-}"
      fi
      ;;
  esac
done < <(sd_parse_delta_tsv "$delta_path")

if [[ "$meta_schema" != "1.0.0" ]]; then
  die_usage "ssot.delta.yaml 的 schema_version 必须为 1.0.0（实际: ${meta_schema:-<empty>}）"
fi

if [[ -n "$set_ref_override" ]]; then
  set_ref="$set_ref_override"
elif [[ -n "$meta_target" ]]; then
  set_ref="$meta_target"
fi

if [[ "$set_ref" != truth://*requirements.index.yaml && "$set_ref" != truth://*requirements.index.yml ]]; then
  die_usage "--set-ref/target_set_ref 必须以 requirements.index.yaml|yml 结尾（实际: ${set_ref}）"
fi

set_rel="${set_ref#truth://}"
set_rel="${set_rel#/}"
index_file="${truth_dir%/}/${set_rel}"

if [[ ! -f "$index_file" ]]; then
  die_usage "未找到 requirements.index: ${set_ref}（解析到: ${index_file}）"
fi
if ! index_schema_ok "$index_file"; then
  die_usage "requirements.index 的 schema_version 必须为 1.0.0: ${index_file}"
fi

while IFS= read -r rid; do
  [[ -n "$rid" ]] || continue
  existing_ids_pipe="${existing_ids_pipe}${rid}|"
  if [[ "$rid" =~ ^R-([0-9]+)$ ]]; then
    num="${BASH_REMATCH[1]}"
    # Avoid octal; treat as base-10.
    num=$((10#${num}))
    if (( num > max_r_num )); then
      max_r_num="$num"
    fi
  fi
done < <(collect_index_ids "$index_file")

new_ids_pipe="|"
op_count=0

append_op() {
  local op="$1"
  local id="$2"
  local severity="$3"
  local anchor="$4"
  local statement="$5"
  local has_sev="$6"
  local has_anchor="$7"
  local has_stmt="$8"

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$op" "$id" "$severity" "$anchor" "$statement" "$has_sev" "$has_anchor" "$has_stmt" >>"$tmp_ops"
  op_count=$((op_count + 1))
}

validate_no_tabs() {
  local label="$1"
  local value="$2"
  if [[ "$value" == *$'\t'* ]]; then
    die_usage "${label} 不能包含 tab 字符"
  fi
}

# Parse ops again and build normalized operations (with auto IDs resolved).
while IFS=$'\x1f' read -r rec op id severity anchor statement title has_sev has_anchor has_stmt has_title; do
  [[ "$rec" == "OP" ]] || continue

  op="$(printf '%s' "${op:-}" | tr '[:upper:]' '[:lower:]')"
  id="${id:-}"
  severity="$(printf '%s' "${severity:-}" | tr '[:upper:]' '[:lower:]')"
  anchor="${anchor:-}"
  statement="${statement:-}"
  has_sev="${has_sev:-0}"
  has_anchor="${has_anchor:-0}"
  has_stmt="${has_stmt:-0}"

  validate_no_tabs "id" "$id"
  validate_no_tabs "anchor" "$anchor"
  validate_no_tabs "statement" "$statement"

  case "$op" in
    add|update|remove) ;;
    "") die_usage "每个 delta item 都必须提供 op" ;;
    *) die_usage "不支持的 op: ${op}" ;;
  esac

  case "$op" in
    remove)
      if [[ -z "$id" ]]; then
        die_usage "remove 操作必须提供 id"
      fi
      if [[ "$existing_ids_pipe" != *"|${id}|"* ]]; then
        die_usage "remove 的 id 不存在于 requirements.index: ${id}"
      fi
      append_op "remove" "$id" "" "" "" "0" "0" "0"
      ;;
    update)
      if [[ -z "$id" ]]; then
        die_usage "update 操作必须提供 id"
      fi
      if [[ "$existing_ids_pipe" != *"|${id}|"* ]]; then
        die_usage "update 的 id 不存在于 requirements.index: ${id}"
      fi
      if [[ "$has_sev" != "1" && "$has_anchor" != "1" && "$has_stmt" != "1" ]]; then
        die_usage "update 操作至少要指定 severity/anchor/statement 之一：id=${id}"
      fi
      if [[ "$has_sev" == "1" ]]; then
        case "$severity" in
          must|should) ;;
          "") die_usage "update 已提供 severity 但值为空：id=${id}" ;;
          *) die_usage "update 的 severity 不合法（must|should）：id=${id} severity=${severity}" ;;
        esac
      fi
      if [[ "$has_stmt" == "1" && -z "$statement" ]]; then
        die_usage "update 已提供 statement 但值为空：id=${id}"
      fi
      append_op "update" "$id" "$severity" "$anchor" "$statement" "$has_sev" "$has_anchor" "$has_stmt"
      ;;
    add)
      # Default severity for add is must.
      if [[ -z "$id" ]]; then
        max_r_num=$((max_r_num + 1))
        id="R-$(printf '%03d' "$max_r_num")"
      fi
      if [[ "$existing_ids_pipe" == *"|${id}|"* || "$new_ids_pipe" == *"|${id}|"* ]]; then
        die_usage "add 的 id 已存在：${id}"
      fi
      new_ids_pipe="${new_ids_pipe}${id}|"

      if [[ "$has_sev" == "1" ]]; then
        case "$severity" in
          must|should) ;;
          "") die_usage "add 已提供 severity 但值为空：id=${id}" ;;
          *) die_usage "add 的 severity 不合法（must|should）：id=${id} severity=${severity}" ;;
        esac
      else
        severity="must"
        has_sev="1"
      fi

      if [[ "$has_stmt" != "1" || -z "$statement" ]]; then
        die_usage "add 操作必须提供 statement：id=${id}"
      fi

      append_op "add" "$id" "$severity" "$anchor" "$statement" "$has_sev" "1" "1"
      ;;
  esac
done < <(sd_parse_delta_tsv "$delta_path")

if [[ "$op_count" -eq 0 ]]; then
  die_usage "delta 中没有找到任何 ops：${delta_path}"
fi

echo "info: SSOT 索引同步" >&2
echo "  项目根目录: ${project_root}" >&2
echo "  真理目录:   ${truth_dir}" >&2
echo "  set_ref:    ${set_ref}" >&2
echo "  索引文件:   ${index_file}" >&2
echo "  ops 数量:   ${op_count}" >&2
if [[ -n "${truth_mapping_json:-}" && "${truth_mapping_json}" != "'{}'" && "${truth_mapping_json}" != "{}" ]]; then
  echo "  truth_mapping: ${truth_mapping_json}" >&2
fi

if [[ "$apply" != true ]]; then
  echo "dry-run: 未写入任何变更（使用 --apply 才会写入）" >&2
  exit 0
fi

tmp_out="$(mktemp)"

awk -v ops_file="$tmp_ops" '
  function trim(s) { sub(/^[ \t\r\n]+/, "", s); sub(/[ \t\r\n]+$/, "", s); return s }
  function strip_quotes(s) {
    s = trim(s)
    sub(/^"/, "", s); sub(/"$/, "", s)
    sub(/^'\''/, "", s); sub(/'\''$/, "", s)
    return s
  }
  function yaml_quote(s,   out) {
    out = s
    gsub(/\\/, "\\\\", out)
    gsub(/"/, "\\\"", out)
    gsub(/\r/, "", out)
    gsub(/\n/, "\\n", out)
    return "\"" out "\""
  }
  function print_item(id, sev, anchor, stmt) {
    print "  - id: " id
    print "    severity: " (sev=="" ? "must" : sev)
    print "    anchor: " yaml_quote(anchor)
    print "    statement: " yaml_quote(stmt)
  }
  function flush_update() {
    if (mode != "capture") return
    sev = (has_sev[cur_id] == 1 ? upd_sev[cur_id] : orig_sev)
    anchor = (has_anchor[cur_id] == 1 ? upd_anchor[cur_id] : orig_anchor)
    stmt = (has_stmt[cur_id] == 1 ? upd_stmt[cur_id] : orig_stmt)
    if (sev == "") sev = "must"
    print_item(cur_id, sev, anchor, stmt)
    mode = "pass"
    cur_id = ""; orig_sev=""; orig_anchor=""; orig_stmt=""
  }
  BEGIN {
    FS="\t"
    in_req = 0
    mode = "pass"
    cur_id = ""
    orig_sev = ""; orig_anchor = ""; orig_stmt = ""
    add_n = 0

    while ((getline < ops_file) > 0) {
      op = $1; id = $2; sev = $3; anc = $4; stmt = $5
      hsev = $6 + 0; hanc = $7 + 0; hstmt = $8 + 0

      if (op == "remove") { rm[id] = 1; continue }
      if (op == "update") {
        upd[id] = 1
        if (hsev == 1) { upd_sev[id] = sev; has_sev[id] = 1 }
        if (hanc == 1) { upd_anchor[id] = anc; has_anchor[id] = 1 }
        if (hstmt == 1) { upd_stmt[id] = stmt; has_stmt[id] = 1 }
        continue
      }
      if (op == "add") {
        add_n++
        add_ids[add_n] = id
        add_sev[id] = sev
        add_anchor[id] = anc
        add_stmt[id] = stmt
      }
    }
    close(ops_file)
  }
  {
    line=$0
    sub(/\r$/, "", line)

    if (!in_req) {
      print line
      if (line ~ /^requirements:[ \t]*$/) {
        in_req = 1
      }
      next
    }

    # End requirements block when a new top-level key appears.
    if (line ~ /^[^ \t-][A-Za-z0-9_.-]*:/) {
      flush_update()
      for (i = 1; i <= add_n; i++) {
        id = add_ids[i]
        print_item(id, add_sev[id], add_anchor[id], add_stmt[id])
      }
      in_req = 0
      print line
      next
    }

    # Detect start of a requirement item.
    if (line ~ /^[ \t]*-[ \t]*id:[ \t]*/) {
      next_id = line
      sub(/^[ \t]*-[ \t]*id:[ \t]*/, "", next_id)
      next_id = strip_quotes(next_id)
      sub(/[ \t]+#.*$/, "", next_id)
      next_id = trim(next_id)

      flush_update()
      cur_id = next_id

      if (rm[cur_id] == 1) {
        mode = "skip"
        next
      }
      if (upd[cur_id] == 1) {
        mode = "capture"
        orig_sev=""; orig_anchor=""; orig_stmt=""
        next
      }

      mode = "pass"
      print line
      next
    }

    if (mode == "skip") {
      next
    }

    if (mode == "capture") {
      t = trim(line)
      if (t ~ /^severity:[ \t]*/) { v=t; sub(/^severity:[ \t]*/, "", v); orig_sev = strip_quotes(v); next }
      if (t ~ /^anchor:[ \t]*/) { v=t; sub(/^anchor:[ \t]*/, "", v); orig_anchor = strip_quotes(v); next }
      if (t ~ /^statement:[ \t]*/) { v=t; sub(/^statement:[ \t]*/, "", v); orig_stmt = strip_quotes(v); next }
      next
    }

    print line
  }
  END {
    if (in_req) {
      flush_update()
      for (i = 1; i <= add_n; i++) {
        id = add_ids[i]
        print_item(id, add_sev[id], add_anchor[id], add_stmt[id])
      }
    }
  }
' "$index_file" >"$tmp_out"

if [[ ! -s "$tmp_out" ]]; then
  rm -f "$tmp_out" >/dev/null 2>&1 || true
  die_usage "生成的索引内容为空，拒绝覆盖：${index_file}"
fi

mv "$tmp_out" "$index_file"
echo "ok: 已更新 requirements.index：${index_file}" >&2

if [[ "$refresh_ledger" == true ]]; then
  ledger_script="${script_dir}/../../devbooks-delivery-workflow/scripts/requirements-ledger-derive.sh"
  if [[ -f "$ledger_script" ]]; then
    bash "$ledger_script" \
      --project-root "$project_root" \
      --change-root "$change_dir_root" \
      --truth-root "$truth_dir" \
      --set-ref "$set_ref" \
      >/dev/null
    echo "ok: 已刷新派生账本（requirements.ledger.yaml）" >&2
  else
    echo "warn: 未找到账本派生脚本，已跳过刷新" >&2
  fi
fi
