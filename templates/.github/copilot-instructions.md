# GitHub Copilot Instructions (DevBooks)

## Language

- 默认使用中文（除非明确要求使用其他语言）。

## Workflow

- 当请求涉及 proposal/spec/change/plan、引入新功能/破坏性变更/架构变更、或请求不明确时：先阅读 `AGENTS.md` 并遵循其中的 DevBooks 协议发现与约束。

## Constraints

- 不要猜测目录根与协议；按 `.devbooks/config.yaml` → `dev-playbooks/project.md` → `project.md` 顺序发现配置。
- 遵守角色隔离：Test Owner 与 Coder 不在同一会话；Coder 禁止修改 `tests/`。
