#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# knife-parallel-schedule.sh
# =============================================================================
# 从 Knife Plan 生成并行执行调度清单
#
# 功能：
#   1. 解析 Knife Plan 的 slices[] 依赖图
#   2. 计算最大并行度（DAG 宽度）
#   3. 生成分层执行清单（Layer 0, 1, 2, ...）
#   4. 识别关键路径
#   5. 输出人类可读的并行执行指南
#
# 用途：
#   Epic 拆分后，用户可以根据此清单开启多个独立 Agent 并行完成变更包
# =============================================================================

usage() {
  cat <<'EOF' >&2
usage: knife-parallel-schedule.sh <epic-id> [options]

从 Knife Plan 生成并行执行调度清单。

Options:
  --project-root <dir>    项目根目录 (default: pwd)
  --truth-root <dir>      真理根目录 (default: specs)
  --out <path>            输出文件路径 (default: stdout)
  --format <md|json>      输出格式 (default: md)
  -h, --help              显示帮助

输出内容：
  - 最大并行度
  - 分层执行清单（哪些 Slice 可以同时开始）
  - 关键路径
  - 每个 Slice 的启动命令模板
  - 溯源信息

Exit codes:
  0 - 成功
  1 - Knife Plan 不存在或解析失败
  2 - 用法错误
EOF
}

errorf() {
  printf 'ERROR: %s\n' "$*" >&2
}

infof() {
  printf 'INFO: %s\n' "$*" >&2
}

# =============================================================================
# 参数解析
# =============================================================================

if [[ $# -eq 0 ]]; then
  usage
  exit 2
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

epic_id="$1"
shift

project_root="${DEVBOOKS_PROJECT_ROOT:-$(pwd)}"
truth_root="${DEVBOOKS_TRUTH_ROOT:-specs}"
out_path=""
format="md"

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
    --out)
      out_path="${2:-}"
      shift 2
      ;;
    --format)
      format="${2:-}"
      shift 2
      ;;
    *)
      errorf "unknown option: $1"
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$epic_id" || "$epic_id" == "-"* ]]; then
  errorf "invalid epic-id: '$epic_id'"
  exit 2
fi

case "$format" in
  md|json) ;;
  *)
    errorf "invalid --format: $format (must be md or json)"
    exit 2
    ;;
esac

project_root="${project_root%/}"
truth_root="${truth_root%/}"

if [[ "$truth_root" = /* ]]; then
  truth_dir="$truth_root"
else
  truth_dir="${project_root}/${truth_root}"
fi

# =============================================================================
# 查找 Knife Plan
# =============================================================================

knife_plan_dir="${truth_dir}/_meta/epics/${epic_id}"
knife_plan_file=""

if [[ -f "${knife_plan_dir}/knife-plan.yaml" ]]; then
  knife_plan_file="${knife_plan_dir}/knife-plan.yaml"
elif [[ -f "${knife_plan_dir}/knife-plan.json" ]]; then
  knife_plan_file="${knife_plan_dir}/knife-plan.json"
else
  errorf "Knife Plan not found at: ${knife_plan_dir}/knife-plan.(yaml|json)"
  exit 1
fi

infof "Found Knife Plan: $knife_plan_file"

# =============================================================================
# 解析 Knife Plan（使用 yq 或 jq）
# =============================================================================

# 检查工具可用性
if command -v yq &>/dev/null; then
  YAML_TOOL="yq"
elif command -v python3 &>/dev/null; then
  YAML_TOOL="python"
else
  errorf "需要 yq 或 python3 来解析 YAML"
  exit 1
fi

# 提取 slices 数据
extract_slices() {
  local file="$1"

  if [[ "$file" == *.json ]]; then
    jq -r '.slices // []' "$file"
  elif [[ "$YAML_TOOL" == "yq" ]]; then
    yq -o=json '.slices // []' "$file"
  else
    python3 -c "
import yaml
import json
import sys

with open('$file', 'r') as f:
    data = yaml.safe_load(f)
    slices = data.get('slices', [])
    print(json.dumps(slices))
"
  fi
}

# 提取元数据
extract_metadata() {
  local file="$1"

  if [[ "$file" == *.json ]]; then
    jq -r '{epic_id, plan_id, plan_revision, risk_level, change_type, ac_ids}' "$file"
  elif [[ "$YAML_TOOL" == "yq" ]]; then
    yq -o=json '{epic_id: .epic_id, plan_id: .plan_id, plan_revision: .plan_revision, risk_level: .risk_level, change_type: .change_type, ac_ids: .ac_ids}' "$file"
  else
    python3 -c "
import yaml
import json
import sys

with open('$file', 'r') as f:
    data = yaml.safe_load(f)
    meta = {
        'epic_id': data.get('epic_id'),
        'plan_id': data.get('plan_id'),
        'plan_revision': data.get('plan_revision'),
        'risk_level': data.get('risk_level'),
        'change_type': data.get('change_type'),
        'ac_ids': data.get('ac_ids', [])
    }
    print(json.dumps(meta))
"
  fi
}

slices_json=$(extract_slices "$knife_plan_file")
metadata_json=$(extract_metadata "$knife_plan_file")

# 验证 slices 不为空
slice_count=$(echo "$slices_json" | jq 'length')
if [[ "$slice_count" -eq 0 ]]; then
  errorf "Knife Plan 中没有定义 slices"
  exit 1
fi

infof "Found $slice_count slices"

# =============================================================================
# 拓扑排序与分层计算
# =============================================================================

# 使用 jq 进行拓扑排序和分层计算
schedule_json=$(echo "$slices_json" | jq '
# 构建 slice_id -> index 映射
. as $slices |
reduce range(length) as $i ({}; . + {($slices[$i].slice_id): $i}) as $id_to_idx |

# 计算每个节点的入度
reduce .[] as $slice (
  (reduce .[] as $s ({}; . + {($s.slice_id): 0}));
  reduce ($slice.depends_on // [])[] as $dep (.; .[$slice.slice_id] = (.[$slice.slice_id] // 0) + 1)
) as $in_degree |

# Kahn 算法进行拓扑排序并分层
{
  layers: [],
  remaining: [.[] | .slice_id],
  in_degree: $in_degree,
  slices: $slices
} |
until((.remaining | length) == 0;
  # 找出当前入度为 0 的节点
  .remaining as $rem |
  .in_degree as $deg |
  [$rem[] | select($deg[.] == 0)] as $current_layer |

  if ($current_layer | length) == 0 then
    # 有环，无法继续
    .remaining = []
  else
    # 更新入度
    reduce ($slices[] | select([.slice_id] | inside($current_layer) | not)) as $s (
      .in_degree;
      reduce ($s.depends_on // [])[] as $dep (
        .;
        if ($current_layer | index($dep)) then
          .[$s.slice_id] = (.[$s.slice_id] - 1)
        else . end
      )
    ) as $new_deg |

    .layers += [$current_layer] |
    .remaining = [.remaining[] | select(. as $id | $current_layer | index($id) | not)] |
    .in_degree = $new_deg
  end
) |

# 计算关键路径（最长路径）
.layers as $layers |
($layers | length) as $depth |

# 构建 slice 详情
{
  max_parallelism: ($layers | map(length) | max),
  total_layers: ($layers | length),
  layers: [range($layers | length) as $i | {
    layer: $i,
    can_start_immediately: ($i == 0),
    depends_on_layer: (if $i > 0 then $i - 1 else null end),
    slices: $layers[$i]
  }],
  critical_path_length: ($layers | length),
  slices_detail: [.slices[] | {
    slice_id: .slice_id,
    change_id: .change_id,
    ac_subset: .ac_subset,
    depends_on: (.depends_on // []),
    budgets: .budgets,
    verification_anchors: .verification_anchors
  }]
}
')

# =============================================================================
# 输出生成
# =============================================================================

generate_markdown() {
  local meta="$1"
  local schedule="$2"
  local knife_file="$3"

  local epic_id plan_id plan_revision risk_level change_type
  epic_id=$(echo "$meta" | jq -r '.epic_id // "N/A"')
  plan_id=$(echo "$meta" | jq -r '.plan_id // "N/A"')
  plan_revision=$(echo "$meta" | jq -r '.plan_revision // "N/A"')
  risk_level=$(echo "$meta" | jq -r '.risk_level // "N/A"')
  change_type=$(echo "$meta" | jq -r '.change_type // "N/A"')

  local max_parallelism total_layers
  max_parallelism=$(echo "$schedule" | jq -r '.max_parallelism')
  total_layers=$(echo "$schedule" | jq -r '.total_layers')

  cat <<EOF
# 并行执行调度清单

> 由 \`knife-parallel-schedule.sh\` 自动生成
> 生成时间: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## 溯源信息

| 字段 | 值 |
|------|-----|
| Epic ID | \`$epic_id\` |
| Plan ID | \`$plan_id\` |
| Plan Revision | \`$plan_revision\` |
| Risk Level | \`$risk_level\` |
| Change Type | \`$change_type\` |
| Knife Plan 路径 | \`$knife_file\` |

## 并行度摘要

- **最大并行度**: $max_parallelism（可同时启动的最大 Agent 数量）
- **总层数**: $total_layers（串行依赖深度）
- **关键路径长度**: $total_layers 层

## 执行层级

EOF

  # 输出每一层
  echo "$schedule" | jq -r '.layers[] | "### Layer \(.layer)\(if .can_start_immediately then " (可立即开始)" else " (依赖 Layer \(.depends_on_layer))" end)\n\n| Slice ID | Change ID |\n|----------|-----------|" + (.slices | map("\n| `\(.)` | - |") | join(""))'

  cat <<EOF

## Slice 详情

EOF

  # 输出每个 slice 的详情
  echo "$schedule" | jq -r '.slices_detail[] | "### \(.slice_id)\n\n- **Change ID**: `\(.change_id // "待分配")`\n- **依赖**: \(if (.depends_on | length) == 0 then "无（可独立执行）" else (.depends_on | map("`\(.)`") | join(", ")) end)\n- **AC 子集**: \(.ac_subset | map("`\(.)`") | join(", "))\n- **Token 预算**: \(.budgets.tokens // "未指定")\n- **验证锚点**: \(if (.verification_anchors | length) == 0 then "无" else (.verification_anchors | map("`\(.)`") | join(", ")) end)\n"'

  cat <<EOF

## 启动命令模板

每个 Slice 对应一个独立的变更包，可以在独立的 Agent 会话中执行：

\`\`\`bash
# Layer 0 的 Slice 可以立即并行启动
EOF

  echo "$schedule" | jq -r '.layers[0].slices[] as $sid | .slices_detail[] | select(.slice_id == $sid) | "# Agent for \(.slice_id)\ndevbooks apply --change-id \(.change_id // "<待分配>") --epic-id '"$epic_id"' --slice-id \(.slice_id)"'

  cat <<EOF
\`\`\`

## 执行建议

1. **并行启动**: 同一 Layer 内的所有 Slice 可以同时启动独立的 Agent
2. **依赖等待**: 下一 Layer 的 Slice 必须等待上一 Layer 全部完成
3. **溯源验证**: 每个变更包完成后，使用 \`devbooks archive\` 归档并回写账本
4. **进度追踪**: 使用 \`progress-dashboard.sh\` 查看整体进度

## 完成后回写

所有 Slice 完成后，执行以下命令更新账本：

\`\`\`bash
# 派生需求账本
requirements-ledger-derive.sh --project-root .

# 验证 Epic 完整性
epic-alignment-check.sh $epic_id --mode strict
\`\`\`

---

*此清单由 DevBooks Knife Parallel Schedule 生成*
*参考: dev-playbooks/specs/knife/spec.md*
EOF
}

generate_json() {
  local meta="$1"
  local schedule="$2"
  local knife_file="$3"

  jq -n \
    --argjson meta "$meta" \
    --argjson schedule "$schedule" \
    --arg knife_file "$knife_file" \
    --arg generated_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    '{
      schema_version: "1.0.0",
      generated_at: $generated_at,
      source: {
        knife_plan_path: $knife_file,
        epic_id: $meta.epic_id,
        plan_id: $meta.plan_id,
        plan_revision: $meta.plan_revision,
        risk_level: $meta.risk_level,
        change_type: $meta.change_type
      },
      summary: {
        max_parallelism: $schedule.max_parallelism,
        total_layers: $schedule.total_layers,
        critical_path_length: $schedule.critical_path_length,
        total_slices: ($schedule.slices_detail | length)
      },
      layers: $schedule.layers,
      slices: $schedule.slices_detail
    }'
}

# =============================================================================
# 输出
# =============================================================================

output=""
if [[ "$format" == "md" ]]; then
  output=$(generate_markdown "$metadata_json" "$schedule_json" "$knife_plan_file")
else
  output=$(generate_json "$metadata_json" "$schedule_json" "$knife_plan_file")
fi

if [[ -n "$out_path" ]]; then
  if [[ "$out_path" = /* ]]; then
    out_file="$out_path"
  else
    out_file="${project_root}/${out_path}"
  fi
  mkdir -p "$(dirname "$out_file")"
  echo "$output" > "$out_file"
  infof "Output written to: $out_file"
else
  echo "$output"
fi

infof "Parallel schedule generated successfully"
infof "Max parallelism: $(echo "$schedule_json" | jq -r '.max_parallelism')"
infof "Total layers: $(echo "$schedule_json" | jq -r '.total_layers')"
