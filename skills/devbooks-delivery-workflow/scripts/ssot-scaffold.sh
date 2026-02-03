#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: ssot-scaffold.sh [options]

Scaffold a minimal Project SSOT pack under truth_root when upstream SSOT is absent.

Creates (default):
  <truth-root>/ssot/SSOT.md
  <truth-root>/ssot/requirements.index.yaml

Options:
  --project-root <dir>    Project root directory (default: pwd)
  --truth-root <dir>      Truth root directory (default: specs)
  --ssot-dir <dir>        SSOT dir under truth_root (default: ssot)
  --set-id <id>           requirements.index set_id (default: derived from project dir)
  --source-ref <ref>      requirements.index source_ref (default: truth://<ssot-dir>/SSOT.md)
  --force                 Overwrite existing files
  -h, --help              Show this help message

Notes:
- This script is intentionally deterministic and does not "discover" external SSOT.
  Use it when your project does not have an upstream SSOT, or you want an internal pointer file.
- requirements.index.yaml schema_version is fixed to 1.0.0 (required by upstream_claims checks).
EOF
}

die_usage() {
  echo "error: $*" >&2
  usage
  exit 2
}

project_root="${DEVBOOKS_PROJECT_ROOT:-$(pwd)}"
truth_root="${DEVBOOKS_TRUTH_ROOT:-specs}"
ssot_dir="ssot"
set_id=""
source_ref=""
force=false

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
    --truth-root)
      truth_root="${2:-}"
      shift 2
      ;;
    --ssot-dir)
      ssot_dir="${2:-}"
      shift 2
      ;;
    --set-id)
      set_id="${2:-}"
      shift 2
      ;;
    --source-ref)
      source_ref="${2:-}"
      shift 2
      ;;
    --force)
      force=true
      shift
      ;;
    *)
      die_usage "unknown option: $1"
      ;;
  esac
done

project_root="${project_root%/}"
truth_root="${truth_root%/}"
ssot_dir="${ssot_dir%/}"

if [[ -z "$project_root" || -z "$truth_root" || -z "$ssot_dir" ]]; then
  die_usage "missing required paths"
fi

if [[ "$truth_root" = /* ]]; then
  truth_dir="$truth_root"
else
  truth_dir="${project_root}/${truth_root}"
fi

ssot_pack_dir="${truth_dir}/${ssot_dir}"

if [[ -z "$set_id" ]]; then
  base="$(basename "$project_root")"
  # Keep set_id readable and safe; schema does not enforce strict charset.
  base_safe="$(printf '%s' "$base" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+|-+$//g')"
  if [[ -z "$base_safe" ]]; then
    base_safe="project"
  fi
  set_id="REQSET-${base_safe}"
fi

if [[ -z "$source_ref" ]]; then
  source_ref="truth://${ssot_dir}/SSOT.md"
fi

write_file() {
  local path="$1"
  shift || true

  if [[ -f "$path" && "$force" != true ]]; then
    echo "skip: $path" >&2
    cat >/dev/null
    return 0
  fi

  mkdir -p "$(dirname "$path")"
  cat >"$path"
  echo "wrote: $path" >&2
}

mkdir -p "$ssot_pack_dir"

ssot_md="${ssot_pack_dir}/SSOT.md"
req_index="${ssot_pack_dir}/requirements.index.yaml"

cat <<'EOF' | write_file "$ssot_md"
# SSOT（Project Source of Truth）

> 目标：让“需求/约束/契约/进度”可寻址、可裁判、可追溯。  
> 原则：只写“可验证的真相”，不复制长材料；长材料用链接/引用回源即可。

## 0) 约定

- **稳定 ID**：建议 `PROJ-P0-001` / `PROJ-P1-001` / `PROJ-P2-001`（或任意稳定规则），一旦发布不得复用。
- **真相与缓存**：
  - 真相：本文件 + `requirements.index.yaml`（机读索引）
  - 缓存：任意派生视图（例如 requirements.ledger.yaml），可删可重建

## 1) 本次系统目标（非功能性也要写）

- 目标用户：
- 成功标准：
- 不做什么（Out of scope）：

## 2) 功能需求（Functional）

> 每条需求应有稳定 ID；标题尽量短；内容必须可被验收（给出可判定条件）。

### <ID>: <标题>
- Statement（MUST/SHOULD）：
- 验收要点（AC / Given-When-Then）：
- 依赖/前置：
- 风险/回滚：

## 3) UI/UX（若有界面）

- 目标设备/分辨率：
- 核心用户路径（3 条以内）：
- 页面/组件清单：
- 视觉/交互约束（可给参考链接或草图路径）：

## 4) 数据与契约（API/Schema/Event）

- 对外 API：
- 数据模型（关键字段/约束/迁移策略）：
- 兼容性策略（版本、迁移、回滚）：

## 5) 运行与质量（Ops / NFR）

- 性能/容量：
- 安全与合规：
- 可观测性（日志/指标/告警）：
- 发布与回滚：

## 6) Open Questions（最多 10 条）

1.
2.
3.
EOF

cat <<EOF | write_file "$req_index"
schema_version: 1.0.0
set_id: ${set_id}
source_ref: ${source_ref}

requirements:
  - id: R-001
    severity: must
    anchor: ""
    statement: "示例：把本项目的 SSOT 最小集落盘，并为每条需求提供稳定 ID。"
EOF

echo "ok: scaffolded ssot pack under: ${ssot_pack_dir}" >&2

