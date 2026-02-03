# SSOT 与 Spec 边界说明

本文档明确 DevBooks 中 SSOT（Single Source of Truth）和 Spec（Specification）的职责边界。

## 核心区别

| 维度 | SSOT | Spec |
|------|------|------|
| **抽象层次** | 需求层（What） | 设计层（How） |
| **粒度** | 项目级 | 模块级 |
| **内容** | 系统必须做什么 | 模块如何工作 |
| **来源** | 业务/产品/合规/架构约束 | 技术设计决策 |
| **变更频率** | 低（里程碑级） | 中（功能级） |

## 内容示例

### SSOT 示例

```markdown
# R-001: API 错误格式标准化
- severity: must
- 所有对外 API 必须返回标准错误格式
- 错误响应必须包含 code、message、details 字段
```

### Spec 示例

```markdown
# ErrorResponse Spec

## Schema
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| code | string | Y | 错误码，格式 `E-{MODULE}-{NUMBER}` |
| message | string | Y | 人类可读错误信息 |
| details | object | N | 附加上下文 |

## 行为
- 4xx 错误：code 以 `E-CLIENT-` 开头
- 5xx 错误：code 以 `E-SERVER-` 开头
```

## 目录结构

```
dev-playbooks/
├── ssot/                        # 【需求层】项目级真理源
│   ├── SSOT.md                  # 人类可读的需求/约束文档
│   ├── requirements.index.yaml  # 机读索引（稳定 ID → 锚点）
│   └── requirements.ledger.yaml # 派生进度（可丢弃可重建）
│
├── specs/                       # 【设计层】模块级行为规格
│   ├── _meta/                   # 元数据（画像/术语表）
│   ├── architecture/            # 架构约束
│   └── <capability>/spec.md     # 模块规格
│
└── changes/                     # 变更历史
    └── <change-id>/
        ├── proposal.md          # upstream_claims 引用 SSOT
        └── specs/               # spec delta（归档后合并到 specs/）
```

## 追溯链条

```
SSOT.md (R-001: API 错误格式标准化)
    ↓ 索引
requirements.index.yaml (R-001 → anchor → statement)
    ↓ 引用
changes/<id>/proposal.md (upstream_claims: [R-001])
    ↓ 设计
changes/<id>/specs/error-handling/spec.md (ErrorResponse 设计)
    ↓ 归档
specs/error-handling/spec.md (真理)
```

## Skill 职责划分

### SSOT 相关

| Skill | 职责 | 触发时机 |
|-------|------|----------|
| `brownfield-bootstrap` | **创建** SSOT 骨架 | 存量项目初始化 |
| `ssot-maintainer` | **维护** SSOT（增删改） | SSOT 内容变更 |

### Spec 相关

| Skill | 职责 | 触发时机 |
|-------|------|----------|
| `brownfield-bootstrap` | **创建** 基线 Spec | 存量项目初始化 |
| `spec-contract` | **定义** 模块行为规格 | 变更包设计阶段 |
| `design-doc` | **设计** 架构与约束 | 变更包设计阶段 |

## 常见问题

### Q: 什么时候写 SSOT，什么时候写 Spec？

- **写 SSOT**：当你在定义"系统必须满足的约束"时
  - 例：合规要求、SLA 承诺、API 兼容性保证
- **写 Spec**：当你在设计"具体模块如何实现"时
  - 例：接口签名、数据模型、状态机

### Q: SSOT 和 Spec 可以只保留一个吗？

不能。它们是不同抽象层次：
- SSOT 是"输入"（需求来源）
- Spec 是"输出"（设计决策）

一个需求（SSOT）可能影响多个模块的 Spec。

### Q: 变更包的 upstream_claims 引用什么？

引用 SSOT 中的需求 ID（如 `R-001`），不引用 Spec。

Spec 是变更包的"产出"，不是"输入"。
