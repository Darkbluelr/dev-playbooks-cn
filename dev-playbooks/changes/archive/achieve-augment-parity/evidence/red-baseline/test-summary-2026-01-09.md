# Red 基线测试摘要

**日期**: 2026-01-09
**Change ID**: achieve-augment-parity
**测试框架**: BATS (Bash Automated Testing System)

## 测试结果概览

| 状态 | 数量 | 百分比 |
|------|------|--------|
| 通过 (ok) | 26 | 37% |
| 失败 (not ok) | 38 | 54% |
| 跳过 (skip) | 6 | 9% |
| **总计** | **70** | **100%** |

## 按 AC 分类的失败统计

| AC | 测试文件 | 通过 | 失败 | 跳过 | 失败原因 |
|---|---|---|---|---|---|
| AC-001 | test_embedding.bats | 8 | 0 | 5 | 部分需 API Key |
| AC-002 | test_graph_rag.bats | 0 | 8 | 0 | 工具未实现 |
| AC-003 | test_reranker.bats | 6 | 2 | 0 | 部分功能未实现 |
| AC-004 | test_call_chain.bats | 2 | 9 | 0 | 工具未实现 |
| AC-005 | test_bug_locator.bats | 0 | 10 | 0 | 工具未实现 |
| AC-006 | test_fallback.bats | 2 | 6 | 0 | 工具未实现 |
| AC-007 | test_config.bats | 5 | 3 | 0 | 工具未实现 |
| AC-008 | test_performance.bats | 3 | 3 | 1 | 工具未实现 |

## 主要失败原因

### 1. 工具不存在 (核心失败)

以下工具尚未实现，导致相关测试全部失败：

- `tools/graph-rag-context.sh` - AC-002 Graph-RAG 上下文引擎
- `tools/bug-locator.sh` - AC-005 Bug 定位工具
- `tools/call-chain-tracer.sh` - 部分功能未实现

### 2. 功能未实现

- Graph-RAG 的 `--mock-embedding` 参数不支持
- Call-chain-tracer 的 `--mock-ckb` 参数不支持
- Bug-locator 工具完全缺失
- 降级标记 (fallback marker) 未输出

### 3. 跳过的测试

- 需要 `OPENAI_API_KEY` 的实际 API 测试（5 个）
- 性能 P95 测试（需要扩展执行时间）

## 通过的测试

以下测试已通过，表明部分基础设施已就绪：

1. **AC-001 Embedding 工具**:
   - 工具存在且可执行
   - 支持 --help
   - status 命令工作正常
   - clean 命令工作正常

2. **AC-003 Reranker 工具**:
   - 工具存在且可执行
   - 支持 --help 和 --mock-llm
   - 输出有效 JSON

3. **AC-004 Call Chain 工具**:
   - 工具存在且可执行
   - 支持 --help

4. **AC-007 配置**:
   - 配置缺失时使用默认值
   - 无效配置值时使用默认值
   - 旧版配置兼容性

5. **AC-008 性能**:
   - Hook 单次执行延迟 < 5s
   - 缓存命中显著降低延迟
   - 大型查询不超时

## 下一步行动

Coder 需要实现以下工具/功能以让测试 Green：

1. **P0 - 必须实现**:
   - `tools/graph-rag-context.sh` - 完整实现
   - `tools/bug-locator.sh` - 完整实现
   - `tools/call-chain-tracer.sh` - 补充 --mock-ckb 支持

2. **P1 - 功能完善**:
   - Hook 输出添加 fallback 标记
   - Graph-RAG 添加 --mock-embedding 支持
   - Reranker 添加 reranked_score 字段

## 证据文件

- 完整测试日志: `evidence/red-baseline/test-failures-2026-01-09.log`
