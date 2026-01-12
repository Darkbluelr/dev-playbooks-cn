# Verification: complete-devbooks-independence

> 产物落点：`dev-playbooks/changes/complete-devbooks-independence/verification.md`
>
> 状态：**Archived**（部分 AC 待后续处理）
> 版本：v1.0.0
> 更新时间：2026-01-12
> Owner：Test Owner
> last_verified：2026-01-12
> archived_by：Spec Gardener
> archive_note：AC-001/012/013/018 标记为"归档后待办"，详见 design.md D-BP-002

---

## ========================
## A) 测试计划指令表
## ========================

### 主线计划区 (Main Plan Area)

- [x] TP1.0 创建测试计划与追溯文档
  - 目标：建立 verification.md，定义测试策略
  - 验收：文档存在且结构完整

- [x] TP1.1 编写 OpenSpec 清理验收测试（AC-001 ~ AC-004）
  - 目标：验证 OpenSpec 引用完全清除
  - 验收：4 个测试用例全部通过
  - 测试类型：unit（静态检查）

- [x] TP1.2 编写 Slash 命令验收测试（AC-005 ~ AC-010）
  - 目标：验证 DevBooks 原生命令可用
  - 验收：6 个测试用例全部通过
  - 测试类型：integration（命令加载）

- [x] TP1.3 编写 npm 包验收测试（AC-011 ~ AC-016）
  - 目标：验证 npm 包功能与纯净性
  - 验收：6 个测试用例全部通过
  - 测试类型：integration + contract

- [x] TP1.4 编写 MCP 可选性验收测试（AC-017 ~ AC-018）
  - 目标：验证无 MCP 环境下基础功能
  - 验收：2 个测试用例全部通过
  - 测试类型：unit

- [x] TP1.5 编写配置发现验收测试（AC-019 ~ AC-020）
  - 目标：验证配置发现逻辑不依赖 OpenSpec
  - 验收：2 个测试用例全部通过
  - 测试类型：unit + integration

- [x] TP1.6 编写迁移验收测试（AC-021 ~ AC-022）
  - 目标：验证迁移脚本有效性
  - 验收：2 个测试用例全部通过
  - 测试类型：integration

- [x] TP2.0 运行测试获取 Red 基线
  - 目标：确认所有测试在实现前失败
  - 验收：Red 基线日志落盘到 evidence/red-baseline/

### 临时计划区 (Temporary Plan Area)

（无临时计划）

### 【断点区】(Context Switch Breakpoint Area)

当前断点：TP2.0 完成

---

## 计划细化区

### Scope & Non-goals

**Scope（测试范围）**：
- AC-001 ~ AC-004：OpenSpec 清理验证（静态检查）
- AC-005 ~ AC-010：Slash 命令功能验证
- AC-011 ~ AC-016：npm 包安装与纯净性验证
- AC-017 ~ AC-018：MCP 可选性验证
- AC-019 ~ AC-020：配置发现逻辑验证
- AC-021 ~ AC-022：迁移脚本验证

**Non-goals（不测试）**：
- UI/UX 相关功能（本项目无 GUI）
- 性能基准测试（非本次变更目标）
- 跨平台兼容性（专注 macOS/Linux）

### 测试金字塔与分层策略

| 类型 | 数量 | 覆盖场景 | 预期执行时间 |
|------|------|----------|--------------|
| 单元测试 | 10 | AC-001~004, AC-017~020 | < 10s |
| 契约测试 | 2 | AC-015~016（纯净性） | < 5s |
| 集成测试 | 10 | AC-005~014, AC-021~022 | < 60s |
| E2E 测试 | 0 | N/A | N/A |

```
        /\
       /  \
      /    \       ≈ 0%（无 E2E）
     /──────\
    /Contract\     ≈ 10%（纯净性检查）
   /──────────\
  / Integration \  ≈ 45%（命令、安装、迁移）
 /────────────────\
/   Unit Tests    \ ≈ 45%（静态检查）
──────────────────
```

### 测试矩阵（AC → Test IDs → 断言点）

| AC ID | Test ID | 断言点 | 测试类型 |
|-------|---------|--------|----------|
| AC-001 | TEST-CLEAN-001 | grep 返回 0 行 | unit |
| AC-002 | TEST-CLEAN-002 | setup/openspec 不存在 | unit |
| AC-003 | TEST-CLEAN-003 | .claude/commands/openspec 不存在 | unit |
| AC-004 | TEST-CLEAN-004 | specs/openspec-integration 不存在 | unit |
| AC-005 | TEST-CMD-001 | devbooks-proposal-author 加载成功 | integration |
| AC-006 | TEST-CMD-002 | devbooks-design-doc 加载成功 | integration |
| AC-007 | TEST-CMD-003 | devbooks-test-owner/coder 加载成功 | integration |
| AC-008 | TEST-CMD-004 | devbooks-code-review 加载成功 | integration |
| AC-009 | TEST-CMD-005 | devbooks-spec-gardener 加载成功 | integration |
| AC-010 | TEST-CMD-006 | devbooks:quick 命令验证 | integration |
| AC-011 | TEST-NPM-001 | npx create-devbooks 可执行 | integration |
| AC-012 | TEST-NPM-002 | dev-playbooks/ 结构完整 | integration |
| AC-013 | TEST-NPM-003 | config.yaml 有效 | contract |
| AC-014 | TEST-NPM-004 | Skills 安装成功 | integration |
| AC-015 | TEST-PURE-001 | tarball 无 changes/ | contract |
| AC-016 | TEST-PURE-002 | tarball 无 backup/ | contract |
| AC-017 | TEST-MCP-001 | 无 MCP 时基础功能正常 | unit |
| AC-018 | TEST-MCP-002 | MCP 检测逻辑正确 | unit |
| AC-019 | TEST-CFG-001 | config-discovery.sh 无 openspec | unit |
| AC-020 | TEST-CFG-002 | Skills 配置发现统一 | integration |
| AC-021 | TEST-MIG-001 | migrate 脚本存在可执行 | unit |
| AC-022 | TEST-MIG-002 | migrate 脚本功能正确 | integration |

### 测试数据与夹具策略

- **配置文件 fixtures**：使用 `tests/complete-devbooks-independence/fixtures/` 目录存放测试配置
- **临时目录**：每个测试在 `$BATS_TMPDIR` 创建隔离环境
- **清理策略**：`teardown` 函数确保测试后清理

### 可复现性策略

- 时间依赖：无
- 随机依赖：无
- 网络依赖：npm 测试需标记 `@network`，默认跳过
- 外部依赖：MCP 测试使用 mock

### 风险与降级

| 风险 | 降级策略 |
|------|----------|
| npm 不可用 | 跳过 AC-011~014，标记 `@skip-no-npm` |
| 无 Claude Code | Slash 命令测试降级为文件存在性检查 |
| 权限不足 | Skills 安装测试使用临时目录 |

### 测试环境要求

| 测试类型 | 运行环境 | 依赖 |
|----------|----------|------|
| 单元测试 | Bash + BATS | 无外部依赖 |
| 契约测试 | Bash + BATS + npm | Node.js >= 18 |
| 集成测试 | Bash + BATS | 完整 DevBooks 环境 |

### 测试隔离要求

- [x] 每个测试独立运行，不依赖执行顺序
- [x] 使用 `setup`/`teardown` 确保环境隔离
- [x] 禁止共享可变状态
- [x] 测试结束后清理创建的临时文件

---

## ========================
## B) 测试代码实现
## ========================

### 测试文件清单

| 文件 | 类型 | 覆盖 AC |
|------|------|---------|
| `tests/complete-devbooks-independence/test_helper.bash` | Helper | 公共函数 |
| `tests/complete-devbooks-independence/test_cleanup.bats` | Unit | AC-001~004 |
| `tests/complete-devbooks-independence/test_slash_commands.bats` | Integration | AC-005~010 |
| `tests/complete-devbooks-independence/test_npm_package.bats` | Integration+Contract | AC-011~016 |
| `tests/complete-devbooks-independence/test_mcp_optional.bats` | Unit | AC-017~018 |
| `tests/complete-devbooks-independence/test_config_discovery.bats` | Unit+Integration | AC-019~020 |
| `tests/complete-devbooks-independence/test_migration.bats` | Integration | AC-021~022 |

### 运行命令

```bash
# 运行所有测试
bats tests/complete-devbooks-independence/

# 按分层运行
bats tests/complete-devbooks-independence/test_cleanup.bats         # 单元测试
bats tests/complete-devbooks-independence/test_mcp_optional.bats    # 单元测试
bats tests/complete-devbooks-independence/test_config_discovery.bats # 单元+集成
bats tests/complete-devbooks-independence/test_slash_commands.bats   # 集成测试
bats tests/complete-devbooks-independence/test_npm_package.bats      # 集成+契约
bats tests/complete-devbooks-independence/test_migration.bats        # 集成测试
```

---

## 追溯矩阵

### AC → Test ID → 证据文件

| AC ID | Test ID | 证据文件 | 状态 |
|-------|---------|----------|------|
| AC-001 | TEST-CLEAN-001 | `evidence/openspec-cleanup.log` | Red |
| AC-002 | TEST-CLEAN-002 | `evidence/openspec-cleanup.log` | Green |
| AC-003 | TEST-CLEAN-003 | `evidence/openspec-cleanup.log` | Green |
| AC-004 | TEST-CLEAN-004 | `evidence/openspec-cleanup.log` | Green |
| AC-005 | TEST-CMD-001 | `evidence/slash-cmd-test.log` | Green |
| AC-006 | TEST-CMD-002 | `evidence/slash-cmd-test.log` | Green |
| AC-007 | TEST-CMD-003 | `evidence/slash-cmd-test.log` | Green |
| AC-008 | TEST-CMD-004 | `evidence/slash-cmd-test.log` | Green |
| AC-009 | TEST-CMD-005 | `evidence/slash-cmd-test.log` | Green |
| AC-010 | TEST-CMD-006 | `evidence/slash-cmd-test.log` | Green |
| AC-011 | TEST-NPM-001 | `evidence/npm-install-test.log` | Green |
| AC-012 | TEST-NPM-002 | `evidence/npm-install-test.log` | Red |
| AC-013 | TEST-NPM-003 | `evidence/npm-install-test.log` | Red |
| AC-014 | TEST-NPM-004 | `evidence/npm-install-test.log` | Green |
| AC-015 | TEST-PURE-001 | `evidence/npm-install-test.log` | Green |
| AC-016 | TEST-PURE-002 | `evidence/npm-install-test.log` | Green |
| AC-017 | TEST-MCP-001 | `evidence/mcp-optional-test.log` | Green |
| AC-018 | TEST-MCP-002 | `evidence/mcp-optional-test.log` | Red |
| AC-019 | TEST-CFG-001 | `evidence/config-discovery-review.md` | Green |
| AC-020 | TEST-CFG-002 | `evidence/config-discovery-review.md` | Green |
| AC-021 | TEST-MIG-001 | `evidence/migration-test.log` | Green |
| AC-022 | TEST-MIG-002 | `evidence/migration-test.log` | Green |

---

## 人工验收清单（MANUAL-*）

以下验收点需要人工验证：

| ID | 描述 | 验证步骤 | 状态 |
|----|------|----------|------|
| MANUAL-001 | Slash 命令在 Claude Code 中实际触发正确 Skill | 在 Claude Code 中输入 `/devbooks:proposal`，观察加载的 Skill | Pending |
| MANUAL-002 | README.md 内容符合独立描述 | 人工审阅 README.md | Pending |

---

## 架构异味报告

### Setup 复杂度

- **低**：测试主要是文件存在性和 grep 检查，setup 简单
- **建议**：无需改进

### Mock 数量

- **低**：仅 MCP 检测需要 mock
- **建议**：保持当前水平

### 清理难度

- **低**：所有临时文件在 `$BATS_TMPDIR`
- **建议**：无需改进

---

## Red 基线状态

**日期**：2026-01-12（评审修复后）
**状态**：Red（5 个测试失败，24 个通过）

> **注意**：部分 AC 已被预先实现（Slash 命令、npm 基础结构、迁移脚本等），
> 剩余 Red 项为 Coder 需要完成的工作。

**失败摘要（Coder 待完成）**：

| AC ID | 测试 | 失败原因 |
|-------|------|----------|
| AC-001 | TEST-CLEAN-001 | OpenSpec 引用未清零（473 处待清理） |
| AC-012 | TEST-NPM-002 | templates/dev-playbooks/ 结构不完整 |
| AC-013 | TEST-NPM-003 | templates/.devbooks/config.yaml 不存在 |
| AC-018 | TEST-MCP-002 | scripts/detect-mcp.sh 不存在 |
| - | TEST-CFG-PRIORITY | config-discovery.sh 优先级问题（额外测试） |

**已通过（无需 Coder 额外工作）**：

| 分类 | 通过数 | 说明 |
|------|--------|------|
| 目录清理 | 3/4 | AC-002~004 已完成 |
| Slash 命令 | 6/6 | AC-005~010 已完成 |
| npm 包 | 4/6 | AC-011,014~016 已完成 |
| MCP 可选性 | 1/2 | AC-017 已完成 |
| 配置发现 | 2/2 | AC-019~020 已完成 |
| 迁移脚本 | 2/2 | AC-021~022 已完成 |

**测试评审修复**（2026-01-12）：
- [C-001] 修复：TEST-PURE-001/002 现在实际运行 npm pack --dry-run
- [M-001] 修复：TEST-CMD-006 增强断言验证快速模式行为
- [M-002] 修复：TEST-MCP-002 简化逻辑为单一清晰路径
- [M-003] 修复：TEST-NPM-004 Skills 数量从配置读取

**详细日志**：`evidence/red-baseline/test-2026-01-12.log`

---

**文档结束**
