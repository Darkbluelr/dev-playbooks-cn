---
name: devbooks-ssot-maintainer
description: devbooks-ssot-maintainer：维护项目 SSOT 的"可寻址索引与派生进度视图"。用于"修改/同步 SSOT（上游或项目内）→ 生成可审计 delta → 同步 requirements.index.yaml →（可选）刷新 requirements.ledger.yaml"。通常由 `/devbooks:delivery` 在 `request_kind=governance` 路由下调用。注意：SSOT 初始化请使用 `brownfield-bootstrap`。
recommended_experts: ["Technical Writer", "System Architect"]
allowed-tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
  - Bash
---

# DevBooks：SSOT Maintainer（索引账本维护闭环）

## 渐进披露
### 基础层（必读）
目标：把"改 SSOT"从口头叙述升级为**可机读、可审计、可裁判**的闭环：`ssot.delta.yaml → requirements.index.yaml →（可选）requirements.ledger.yaml`。
输入：变更包路径、上游/项目内 SSOT 的引用锚点、以及本次变更的 delta。
输出：
- `<change-root>/<change-id>/inputs/ssot.delta.yaml`（本次变更的最小机读输入）
- `<devbooks-root>/ssot/requirements.index.yaml`（真相：稳定 ID → anchor → statement）
- `<devbooks-root>/ssot/requirements.ledger.yaml`（派生缓存：进度视图，可丢弃可重建）
边界：
- 不通读/不复制上游 SSOT 全库；只维护索引与引用锚点。
- 不改变 `upstream_claims` 的合同语义。
- **不负责 SSOT 初始化**（初始化请使用 `brownfield-bootstrap`）。
证据：脚本输出日志、更新后的索引文件、（可选）ledger 刷新日志。

### 进阶层（可选）
适用：需要同时管理"上游 SSOT（外部目录）+ 项目级最小 SSOT 包"时的约束与最佳实践。

### 扩展层（可选）
适用：需要将 SSOT 维护纳入 Knife/Epic 切片（例如 `slices[].ssot_ids`）或更严格治理闸门时。

## 与 brownfield-bootstrap 的职责边界

| Skill | 职责 | 类比 | 触发时机 |
|-------|------|------|----------|
| **brownfield-bootstrap** | **创建** SSOT 骨架 | `git init` | `ssot/` 不存在或为空 |
| **ssot-maintainer** | **维护** SSOT（增删改） | `git commit` | SSOT 已存在，需要变更 |

**关键区分**：
- 如果 `<devbooks-root>/ssot/` 目录不存在或为空，应先使用 `brownfield-bootstrap` 初始化
- 本 Skill 只处理**已有 SSOT 的增删改**，不负责从零创建

## SSOT 与 Spec 的区别

| 维度 | SSOT | Spec |
|------|------|------|
| **抽象层次** | 需求层（What） | 设计层（How） |
| **粒度** | 项目级 | 模块级 |
| **位置** | `<devbooks-root>/ssot/` | `<truth-root>/` |
| **内容** | 系统必须做什么 | 模块如何工作 |

详见 `docs/SSOT与Spec边界说明.md`

## 前置：配置发现（协议无关）

执行前必须按以下顺序查找配置（找到后停止）：
1. `.devbooks/config.yaml`（如存在）→ 解析映射（尤其是 `paths.ssot`）
2. `dev-playbooks/project.md`（如存在）→ Dev-Playbooks 协议
3. `project.md`（如存在）→ template 协议
4. 若仍无法确定 → 停止并询问用户

## 核心闭环（最小充分）

### 1) 确定 SSOT 来源（只索引，不复制）

- 若存在上游 SSOT 文档库：在项目 `.devbooks/config.yaml` 配置：
  - `truth_mapping: { ssot_root: "SSOT docs/" }`
- 若不存在上游 SSOT：确保 `<devbooks-root>/ssot/SSOT.md` 与 `<devbooks-root>/ssot/requirements.index.yaml` 存在
  - 如果不存在，提示用户先运行 `brownfield-bootstrap` 初始化

### 2) 修改 SSOT（内容编辑）并产出 delta（机读）

你可以用 AI 讨论"要怎么改"，但最终必须落盘为 delta（禁止只留在聊天里）：

- 推荐落点：`<change-root>/<change-id>/inputs/ssot.delta.yaml`
- 约束：`statement` 必须是单行字符串（否则脚本会拒绝执行）
- 每条需求必须有稳定 id；若上游没有 id，可先在 delta 里生成新 id（或留空让脚本自动分配 `R-###`）

### 3) 同步索引（真相）

运行：
- `skills/devbooks-ssot-maintainer/scripts/ssot-index-sync.sh --delta <path> --apply`

脚本会：
- 校验 delta 与现有索引（schema_version、唯一性、操作合法性）
- 对 `requirements.index.yaml` 执行 add/update/remove
- 失败则不写坏原文件

### 4) （可选）刷新进度账本（派生缓存）

若你需要"已做/未做"的可见性（仪表板/审计），可刷新：
- `skills/devbooks-delivery-workflow/scripts/requirements-ledger-derive.sh ...`

注意：ledger 是 derived cache，可删可重建，不能当作 SSOT 采信。

## 推荐用法（通过 Delivery 统一入口）

当你的诉求是"修改 SSOT/同步索引/更新账本"，建议在 `/devbooks:delivery` 的输入里明确：

- `request_kind=governance`
- 变更类型：SSOT maintenance
- 受影响的 ssot_ids（如已知）
- 上游 SSOT 路径锚点（如果存在）
