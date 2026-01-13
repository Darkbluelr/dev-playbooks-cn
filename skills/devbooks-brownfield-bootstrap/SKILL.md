---
name: devbooks-brownfield-bootstrap
description: devbooks-brownfield-bootstrap：存量项目初始化：在当前真理目录为空时生成项目画像、术语表、基线规格与最小验证锚点，避免"边补 specs 边改行为"。用户说"存量初始化/基线 specs/项目画像/建立 glossary/把老项目接入上下文协议"等时使用。
tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
  - Bash
  - mcp__ckb__getStatus
  - mcp__ckb__getArchitecture
  - mcp__ckb__getHotspots
  - mcp__ckb__listKeyConcepts
  - mcp__ckb__getModuleOverview
---

# DevBooks：存量项目初始化（Brownfield Bootstrap）

## 前置：配置发现（协议无关）

- `<truth-root>`：当前真理目录根
- `<change-root>`：变更包目录根
- `<devbooks-root>`：DevBooks 管理目录（通常是 `dev-playbooks/`）

执行前**必须**按以下顺序查找配置（找到后停止）：
1. `.devbooks/config.yaml`（如存在）→ 解析并使用其中的映射
2. `dev-playbooks/project.md`（如存在）→ DevBooks 2.0 协议，使用默认映射
4. `project.md`（如存在）→ template 协议，使用默认映射
5. 若仍无法确定 → **创建 DevBooks 目录结构并初始化基础配置**

**关键约束**：
- 如果配置中指定了 `agents_doc`（规则文档），**必须先阅读该文档**再执行任何操作
- 禁止猜测目录根
- 禁止跳过规则文档阅读

---

## 核心职责

存量项目初始化包含以下职责：

### 1. 基础配置文件初始化（新增）

在 `<devbooks-root>/`（通常是 `dev-playbooks/`）下检查并创建：

| 文件 | 用途 | 创建条件 |
|------|------|----------|
| `constitution.md` | 项目宪法（GIP 原则） | 文件不存在时 |
| `project.md` | 项目上下文（技术栈/约定） | 文件不存在时 |

**创建方式**：
- **不是简单复制模板**，而是根据代码分析结果定制内容
- `constitution.md`：基于默认 GIP 原则，可根据项目特性调整
- `project.md`：根据代码分析结果填充：
  - 技术栈（语言/框架/数据库）
  - 开发约定（代码风格/测试策略/Git 工作流）
  - 领域上下文（核心概念/角色定义）
  - 目录根映射

### 2. 项目画像与元数据

在 `<truth-root>/_meta/` 下生成：

| 产物 | 路径 | 说明 |
|------|------|------|
| 项目画像 | `_meta/project-profile.md` | 三层架构的详细技术画像 |
| 术语表 | `_meta/glossary.md` | 统一语言表（可选但推荐） |
| 领域概念 | `_meta/key-concepts.md` | CKB 提取的概念（增强模式） |

### 3. 架构分析产物

在 `<truth-root>/architecture/` 下生成：

| 产物 | 路径 | 数据来源 |
|------|------|----------|
| 模块依赖图 | `architecture/module-graph.md` | `mcp__ckb__getArchitecture` |
| 技术债热点 | `architecture/hotspots.md` | `mcp__ckb__getHotspots` |

### 4. 基线变更包

在 `<change-root>/<baseline-id>/` 下生成：

| 产物 | 说明 |
|------|------|
| `proposal.md` | 基线范围、In/Out、风险 |
| `design.md` | 现状盘点（capability inventory） |
| `specs/<cap>/spec.md` | 基线 spec deltas（ADDED 为主） |
| `verification.md` | 最小验证锚点计划 |

---

## COD 模型生成（Code Overview & Dependencies）

在初始化时自动生成项目的"代码地图"（需要 CKB MCP Server 可用，否则跳过）：

### 自动生成产物

| 产物 | 路径 | 数据来源 |
|------|------|----------|
| 模块依赖图 | `<truth-root>/architecture/module-graph.md` | `mcp__ckb__getArchitecture` |
| 技术债热点 | `<truth-root>/architecture/hotspots.md` | `mcp__ckb__getHotspots` |
| 领域概念 | `<truth-root>/_meta/key-concepts.md` | `mcp__ckb__listKeyConcepts` |
| 项目画像 | `<truth-root>/_meta/project-profile.md` | 综合分析 |

### 热点计算公式

```
热点分数 = 变更频率 × 圈复杂度
```

- **高热点**（分数 > 阈值）：频繁修改 + 高复杂度 = Bug 密集区
- **休眠债务**（高复杂度 + 低频率）：暂时安全但需关注
- **活跃健康**（高频率 + 低复杂度）：正常维护区域

### 边界识别

自动区分：
- **用户代码**：`src/`、`lib/`、`app/` 等（可修改）
- **库代码**：`node_modules/`、`vendor/`、`.venv/` 等（不可变接口）
- **生成代码**：`dist/`、`build/`、`*.generated.*` 等（禁止手动修改）

### 执行流程

1) **检查图索引**：调用 `mcp__ckb__getStatus`
   - 若 SCIP 可用 → 使用图基分析
   - 若不可用 → 提示生成索引或使用 Git 历史分析

2) **生成 COD 产物**：
   ```bash
   # 获取模块架构
   mcp__ckb__getArchitecture(depth=2, includeExternalDeps=false)

   # 获取热点（近 30 天）
   mcp__ckb__getHotspots(limit=20)

   # 获取领域概念
   mcp__ckb__listKeyConcepts(limit=12)
   ```

3) **生成项目画像**：整合以上数据 + 传统分析

## 参考骨架与模板

- 工作流：`references/存量项目初始化.md`
- 代码导航策略：`references/代码导航策略.md`
- **项目画像模板（三层架构）**：`templates/project-profile-template.md`
- 一次性提示词：`references/存量项目初始化提示词.md`
- 模板（按需）：`references/术语表模板.md`

---

## 上下文感知

本 Skill 在执行前自动检测上下文，选择合适的初始化范围。

检测规则参考：`skills/_shared/context-detection-template.md`

### 检测流程

1. 检测 `<devbooks-root>/constitution.md` 是否存在
2. 检测 `<devbooks-root>/project.md` 是否存在
3. 检测 `<truth-root>/` 是否为空或基本为空
4. 检测 CKB 索引是否可用
5. 检测项目规模和语言栈

### 本 Skill 支持的模式

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| **全新初始化** | devbooks-root 不存在或为空 | 创建完整目录结构 + constitution + project + 画像 |
| **补充配置** | constitution/project 缺失 | 只补充缺失的配置文件 |
| **完整初始化** | truth-root 为空 | 生成所有基础产物（画像/基线/验证） |
| **增量初始化** | truth-root 部分存在 | 只补充缺失产物 |
| **增强模式** | CKB 索引可用 | 使用图分析生成更精确的画像 |
| **基础模式** | CKB 索引不可用 | 使用传统分析方法 |

### 检测输出示例

```
检测结果：
- devbooks-root：存在
- constitution.md：不存在 → 将创建
- project.md：不存在 → 将创建
- truth-root：为空
- CKB 索引：可用
- 项目规模：中型（~50K LOC）
- 运行模式：补充配置 + 完整初始化 + 增强模式
```

---

## MCP 增强

本 Skill 支持 MCP 运行时增强，自动检测并启用高级功能。

MCP 增强规则参考：`skills/_shared/mcp-enhancement-template.md`

### 依赖的 MCP 服务

| 服务 | 用途 | 超时 |
|------|------|------|
| `mcp__ckb__getStatus` | 检测 CKB 索引可用性 | 2s |
| `mcp__ckb__getArchitecture` | 获取模块依赖图 | 2s |
| `mcp__ckb__getHotspots` | 获取技术债热点 | 2s |
| `mcp__ckb__listKeyConcepts` | 获取领域概念 | 2s |
| `mcp__ckb__getModuleOverview` | 获取模块概览 | 2s |

### 检测流程

1. 调用 `mcp__ckb__getStatus`（2s 超时）
2. 若 CKB 可用 → 使用图基分析生成 COD 产物
3. 若超时或失败 → 降级到传统分析（Git 历史 + 文件统计）

### 增强模式 vs 基础模式

| 功能 | 增强模式 | 基础模式 |
|------|----------|----------|
| 模块依赖图 | CKB getArchitecture | 目录结构推断 |
| 技术债热点 | CKB getHotspots | Git log 统计 |
| 领域概念 | CKB listKeyConcepts | 命名分析 |
| 边界识别 | 精确模块边界 | 目录约定 |

### 降级提示

当 MCP 不可用时，输出以下提示：

```
⚠️ CKB 不可用，使用传统分析方法生成项目画像。
如需更精确的架构分析，请运行 /devbooks:index 生成索引。
```
