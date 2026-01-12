# 验收测试计划：boost-local-intelligence

> **变更包 ID**：boost-local-intelligence
> **Test Owner**：Test Owner
> **创建时间**：2026-01-09
> **状态**：Draft

---

## 1. 测试范围

### 1.1 关联验收标准（AC）

| AC ID | 描述 | 优先级 | 对应规格 |
|-------|------|--------|----------|
| **AC-001** | Ollama 可用时自动使用本地模型 | P0 | SPEC-EMB-001 |
| **AC-002** | Ollama 不可用时自动降级到 API | P0 | SPEC-EMB-001 |
| **AC-003** | API 不可用时降级到关键词搜索 | P0 | SPEC-EMB-001 |
| **AC-004** | CKB API 替代 import 解析 | P0 | SPEC-GRG-001 |
| **AC-005** | 图遍历支持 2-4 跳 | P1 | SPEC-GRG-001 |
| **AC-006** | 熵报告包含 Mermaid 图 | P1 | SPEC-ENT-001 |
| **AC-007** | 意图四分类生效 | P1 | SPEC-INT-001 |
| **AC-008** | 向后兼容 | P0 | 全部规格 |

### 1.2 测试分层策略

| 类型 | 数量 | 覆盖场景 | 预期执行时间 |
|------|------|----------|--------------|
| 单元测试 | 12 | AC-007（意图分类）、函数级别 | < 5s |
| 集成测试 | 18 | AC-001~006、降级机制、API 集成 | < 60s |
| 契约测试 | 22 | CT-EMB-*, CT-GRG-*, CT-ENT-*, CT-INT-* | < 30s |
| 回归测试 | 6 | AC-008（向后兼容） | < 15s |

### 1.3 测试环境要求

| 测试类型 | 运行环境 | 依赖 |
|----------|----------|------|
| 单元测试 | Bash + BATS | 无外部依赖 |
| 集成测试 | Bash + BATS + Mock | Ollama（可选）、ripgrep |
| 契约测试 | Bash + BATS | CKB MCP（可选） |
| 回归测试 | Bash + BATS | 原有配置文件 |

---

## 2. 追溯矩阵

### 2.1 AC → Contract Test 映射

| AC ID | Contract Tests | 测试文件 |
|-------|----------------|----------|
| AC-001 | CT-EMB-001 | `tests/boost-local-intelligence/test_embedding_ollama.bats` |
| AC-002 | CT-EMB-002 | `tests/boost-local-intelligence/test_embedding_fallback.bats` |
| AC-003 | CT-EMB-002 | `tests/boost-local-intelligence/test_embedding_fallback.bats` |
| AC-004 | CT-GRG-001, CT-GRG-004 | `tests/boost-local-intelligence/test_graph_rag_ckb.bats` |
| AC-005 | CT-GRG-003, CT-GRG-007 | `tests/boost-local-intelligence/test_graph_rag_depth.bats` |
| AC-006 | CT-ENT-001, CT-ENT-002 | `tests/boost-local-intelligence/test_entropy_viz.bats` |
| AC-007 | CT-INT-001, CT-INT-003 | `tests/boost-local-intelligence/test_intent_classification.bats` |
| AC-008 | CT-EMB-003, CT-GRG-006, CT-ENT-003, CT-INT-002 | `tests/boost-local-intelligence/test_backward_compat.bats` |

### 2.2 Requirements → Test 映射

| Requirement ID | Test IDs |
|----------------|----------|
| REQ-EMB-001 | T-EMB-001, T-EMB-002 |
| REQ-EMB-002 | T-EMB-003, T-EMB-004, T-EMB-005 |
| REQ-EMB-003 | T-EMB-006, T-EMB-007 |
| REQ-EMB-004 | T-COMPAT-001, T-COMPAT-002 |
| REQ-GRG-001 | T-GRG-001, T-GRG-002 |
| REQ-GRG-002 | T-GRG-003 |
| REQ-GRG-004 | T-GRG-004, T-GRG-005 |
| REQ-ENT-001 | T-ENT-001, T-ENT-002 |
| REQ-ENT-002 | T-ENT-003 |
| REQ-INT-001 | T-INT-001, T-INT-002, T-INT-003, T-INT-004 |
| REQ-INT-002 | T-INT-005 |

---

## 3. 测试用例

### 3.1 P1: 本地 Embedding 测试

#### T-EMB-001: Ollama 可用时自动使用本地模型

**关联**：AC-001, CT-EMB-001, REQ-EMB-001

**前置条件**：
- Ollama 服务运行中
- 模型 `nomic-embed-text` 已下载
- 配置 `embedding.provider: auto`

**测试步骤**：
```bash
./tools/devbooks-embedding.sh search "authentication" --provider auto --format json
```

**预期结果**：
- [ ] 输出包含 `"source": "ollama"`
- [ ] 输出包含 `"model": "nomic-embed-text"`
- [ ] `candidates` 不为空
- [ ] 延迟 < 3s

**实际结果**：`[待填写]`

---

#### T-EMB-002: Ollama 指定模型

**关联**：AC-001, CT-EMB-001, REQ-EMB-001

**前置条件**：
- Ollama 服务运行中
- 模型 `mxbai-embed-large` 已下载

**测试步骤**：
```bash
./tools/devbooks-embedding.sh search "test" --provider ollama --ollama-model mxbai-embed-large --format json
```

**预期结果**：
- [ ] 输出包含 `"model": "mxbai-embed-large"`
- [ ] 返回有效结果

**实际结果**：`[待填写]`

---

#### T-EMB-003: Ollama → OpenAI API 降级

**关联**：AC-002, CT-EMB-002, REQ-EMB-002

**前置条件**：
- Ollama 服务未启动或不可用
- `OPENAI_API_KEY` 环境变量已设置
- 配置 `embedding.provider: auto`

**测试步骤**：
```bash
# 模拟 Ollama 不可用
OLLAMA_UNAVAILABLE=1 ./tools/devbooks-embedding.sh search "test" --provider auto --format json
```

**预期结果**：
- [ ] 日志包含 "Ollama 不可用，降级到 OpenAI API"
- [ ] 输出包含 `"source": "openai"`
- [ ] 返回有效结果

**实际结果**：`[待填写]`

---

#### T-EMB-004: OpenAI API → 关键词搜索降级

**关联**：AC-003, CT-EMB-002, REQ-EMB-002

**前置条件**：
- Ollama 不可用
- `OPENAI_API_KEY` 未设置或无效
- 配置 `embedding.fallback_to_keyword: true`

**测试步骤**：
```bash
unset OPENAI_API_KEY
OLLAMA_UNAVAILABLE=1 ./tools/devbooks-embedding.sh search "authentication" --provider auto --format json
```

**预期结果**：
- [ ] 日志包含 "降级到关键词搜索"
- [ ] 输出包含 `"source": "keyword"`
- [ ] 返回文件列表（基于 ripgrep）

**实际结果**：`[待填写]`

---

#### T-EMB-005: 三级降级完整路径

**关联**：AC-001/002/003, CT-EMB-002, REQ-EMB-002

**前置条件**：
- 配置 `embedding.provider: auto`

**测试步骤**：
```bash
# 测试 1: Ollama 可用
./tools/devbooks-embedding.sh search "test" --provider auto --format json | jq '.source'
# 预期: "ollama"

# 测试 2: Ollama 不可用，API 可用
OLLAMA_UNAVAILABLE=1 ./tools/devbooks-embedding.sh search "test" --provider auto --format json | jq '.source'
# 预期: "openai"

# 测试 3: 全部不可用
OLLAMA_UNAVAILABLE=1 unset OPENAI_API_KEY && ./tools/devbooks-embedding.sh search "test" --provider auto --format json | jq '.source'
# 预期: "keyword"
```

**预期结果**：
- [ ] 三级降级路径正确执行
- [ ] 每次降级都有日志提示

**实际结果**：`[待填写]`

---

### 3.2 P2: CKB 图遍历测试

#### T-GRG-001: CKB API 基础功能

**关联**：AC-004, CT-GRG-001, REQ-GRG-001

**前置条件**：
- CKB MCP 服务在线
- 目标代码库已建立 SCIP 索引

**测试步骤**：
```bash
./tools/graph-rag-context.sh --query "authentication" --format json
```

**预期结果**：
- [ ] `metadata.ckb_available` = `true`
- [ ] `candidates[0].source` = `"ckb"`
- [ ] `candidates[0].symbol_id` 存在
- [ ] 延迟 < 3s

**实际结果**：`[待填写]`

---

#### T-GRG-002: CKB 输出包含符号 ID

**关联**：AC-004, CT-GRG-004, REQ-GRG-005

**前置条件**：
- CKB MCP 服务在线

**测试步骤**：
```bash
./tools/graph-rag-context.sh --query "authenticate" --format json | jq '.candidates[0].symbol_id'
```

**预期结果**：
- [ ] 返回非空的符号 ID（格式：`ckb:repo:sym:*`）

**实际结果**：`[待填写]`

---

#### T-GRG-003: CKB 不可用时降级到 import 解析

**关联**：AC-004, CT-GRG-002, REQ-GRG-002

**前置条件**：
- CKB MCP 服务离线
- 配置 `graph_rag.ckb.fallback_to_import: true`

**测试步骤**：
```bash
CKB_UNAVAILABLE=1 ./tools/graph-rag-context.sh --query "test" --format json
```

**预期结果**：
- [ ] `metadata.ckb_available` = `false`
- [ ] `candidates[0].source` = `"import"`
- [ ] 日志包含 "CKB 不可用，降级到 import 解析"

**实际结果**：`[待填写]`

---

#### T-GRG-004: 2 跳图遍历

**关联**：AC-005, CT-GRG-003, REQ-GRG-004

**前置条件**：
- CKB MCP 服务在线

**测试步骤**：
```bash
./tools/call-chain-tracer.sh --symbol "authenticate" --depth 2 --format json
```

**预期结果**：
- [ ] 返回结果包含 `depth: 0, 1, 2` 的节点
- [ ] 无 `depth > 2` 的节点
- [ ] 调用链路清晰

**实际结果**：`[待填写]`

---

#### T-GRG-005: 4 跳图遍历

**关联**：AC-005, CT-GRG-003, REQ-GRG-004

**前置条件**：
- CKB MCP 服务在线

**测试步骤**：
```bash
./tools/call-chain-tracer.sh --symbol "authenticate" --depth 4 --format json
```

**预期结果**：
- [ ] 返回结果包含 `depth: 0, 1, 2, 3, 4` 的节点
- [ ] 节点数 < 200（避免爆炸）
- [ ] 无循环引用（去重）

**实际结果**：`[待填写]`

---

#### T-GRG-006: 循环引用检测

**关联**：AC-005, CT-GRG-007, REQ-GRG-004

**前置条件**：
- 代码存在循环调用关系

**测试步骤**：
```bash
# 构造循环调用测试场景
./tools/call-chain-tracer.sh --symbol "cyclic_function" --depth 4 --format json
```

**预期结果**：
- [ ] 检测到循环引用
- [ ] 标记循环节点：`"is_cycle": true`
- [ ] 避免无限递归

**实际结果**：`[待填写]`

---

### 3.3 P3: 熵度量可视化测试

#### T-ENT-001: Mermaid 图表生成

**关联**：AC-006, CT-ENT-001, REQ-ENT-001

**前置条件**：
- 配置 `features.entropy_visualization: true`
- 项目有 Git 历史

**测试步骤**：
```bash
./tools/devbooks-entropy-viz.sh --output /tmp/test-entropy-report.md
grep -c '```mermaid' /tmp/test-entropy-report.md
```

**预期结果**：
- [ ] 报告包含至少 2 个 Mermaid 代码块
- [ ] Mermaid 语法正确

**实际结果**：`[待填写]`

---

#### T-ENT-002: Mermaid 趋势图数据正确

**关联**：AC-006, CT-ENT-001, REQ-ENT-001

**前置条件**：
- 配置 `features.entropy_mermaid: true`

**测试步骤**：
```bash
./tools/devbooks-entropy-viz.sh --output /tmp/test-entropy-report.md
grep -A 10 'xychart-beta' /tmp/test-entropy-report.md
```

**预期结果**：
- [ ] 包含 `xychart-beta` 图表
- [ ] X 轴包含时间点
- [ ] Y 轴包含健康度评分

**实际结果**：`[待填写]`

---

#### T-ENT-003: ASCII 仪表盘生成

**关联**：AC-006, CT-ENT-002, REQ-ENT-002

**前置条件**：
- 配置 `features.entropy_ascii_dashboard: true`

**测试步骤**：
```bash
./tools/devbooks-entropy-viz.sh --output /tmp/test-entropy-report.md
grep '综合健康度' /tmp/test-entropy-report.md
grep '████' /tmp/test-entropy-report.md
```

**预期结果**：
- [ ] 包含综合健康度评分
- [ ] 包含进度条字符（████）
- [ ] 包含状态图标（✅ ⚠️）

**实际结果**：`[待填写]`

---

#### T-ENT-004: NO_COLOR 环境变量支持

**关联**：AC-006, CT-ENT-004, REQ-ENT-004

**前置条件**：
- 环境变量 `NO_COLOR=1`

**测试步骤**：
```bash
NO_COLOR=1 ./tools/devbooks-entropy-viz.sh --output /tmp/test-entropy-report.md
grep -E '\[OK\]|\[WARNING\]' /tmp/test-entropy-report.md
```

**预期结果**：
- [ ] 不包含 ANSI 颜色码
- [ ] 状态用文本标识：`[OK]`, `[WARNING]`, `[ERROR]`

**实际结果**：`[待填写]`

---

### 3.4 P5: 意图四分类测试

#### T-INT-001: 调试类意图识别

**关联**：AC-007, CT-INT-001, REQ-INT-001

**前置条件**：
- 函数 `get_intent_type()` 已实现

**测试步骤**：
```bash
source tools/devbooks-common.sh
get_intent_type "fix authentication bug"
```

**预期结果**：
- [ ] 返回 `debug`

**实际结果**：`[待填写]`

---

#### T-INT-002: 重构类意图识别

**关联**：AC-007, CT-INT-001, REQ-INT-001

**前置条件**：
- 函数 `get_intent_type()` 已实现

**测试步骤**：
```bash
source tools/devbooks-common.sh
get_intent_type "refactor auth module"
```

**预期结果**：
- [ ] 返回 `refactor`

**实际结果**：`[待填写]`

---

#### T-INT-003: 新功能类意图识别

**关联**：AC-007, CT-INT-001, REQ-INT-001

**前置条件**：
- 函数 `get_intent_type()` 已实现

**测试步骤**：
```bash
source tools/devbooks-common.sh
get_intent_type "add OAuth support"
```

**预期结果**：
- [ ] 返回 `feature`

**实际结果**：`[待填写]`

---

#### T-INT-004: 文档类意图识别

**关联**：AC-007, CT-INT-001, REQ-INT-001

**前置条件**：
- 函数 `get_intent_type()` 已实现

**测试步骤**：
```bash
source tools/devbooks-common.sh
get_intent_type "update API docs"
```

**预期结果**：
- [ ] 返回 `docs`

**实际结果**：`[待填写]`

---

#### T-INT-005: 向后兼容 is_code_intent()

**关联**：AC-007, CT-INT-002, REQ-INT-002

**前置条件**：
- 函数 `is_code_intent()` 保持原有签名

**测试步骤**：
```bash
source tools/devbooks-common.sh

# 调试类（code intent）
is_code_intent "fix bug" && echo "code" || echo "non-code"

# 文档类（non-code intent）
is_code_intent "update docs" && echo "code" || echo "non-code"
```

**预期结果**：
- [ ] `fix bug` → `code`
- [ ] `update docs` → `non-code`

**实际结果**：`[待填写]`

---

#### T-INT-006: 优先级匹配

**关联**：AC-007, CT-INT-003, REQ-INT-003

**前置条件**：
- 函数 `get_intent_type()` 已实现

**测试步骤**：
```bash
source tools/devbooks-common.sh
# 包含 fix（debug）和 refactor（refactor），优先级 debug 更高
get_intent_type "fix and refactor module"
```

**预期结果**：
- [ ] 返回 `debug`（优先级更高）

**实际结果**：`[待填写]`

---

#### T-INT-007: 大小写不敏感

**关联**：AC-007, CT-INT-003, REQ-INT-003

**前置条件**：
- 函数 `get_intent_type()` 已实现

**测试步骤**：
```bash
source tools/devbooks-common.sh
result1=$(get_intent_type "FIX BUG")
result2=$(get_intent_type "Fix Bug")
result3=$(get_intent_type "fix bug")
[ "$result1" = "$result2" ] && [ "$result2" = "$result3" ] && echo "PASS"
```

**预期结果**：
- [ ] 三者结果一致（均为 `debug`）

**实际结果**：`[待填写]`

---

#### T-INT-008: 边界情况处理

**关联**：AC-007, CT-INT-006, REQ-INT-003

**前置条件**：
- 函数 `get_intent_type()` 已实现

**测试步骤**：
```bash
source tools/devbooks-common.sh
get_intent_type ""           # 空字符串
get_intent_type "   "        # 空白字符
get_intent_type "!@#$%^&*()" # 特殊字符
```

**预期结果**：
- [ ] 空字符串返回 `feature`
- [ ] 空白字符返回 `feature`
- [ ] 特殊字符返回 `feature`

**实际结果**：`[待填写]`

---

### 3.5 向后兼容性测试

#### T-COMPAT-001: 不带新参数时行为一致

**关联**：AC-008, CT-EMB-003, REQ-EMB-004

**前置条件**：
- 配置文件无 `embedding.provider` 字段
- `OPENAI_API_KEY` 已设置

**测试步骤**：
```bash
./tools/devbooks-embedding.sh search "test"
```

**预期结果**：
- [ ] 使用 OpenAI API（原有行为）
- [ ] 无报错
- [ ] 结果格式与原版一致

**实际结果**：`[待填写]`

---

#### T-COMPAT-002: 旧配置格式兼容

**关联**：AC-008, CT-EMB-003, REQ-EMB-004

**前置条件**：
- 使用旧版本配置文件（无 `ollama` 字段）

**测试步骤**：
```bash
# 创建旧格式配置
cat > /tmp/old-config.yaml <<EOF
embedding:
  enabled: true
  model: text-embedding-3-small
EOF

./tools/devbooks-embedding.sh status --config /tmp/old-config.yaml
```

**预期结果**：
- [ ] 正常读取配置
- [ ] 无报错

**实际结果**：`[待填写]`

---

#### T-COMPAT-003: 调用方不受影响

**关联**：AC-008, CT-GRG-006, REQ-GRG-007

**前置条件**：
- 现有 hooks 脚本

**测试步骤**：
```bash
# 测试 augment-context.sh 调用
.claude/hooks/augment-context.sh "test query" 2>&1
```

**预期结果**：
- [ ] 正常执行
- [ ] 无报错
- [ ] 行为与原版一致

**实际结果**：`[待填写]`

---

#### T-COMPAT-004: Graph-RAG 旧版本调用

**关联**：AC-008, CT-GRG-006, REQ-GRG-007

**前置条件**：
- 配置文件无 `graph_rag.ckb` 字段

**测试步骤**：
```bash
./tools/graph-rag-context.sh --query "test"
```

**预期结果**：
- [ ] 自动检测 CKB 可用性
- [ ] 无报错
- [ ] 结果格式向后兼容

**实际结果**：`[待填写]`

---

#### T-COMPAT-005: 熵报告向后兼容

**关联**：AC-008, CT-ENT-003, REQ-ENT-003

**前置条件**：
- 配置 `features.entropy_visualization: false`

**测试步骤**：
```bash
# 禁用可视化
./tools/devbooks-entropy-viz.sh --no-visualization --output /tmp/test-report.md
```

**预期结果**：
- [ ] 报告格式与原版一致
- [ ] 不包含 Mermaid 图表
- [ ] 不包含 ASCII 仪表盘

**实际结果**：`[待填写]`

---

#### T-COMPAT-006: 意图分类向后兼容

**关联**：AC-008, CT-INT-002, REQ-INT-002

**前置条件**：
- 原有调用方使用 `is_code_intent()`

**测试步骤**：
```bash
source tools/devbooks-common.sh

# 验证原有函数签名
type is_code_intent | head -5

# 验证行为
is_code_intent "fix bug" && echo "PASS" || echo "FAIL"
```

**预期结果**：
- [ ] 函数签名不变
- [ ] 行为与原版一致

**实际结果**：`[待填写]`

---

## 4. 测试执行计划

### 4.1 Red 基线（功能未实现前）

| 批次 | 测试 | 预期结果 | 实际结果 |
|------|------|----------|----------|
| 1 | T-EMB-001~005 | 全部 FAIL | `[待执行]` |
| 2 | T-GRG-001~006 | 全部 FAIL | `[待执行]` |
| 3 | T-ENT-001~004 | 全部 FAIL | `[待执行]` |
| 4 | T-INT-001~008 | 全部 FAIL | `[待执行]` |
| 5 | T-COMPAT-001~006 | 部分 PASS（原有功能） | `[待执行]` |

### 4.2 Green 基线（功能实现后）

| 批次 | 测试 | 预期结果 | 实际结果 |
|------|------|----------|----------|
| 1 | T-EMB-001~005 | 全部 PASS | `[待执行]` |
| 2 | T-GRG-001~006 | 全部 PASS | `[待执行]` |
| 3 | T-ENT-001~004 | 全部 PASS | `[待执行]` |
| 4 | T-INT-001~008 | 全部 PASS | `[待执行]` |
| 5 | T-COMPAT-001~006 | 全部 PASS | `[待执行]` |

---

## 5. 证据管理

### 5.1 证据目录结构

```
openspec/changes/boost-local-intelligence/evidence/
├── red-baseline/
│   ├── test-embedding-2026-01-09.log
│   ├── test-graph-rag-2026-01-09.log
│   ├── test-entropy-2026-01-09.log
│   └── test-intent-2026-01-09.log
└── green-final/
    ├── test-embedding-2026-01-09.log
    ├── test-graph-rag-2026-01-09.log
    ├── test-entropy-2026-01-09.log
    └── test-intent-2026-01-09.log
```

### 5.2 输出管理规则

- 测试输出 > 50 行：只保留首尾各 10 行 + 失败摘要
- 完整日志：落盘到 `evidence/` 目录
- 大量测试用例列表：用表格摘要

---

## 6. DoD 检查清单

- [ ] **行为测试**：所有 AC 对应测试通过
- [ ] **契约测试**：22 个 CT 全部通过
- [ ] **结构测试**：测试覆盖率 > 80%
- [ ] **静态检查**：无 lint 错误
- [ ] **Red 基线**：证据已落盘
- [ ] **Green 基线**：证据已落盘
- [ ] **追溯矩阵**：完整且一致

---

## 7. 变更历史

| 日期 | 作者 | 变更 |
|------|------|------|
| 2026-01-09 | Test Owner | 初稿 |

---

**状态**：Draft → Red 基线执行中
