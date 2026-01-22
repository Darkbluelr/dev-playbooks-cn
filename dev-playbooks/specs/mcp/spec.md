# Spec: MCP Integration

---
owner: Spec Owner
last_verified: 2026-01-12
status: Active
freshness_check: 3 Months
source_change: redesign-slash-command-routing
---

## 1. Requirements

### REQ-MCP-001: DevBooks MCP Server 子项目

系统 SHALL 提供 DevBooks MCP Server 子项目，用于 MCP 工具集成。

**验收条件**：
- `mcp/devbooks-mcp-server/package.json` 存在
- `npm run build` 产出 `dist/index.js`

---

### REQ-MCP-002: MCP 配置指南

系统 SHALL 提供 MCP 配置指南，说明 Claude Code 的配置方式。

**验收条件**：
- `mcp/mcp_claude.md` 存在且包含配置示例

---

### REQ-MCP-003: MCP 运行时检测触发

> 来源：redesign-slash-command-routing 变更

Skill 执行时 SHALL 自动触发 MCP 检测机制，检查 CKB 等 MCP Server 的可用性。

**检测方式**：
- 调用 `mcp__ckb__getStatus()`
- 设置 2s 超时

Trace: AC-006

---

### REQ-MCP-004: MCP 检测超时与降级

> 来源：redesign-slash-command-routing 变更

MCP 检测 SHALL 设置 2 秒超时，超时后自动降级到基础模式。

**降级行为**：
- 输出 `[MCP 检测超时，已降级为基础模式]`
- 使用 Grep + Glob 代替 CKB 工具
- Skill 继续执行（不阻塞）

Trace: AC-007

---

### REQ-MCP-005: SKILL.md MCP 章节

> 来源：redesign-slash-command-routing 变更

每个 SKILL.md SHALL 包含"MCP 增强"章节，说明：
1. 检测方式（调用 `mcp__ckb__getStatus()`）
2. 超时时间（2s）
3. 降级策略

Trace: AC-006

---

## 2. Scenarios

### SC-MCP-001: 构建 MCP Server

- **GIVEN** 在 `mcp/devbooks-mcp-server/` 目录
- **WHEN** 执行 `npm install` 与 `npm run build`
- **THEN** 产物 `dist/index.js` 可用于 MCP 配置

---

### SC-MCP-002: MCP 检测触发

- **GIVEN** 用户执行任意 DevBooks Skill
- **WHEN** Skill 初始化
- **THEN** 日志显示 MCP 检测尝试（`[MCP 检测] 正在检查 CKB 可用性...`）

Trace: AC-006

---

### SC-MCP-003: MCP 检测超时降级

- **GIVEN** CKB MCP Server 不可用或响应超过 2 秒
- **WHEN** Skill 执行 MCP 检测
- **THEN** 2 秒后输出 `[MCP 检测超时，已降级为基础模式]`
- **AND** Skill 继续执行（不阻塞）

Trace: AC-007

---

### SC-MCP-004: MCP 检测成功

- **GIVEN** CKB MCP Server 可用且响应时间 < 2 秒
- **WHEN** Skill 执行 MCP 检测
- **THEN** 输出 `[MCP 检测成功，已启用增强模式]`
- **AND** Skill 使用增强模式（CKB 工具）

---

### SC-MCP-005: 基础模式可用

- **GIVEN** MCP 检测超时或失败
- **WHEN** Skill 需要搜索代码
- **THEN** 使用 Grep/Glob 工具执行搜索
- **AND** 功能正常完成（仅损失部分增强能力）

---

## 3. Contract Tests

| ID | 场景 | 断言 |
|----|------|------|
| CT-MCP-001 | MCP Server 构建 | `dist/index.js` 存在 |
| CT-MCP-002 | MCP 检测触发 | Skill 执行时日志含 MCP 检测 |
| CT-MCP-003 | MCP 超时降级 | 2s 后降级提示出现 |
| CT-MCP-004 | 基础模式可用 | Grep/Glob 正常工作 |

---

## 4. 关联规格

- `specs/slash-commands/spec.md`：Slash 命令规格
- `specs/context-detection/spec.md`：上下文检测规格
