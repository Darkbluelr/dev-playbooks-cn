---
name: devbooks-c4-map
description: devbooks-c4-map：维护/更新项目的 C4 架构地图（当前真理），并按变更输出 C4 Delta。用户说"画架构图/C4/边界/依赖方向/模块地图/架构地图维护"等时使用。
tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
---

# DevBooks：C4 架构地图

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

## 产物落点

- 权威 C4 地图：`<truth-root>/architecture/c4.md`
- 分层约束定义：`<truth-root>/architecture/layering-constraints.md`（可选）

## 分层依赖约束（Layering Constraints）

借鉴 VS Code 的分层架构强制机制，C4 地图应包含**分层约束**章节：

### 分层约束定义规则

1. **单向依赖原则**：上层可依赖下层，下层禁止依赖上层
   - 示例：`base ← platform ← domain ← application ← ui`
   - 箭头方向表示"被依赖方向"

2. **环境隔离原则**：`common` 层只能被 `browser`/`node` 层引用，不能反向
   - `common`：平台无关代码
   - `browser`：浏览器特定代码（DOM API）
   - `node`：Node.js 特定代码（fs、process）

3. **contrib 反向隔离**：贡献模块只能依赖核心，核心禁止依赖贡献模块
   - 示例：`workbench/contrib/*` → `workbench/core`（允许）
   - 示例：`workbench/core` → `workbench/contrib/*`（禁止）

### 分层约束输出格式

在 `c4.md` 的 `## Architecture Guardrails` 部分必须包含：

```markdown
### Layering Constraints

| 层级 | 可依赖 | 禁止依赖 |
|------|--------|----------|
| base | （无） | platform, domain, application, ui |
| platform | base | domain, application, ui |
| domain | base, platform | application, ui |
| application | base, platform, domain | ui |
| ui | base, platform, domain, application | （无） |

### Environment Constraints

| 环境 | 可引用 | 禁止引用 |
|------|--------|----------|
| common | （平台无关库） | browser/*, node/* |
| browser | common/* | node/* |
| node | common/* | browser/* |
```

## 执行方式

1) 先阅读并遵守：`references/项目开发实用提示词.md`（可验证性 + 结构质量守门）。
2) 严格按完整提示词输出：`references/8 C4 架构地图提示词.md`。
3) 参考分层约束检查清单：`references/分层约束检查清单.md`。
