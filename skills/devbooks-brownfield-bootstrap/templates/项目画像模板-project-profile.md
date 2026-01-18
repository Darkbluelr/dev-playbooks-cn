# 项目画像模板（Project Profile Template）

---

## A) 语法层（Syntax Layer）

**目标**：建立代码的结构认知——技术栈、目录布局、构建命令。

### A.1 技术栈概览

| 维度 | 值 |
|------|-----|
| 主语言 | `<language>` |
| 框架 | `<framework>` |
| 运行时 | `<runtime>` |
| 包管理器 | `<package-manager>` |
| 构建工具 | `<build-tool>` |

### A.2 目录结构

```
<project-root>/
├── src/                    # 源代码
│   ├── base/               # 基础层（平台无关）
│   ├── platform/           # 平台层（平台服务）
│   ├── domain/             # 领域层（业务逻辑）
│   ├── application/        # 应用层（用例编排）
│   └── ui/                 # UI 层（用户交互）
├── tests/                  # 测试代码
├── docs/                   # 文档
└── scripts/                # 脚本
```

### A.3 关键命令

| 命令 | 用途 |
|------|------|
| `<install-cmd>` | 安装依赖 |
| `<build-cmd>` | 编译构建 |
| `<test-cmd>` | 运行测试 |
| `<lint-cmd>` | 代码检查 |
| `<start-cmd>` | 启动服务 |

---

## B) 语义层（Semantics Layer）

**目标**：理解代码的逻辑关系——模块依赖、API 边界、数据流向。

### B.1 模块依赖图

> 由 `mcp__ckb__getArchitecture` 生成，或手动维护

```
[base] ← [platform] ← [domain] ← [application] ← [ui]
           ↑
       [external-libs]
```

**分层约束**（Layering Constraints）：

| 层级 | 可依赖 | 禁止依赖 |
|------|--------|----------|
| base | （无） | 所有上层 |
| platform | base | domain, application, ui |
| domain | base, platform | application, ui |
| application | base, platform, domain | ui |
| ui | 所有层 | （无） |

### B.2 核心能力（Capabilities）

| 能力 | 入口 | 负责模块 | 依赖 |
|------|------|----------|------|
| `<capability-1>` | `<entry-point>` | `<module>` | `<deps>` |
| `<capability-2>` | `<entry-point>` | `<module>` | `<deps>` |

### B.3 对外契约

| 类型 | 位置 | 格式 |
|------|------|------|
| REST API | `src/api/` | OpenAPI 3.0 |
| 事件 | `src/events/` | CloudEvents |
| 数据 Schema | `src/schemas/` | JSON Schema |
| 配置 | `config/` | YAML |

### B.4 边界识别

| 区域 | 路径模式 | 属性 |
|------|----------|------|
| **用户代码** | `src/**`, `lib/**` | 可修改 |
| **库代码** | `node_modules/**`, `vendor/**` | 不可变接口 |
| **生成代码** | `dist/**`, `*.generated.*` | 禁止手动修改 |
| **配置文件** | `*.config.*`, `.*rc` | 需要声明变更 |

---

## C) 上下文层（Context Layer）

**目标**：捕获项目的隐性知识——历史决策、团队约定、技术债务。

### C.1 技术债热点

> 由 `mcp__ckb__getHotspots` 生成，或从 Git 历史计算

| 文件 | 变更频率 | 复杂度 | 热点分数 | 风险等级 |
|------|----------|--------|----------|----------|
| `<file-1>` | 高 | 高 | `<score>` | 🔴 Critical |
| `<file-2>` | 中 | 高 | `<score>` | 🟡 High |
| `<file-3>` | 高 | 低 | `<score>` | 🟢 Normal |

### C.2 领域概念（Glossary）

> 由 `mcp__ckb__listKeyConcepts` 生成，或手动维护

| 术语 | 定义 | 代码位置 |
|------|------|----------|
| `<term-1>` | `<definition>` | `<location>` |
| `<term-2>` | `<definition>` | `<location>` |

### C.3 架构决策记录（ADRs）

| 编号 | 标题 | 状态 | 日期 |
|------|------|------|------|
| ADR-001 | `<title>` | Accepted | `<date>` |
| ADR-002 | `<title>` | Superseded | `<date>` |

### C.4 已知约束与限制

| 约束 | 原因 | 影响范围 |
|------|------|----------|
| `<constraint-1>` | `<reason>` | `<scope>` |
| `<constraint-2>` | `<reason>` | `<scope>` |

### C.5 团队约定

| 类别 | 约定 | 强制程度 |
|------|------|----------|
| 命名规范 | `<convention>` | 必须 |
| 提交规范 | `<convention>` | 必须 |
| 分支策略 | `<convention>` | 必须 |
| 代码风格 | `<convention>` | Lint 强制 |

---

## D) 质量闸门（Quality Gates）

### D.1 合并前检查

- [ ] 编译通过：`<build-cmd>`
- [ ] Lint 通过：`<lint-cmd>`
- [ ] 测试通过：`<test-cmd>`
- [ ] 分层约束通过：`guardrail-check.sh --check-layers`
- [ ] 无循环依赖：`guardrail-check.sh --check-cycles`

### D.2 热点变更额外检查

当变更触及热点文件时：

- [ ] 测试覆盖率 ≥ 80%
- [ ] 代码评审重点关注
- [ ] 圈复杂度未增加

---

## E) 元数据

| 字段 | 值 |
|------|-----|
| 创建日期 | `<date>` |
| 最后更新 | `<date>` |
| 维护者 | `<maintainer>` |
| 版本 | `<version>` |
