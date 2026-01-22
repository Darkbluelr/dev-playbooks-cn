# 现状设计盘点（基线）

## 更新记录

- 2026-01-08：补充基线验收与证据策略

## 目标

- 盘点当前 DevBooks 仓库的能力边界与对外入口
- 为规格基线提供能力清单与依赖方向
- 不引入任何实现改动

## 能力清单（7 项）

1. Skills 安装与分发
   - 入口：`scripts/install-skills.sh`
   - 依赖：`skills/`，`prompts/`
2. 全局上下文 Hook 注入
   - 入口：`setup/global-hooks/install.sh`
   - 依赖：`setup/global-hooks/augment-context-global.sh`
3. OpenSpec 协议集成
   - 入口：`setup/openspec/安装提示词.md`
   - 依赖：`setup/openspec/template.devbooks-config.yaml`，`setup/openspec/OpenSpec集成模板（project.md 与 AGENTS附加块）.md`
4. 协议发现与配置解析
   - 入口：`scripts/config-discovery.sh`
   - 依赖：`.devbooks/config.yaml`
5. MCP 服务器与配置管理
   - 入口：`mcp/devbooks-mcp-server/` 与 `mcp/mcp_*.md`
   - 依赖：Node.js 运行时
6. Embedding 语义检索
   - 入口：`tools/devbooks-embedding.sh`
   - 依赖：`.devbooks/embedding.yaml`
7. 自动化守门与 CI 模板
   - 入口：`setup/hooks/install-git-hooks.sh` 与 `templates/ci/`
   - 依赖：Git 仓库与 CI 环境

## 边界与依赖方向

- 安装与分发以脚本复制为主，不依赖运行时服务
- 全局 Hook 与 Claude Code 配置耦合，写入用户目录配置文件
- MCP 子项目独立构建，与仓库其他模块通过文档和配置集成
- Embedding 与索引工具为可选能力，依赖外部 API 或索引器

## 设计决策与验收策略

### 决策 DD-BASE-001：基线验收以手工验证为主

- 本次基线不新增自动化测试，仅以人工步骤确认脚本与文档的现状行为
- 影响：验收锚点统一落在 MANUAL-1 到 MANUAL-7

### 决策 DD-BASE-002：证据集中存放于变更包的 evidence 目录

- 所有验收输出与日志在归档前集中保管，便于追溯与复核
- 影响：证据收集位置保持一致，不引入新目录

## 规格与契约更新点

### 契约计划

- 本次变更不涉及对外 API、事件或 Schema 的新增与修改
- 不新增契约文件与 Contract Tests
- 兼容性策略保持现状，不引入版本迁移

### 当前真理更新点

归档时将以下基线规格合并到真理源：

1. install-skills
2. global-hooks
3. openspec-integration
4. protocol-discovery
5. mcp
6. embedding
7. automation-guardrails

## 非目标

- 不引入新的能力或命令
- 不调整任何现有脚本与文档的行为
- 不补齐未明确的对外契约细节
