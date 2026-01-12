# glossary.md

---
owner: devbooks-brownfield-bootstrap
last_verified: 2026-01-10
status: Draft
freshness_check: 3 Months
---

## 术语表（Ubiquitous Language）

| 术语（中文） | 术语（英文） | 代码名/实体 | 定义（业务含义） | 同义词（允许） | 禁用词（避免） | 备注/例子 |
|---|---|---|---|---|---|---|
| DevBooks | DevBooks | DevBooks | 面向 Claude Code 与 Codex CLI 的代理式开发工作流集合 | Dev Playbooks | 无 | 证据：`README.md` |
| Skill | Skill | devbooks-* | 可被 AI 调用的工作流或角色能力模块 | 技能 | Script | 证据：`skills/` |
| DevBooks | DevBooks | dev-playbooks/ | 规范驱动开发协议与目录结构 | DevBooks 协议 | 无 | 证据：`AGENTS.md` |
| 真理源 | Truth Root | truth_root | 当前规格与规则的唯一权威目录 | 真理目录 | source-of-truth | 证据：`setup/dev-playbooks/template.devbooks-config.yaml` |
| 变更包 | Change Package | change_root | 每次变更的提案、规格与验证产物目录 | 变更目录 | patch | 证据：`setup/dev-playbooks/template.devbooks-config.yaml` |
| MCP | MCP | mcpServers | Model Context Protocol 的服务器配置 | Model Context Protocol | Plugin | 证据：`mcp/mcp_claude.md` |
| CKB | CKB | ckb | 代码知识后端，用于图基分析 | Code Knowledge Backend | 无 | 证据：`mcp/mcp-servers.md` |
| Test Reviewer | Test Reviewer | devbooks-test-reviewer | 测试质量评审角色，只读取 tests/，评审覆盖率/边界条件/可读性/可维护性 | 测试评审员 | Code Reviewer | 证据：`skills/devbooks-test-reviewer/SKILL.md` |
