#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: change-scaffold.sh <change-id> [--project-root <dir>] [--change-root <dir>] [--truth-root <dir>] [--force] [--prototype]

Creates a DevBooks change package skeleton under:
  <change-root>/<change-id>/

Defaults (can be overridden by flags or env):
  DEVBOOKS_PROJECT_ROOT: pwd
  DEVBOOKS_CHANGE_ROOT:  changes
  DEVBOOKS_TRUTH_ROOT:   specs

Options:
  --prototype   Create prototype track skeleton (prototype/src + prototype/characterization).
                Use this for "Plan to Throw One Away" exploratory work.
                Prototype code is physically isolated from production code.

Notes:
- Use --change-root and --truth-root to customize paths for your project layout.
- It writes markdown templates for proposal/design/tasks/verification and creates specs/ + evidence/ directories.
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

change_id="$1"
shift

project_root="${DEVBOOKS_PROJECT_ROOT:-$(pwd)}"
change_root="${DEVBOOKS_CHANGE_ROOT:-changes}"
truth_root="${DEVBOOKS_TRUTH_ROOT:-specs}"
force=false
prototype=false

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
    --truth-root)
      truth_root="${2:-}"
      shift 2
      ;;
    --force)
      force=true
      shift
      ;;
    --prototype)
      prototype=true
      shift
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$change_id" || "$change_id" == "-"* || "$change_id" =~ [[:space:]] ]]; then
  echo "error: invalid change-id: '$change_id'" >&2
  exit 2
fi

if [[ -z "$project_root" || -z "$change_root" || -z "$truth_root" ]]; then
  usage
  exit 2
fi

change_root="${change_root%/}"
truth_root="${truth_root%/}"
project_root="${project_root%/}"

if [[ "$change_root" = /* ]]; then
  change_dir="${change_root}/${change_id}"
else
  change_dir="${project_root}/${change_root}/${change_id}"
fi

mkdir -p "${change_dir}/specs" "${change_dir}/evidence"

write_file() {
  local path="$1"
  shift || true

  if [[ -f "$path" && "$force" != true ]]; then
    echo "skip: $path"
    cat >/dev/null
    return 0
  fi

  mkdir -p "$(dirname "$path")"
  cat >"$path"
  echo "wrote: $path"
}

escape_sed_repl() {
  printf '%s' "$1" | sed -e 's/[\\/&|]/\\&/g'
}

esc_change_id="$(escape_sed_repl "$change_id")"
esc_change_root="$(escape_sed_repl "$change_root")"
esc_truth_root="$(escape_sed_repl "$truth_root")"

render_template() {
  sed \
    -e "s|__CHANGE_ID__|${esc_change_id}|g" \
    -e "s|__CHANGE_ROOT__|${esc_change_root}|g" \
    -e "s|__TRUTH_ROOT__|${esc_truth_root}|g"
}

cat <<'EOF' | render_template | write_file "${change_dir}/proposal.md"
# Proposal: __CHANGE_ID__

> 产物落点：`__CHANGE_ROOT__/__CHANGE_ID__/proposal.md`
>
> 注意：proposal 阶段禁止写实现代码；只定义 Why/What/Impact/Risks/Validation + 争议点。

## Why

- 问题：
- 目标：

## What Changes

- In scope：
- Out of scope（Non-goals）：
- 影响范围（模块/能力/对外契约/数据不变量）：

## Impact

- 对外契约（API/Schema/Event）：
- 数据与迁移：
- 受影响模块与依赖：
- 测试与质量闸门：
- 价值信号与观测口径：<填“无”或写明指标/看板/日志/业务事件>
- 价值流瓶颈假设（哪里会堵：PR review / tests / 发布 / 手工验收）：<填“无”或写明假设与缓解策略>

## Risks & Rollback

- 风险：
- 降级策略：
- 回滚策略：

## Validation

- 候选验收锚点（tests/静态检查/build/手工证据）：
- 证据落点：`__CHANGE_ROOT__/__CHANGE_ID__/evidence/`（推荐用 `change-evidence.sh <change-id> -- <command>` 采集）

## Debate Packet

- 争议点/需要裁决的问题（<=7 条）：

## Decision Log

- 决策状态：Pending
- 裁决摘要：
- 需要裁决的问题清单：
EOF

cat <<'EOF' | render_template | write_file "${change_dir}/design.md"
# Design: __CHANGE_ID__

> 产物落点：`__CHANGE_ROOT__/__CHANGE_ID__/design.md`
>
> 只写 What/Constraints + AC-xxx；禁止写实现步骤与函数体代码。

## 背景与现状

- 当前行为（可观察事实）：
- 主要约束（性能/安全/兼容/依赖方向）：

## Goals / Non-goals

- Goals：
- Non-goals：

## 设计原则与红线

- 原则：
- Red Lines（不可破）：

## 目标架构（可选）

- 边界与依赖方向：
- 扩展点：

## 数据与契约（按需）

- Artifacts / Events / Schema：
- 兼容策略（版本化/迁移/回放）：

## 可观测性与验收（按需）

- 指标/KPI/SLO：

## Acceptance Criteria

- AC-001（A/B/C）：<可观察的 Pass/Fail 判据>（候选锚点：tests/命令/证据）
EOF

cat <<'EOF' | render_template | write_file "${change_dir}/tasks.md"
# Tasks: __CHANGE_ID__

> 产物落点：`__CHANGE_ROOT__/__CHANGE_ID__/tasks.md`
>
> 只从 `__CHANGE_ROOT__/__CHANGE_ID__/design.md` 推导任务；不要从 tests/ 反推计划。

========================
主线计划区 (Main Plan Area)
========================

- [ ] MP1.1 <一句话目标>
  - Why：
  - Acceptance Criteria（引用 AC-xxx）：
  - Candidate Anchors（tests/命令/证据）：
  - Dependencies：
  - Risks：

========================
临时计划区 (Temporary Plan Area)
========================

- （留空/按需）

========================
断点区 (Context Switch Breakpoint Area)
========================

- 上次进度：
- 当前阻塞：
- 下一步最短路径：
EOF

cat <<'EOF' | render_template | write_file "${change_dir}/verification.md"
# verification.md（__CHANGE_ID__）

> 推荐路径：`__CHANGE_ROOT__/__CHANGE_ID__/verification.md`
>
> 目标：把“完成定义”落到可执行锚点与证据上，并提供 `AC-xxx -> Requirement/Scenario -> Test IDs -> Evidence` 的追溯。

---

## 元信息

- Change ID：`__CHANGE_ID__`
- 状态：Draft | Ready | Done | Archived
- 关联：
  - Proposal：`__CHANGE_ROOT__/__CHANGE_ID__/proposal.md`
  - Design：`__CHANGE_ROOT__/__CHANGE_ID__/design.md`
  - Tasks：`__CHANGE_ROOT__/__CHANGE_ID__/tasks.md`
  - Spec deltas：`__CHANGE_ROOT__/__CHANGE_ID__/specs/**`
- 维护者：<you>
- 更新时间：YYYY-MM-DD
- Test Owner（独立对话）：<session/agent>
- Coder（独立对话）：<session/agent>
- Red 基线证据：`__CHANGE_ROOT__/__CHANGE_ID__/evidence/`

---

========================
A) 测试计划指令表
========================

### 主线计划区 (Main Plan Area)

- [ ] TP1.1 <一句话目标>
  - Why：
  - Acceptance Criteria（引用 AC-xxx / Requirement）：
  - Test Type：unit | contract | integration | e2e | fitness | static
  - Non-goals：
  - Candidate Anchors（Test IDs / commands / evidence）：

### 临时计划区 (Temporary Plan Area)

- （留空/按需）

### 断点区 (Context Switch Breakpoint Area)

- 上次进度：
- 当前阻塞：
- 下一步最短路径：

---

========================
B) 追溯矩阵（Traceability Matrix）
========================

| AC | Requirement/Scenario | Test IDs / Commands | Evidence / MANUAL-* | Status |
|---|---|---|---|---|
| AC-001 | <capability>/Requirement... | TEST-... / pnpm test ... | MANUAL-001 / link | TODO |

---

========================
C) 执行锚点（Deterministic Anchors）
========================

### 1) 行为（Behavior）

- unit：
- integration：
- e2e：

### 2) 契约（Contract）

- OpenAPI/Proto/Schema：
- contract tests：

### 3) 结构（Structure / Fitness Functions）

- 分层/依赖方向/禁止循环：

### 4) 静态与安全（Static/Security）

- lint/typecheck/build：
- SAST/secret scan：
- 报告格式：json|xml（优先机器可读）

---

========================
D) MANUAL-* 清单（人工/混合验收）
========================

- [ ] MANUAL-001 <验收项>
  - Pass/Fail 判据：
  - Evidence（截图/录像/链接/日志）：
  - 责任人/签字：

---

========================
E) 风险与降级（可选）
========================

- 风险：
- 降级策略：
- 回滚策略：

========================
F) 结构质量守门记录
========================

- 冲突点：
- 评估影响（内聚/耦合/可测试性）：
- 替代闸门（复杂度/耦合/依赖方向/测试质量）：
- 决策与授权：<填“无”或写明授权人/结论>

========================
G) 价值流与度量（可选，但必须显式填“无”）
========================

- 目标价值信号：<填“无”或写明指标/看板/日志/业务事件>
- 交付与稳定性指标（可选 DORA）：<填“无”或写明 Lead Time / Deploy Frequency / Change Failure Rate / MTTR 的观测口径>
- 观测窗口与触发点：<填“无”或写明上线后多久、观察哪些告警/报表>
- Evidence：<填“无”或写明链接/截图/报表路径（建议落到 evidence/）>
EOF

specs_readme_path="${change_dir}/specs/README.md"
if [[ ! -f "$specs_readme_path" || "$force" == true ]]; then
  printf '%s\n' "# specs/" "" "在本目录下为每个 capability 创建子目录，并在其中写 \`spec.md\`：" "" "- \`${change_root}/${change_id}/specs/<capability>/spec.md\`" "" | write_file "$specs_readme_path"
fi

# Prototype mode: create prototype track skeleton
if [[ "$prototype" == true ]]; then
  mkdir -p "${change_dir}/prototype/src" "${change_dir}/prototype/characterization"

  cat <<'EOF' | render_template | write_file "${change_dir}/prototype/PROTOTYPE.md"
# Prototype Declaration: __CHANGE_ID__

> 此目录包含原型代码，**禁止直接合并到生产代码库**。
>
> 来源：《人月神话》第11章"未雨绸缪" — "第一个开发的系统并不合用...为舍弃而计划"

## 目录结构

```
prototype/
├── PROTOTYPE.md          # 本文件：原型声明与状态
├── src/                  # 原型实现代码（允许技术债）
└── characterization/     # 表征测试（记录实际行为，非验收测试）
```

## 状态

- [ ] 原型完成
- [ ] 表征测试就绪（行为快照已记录）
- [ ] 已决定：提升 / 丢弃 / 迭代

## 约束（必须遵守）

1. **物理隔离**：原型代码只能在 `prototype/src/` 下，禁止直接落到仓库 `src/`
2. **角色隔离不变**：Test Owner 与 Coder 仍必须独立对话/独立实例
3. **表征测试优先**：Test Owner 产出的是"表征测试"（记录实际行为），不是验收测试
4. **提升需显式触发**：运行 `prototype-promote.sh __CHANGE_ID__` 并完成检查清单

## 提升检查清单（提升前必须完成）

- [ ] 创建生产级 `design.md`（从原型学习中提炼 What/Constraints/AC-xxx）
- [ ] Test Owner 产出验收测试 `verification.md`（替代表征测试）
- [ ] 运行 `prototype-promote.sh __CHANGE_ID__` 并通过所有闸门
- [ ] 原型代码归档到 `tests/archived-characterization/__CHANGE_ID__/`

## 丢弃检查清单（丢弃时）

- [ ] 记录学习到的关键洞察到 `proposal.md` 的 Decision Log
- [ ] 删除 `prototype/` 目录

## 学习记录

> 在原型过程中学到了什么？这些洞察将帮助生产级实现。

- 技术发现：
- 风险澄清：
- 设计约束更新：
EOF

  echo "ok: created prototype track at ${change_dir}/prototype/"
fi

echo "ok: scaffolded ${change_dir}"
