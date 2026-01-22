# Implementation Plan: split-augment-add-test-reviewer

---
owner: Implementation Lead
created: 2026-01-10
status: Completed
design_ref: ./design.md
---

> 产物落点：`openspec/changes/split-augment-add-test-reviewer/tasks.md`
>
> 本文档由 design.md 推导，包含可跟踪的主线计划、验收锚点绑定。

---

## 主线计划区

### Phase 1: 新项目初始化（code-intelligence-mcp）

- [x] **T-001** 创建 `code-intelligence-mcp` 仓库基础结构 [AC: -]
- [x] **T-002** 迁移 11 个代码理解工具脚本到 `scripts/` [AC: AC-002]
- [x] **T-003** 迁移 4 个 Hook 脚本到 `hooks/` [AC: AC-003]
- [x] **T-004** 迁移配置模板到 `config/` [AC: -]
- [x] **T-005** 实现 MCP Server 薄壳 `src/server.ts` [AC: AC-001]
- [x] **T-006** 实现命令行入口 `bin/ci-search` [AC: AC-001]
- [x] **T-007** 创建安装脚本 `install.sh` [AC: AC-001]
- [x] **T-008** 通过 ShellCheck 验证所有脚本 [CON: CON-QUAL-001]
- [x] **T-009** 实现 `--help`, `--version` 参数支持 [CON: CON-QUAL-002]

### 断点区

**CP-1**：新项目可独立运行
- 验证命令：`code-intelligence-mcp --version && code-intelligence-mcp search "test"`

---

### Phase 2: DevBooks 代码修改

- [x] **T-010** Hook 脚本添加 deprecated 警告（Phase 1 策略）[AC: AC-003, CON: CON-COMPAT-001]
- [x] **T-011** 创建迁移脚本 `migrate-to-mcp.sh` [AC: AC-004, CON: CON-COMPAT-002]
- [x] **T-012** 迁移脚本支持 `--dry-run` 和跨平台兼容 [AC: AC-004, CON: CON-COMPAT-003]
- [x] **T-013** 迁移脚本备份 `.devbooks/config.yaml` [AC: AC-012, CON: CON-COMPAT-004]
- [x] **T-014** 更新 `.devbooks/config.yaml` 移除 embedding 段，新增 mcp_dependencies [AC: -]
- [x] **T-015** 实现 MCP 失败降级到本地脚本逻辑 [AC: AC-011, CON: CON-TECH-003]

### 断点区

**CP-2**：迁移脚本可用
- 验证命令：`./migrate-to-mcp.sh --dry-run` 在 macOS/Ubuntu 无报错

---

### Phase 3: test-reviewer 角色实现

- [x] **T-016** 创建 `skills/devbooks-test-reviewer/SKILL.md` [AC: AC-005, CON: CON-ROLE-001~003]
- [x] **T-017** 实现 test-reviewer 评审脚本（如需）[AC: AC-005] *(OQ-003: 暂不需要，评审基于 verification.md)*
- [x] **T-018** 更新 `openspec/project.md` 添加 test-reviewer 角色定义 [AC: AC-006]
- [x] **T-019** 验证 test-reviewer 只读取 `tests/`，不修改代码 [CON: CON-ROLE-001~002, CT: CT-ROLE-001~002] *(通过 SKILL.md 约束定义)*

### 断点区

**CP-3**：test-reviewer Skill 可用
- 验证命令：`/devbooks-test-reviewer` 返回预期产物

---

### Phase 4: 文档更新（12 个文档）

- [x] **T-020** 更新 `README.md`：移除 Augment 描述，新增 MCP 依赖 [AC: AC-008, AC-009]
- [x] **T-021** 更新 `使用说明书.md`：拆分架构说明 [AC: AC-008]
- [x] **T-022** 更新 `角色使用说明.md`：新增 test-reviewer [AC: AC-007, AC-008]
- [x] **T-023** 更新 `openspec/specs/_meta/project-profile.md`：更新能力清单 [AC: AC-008]
- [x] **T-024** 更新 `openspec/specs/_meta/glossary.md`：新增术语 [AC: AC-008]
- [x] **T-025** 更新 `docs/embedding-quickstart.md`：重定向到新项目 [AC: AC-008, AC-010]
- [x] **T-026** 标记 `docs/Augment-vs-DevBooks-技术对比.md` 为历史 [AC: AC-008]
- [x] **T-027** 移动或标记 `docs/Augment技术解析.md` 为历史 [AC: AC-008]
- [x] **T-028** 更新 `setup/README.md`：更新安装流程 [AC: AC-008]
- [x] **T-029** 更新 `setup/hooks/README.md`：重定向到新项目 [AC: AC-008]
- [x] **T-030** 更新 `.devbooks/config.yaml`：配置结构调整 [AC: AC-008]
- [x] **T-031** 更新 `openspec/specs/architecture/c4.md`：C4 Delta 写入 [AC: -]

### 断点区

**CP-4**：文档更新完成
- 验证方法：12 个文档逐项检查，AC-008 ~ AC-010 验证通过

---

### Phase 5: 验证与收尾

- [x] **T-032** 运行 `openspec validate split-augment-add-test-reviewer --strict` [AC: 全部 AC]
- [x] **T-033** Contract Test 执行：CT-MIG-001~002, CT-FALLBACK-001~002, CT-ROLE-001~002 [CT: CT-*]
- [x] **T-034** 现有 20 个 Skills 功能回归测试 [CON: CON-QUAL-003]
- [x] **T-035** 解决 Open Questions（OQ-001~003）[AC: -]

### 断点区

**CP-5（最终）**：变更包可归档
- 验证方法：全部 AC 通过，Contract Test 通过，回归测试通过

---

## 验收锚点映射

| AC-ID | 对应 Task | 验证命令/方法 |
|-------|-----------|---------------|
| AC-001 | T-005, T-006, T-007 | `code-intelligence-mcp --version && code-intelligence-mcp search "test"` |
| AC-002 | T-002 | `ls code-intelligence-mcp/scripts/` 验证 11 个脚本存在 |
| AC-003 | T-003, T-010 | `grep "DEPRECATED" .claude/hooks/augment-context.sh` |
| AC-004 | T-011, T-012 | `./migrate-to-mcp.sh --dry-run` 在 macOS/Ubuntu 无报错 |
| AC-005 | T-016, T-017 | `/devbooks-test-reviewer` 返回预期产物 |
| AC-006 | T-018 | `grep "test-reviewer" openspec/project.md` |
| AC-007 | T-022 | `grep "test-reviewer" 角色使用说明.md` |
| AC-008 | T-020~T-031 | 逐文件检查 |
| AC-009 | T-020 | `grep -v "Augment" README.md`（无匹配为通过） |
| AC-010 | T-025 | 检查 `docs/embedding-quickstart.md` 内容包含重定向信息 |
| AC-011 | T-015 | 模拟 MCP 超时，验证降级到本地脚本 |
| AC-012 | T-013 | `ls .devbooks/config.yaml.bak` |

---

## 约束遵守检查清单

| 约束 ID | 对应 Task | 检查方式 |
|---------|-----------|----------|
| CON-PUB-001~003 | T-007 | 确认 install.sh 使用 git clone，无 npm publish |
| CON-TECH-001 | T-002 | 脚本为 Shell，无 TypeScript 重写 |
| CON-TECH-002 | T-005 | server.ts 为薄壳，核心逻辑在 Shell |
| CON-TECH-003 | T-015 | 降级逻辑存在 |
| CON-TECH-004 | T-005 | package.json 指定 engines.node >= 18 |
| CON-COMPAT-001 | T-010 | Hook 三阶段废弃策略实施 |
| CON-COMPAT-002 | T-011 | 迁移脚本支持 dry-run |
| CON-COMPAT-003 | T-012 | 跨平台测试 |
| CON-COMPAT-004 | T-013 | 配置备份 |
| CON-ROLE-001~003 | T-016, T-019 | test-reviewer 实现验证 |
| CON-QUAL-001 | T-008 | ShellCheck 通过 |
| CON-QUAL-002 | T-009 | --help/--version 支持 |
| CON-QUAL-003 | T-034 | 回归测试通过 |

---

## Open Questions 处理计划

| OQ-ID | 问题 | 建议处理 Task | 默认决策（如不另行决策） |
|-------|------|---------------|-------------------------|
| OQ-001 | `devbooks-index-bootstrap` 和 `devbooks-entropy-monitor` 如何迁移？ | T-002 | 保留在 DevBooks，作为 MCP 客户端调用新项目 |
| OQ-002 | Phase 2/3 绑定版本号？ | T-035 | Phase 2: v2.1.0, Phase 3: v3.0.0 |
| OQ-003 | test-reviewer 是否需要 `references/` 目录？ | T-016 | 暂不需要，评审基于 verification.md 规格 |

---

## 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 新 MCP Server 稳定性不足 | 用户体验下降 | T-015 降级机制 + 双轨运行 |
| 迁移脚本跨平台问题 | 部分用户无法迁移 | T-012 多平台测试覆盖 |
| 文档更新遗漏 | 用户困惑 | T-020~T-031 逐项检查 |

---

## 元数据

| 字段 | 值 |
|------|-----|
| 创建日期 | 2026-01-10 |
| 状态 | Draft |
| 关联 design | ./design.md |
| 作者 | Implementation Lead |
| 任务总数 | 35 |
| 断点数 | 5 |

---

*此编码计划由 design.md 推导，遵循 devbooks-implementation-plan 规范。*
