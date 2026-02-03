#!/usr/bin/env bash
set -euo pipefail

# ssot-delta.sh
# ssot.delta.yaml 的最小解析器（无外部依赖：不需要 yq）。
#
# 合同（支持子集）：
# - 顶层字段：
#   - schema_version: 1.0.0
#   - target_set_ref: truth://ssot/requirements.index.yaml  （可选）
#   - ops:
#       - op: add|update|remove
#         id: <add 可选；update/remove 必填>
#         severity: must|should（可选；默认=must）
#         anchor: <string>（可选）
#         statement: <单行字符串>（remove 可选；add 必填；update 可选）
#         title: <string>（可选）
#
# 输出（stdout）：使用“单元分隔符”(Unit Separator, ASCII 0x1F) 分隔字段，先 meta 后 ops：
#   META␟SCHEMA_VERSION␟<value>
#   META␟TARGET_SET_REF␟<value>
#   OP␟<op>␟<id>␟<severity>␟<anchor>␟<statement>␟<title>␟<has_severity>␟<has_anchor>␟<has_statement>␟<has_title>

sd_parse_delta_tsv() {
  local delta_file="${1:-}"
  if [[ -z "$delta_file" || ! -f "$delta_file" ]]; then
    echo "error: 找不到 ssot delta 文件: ${delta_file:-<empty>}" >&2
    return 2
  fi

  awk '
    function trim(s) {
      sub(/^[ \t\r\n]+/, "", s)
      sub(/[ \t\r\n]+$/, "", s)
      return s
    }
    function strip_quotes(s) {
      s = trim(s)
      sub(/^"/, "", s); sub(/"$/, "", s)
      sub(/^'\''/, "", s); sub(/'\''$/, "", s)
      return s
    }
    function flush_current() {
      if (cur_op == "") return
      op_n++
      ops[op_n] = cur_op
      ids[op_n] = cur_id
      sevs[op_n] = cur_sev
      ancs[op_n] = cur_anchor
      stmts[op_n] = cur_stmt
      titles[op_n] = cur_title
      hsev[op_n] = cur_hsev
      hanc[op_n] = cur_hanc
      hstmt[op_n] = cur_hstmt
      htitle[op_n] = cur_htitle
      cur_op = ""; cur_id = ""; cur_sev = ""; cur_anchor = ""; cur_stmt = ""; cur_title = ""
      cur_hsev = 0; cur_hanc = 0; cur_hstmt = 0; cur_htitle = 0
    }
    BEGIN {
      in_ops = 0
      op_n = 0
      schema = ""
      target = ""
      cur_op = ""; cur_id = ""; cur_sev = ""; cur_anchor = ""; cur_stmt = ""; cur_title = ""
      cur_hsev = 0; cur_hanc = 0; cur_hstmt = 0; cur_htitle = 0
    }
    {
      line = $0
      sub(/\r$/, "", line)
      if (line ~ /^[ \t]*#/) next

      if (!in_ops) {
        if (line ~ /^schema_version:[ \t]*/) {
          v = line
          sub(/^schema_version:[ \t]*/, "", v)
          schema = strip_quotes(v)
          next
        }
        if (line ~ /^target_set_ref:[ \t]*/) {
          v = line
          sub(/^target_set_ref:[ \t]*/, "", v)
          target = strip_quotes(v)
          next
        }
        if (line ~ /^ops:[ \t]*$/) { in_ops = 1; next }
        next
      }

      # End ops if another top-level key appears.
      if (line ~ /^[^ \t-][A-Za-z0-9_.-]*:/) {
        flush_current()
        in_ops = 0
        next
      }

      if (line ~ /^[ \t]*-[ \t]*op:[ \t]*/) {
        flush_current()
        v = line
        sub(/^[ \t]*-[ \t]*op:[ \t]*/, "", v)
        cur_op = strip_quotes(v)
        next
      }

      t = trim(line)
      if (t ~ /^op:[ \t]*/) { v=t; sub(/^op:[ \t]*/, "", v); cur_op = strip_quotes(v); next }
      if (t ~ /^id:[ \t]*/) { v=t; sub(/^id:[ \t]*/, "", v); cur_id = strip_quotes(v); next }
      if (t ~ /^severity:[ \t]*/) { v=t; sub(/^severity:[ \t]*/, "", v); cur_sev = strip_quotes(v); cur_hsev = 1; next }
      if (t ~ /^anchor:[ \t]*/) { v=t; sub(/^anchor:[ \t]*/, "", v); cur_anchor = strip_quotes(v); cur_hanc = 1; next }
      if (t ~ /^statement:[ \t]*/) { v=t; sub(/^statement:[ \t]*/, "", v); cur_stmt = strip_quotes(v); cur_hstmt = 1; next }
      if (t ~ /^title:[ \t]*/) { v=t; sub(/^title:[ \t]*/, "", v); cur_title = strip_quotes(v); cur_htitle = 1; next }
    }
    END {
      flush_current()
      printf "META\037SCHEMA_VERSION\037%s\n", schema
      printf "META\037TARGET_SET_REF\037%s\n", target
      for (i = 1; i <= op_n; i++) {
        printf "OP\037%s\037%s\037%s\037%s\037%s\037%s\037%d\037%d\037%d\037%d\n", ops[i], ids[i], sevs[i], ancs[i], stmts[i], titles[i], hsev[i], hanc[i], hstmt[i], htitle[i]
      }
    }
  ' "$delta_file"
}
