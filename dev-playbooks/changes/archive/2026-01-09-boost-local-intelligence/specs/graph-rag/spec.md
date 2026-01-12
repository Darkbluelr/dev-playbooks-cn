# 规格：CKB 真实图遍历

> **改进项**：P2 - CKB 真实图遍历（优先级：高）
> **变更包**：boost-local-intelligence
> **版本**：1.0
> **状态**：Draft

---

## 元信息

| 字段 | 内容 |
|------|------|
| Spec ID | SPEC-GRG-001 |
| 对应设计 | `design.md` P2 章节 |
| 涉及组件 | `tools/graph-rag-context.sh`, `tools/call-chain-tracer.sh` |
| 契约变更 | JSON 输出格式、配置文件、CKB API 调用 |

---

## ADDED Requirements

### Requirement: REQ-GRG-001 CKB API 集成

**描述**：系统必须调用真实的 CKB MCP API 进行图遍历，替代现有的 import 解析。

**优先级**：P0（必须）

**涉及的 CKB API**：
1. `mcp__ckb__searchSymbols`：搜索锚点符号
2. `mcp__ckb__getCallGraph`：获取调用关系（callers + callees）
3. `mcp__ckb__findReferences`：查找引用关系

**验收条件**：
- 能够成功调用上述 3 个 CKB MCP API
- API 调用结果正确解析为 JSON 格式
- 图遍历深度支持 2-4 跳（通过 `--max-depth` 参数）
- JSON 输出包含 `"source": "ckb"` 标识

**关联契约**：CT-GRG-001

#### Scenario: SC-GRG-001
- **Given**: CKB MCP 服务可用，SCIP 索引存在
- **When**: 执行 `./tools/graph-rag-context.sh --query "authenticate" --format json`
- **Then**: 返回 JSON 包含 `"source": "ckb"` 和 `"symbol_id"` 字段

---

### Requirement: REQ-GRG-002 保留 import 解析作为降级

**描述**：当 CKB MCP 不可用时，必须自动降级到 import 解析，保证基本可用性。

**优先级**：P0（必须）

**降级条件**：
- CKB MCP 服务不在线
- CKB API 调用超时（> 5s）
- CKB API 返回错误
- 用户配置 `graph_rag.ckb.enabled: false`

**验收条件**：
- 降级时输出清晰日志：`CKB 不可用，降级到 import 解析`
- JSON 输出包含 `"source": "import"` 标识
- 降级后功能仍可用（虽然精度较低）

**关联契约**：CT-GRG-002

#### Scenario: SC-GRG-002
- **Given**: CKB MCP 服务不可用
- **When**: 执行 `./tools/graph-rag-context.sh --query "test" --format json`
- **Then**: 返回 JSON 包含 `"source": "import"` 且日志输出降级提示

---

### Requirement: REQ-GRG-003 CKB 可用性检测

**描述**：启动时必须检测 CKB MCP 是否在线，避免每次查询都尝试连接。

**优先级**：P1（高）

**检测方式**：
- 调用 `mcp__ckb__getStatus` API
- 超时时间：1s（快速失败）
- 缓存检测结果：5 分钟

**验收条件**：
- 检测成功率 > 99%
- 检测延迟 < 100ms
- 检测失败时不影响后续降级

**关联契约**：CT-GRG-001

#### Scenario: SC-GRG-003
- **Given**: CKB MCP 服务可用
- **When**: 调用 `mcp__ckb__getStatus` API
- **Then**: 检测延迟 < 100ms 且返回正确状态

---

### Requirement: REQ-GRG-004 多跳图遍历

**描述**：支持 2-4 跳的图遍历，获取更完整的调用上下文。

**优先级**：P1（高）

**遍历策略**：
- 从锚点符号开始，向上遍历 callers，向下遍历 callees
- 每跳限制节点数：< 50（避免爆炸）
- 支持 BFS 或 DFS 策略（配置可选）
- 返回结果包含每个节点的深度信息

**验收条件**：
- `--max-depth 2` 返回 2 跳内的所有节点
- `--max-depth 4` 返回 4 跳内的所有节点
- 深度标识正确（`depth: 1, 2, 3, 4`）
- 避免循环引用（检测并去重）

**关联契约**：CT-GRG-003

#### Scenario: SC-GRG-004
- **Given**: CKB MCP 服务可用
- **When**: 执行 `./tools/call-chain-tracer.sh --symbol "authenticate" --depth 2 --format json`
- **Then**: 返回结果中所有节点的 depth <= 2

---

### Requirement: REQ-GRG-005 JSON 输出增强

**描述**：JSON 输出必须包含更丰富的元数据，标识数据来源和质量。

**优先级**：P1（高）

**新增字段**：
- `source`：数据来源（`"ckb"` 或 `"import"`）
- `symbol_id`：符号稳定 ID（仅 CKB）
- `depth`：图遍历深度
- `metadata.ckb_available`：CKB 是否可用
- `metadata.graph_depth`：实际遍历深度

**验收条件**：
- JSON Schema 校验通过
- 向后兼容（旧字段保持不变）
- 新增字段可选（import 解析时部分字段为 null）

**关联契约**：CT-GRG-004

#### Scenario: SC-GRG-005
- **Given**: CKB MCP 服务可用
- **When**: 执行 `./tools/graph-rag-context.sh --query "test" --format json`
- **Then**: 返回 JSON 包含 `source`, `symbol_id`, `metadata.ckb_available` 字段

---

### Requirement: REQ-GRG-006 性能要求

**描述**：CKB API 调用性能必须满足 P95 延迟 < 3s 的要求。

**优先级**：P1（高）

**性能指标**：
- P50 延迟：< 1s
- P95 延迟：< 3s
- P99 延迟：< 5s
- 超时阈值：5s（超时则降级）

**验收条件**：
- 100 次查询的 P95 延迟 < 3s
- CKB API 调用不阻塞主线程
- 超时后自动降级

**关联契约**：CT-GRG-005

#### Scenario: SC-GRG-006
- **Given**: CKB MCP 服务可用
- **When**: 执行 100 次图遍历查询
- **Then**: P95 延迟 < 3s

---

### Requirement: REQ-GRG-007 向后兼容性

**描述**：新功能必须保持向后兼容，不破坏现有调用方。

**优先级**：P0（必须）

**兼容性要求**：
- 不带新参数时，行为与原版一致
- 原有 JSON 输出字段保持不变（仅新增字段）
- 现有调用方（hooks）不需要修改

**验收条件**：
- 旧版本脚本调用 `graph-rag-context.sh --query "test"` 仍正常工作
- 旧配置文件不包含 `graph_rag.ckb` 时，自动检测 CKB 可用性
- 所有现有测试用例仍通过

**关联契约**：CT-GRG-006

#### Scenario: SC-GRG-007
- **Given**: 旧版本脚本，旧配置文件（无 `graph_rag.ckb` 字段）
- **When**: 执行 `./tools/graph-rag-context.sh --query "test"`
- **Then**: 功能正常工作，自动检测 CKB 可用性

---

## 2. Scenarios（场景）

### SC-GRG-001: CKB 可用时使用 CKB API

**场景描述**：CKB MCP 服务在线，执行图遍历时调用 CKB API 获取高精度结果。

**Given（前置条件）**：
- CKB MCP 服务在线（`mcp__ckb__getStatus` 返回成功）
- 配置 `graph_rag.ckb.enabled: true` 或未配置（默认）
- 目标代码库已建立 SCIP 索引

**When（操作）**：
```bash
./tools/graph-rag-context.sh --query "authentication logic" --format json
```

**Then（预期结果）**：
- 日志输出：`使用 CKB API 进行图遍历`
- 返回 JSON 包含：
  ```json
  {
    "source": "graph-rag",
    "candidates": [
      {
        "file_path": "src/auth/login.ts",
        "symbol_name": "authenticate",
        "source": "ckb",
        "symbol_id": "ckb:repo:sym:abc123",
        "depth": 1,
        "relevance_score": 0.92
      }
    ],
    "metadata": {
      "ckb_available": true,
      "graph_depth": 2,
      "embedding_source": "ollama"
    }
  }
  ```
- 精度 > 85%（基于预设 10 个查询）
- 延迟 < 3s

**关联需求**：REQ-GRG-001, REQ-GRG-003, REQ-GRG-005

---

### SC-GRG-002: CKB 不可用时降级到 import 解析

**场景描述**：CKB MCP 服务离线或超时，系统自动降级到 import 解析。

**Given（前置条件）**：
- CKB MCP 服务离线（`mcp__ckb__getStatus` 失败）
- 配置 `graph_rag.ckb.fallback_to_import: true`

**When（操作）**：
```bash
./tools/graph-rag-context.sh --query "authentication logic" --format json
```

**Then（预期结果）**：
- 日志输出：`CKB 不可用，降级到 import 解析`
- 返回 JSON 包含：
  ```json
  {
    "source": "graph-rag",
    "candidates": [
      {
        "file_path": "src/auth/login.ts",
        "source": "import",
        "symbol_id": null,
        "depth": 1,
        "relevance_score": 0.68
      }
    ],
    "metadata": {
      "ckb_available": false,
      "graph_depth": 1,
      "degraded_reason": "ckb_unavailable"
    }
  }
  ```
- 使用 import 语句解析
- 精度约 60%（低于 CKB）

**关联需求**：REQ-GRG-002, REQ-GRG-003

---

### SC-GRG-003: 多跳图遍历（2-4 跳）

**场景描述**：使用 CKB API 进行多跳遍历，获取更完整的调用链。

**Given（前置条件）**：
- CKB MCP 服务在线
- 配置 `graph_rag.max_depth: 3`

**When（操作）**：
```bash
./tools/call-chain-tracer.sh --symbol "authenticate" --depth 3 --format json
```

**Then（预期结果）**：
- 返回 3 跳内的所有调用关系：
  ```json
  {
    "root_symbol": "authenticate",
    "call_chain": [
      {
        "symbol": "authenticate",
        "file": "src/auth/login.ts",
        "depth": 0
      },
      {
        "symbol": "validateToken",
        "file": "src/auth/token.ts",
        "depth": 1,
        "called_by": "authenticate"
      },
      {
        "symbol": "checkExpiry",
        "file": "src/auth/token.ts",
        "depth": 2,
        "called_by": "validateToken"
      }
    ],
    "metadata": {
      "total_nodes": 15,
      "max_depth": 3,
      "source": "ckb"
    }
  }
  ```
- 深度标识正确
- 无循环引用

**关联需求**：REQ-GRG-004

---

### SC-GRG-004: 强制禁用 CKB（企业场景）

**场景描述**：企业环境禁止使用 CKB MCP（防火墙限制），强制使用 import 解析。

**Given（前置条件）**：
- 配置 `graph_rag.ckb.enabled: false`

**When（操作）**：
```bash
./tools/graph-rag-context.sh --query "test" --format json
```

**Then（预期结果）**：
- 直接使用 import 解析，不尝试调用 CKB API
- JSON 输出：`"source": "import"`
- 无 CKB 相关日志

**关联需求**：REQ-GRG-002

---

### SC-GRG-005: CKB API 超时自动降级

**场景描述**：CKB API 调用超时（> 5s），自动降级到 import 解析。

**Given（前置条件）**：
- CKB MCP 服务响应缓慢（网络延迟）
- 配置超时时间：5s

**When（操作）**：
```bash
./tools/graph-rag-context.sh --query "test" --format json
```

**Then（预期结果）**：
- 5s 后超时
- 日志输出：`CKB API 超时，降级到 import 解析`
- 自动切换到 import 解析
- 总延迟 < 8s（5s 超时 + 3s import 解析）

**关联需求**：REQ-GRG-002, REQ-GRG-006

---

### SC-GRG-006: 向后兼容旧版本调用

**场景描述**：现有脚本不带新参数调用，应保持原有行为。

**Given（前置条件）**：
- 配置文件为旧版本（无 `graph_rag.ckb` 字段）
- CKB MCP 服务在线

**When（操作）**：
```bash
./tools/graph-rag-context.sh --query "test"  # 旧版本调用方式
```

**Then（预期结果）**：
- 自动检测 CKB 可用性
- 如果 CKB 可用，使用 CKB API
- 如果 CKB 不可用，降级到 import 解析
- 结果格式与原版一致（新增字段不影响旧调用方）

**关联需求**：REQ-GRG-007

---

### SC-GRG-007: 避免循环引用

**场景描述**：代码存在循环调用关系，图遍历必须检测并去重。

**Given（前置条件）**：
- 代码存在循环调用：`A -> B -> C -> A`
- 配置 `graph_rag.max_depth: 4`

**When（操作）**：
```bash
./tools/call-chain-tracer.sh --symbol "A" --depth 4
```

**Then（预期结果）**：
- 检测到循环引用：`A -> B -> C -> A [cycle]`
- 去重后只返回每个符号一次
- 标记循环节点：`"is_cycle": true`
- 避免无限递归

**关联需求**：REQ-GRG-004

---

## 3. API Specification（API 规范）

### 3.1 CLI 接口

#### `graph-rag-context.sh`

**新增参数**：

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `--max-depth` | int | 否 | `2` | 图遍历最大深度（1-4） |
| `--use-ckb` | bool | 否 | `true` | 是否使用 CKB API |
| `--timeout` | int | 否 | `5` | CKB API 超时时间（秒） |

**原有参数**（保持不变）：
- `--query`：搜索查询
- `--format`：输出格式（`json` 或 `text`）
- `--top-k`：返回结果数量

**示例**：
```bash
# 使用 CKB API，2 跳遍历
./tools/graph-rag-context.sh --query "auth logic" --max-depth 2 --format json

# 强制使用 import 解析
./tools/graph-rag-context.sh --query "auth logic" --use-ckb false --format json
```

---

#### `call-chain-tracer.sh`

**新增参数**：

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `--depth` | int | 否 | `2` | 调用链深度（1-4） |
| `--direction` | string | 否 | `both` | 遍历方向：`callers`, `callees`, `both` |

**示例**：
```bash
# 查找 3 跳内的调用链
./tools/call-chain-tracer.sh --symbol "authenticate" --depth 3 --direction both
```

---

### 3.2 配置文件 Schema

#### `.devbooks/config.yaml` - graph_rag 部分

**新增字段**：

```yaml
graph_rag:
  enabled: true

  # CKB 集成（新增）
  ckb:
    enabled: true  # 是否使用 CKB API
    fallback_to_import: true  # CKB 不可用时降级到 import
    timeout: 5  # 超时时间（秒）

  # 图遍历参数
  max_depth: 2  # 1-4
  token_budget: 8000
  top_k: 10
  cache_ttl: 300
```

**字段说明**：

| 字段路径 | 类型 | 必填 | 默认值 | 说明 |
|---------|------|------|--------|------|
| `graph_rag.ckb.enabled` | bool | 否 | `true` | 是否使用 CKB API |
| `graph_rag.ckb.fallback_to_import` | bool | 否 | `true` | CKB 不可用时降级到 import |
| `graph_rag.ckb.timeout` | int | 否 | `5` | CKB API 超时时间（秒） |
| `graph_rag.max_depth` | int | 否 | `2` | 图遍历最大深度（1-4） |

---

### 3.3 JSON 输出 Schema

#### 成功响应（CKB API）

```json
{
  "schema_version": "1.0",
  "source": "graph-rag",
  "token_count": 1234,
  "candidates": [
    {
      "file_path": "src/auth/login.ts",
      "line_start": 10,
      "line_end": 25,
      "symbol_name": "authenticate",
      "relevance_score": 0.92,

      // 新增字段
      "source": "ckb",
      "symbol_id": "ckb:repo:sym:abc123",
      "depth": 1,
      "callers": [
        {
          "symbol_id": "ckb:repo:sym:def456",
          "symbol_name": "handleLogin",
          "file_path": "src/routes/auth.ts",
          "depth": 0
        }
      ],
      "callees": [
        {
          "symbol_id": "ckb:repo:sym:ghi789",
          "symbol_name": "validateToken",
          "file_path": "src/auth/token.ts",
          "depth": 2
        }
      ]
    }
  ],
  "metadata": {
    // 新增元数据
    "ckb_available": true,
    "embedding_source": "ollama",
    "graph_depth": 2,
    "total_symbols": 15,
    "cache_hit": false
  }
}
```

#### 降级响应（import 解析）

```json
{
  "schema_version": "1.0",
  "source": "graph-rag",
  "token_count": 800,
  "candidates": [
    {
      "file_path": "src/auth/login.ts",
      "line_start": 10,
      "line_end": 25,
      "relevance_score": 0.68,

      // 新增字段
      "source": "import",
      "symbol_id": null,
      "depth": 1,
      "callers": [],  // import 解析无法获取 callers
      "callees": []
    }
  ],
  "metadata": {
    "ckb_available": false,
    "embedding_source": "ollama",
    "graph_depth": 1,
    "degraded_reason": "ckb_unavailable"
  }
}
```

---

### 3.4 CKB API 调用规范

#### 调用 `searchSymbols`

**用途**：搜索锚点符号

**请求参数**：
```json
{
  "query": "authenticate",
  "limit": 10,
  "kinds": ["function", "method"]
}
```

**响应处理**：
- 提取 `symbol_id`
- 提取符号位置（`file_path`, `line_start`, `line_end`）
- 作为后续 `getCallGraph` 的输入

---

#### 调用 `getCallGraph`

**用途**：获取调用关系

**请求参数**：
```json
{
  "symbolId": "ckb:repo:sym:abc123",
  "depth": 2,
  "direction": "both"
}
```

**响应处理**：
- 遍历 `callers` 和 `callees`
- 记录每个节点的深度
- 检测循环引用（通过 `symbol_id` 去重）

---

#### 调用 `findReferences`

**用途**：查找引用关系（辅助）

**请求参数**：
```json
{
  "symbolId": "ckb:repo:sym:abc123",
  "limit": 50
}
```

**响应处理**：
- 补充引用信息
- 与 `getCallGraph` 结果合并

---

## 4. Quality Attributes（质量属性）

### 4.1 性能

| 指标 | 目标值 | 测量方式 |
|------|--------|---------|
| P50 延迟 | < 1s | 100 次查询统计 |
| P95 延迟 | < 3s | 100 次查询统计 |
| P99 延迟 | < 5s | 100 次查询统计 |
| CKB API 超时 | 5s | 配置项 |

### 4.2 精度

| 指标 | 目标值 | 测量方式 |
|------|--------|---------|
| CKB API 精度 | > 85% | 10 个预设查询命中率 |
| import 解析精度 | 约 60% | 10 个预设查询命中率 |
| 降级成功率 | 100% | CKB 不可用时自动降级 |

### 4.3 可用性

| 指标 | 目标值 | 测量方式 |
|------|--------|---------|
| CKB 可用时成功率 | 99% | 1000 次查询统计 |
| 降级成功率 | 100% | import 解析始终可用 |
| 循环检测准确率 | 100% | 预设循环调用测试 |

---

## 5. Contract Tests（契约测试计划）

### CT-GRG-001: CKB API 基础功能

**测试类型**：集成测试

**前置条件**：
- CKB MCP 服务运行中
- 目标代码库已建立 SCIP 索引

**测试步骤**：
1. 执行：`./tools/graph-rag-context.sh --query "authenticate" --format json`
2. 验证 JSON 输出：
   - `candidates[0].source` = `"ckb"`
   - `candidates[0].symbol_id` 存在
   - `metadata.ckb_available` = `true`
   - `candidates[0].depth` ≥ 1

**通过标准**：
- 响应时间 < 3s
- JSON Schema 校验通过
- 精度 > 85%（10 个预设查询）

---

### CT-GRG-002: 降级机制

**测试类型**：集成测试

**测试用例 2.1**：CKB 不可用时降级到 import

**步骤**：
1. 停止 CKB MCP 服务
2. 配置 `graph_rag.ckb.fallback_to_import: true`
3. 执行：`./tools/graph-rag-context.sh --query "test" --format json`
4. 验证：
   - `candidates[0].source` = `"import"`
   - `metadata.ckb_available` = `false`
   - `metadata.degraded_reason` = `"ckb_unavailable"`

**测试用例 2.2**：CKB 超时时降级

**步骤**：
1. 模拟 CKB API 延迟（> 5s）
2. 执行：`./tools/graph-rag-context.sh --query "test" --format json`
3. 验证：
   - 5s 后超时
   - 自动降级到 import 解析
   - 日志包含 `"CKB API 超时"`

---

### CT-GRG-003: 多跳图遍历

**测试类型**：功能测试

**测试用例 3.1**：2 跳遍历

**步骤**：
1. 执行：`./tools/call-chain-tracer.sh --symbol "authenticate" --depth 2`
2. 验证：
   - 返回结果包含 `depth: 0, 1, 2` 的节点
   - 无 `depth > 2` 的节点
   - 调用链路清晰

**测试用例 3.2**：4 跳遍历

**步骤**：
1. 执行：`./tools/call-chain-tracer.sh --symbol "authenticate" --depth 4`
2. 验证：
   - 返回结果包含 `depth: 0, 1, 2, 3, 4` 的节点
   - 节点数 < 200（避免爆炸）
   - 无循环引用

---

### CT-GRG-004: JSON 输出格式

**测试类型**：契约测试

**测试用例 4.1**：CKB 输出格式

**步骤**：
1. 执行：`./tools/graph-rag-context.sh --query "test" --format json > output.json`
2. 使用 JSON Schema 校验 `output.json`
3. 验证新增字段：
   - `candidates[].source`
   - `candidates[].symbol_id`
   - `candidates[].depth`
   - `metadata.ckb_available`

**测试用例 4.2**：import 输出格式

**步骤**：
1. 停止 CKB MCP 服务
2. 执行：`./tools/graph-rag-context.sh --query "test" --format json > output.json`
3. 验证：
   - `candidates[].source` = `"import"`
   - `candidates[].symbol_id` = `null`
   - `metadata.ckb_available` = `false`

---

### CT-GRG-005: 性能基准测试

**测试类型**：性能测试

**测试用例 5.1**：CKB API 延迟测试

**步骤**：
1. 执行 100 次查询（不同 query）
2. 记录每次延迟
3. 计算 P50、P95、P99

**通过标准**：
- P50 < 1s
- P95 < 3s
- P99 < 5s

---

### CT-GRG-006: 向后兼容性

**测试类型**：回归测试

**测试用例 6.1**：旧版本调用

**步骤**：
1. 删除配置中的 `graph_rag.ckb` 字段
2. 执行：`./tools/graph-rag-context.sh --query "test"`
3. 验证：正常工作，自动检测 CKB

**测试用例 6.2**：旧配置格式兼容

**步骤**：
1. 使用旧版本配置文件（无 `ckb` 字段）
2. 执行：`./tools/graph-rag-context.sh --query "test"`
3. 验证：无报错，自动检测 CKB 可用性

---

### CT-GRG-007: 循环引用检测

**测试类型**：边界测试

**测试用例 7.1**：简单循环

**步骤**：
1. 构造循环调用：`A -> B -> A`
2. 执行：`./tools/call-chain-tracer.sh --symbol "A" --depth 3`
3. 验证：
   - 检测到循环：`A -> B -> A [cycle]`
   - 去重后只返回 A 和 B 各一次
   - 标记循环节点：`"is_cycle": true`

**测试用例 7.2**：复杂循环

**步骤**：
1. 构造复杂循环：`A -> B -> C -> D -> B`
2. 执行：`./tools/call-chain-tracer.sh --symbol "A" --depth 4`
3. 验证：
   - 检测到循环：`B -> C -> D -> B [cycle]`
   - 避免无限递归

---

## 6. Migration & Rollback（迁移与回滚）

### 6.1 迁移步骤

#### 对现有用户

1. **零配置用户**（使用默认配置）：
   - 无需任何操作
   - 自动检测 CKB 可用性
   - CKB 可用时自动使用，不可用时降级到 import

2. **配置 import 解析的用户**：
   - 无需修改配置
   - 可选：增加 `graph_rag.ckb.enabled: false` 强制使用 import

3. **希望使用 CKB API 的用户**：
   - 确保 CKB MCP 服务运行中
   - 确保代码库已建立 SCIP 索引（通过 `devbooks-index-bootstrap`）
   - 配置：`graph_rag.ckb.enabled: true`（或留空，使用默认）

### 6.2 回滚策略

#### 配置回滚

**方法 1**：强制使用 import 解析
```yaml
graph_rag:
  ckb:
    enabled: false  # 禁用 CKB API
```

**方法 2**：恢复到原版配置
```yaml
graph_rag:
  enabled: true
  # 删除所有 ckb 字段，使用原版 import 解析
```

#### 代码回滚

- 所有新功能封装在独立函数中
- 通过 `git revert` 可完全回滚
- 回滚后自动恢复到原有行为（import 解析）

---

## 7. Dependencies（依赖）

### 7.1 外部依赖

| 依赖 | 版本 | 必须？ | 说明 |
|------|------|--------|------|
| CKB MCP | >= 1.0 | 否 | 代码知识库，提供图遍历能力 |
| SCIP 索引 | - | 否 | CKB API 的数据源 |
| ripgrep | >= 13.0 | 是 | import 解析（降级） |

### 7.2 内部依赖

| 组件 | 依赖关系 | 说明 |
|------|---------|------|
| `call-chain-tracer.sh` | `graph-rag-context.sh` | 调用方，封装调用链追踪 |
| `.devbooks/config.yaml` | 所有 tools | 读取配置 |
| hooks | `graph-rag-context.sh` | 调用方 |

---

## 8. Open Issues（待解决问题）

| 问题 ID | 问题描述 | 状态 | 优先级 |
|--------|---------|------|--------|
| ISSUE-GRG-001 | CKB API 可用性检测超时时间设置为 1s 是否合理？（可能需要更长时间） | Open | P1 |
| ISSUE-GRG-002 | 多跳遍历时，每跳节点数限制为 50 是否合适？（可能需要根据项目规模调整） | Open | P2 |
| ISSUE-GRG-003 | 循环引用检测是否需要标记循环路径？（当前只标记节点） | Open | P2 |

---

## 9. References（参考资料）

| 资料 | 路径/链接 |
|------|---------|
| 设计文档 | `openspec/changes/boost-local-intelligence/design.md` |
| CKB MCP API 文档 | `mcp/devbooks-mcp-server/README.md` |
| SCIP 索引规范 | https://github.com/sourcegraph/scip |
| 原有 Graph-RAG 实现 | `tools/graph-rag-context.sh`（当前版本） |

---

## 10. Approval & Sign-off（批准与签署）

| 角色 | 姓名 | 日期 | 签名 |
|------|------|------|------|
| Spec Owner | - | 2026-01-09 | Draft |
| Design Owner | - | - | Pending |
| Test Owner | - | - | Pending |

---

**变更历史**：

| 日期 | 作者 | 变更 |
|------|------|------|
| 2026-01-09 | Spec Owner | 初稿 |

---

**状态**：Draft → 等待 Test Owner 产出契约测试 → 等待 Coder 实现
