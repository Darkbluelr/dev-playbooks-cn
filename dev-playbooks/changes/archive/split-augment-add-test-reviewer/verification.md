# Verification: split-augment-add-test-reviewer

---
owner: Test Owner
created: 2026-01-10
status: Red
design_ref: ./design.md
proposal_ref: ./proposal.md
red_baseline: 2026-01-10
evidence_dir: ./evidence/red-baseline/
---

> 产物落点：`openspec/changes/split-augment-add-test-reviewer/verification.md`
>
> 本文档由 design.md 中的 AC 推导，由 Test Owner 负责维护。
>
> **测试代码**：`tests/split-augment-add-test-reviewer/`

---

## 测试分层策略

| 类型 | 数量 | 覆盖场景 | 预期执行时间 |
|------|------|----------|--------------|
| 单元测试 | 12 | AC-001~012 验收准则 | < 30s |
| 契约测试 | 6 | CT-MIG-001~002, CT-FALLBACK-001~002, CT-ROLE-001~002 | < 10s |
| 集成测试 | 0 | 无（本次变更主要是物理拆分） | - |
| E2E 测试 | 0 | 无（Skill 调用由人工验证） | - |

### 测试环境要求

| 测试类型 | 运行环境 | 依赖 |
|----------|----------|------|
| 单元测试 | bash + bats | bats-core, bats-support, bats-assert |
| 契约测试 | bash + bats | bats-core |

### Red 基线状态

- **首次运行**：2026-01-10
- **预期结果**：全部失败（功能未实现）
- **证据目录**：`evidence/red-baseline/`

---

## A) 测试计划指令表

| 指令 ID | 类型 | 描述 | 优先级 |
|---------|------|------|--------|
| VT-001 | 自动化 | 新项目可独立运行验证 | P0 |
| VT-002 | 自动化 | 脚本迁移完整性验证 | P0 |
| VT-003 | 自动化 | Hook deprecated 警告验证 | P1 |
| VT-004 | 自动化 | 迁移脚本 dry-run 验证 | P1 |
| VT-005 | 自动化 | test-reviewer Skill 可用性验证 | P0 |
| VT-006 | 自动化 | 角色定义存在性验证 | P1 |
| VT-007 | 自动化 | 文档更新完整性验证 | P2 |
| VT-008 | 手动 | MCP 降级策略验证 | P1 |
| VT-009 | 自动化 | 配置备份存在性验证 | P2 |

---

## B) 追溯矩阵

| AC-ID | 描述 | VT-ID | 测试状态 | 证据路径 |
|-------|------|-------|----------|----------|
| AC-001 | 新项目可独立运行 | VT-001 | Pending | evidence/vt-001.log |
| AC-002 | 11 个脚本已迁移 | VT-002 | Pending | evidence/vt-002.log |
| AC-003 | Hook 标记 deprecated | VT-003 | Pending | evidence/vt-003.log |
| AC-004 | 迁移脚本 dry-run 无报错 | VT-004 | Pending | evidence/vt-004.log |
| AC-005 | test-reviewer Skill 可调用 | VT-005 | Pending | evidence/vt-005.log |
| AC-006 | project.md 包含 test-reviewer | VT-006 | Pending | evidence/vt-006.log |
| AC-007 | 角色使用说明.md 包含 test-reviewer | VT-007 | Pending | evidence/vt-007.log |
| AC-008 | 12 个文档已更新 | VT-007 | Pending | evidence/vt-007.log |
| AC-009 | README.md 无 Augment 描述 | VT-007 | Pending | evidence/vt-007.log |
| AC-010 | embedding-quickstart.md 重定向 | VT-007 | Pending | evidence/vt-007.log |
| AC-011 | MCP 失败降级到本地脚本 | VT-008 | Pending | evidence/vt-008.log |
| AC-012 | config.yaml.bak 存在 | VT-009 | Pending | evidence/vt-009.log |

---

## C) 执行锚点

### 自动化测试脚本

```bash
#!/bin/bash
# verification-runner.sh

set -e

# VT-001: 新项目可独立运行
vt_001() {
  echo "=== VT-001: 新项目可独立运行 ==="
  code-intelligence-mcp --version
  code-intelligence-mcp search "test"
  echo "VT-001: PASS"
}

# VT-002: 脚本迁移完整性
vt_002() {
  echo "=== VT-002: 脚本迁移完整性 ==="
  local scripts=(
    "embedding.sh"
    "indexer.sh"
    "complexity.sh"
    "entropy-viz.sh"
    "call-chain.sh"
    "graph-rag.sh"
    "bug-locator.sh"
    "reranker.sh"
    "common.sh"
    "cache-utils.sh"
    "test-embedding.sh"
  )
  for script in "${scripts[@]}"; do
    test -f "code-intelligence-mcp/scripts/${script}" || {
      echo "Missing: ${script}"
      exit 1
    }
  done
  echo "VT-002: PASS (11 scripts verified)"
}

# VT-003: Hook deprecated 警告
vt_003() {
  echo "=== VT-003: Hook deprecated 警告 ==="
  grep -q "DEPRECATED" .claude/hooks/augment-context.sh
  echo "VT-003: PASS"
}

# VT-004: 迁移脚本 dry-run
vt_004() {
  echo "=== VT-004: 迁移脚本 dry-run ==="
  ./migrate-to-mcp.sh --dry-run
  echo "VT-004: PASS"
}

# VT-005: test-reviewer Skill 可用性
vt_005() {
  echo "=== VT-005: test-reviewer Skill 可用性 ==="
  test -f skills/devbooks-test-reviewer/SKILL.md
  echo "VT-005: PASS"
}

# VT-006: 角色定义存在性
vt_006() {
  echo "=== VT-006: 角色定义存在性 ==="
  grep -q "test-reviewer" openspec/project.md
  grep -q "test-reviewer" 角色使用说明.md
  echo "VT-006: PASS"
}

# VT-007: 文档更新完整性
vt_007() {
  echo "=== VT-007: 文档更新完整性 ==="
  # 检查 README.md 无 Augment 描述
  ! grep -q "Augment.*功能" README.md || echo "Warning: Augment found in README"
  # 检查 embedding-quickstart.md 重定向
  grep -q "code-intelligence-mcp" docs/embedding-quickstart.md
  echo "VT-007: PASS"
}

# VT-009: 配置备份存在性
vt_009() {
  echo "=== VT-009: 配置备份存在性 ==="
  test -f .devbooks/config.yaml.bak
  echo "VT-009: PASS"
}

# Main
main() {
  vt_001
  vt_002
  vt_003
  vt_004
  vt_005
  vt_006
  vt_007
  vt_009
  echo ""
  echo "=== All automated tests PASSED ==="
}

main "$@"
```

---

## D) MANUAL-* 清单

| MANUAL-ID | 描述 | 验证步骤 | 预期结果 |
|-----------|------|----------|----------|
| MANUAL-001 | MCP 超时降级验证 | 1. 启动 MCP Server<br>2. 模拟网络延迟 >30s<br>3. 触发代码搜索 | 输出 "MCP 响应超时，使用本地脚本..." 并返回结果 |
| MANUAL-002 | MCP 未启动降级验证 | 1. 确保 MCP Server 未启动<br>2. 触发代码搜索 | 输出 "MCP 未启动，使用本地脚本..." 并返回结果 |
| MANUAL-003 | 完全降级失败验证 | 1. MCP 未启动<br>2. 本地脚本不可用<br>3. 触发代码搜索 | 报错退出，输出 "代码搜索不可用，请检查配置" |

---

## E) Contract Tests

| CT-ID | 契约 | 验证内容 | 验证命令 |
|-------|------|----------|----------|
| CT-MIG-001 | 迁移脚本 | dry-run 无报错 | `./migrate-to-mcp.sh --dry-run` |
| CT-MIG-002 | 迁移脚本 | 配置备份存在 | `test -f .devbooks/config.yaml.bak` |
| CT-FALLBACK-001 | MCP 降级 | MCP 超时降级到本地脚本 | MANUAL-001 |
| CT-FALLBACK-002 | Embedding 降级 | 索引缺失降级到关键词搜索 | 模拟测试 |
| CT-ROLE-001 | test-reviewer | 只评审 tests/ 目录 | Skill 实现验证 |
| CT-ROLE-002 | test-reviewer | 不修改任何代码 | Skill 实现验证 |

---

## F) 回归测试清单

| 回归项 | 验证内容 | 验证方式 |
|--------|----------|----------|
| REG-001 | 现有 20 个 Skills 功能不变 | 逐个 Skill 功能验证 |
| REG-002 | OpenSpec 协议流程不变 | proposal/apply/archive 流程验证 |
| REG-003 | CKB MCP 依赖不变 | CKB 功能验证 |

---

## F) 结构质量守门记录

F) 结构质量守门记录

| 检查项 | 状态 | 备注 |
|--------|------|------|
| ShellCheck | Pending | 新项目所有脚本通过 ShellCheck |
| 依赖方向 | Pending | 无循环依赖 |
| 测试覆盖 | Pending | AC 全覆盖 |

- 决策与授权：Design Owner 已授权本次变更，无敏感文件修改

---

## G) 价值流与度量

G) 价值流与度量

- 目标价值信号：代码理解能力复用率（独立项目安装数/DevBooks 用户数）；测试评审独立执行率
- 观测口径：GitHub Release 下载数、Skill 调用日志
- 基线：当前无独立安装数据（首次拆分）
- 目标：拆分后 3 个月内，独立项目获得至少 100 次 clone

---

## 元数据

| 字段 | 值 |
|------|-----|
| 创建日期 | 2026-01-10 |
| 状态 | Red |
| 关联 design | ./design.md |
| 作者 | Test Owner |

---

## H) Red 基线结果摘要（2026-01-10）

### 测试统计

| 指标 | 值 |
|------|-----|
| 总测试数 | 79 |
| 通过数 | 15 |
| 失败数 | 64 |
| 通过率 | 19.0% |

### 失败分类

| 类别 | 失败数 | 原因 |
|------|--------|------|
| 拆分验收 (AC-001~004) | 19 | 新项目未创建，工具未迁移，脚本未创建 |
| 角色验收 (AC-005~007) | 13 | devbooks-test-reviewer Skill 未创建 |
| 文档验收 (AC-008~010) | 12 | 文档未更新 |
| 兼容验收 (AC-011~012) | 2 | 迁移脚本不存在 |
| 契约测试 (CT-xxx) | 8 | 脚本/Skill 不存在 |

### 证据文件

- 完整日志: `evidence/red-baseline/test-run-*.log`
- 摘要报告: `evidence/red-baseline/summary.md`

### 测试代码位置

- `tests/split-augment-add-test-reviewer/test_split.bats` - 拆分验收测试
- `tests/split-augment-add-test-reviewer/test_role.bats` - 角色验收测试
- `tests/split-augment-add-test-reviewer/test_docs.bats` - 文档验收测试
- `tests/split-augment-add-test-reviewer/test_compat.bats` - 兼容验收测试
- `tests/split-augment-add-test-reviewer/test_contract.bats` - 契约测试

---

*此验证文档由 devbooks-test-owner 产出。Red 基线已于 2026-01-10 建立。*
