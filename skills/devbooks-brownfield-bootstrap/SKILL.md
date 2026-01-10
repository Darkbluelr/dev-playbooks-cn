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

执行前**必须**按以下顺序查找配置（找到后停止）：
1. `.devbooks/config.yaml`（如存在）→ 解析并使用其中的映射
2. `openspec/project.md`（如存在）→ OpenSpec 协议，使用默认映射
3. `project.md`（如存在）→ template 协议，使用默认映射
4. 若仍无法确定 → **停止并询问用户**

**关键约束**：
- 如果配置中指定了 `agents_doc`（规则文档），**必须先阅读该文档**再执行任何操作
- 禁止猜测目录根
- 禁止跳过规则文档阅读

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
- 一次性提示词：`references/9 存量项目初始化提示词.md`
- 模板（按需）：`references/10 术语表模板.md`
