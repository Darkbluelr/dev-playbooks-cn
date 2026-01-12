# Red Baseline Summary - split-augment-add-test-reviewer

**日期**: 2026-01-10
**状态**: Red (预期)

## 测试统计

| 指标 | 值 |
|------|-----|
| 总测试数 | 79 |
| 通过数 | 15 |
| 失败数 | 64 |
| 通过率 | 19.0% |

## 通过的测试（15个）

这些测试在当前代码库中已通过，表示这些条件已满足：

1. `AC-011-1`: fallback strategy implemented in code ✓
2. `AC-011-2`: MCP timeout has fallback handling ✓
3. `AC-011-3`: local script fallback path exists ✓
4. `REG-001`: skills directory still contains 20 existing Skills ✓
5. `REG-002`: openspec protocol directory structure intact ✓
6. `REG-003`: CKB MCP config still exists ✓
7. `CT-FALLBACK-001-1`: fallback strategy documented ✓
8. `CT-FALLBACK-001-2`: fallback strategy implemented ✓
9. `CT-FALLBACK-002-1`: Embedding config has fallback setting ✓
10. `CT-FALLBACK-002-2`: missing index falls back to keyword ✓
11. `CT-PUB-001`: proposal declares no npm publishing ✓
12. `CT-PUB-002`: installation method is git clone ✓
13. `AC-008-1`: README.md no Augment description ✓
14. `AC-008-11`: docs/Augment-vs-DevBooks technical comparison updated ✓
15. `AC-009-1`: README.md no Augment style description ✓

## 失败的测试分类（64个）

### 拆分验收（AC-001~004）: 19 个失败

- AC-001-1~3: code-intelligence-mcp 命令不存在（新项目未创建）
- AC-002-1~12: 11 个代码理解脚本仍在 tools/ 目录
- AC-003-1~3: Hook 未标记 deprecated
- AC-004-1~4: migrate-to-mcp.sh 脚本不存在

### 角色验收（AC-005~007）: 13 个失败

- AC-005-1~10: devbooks-test-reviewer Skill 不存在
- AC-006-1~3: project.md 未包含 test-reviewer
- AC-007-1~3: 角色使用说明.md 未包含 test-reviewer

### 文档验收（AC-008~010）: 12 个失败

- AC-008-2~10, 12~13: 文档未更新包含 code-intelligence-mcp
- AC-009-2~4: README.md 仍包含部分 Embedding/Graph-RAG 描述
- AC-010-1~2: embedding-quickstart.md 未重定向

### 兼容验收（AC-011~012）: 2 个失败

- AC-012-1~2: migrate-to-mcp.sh 不存在

### 契约测试（CT-xxx）: 8 个失败

- CT-MIG-001-1~3, CT-MIG-002-1: 迁移脚本不存在
- CT-ROLE-001-1~2, CT-ROLE-002-1~2: test-reviewer Skill 不存在

## 预期修复顺序

1. **Phase 1**: 创建 devbooks-test-reviewer Skill（AC-005~007, CT-ROLE-001~002）
2. **Phase 2**: 更新文档（AC-008~010）
3. **Phase 3**: 创建迁移脚本（AC-004, AC-012, CT-MIG-001~002）
4. **Phase 4**: 标记 Hook deprecated（AC-003）
5. **Phase 5**: 创建 code-intelligence-mcp 项目并迁移工具（AC-001~002）

## 证据文件

- 完整日志: `evidence/red-baseline/test-run-*.log`

---

*此报告由 Test Owner 生成，用于建立 Red 基线证据。*
