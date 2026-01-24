# MCP 提示模板（推荐 MCP 能力类型）

> 本模板供各 `skills/**/SKILL.md` 引用，用于提示“本任务适合使用哪些 MCP 能力类型”。
> 不绑定任何具体 MCP 服务/工具名，不描述运行时检测、超时、失败处理与降级策略。

---

## 标准章节格式（复制到 SKILL.md）

```markdown
## 推荐 MCP 能力类型
- 代码检索（code-search）
- 引用追踪（reference-tracking）
- 影响分析（impact-analysis）
- 文档检索（doc-retrieval）
```

## 规则（SKILL.md 专用）

- 只写能力类型清单（中文名 + 可选英文标识）。
- 不写具体 MCP 服务名称、函数名或命令（例如 `ckb`、`context7`、`mcp__*`）。
- 不写运行时检测/超时阈值/失败处理/降级提示。

---

## 旧版“## MCP 增强”章节（弃用）

`skills/**/SKILL.md` 不再使用"## MCP 增强/依赖的 MCP 服务/增强模式 vs 基础模式"等结构。
如需描述 MCP 的运行时检测与失败处理，仅在规格中维护：
- 规格：`dev-playbooks/specs/mcp/spec.md`
