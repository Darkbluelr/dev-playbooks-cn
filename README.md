# DevBooks

**AI 编程的质量闸门：让 AI 助手从"不可预测"变成"可验证"**

[![npm](https://img.shields.io/npm/v/dev-playbooks-cn)](https://www.npmjs.com/package/dev-playbooks-cn)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

![DevBooks 工作流](docs/workflow-diagram.svg)

---

## 最佳实践：一键跑完整闭环

不知道怎么用？直接运行：

```bash
/devbooks-delivery-workflow
```

这个 skill 会自动编排完整的开发闭环：Proposal → Design → Spec → Plan → Test → Implement → Review → Archive

**适用场景**：新功能开发、重大重构、不熟悉 DevBooks 工作流

---

## 定位与文本规范

DevBooks 本体是非 MCP 工具，但提供 MCP 可选集成点，便于按需接入外部能力，同时保留少量自检脚本作为护栏。
DevBooks 是一套围绕协议、工作流、文本规范的协作体系，强调可追溯与可验证。

约束：核心流程必须保持可追溯与可审计。
取舍：更重视一致性检查，接受部分自动化效率降低。
影响：文档可扫描性提高，协作成本下降。

---

## 我们解决的核心问题

### 问题 1：逻辑幻觉与事实捏造

**痛点**：AI 在缺乏知识时倾向于自信地编造代码或库，而非承认无知。

**DevBooks 方案**：
- 规格驱动开发：所有代码必须追溯到 AC-xxx（验收标准）
- Contract Tests：验证对外契约，防止 API 幻觉

### 问题 2：非收敛性调试

**痛点**：修复一个 Bug 引入两个新 Bug，陷入"打地鼠"循环。

**DevBooks 方案**：
- 角色隔离：Test Owner 先跑出 Red 基线，Coder 不能修改测试
- 收敛性审计：`devbooks-convergence-audit` 评估变更包是否有效推进

### 问题 3：局部最优与全局短视

**痛点**：AI 倾向于生成"能跑通"的独立代码块，缺乏对整体架构的考量。

**DevBooks 方案**：
- 设计先行：Design Doc 定义 What/Constraints，不写 How
- 架构约束：Fitness Rules 验证架构规则
- 影响分析：变更前评估跨模块影响

### 问题 4：验证疲劳

**痛点**：AI 生成速度极快，人类审查代码的警觉性随时间呈指数下降。

**DevBooks 方案**：
- 自动化质量闸门：Green 证据检查、任务完成率、角色边界检查
- 强制评审：Reviewer 只审查可维护性，业务正确性由测试保证

---

## 快速开始

### 安装

```bash
# 全局安装
npm install -g dev-playbooks-cn

# 在项目中初始化
dev-playbooks-cn init
```

### 更新

```bash
dev-playbooks-cn update
```

### 支持的 AI 工具

| 工具 | 支持级别 |
|------|----------|
| Claude Code | 完整 Skills（`.claude/skills/`）|
| Codex CLI | 完整 Skills（`.codex/skills/`）|
| Qoder | 完整 Skills |
| OpenCode | 完整 Skills |
| Every Code | 完整 Skills |
| Factory | 原生 Skills（`.factory/skills/`）|
| Cursor | 原生 Skills（`.cursor/skills/`）|
| Windsurf | Rules 系统 |
| Gemini CLI | Rules 系统 |

---

## 文档

- [使用指南](docs/使用指南.md) - 完整工作流程和最佳实践
- [Skill 详解](docs/Skill详解.md) - 18 个 Skills 的特色和功能

---

## 核心理念

### 1. 角色隔离（Role Isolation）

Test Owner 与 Coder **必须在独立对话**中工作。这不是建议，是硬性约束。

**隔离执行基线：**
- 同一对话不同时编写测试与实现
- 测试用于验证规格

### 2. 规格驱动（Spec-Driven）

所有代码必须追溯到 AC-xxx（验收标准）。

```
需求 → Proposal → Design (AC-001, AC-002) → Spec → Tasks → Tests → Code
```

### 3. 证据优先（Evidence-First）

完成由证据定义，而非 AI 声明。

必需的证据：
- 测试通过（Green 证据）
- 构建成功
- 静态检查通过
- 任务完成率 100%

---

## 工作流程

```
1. Proposal（提案）- 分析需求，评估影响
   ↓
2. Design（设计）- 定义 What/Constraints + AC-xxx
   ↓
3. Spec（规格）- 定义对外行为契约
   ↓
4. Plan（计划）- 制定实现计划和任务拆解
   ↓
5. Test（测试）- 编写验收测试（独立对话）
   ↓
6. Implement（实现）- 实现功能（独立对话）
   ↓
7. Review（评审）- 代码评审
   ↓
8. Archive（归档）- 归档变更包
```

---

## 18 个 Skills

| Skill | 阶段 | 作用 |
|-------|------|------|
| devbooks-router | 入口 | 工作流引导 |
| devbooks-proposal-author | Proposal | 撰写提案 |
| devbooks-proposal-challenger | Proposal | 质疑提案 |
| devbooks-proposal-judge | Proposal | 裁决提案 |
| devbooks-design-doc | Design | 编写设计文档 |
| devbooks-spec-contract | Spec | 定义规格契约 |
| devbooks-implementation-plan | Plan | 制定实现计划 |
| devbooks-test-owner | Test | 编写验收测试 |
| devbooks-test-reviewer | Review | 测试评审 |
| devbooks-coder | Implement | 实现功能 |
| devbooks-reviewer | Review | 代码评审 |
| devbooks-archiver | Archive | 归档变更包 |
| devbooks-docs-consistency | Quality | 文档一致性检查 |
| devbooks-impact-analysis | Quality | 影响分析 |
| devbooks-convergence-audit | Quality | 收敛性审计 |
| devbooks-entropy-monitor | Quality | 熵度量监控 |
| devbooks-brownfield-bootstrap | Init | 存量项目初始化 |
| devbooks-delivery-workflow | Full | 完整闭环编排 |

详见 [Skill 详解](docs/Skill详解.md)

---

## 传统 AI 编程对照

### 对比传统 AI 编程

| 传统 AI 编程 | DevBooks |
|-------------|----------|
| AI 自评"已完成" | 测试通过 + 构建成功 |
| 同一对话写测试又写代码 | 角色隔离，独立对话 |
| 无验证闸门 | 多重质量闸门 |
| 边修边破 | 稳定推进 |
| 只支持 0→1 项目 | 支持存量项目 |

### 适用场景

- 新功能开发
- 重大重构
- Bug 修复
- 存量项目接入
- 需要高质量保证的项目

---

## 许可证

MIT License - 详见 [LICENSE](LICENSE)
