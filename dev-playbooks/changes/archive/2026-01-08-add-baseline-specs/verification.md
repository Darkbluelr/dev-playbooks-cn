# 验证与追溯：add-baseline-specs

## A) 目标

- 验证基线规格与现状脚本文档一致
- 为后续变更提供最小可执行验证锚点
- 记录未确认项的验证路径

## B) 覆盖范围

- 覆盖 7 个能力的基线规格增量
- 不包含业务功能验证与性能测试

## C) 追溯矩阵

| 规格文件 | 验证项 | 类型 |
|---|---|---|
| `openspec/changes/add-baseline-specs/specs/install-skills/spec.md` | MANUAL-1 | 手工验证 |
| `openspec/changes/add-baseline-specs/specs/global-hooks/spec.md` | MANUAL-2 | 手工验证 |
| `openspec/changes/add-baseline-specs/specs/openspec-integration/spec.md` | MANUAL-3 | 手工验证 |
| `openspec/changes/add-baseline-specs/specs/protocol-discovery/spec.md` | MANUAL-4 | 手工验证 |
| `openspec/changes/add-baseline-specs/specs/mcp/spec.md` | MANUAL-5 | 手工验证 |
| `openspec/changes/add-baseline-specs/specs/embedding/spec.md` | MANUAL-6 | 手工验证 |
| `openspec/changes/add-baseline-specs/specs/automation-guardrails/spec.md` | MANUAL-7 | 手工验证 |

### 设计决策追溯

| 设计决策 | 验证项 | 证据位置 |
|---|---|---|
| DD-BASE-001 | MANUAL-1, MANUAL-2, MANUAL-3, MANUAL-4, MANUAL-5, MANUAL-6, MANUAL-7 | `openspec/changes/add-baseline-specs/evidence/` |
| DD-BASE-002 | MANUAL-1, MANUAL-2, MANUAL-3, MANUAL-4, MANUAL-5, MANUAL-6, MANUAL-7 | `openspec/changes/add-baseline-specs/evidence/` |

## D) 手工验证清单（MANUAL）

- MANUAL-1：Skills 安装脚本
  - 命令：`./scripts/install-skills.sh --dry-run`
  - 预期：输出包含安装目标 `~/.claude/skills` 与 `$CODEX_HOME/skills`，并列出 devbooks-* 目录
- MANUAL-2：全局 Hook 安装
  - 命令：`./setup/global-hooks/install.sh`
  - 预期：`~/.claude/hooks/augment-context-global.sh` 存在且可执行，`~/.claude/settings.json` 已包含 hook 配置
- MANUAL-3：OpenSpec 集成
  - 命令：按 `setup/openspec/安装提示词.md` 执行
  - 预期：`.devbooks/config.yaml`、`openspec/project.md` 与根 `AGENTS.md` 按模板完成接线
- MANUAL-4：协议发现脚本
  - 命令：`./scripts/config-discovery.sh`
  - 预期：输出 `protocol=openspec`，`truth_root=openspec/specs/`，`change_root=openspec/changes/`
- MANUAL-5：MCP Server
  - 命令：`cd mcp/devbooks-mcp-server && npm install && npm run build`
  - 预期：`dist/index.js` 生成且 `npm run build` 成功
- MANUAL-6：Embedding
  - 命令：`./tools/devbooks-embedding.sh build`
  - 预期：`.devbooks/embeddings/` 生成索引文件
- MANUAL-7：自动化守门
  - 命令：`bash setup/hooks/install-git-hooks.sh .`
  - 预期：`.git/hooks/post-commit`、`.git/hooks/post-merge`、`.git/hooks/post-checkout` 存在且可执行

## E) TBD 验证任务

1. 确认仓库是否有统一测试入口
   - 动作：检查根目录是否存在 CI 工作流或测试脚本
2. 确认 MCP 与索引器的运行环境与依赖版本
   - 动作：核对 `setup/hooks/README.md` 与 `tools/devbooks-indexer.sh`
3. 确认 Embedding API 供应商与密钥获取方式
   - 动作：核对 `docs/embedding-guide.md`
4. 评估是否需要定义分层约束
   - 动作：基于现有目录结构评估是否需要新增分层规则文档

## F) 证据与输出位置

- 手工验证输出与日志建议放置在：`openspec/changes/add-baseline-specs/evidence/`
- 热点统计可复用命令：`git -c core.quotepath=false log --since="30 days ago" --name-only --pretty=format:`
