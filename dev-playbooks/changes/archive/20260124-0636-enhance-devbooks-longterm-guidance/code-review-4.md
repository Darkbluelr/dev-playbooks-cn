# 文档与 Skills 审查（收敛版）

评审视角：System Architect / Security Expert  
范围：`README.md`、`docs/使用指南.md`、`docs/Skill详解.md`、`skills/*/SKILL.md`

## 1) 渐进披露/上下文爆炸
结论：违反。多个 SKILL.md 将“渐进披露”放在长段落之后，读者先暴露于细节，分层导览失效。  
证据（样例）：`skills/devbooks-reviewer/SKILL.md:210`、`skills/devbooks-proposal-author/SKILL.md:185`、`skills/devbooks-design-doc/SKILL.md:255`。  
建议：将“基础层（必读）”摘要前置到文档开头，进阶/扩展层移入 references 或折叠区块。

## 2) 设计思路写入用户文档（“为了…所以…”类）
结论：存在（未发现“为了…所以…”字面，但“约束/取舍/影响”属于设计权衡描述）。  
证据：`README.md:26`、`docs/使用指南.md:52`、`docs/Skill详解.md:7`。  
建议：抽成单一权威说明或移入 design/spec 文档。

## 3) SKILL.md 是否仍绑定具体 MCP 服务名
结论：未发现绑定。`skills/*/SKILL.md` 未出现 CKB/Context7/GitHub/Playwright 或 `mcp__` 工具名。  
证据：关键词检索结果为空（`rg -n "CKB|Context7|GitHub|Playwright|mcp__" skills/*/SKILL.md`）。

## 4) 术语一致性问题
结论：存在。glossary 允许“测试评审员”，但文档与 SKILL.md 使用“测试评审/测试评审者”。  
证据：`dev-playbooks/specs/_meta/glossary.md:21`、`README.md:181`、`docs/Skill详解.md:282`、`skills/devbooks-test-reviewer/SKILL.md:12`。  
建议：统一术语或在 glossary 增补允许同义词。
