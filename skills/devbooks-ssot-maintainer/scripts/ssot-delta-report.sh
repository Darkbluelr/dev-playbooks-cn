#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
用法: ssot-delta-report.sh --delta <path> [--out <path>]

为 ssot.delta.yaml 生成一份人类可读报告（无外部依赖）。

选项:
  --delta <path>   inputs/ssot.delta.yaml 路径（必填）
  --out <path>     写入到指定文件（默认: stdout）
  -h, --help       显示帮助
EOF
}

die_usage() {
  echo "error: $*" >&2
  usage
  exit 2
}

delta_path=""
out_path=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --delta) delta_path="${2:-}"; shift 2 ;;
    --out) out_path="${2:-}"; shift 2 ;;
    *) die_usage "未知选项: $1" ;;
  esac
done

if [[ -z "$delta_path" ]]; then
  die_usage "必须提供 --delta"
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/ssot-delta.sh
source "${script_dir}/lib/ssot-delta.sh"

tmp_report="$(mktemp)"
cleanup() {
  rm -f "$tmp_report" >/dev/null 2>&1 || true
}
trap cleanup EXIT

schema=""
target=""
adds=0
updates=0
removes=0

{
  echo "# SSOT Delta 报告"
  echo ""
  echo "- 生成时间: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "- Delta 文件: ${delta_path}"
  echo ""
} >"$tmp_report"

while IFS=$'\x1f' read -r rec a b c d e f g h i j; do
  if [[ "$rec" == "META" && "$a" == "SCHEMA_VERSION" ]]; then
    schema="${b:-}"
  fi
  if [[ "$rec" == "META" && "$a" == "TARGET_SET_REF" ]]; then
    target="${b:-}"
  fi
done < <(sd_parse_delta_tsv "$delta_path")

{
  echo "## 元数据"
  echo ""
  echo "- schema_version: ${schema:-<空>}"
  echo "- target_set_ref: ${target:-<空>}"
  echo ""
} >>"$tmp_report"

if [[ "$schema" != "1.0.0" ]]; then
  echo "## 校验" >>"$tmp_report"
  echo "" >>"$tmp_report"
  echo "- 状态: fail" >>"$tmp_report"
  echo "- 原因: schema_version 必须为 1.0.0" >>"$tmp_report"
else
  echo "## 操作" >>"$tmp_report"
  echo "" >>"$tmp_report"

  while IFS=$'\x1f' read -r rec op id severity anchor statement title has_sev has_anchor has_stmt has_title; do
    [[ "$rec" == "OP" ]] || continue

    op="$(printf '%s' "${op:-}" | tr '[:upper:]' '[:lower:]')"
    severity="$(printf '%s' "${severity:-}" | tr '[:upper:]' '[:lower:]')"

    case "$op" in
      add) adds=$((adds + 1)) ;;
      update) updates=$((updates + 1)) ;;
      remove) removes=$((removes + 1)) ;;
    esac

    if [[ "$op" == "add" && "${has_sev:-0}" != "1" ]]; then
      severity="must"
    fi

    echo "- op: ${op}" >>"$tmp_report"
    echo "  - id: ${id:-<自动分配>}" >>"$tmp_report"
    [[ -n "$severity" ]] && echo "  - severity: ${severity}" >>"$tmp_report"
    [[ -n "${anchor:-}" || "${has_anchor:-0}" == "1" ]] && echo "  - anchor: ${anchor}" >>"$tmp_report"
    [[ -n "${statement:-}" || "${has_stmt:-0}" == "1" ]] && echo "  - statement: ${statement}" >>"$tmp_report"
    [[ -n "${title:-}" || "${has_title:-0}" == "1" ]] && echo "  - title: ${title}" >>"$tmp_report"
  done < <(sd_parse_delta_tsv "$delta_path")

  {
    echo ""
    echo "## 汇总"
    echo ""
    echo "- add: ${adds}"
    echo "- update: ${updates}"
    echo "- remove: ${removes}"
  } >>"$tmp_report"
fi

if [[ -n "$out_path" ]]; then
  mkdir -p "$(dirname "$out_path")"
  cp "$tmp_report" "$out_path"
  echo "ok: 已写入报告: ${out_path}" >&2
else
  cat "$tmp_report"
fi
