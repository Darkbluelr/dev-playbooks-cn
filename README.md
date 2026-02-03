# DevBooks

[![npm](https://img.shields.io/npm/v/dev-playbooks-cn)](https://www.npmjs.com/package/dev-playbooks-cn)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**让 AI 写代码从"说完成就完成"变成"有证据才算完成"。**

DevBooks 是一套面向 AI 的工程协议，通过上游真理源（SSOT）、可执行闸门、证据闭环，把 AI 编程从"对话式猜测"升级为"可审计的工程交付"。

---

## 核心理念

软件工程的本质是**在不可靠的组件之上构建可靠的系统**。传统工程用 RAID 对抗不可靠的硬盘，用 TCP 重传对抗不可靠的网络，用 Code Review 对抗不可靠的人类程序员。AI 工程同样需要用**闸门与证据闭环**约束不可靠的 LLM 输出。

DevBooks 不是提示词优化，而是工程约束。

---

## 上游真理源（SSOT）：全开发周期的单一权威

DevBooks 的核心是**上游真理源（Single Source of Truth）**——所有关键知识落盘并版本化，跨对话、跨变更稳定。

```
你的需求文档（如果有）
    ↓ 提取约束，建立索引
specs/（术语、边界、决策、场景）← 跨变更稳定的"项目记忆"
    ↓ 派生变更包
changes/<id>/（提案、设计、任务、证据）
    ↓ 归档回写
specs/（更新真理）
```

**SSOT 解决的问题：**

| 问题 | 根因 | SSOT 如何解决 |
|-----|------|--------------|
| 每次都要从头教 | 对话是临时的，知识没有持久化 | 术语、边界、约束写在文件里，不依赖对话记忆 |
| 改着改着就忘了之前说的 | 上下文窗口有限，早期信息被挤出去 | 真理工件持久化，强制注入关键约束 |
| 不知道改了什么 | 没有可审计的变更记录 | 每次变更有完整记录——提案、设计、任务、证据 |

---

## 账本与索引：持续追踪完成情况

DevBooks 通过**完成合同（Completion Contract）**和**需求索引（Requirements Index）**持续追踪交付状态。

### 完成合同：把"我要什么"编译成机器可检查的清单

```yaml
obligations:
  - id: O-001
    describes: "用户可以通过邮箱登录"
    severity: must
checks:
  - id: C-001
    type: test
    covers: [O-001]
    artifacts: ["evidence/gates/login-test.log"]
```

不是"大概做完了"，而是"这 5 条义务都有证据"。

### 需求索引：把上游文档变成可追溯的义务清单

```yaml
set_id: ARCH-P3
source_ref: "truth://specs/architecture/design.md"
requirements:
  - id: R-001
    severity: must
    statement: "所有 API 必须支持版本化"
  - id: R-002
    severity: should
    statement: "响应时间 < 200ms"
```

当变更包宣称"已完成上游任务"时，系统可以裁判这个宣称——不是口头确认，而是机器校验。

---

## Knife 切片协议：把大需求变成可执行队列

大需求直接交给 AI 会怎样？改了 A 忘了 B，修了 B 又破坏了 C。

Knife 协议通过**复杂度预算**和**拓扑排序**，把 Epic 切成可独立验证的原子变更包队列。

### 切片算法

```
Score = w₁·Files + w₂·Modules + w₃·RiskFlags + w₄·HotspotWeight
```

| 信号 | 权重 | 说明 |
|-----|------|-----|
| files_touched | 1.0 | 每个文件计 1 分 |
| modules_touched | 5.0 | 跨模块风险高 |
| risk_flags | 10.0 | 每个风险旗标计 10 分 |
| hotspot_weight | 2.0 | 高 churn 区域加权 |

**超预算必须再切**——禁止"硬做"。

### 切片不变量

1. **MECE 覆盖**：所有切片的验收点并集等于 Epic 的完整验收点集合，且不重叠
2. **可独立 Green**：每个切片至少一个确定性验证锚点，不允许"中间态不可编译"
3. **拓扑可排序**：依赖图必须无环，执行顺序必须为拓扑序
4. **预算熔断**：超预算必须递归切分，或回流补信息

### 并行执行调度

当 Knife Plan 包含多个 Slice 时，可以生成并行执行清单：

```bash
knife-parallel-schedule.sh <epic-id> --format md --out parallel-schedule.md
```

输出内容：
- **最大并行度**：可同时启动的最大 Agent 数量
- **分层执行清单**：Layer 0（无依赖）→ Layer 1 → Layer N
- **关键路径**：串行依赖深度
- **启动命令模板**：每个 Slice 的 Agent 启动命令

由于当前 AI 编程工具不支持二级子代理调用，Epic 拆分后需要人类协调多个独立 Agent 并行完成。

---

## 7 道闸门：全链路可裁判检查点

| 闸门 | 检查什么 | 失败后果 |
|-----|---------|---------|
| G0 | 输入就绪了吗？基线工件齐全吗？ | 回流到 Bootstrap |
| G1 | 该有的文件都有吗？结构正确吗？ | 阻断 |
| G2 | 任务都完成了吗？绿证据存在吗？ | 阻断 |
| G3 | 切片正确吗？锚点齐全吗？（大需求） | 回流到 Knife |
| G4 | 文档同步了吗？扩展包完整吗？ | 阻断 |
| G5 | 风险覆盖了吗？回滚策略有吗？（高风险） | 阻断 |
| G6 | 证据完整吗？合同满足吗？可以归档吗？ | 阻断 |

任何一道失败，流程阻断。不是警告，是阻断。

---

## 角色隔离：防止 AI 自己验证自己

| 角色 | 职责 | 硬约束 |
|-----|------|-------|
| Test Owner | 从设计推导验收测试 | 禁止看实现代码 |
| Coder | 按任务实现功能 | 禁止修改 tests/ |
| Reviewer | 审查可读性与一致性 | 不改测试不改设计 |

Test Owner 和 Coder 必须在**不同上下文**执行——不是"不同人"，而是"不同对话/不同实例"。两者之间只能通过**落盘工件**交接。

---

## 快速开始

```bash
npm install -g dev-playbooks-cn
dev-playbooks-cn init
dev-playbooks-cn delivery
```

你只需要记住一个命令：`delivery`。系统会问你几个问题，然后生成一份 `RUNBOOK.md`——这是你这次任务的操作手册。照着做就行。

```
你的需求
    ↓
Delivery（判断类型、生成 RUNBOOK）
    ↓
┌─────────────────────────────────┐
│ 小改动 → 直接执行                │
│ 大需求 → 先切片再执行            │
│ 不确定 → 先研究再决策            │
└─────────────────────────────────┘
    ↓
闸门检查（7 道关卡，任何一道失败都会阻断）
    ↓
证据归档（测试日志、构建输出、审批记录）
```

---

## 目录结构

```
project/
├── .devbooks/config.yaml        # 配置入口
└── dev-playbooks/
    ├── constitution.md          # 硬约束（不可绕过的规则）
    ├── specs/                   # 真理源（SSOT）
    │   ├── _meta/
    │   │   ├── glossary.md      # 统一语言
    │   │   ├── boundaries.md    # 模块边界
    │   │   ├── capabilities.yaml # 能力注册表
    │   │   └── epics/           # Knife 切片计划
    │   └── ...
    └── changes/                 # 变更包
        └── <change-id>/
            ├── proposal.md      # 为什么做、做什么
            ├── design.md        # 怎么做、验收标准
            ├── tasks.md         # 拆成可执行的步骤
            ├── completion.contract.yaml  # 完成合同
            ├── verification.md  # 怎么证明做对了
            └── evidence/        # 测试日志、构建输出
```

---

## 适用场景

- **存量项目接入**：自动索引现有文档，提取可裁判约束，建立最小 SSOT 包
- **新项目启动**：引导补齐术语、边界、场景、决策，建立基线
- **日常变更**：最小充分闭环，可复现验证锚点 + 证据归档
- **大型重构**：Knife 切片 + 迁移范式（Expand-Contract / Strangler Fig / Branch by Abstraction）

---

## 下一步

- [快速开始](docs/使用指南.md)
- [设计原理](docs/AI软件工程开发框架设计.md)
- [Skill 详解](docs/Skill详解.md)

---

## 许可证

MIT
