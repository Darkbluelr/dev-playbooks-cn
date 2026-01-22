# 规格：本地 Embedding 向量化

> **改进项**：P1 - 本地 Embedding（优先级：高）
> **变更包**：boost-local-intelligence
> **版本**：1.0
> **状态**：Draft

---

## 元信息

| 字段 | 内容 |
|------|------|
| Spec ID | SPEC-EMB-001 |
| 对应设计 | `design.md` P1 章节 |
| 涉及组件 | `tools/devbooks-embedding.sh`, `tools/embedding-helper.py`, `.devbooks/config.yaml` |
| 契约变更 | CLI 参数、配置文件、降级机制 |

---

## ADDED Requirements

### Requirement: REQ-EMB-001 Ollama 本地模型支持

**描述**：系统必须支持使用 Ollama 本地模型进行代码向量化。

**优先级**：P0（必须）

**验收条件**：
- 当 Ollama 服务可用时，系统能够自动检测并使用本地模型
- 支持配置 Ollama 模型名称（`nomic-embed-text` 或 `mxbai-embed-large`）
- 支持配置 Ollama API endpoint（默认：`http://localhost:11434`）
- 向量化延迟 < 3s（单次查询）

**关联契约**：CT-EMB-001

#### Scenario: SC-EMB-001
- **Given**: Ollama 服务已安装且运行中，模型 `nomic-embed-text` 已下载
- **When**: 执行 `./tools/devbooks-embedding.sh search "authentication" --format json`
- **Then**: 返回 JSON 包含 `"source": "ollama"` 且延迟 < 3s

---

### Requirement: REQ-EMB-002 三级降级机制

**描述**：系统必须实现自动降级机制，保证在任何环境下都能提供基本功能。

**优先级**：P0（必须）

**降级路径**：
1. **L1（首选）**：Ollama 本地模型
2. **L2（降级）**：OpenAI API
3. **L3（兜底）**：关键词搜索（ripgrep）

**验收条件**：
- Ollama 不可用时，自动降级到 OpenAI API
- OpenAI API 不可用时，自动降级到关键词搜索
- 每次降级都输出清晰的日志提示
- 降级到关键词搜索时，JSON 输出包含 `"source": "keyword"`

**关联契约**：CT-EMB-002

#### Scenario: SC-EMB-002
- **Given**: Ollama 不可用，OpenAI API Key 已设置
- **When**: 执行 `./tools/devbooks-embedding.sh search "test" --provider auto --format json`
- **Then**: 返回 JSON 包含 `"source": "openai"` 且日志输出降级提示

#### Scenario: SC-EMB-003
- **Given**: Ollama 不可用，OpenAI API Key 未设置
- **When**: 执行 `./tools/devbooks-embedding.sh search "test" --provider auto --format json`
- **Then**: 返回 JSON 包含 `"source": "keyword"`

---

### Requirement: REQ-EMB-003 自动检测与配置优先级

**描述**：系统必须在启动时自动检测可用的 provider，并遵循配置优先级。

**优先级**：P0（必须）

**配置优先级**（从高到低）：
1. CLI 参数 `--provider`
2. `.devbooks/config.yaml` 中的 `embedding.provider`
3. 自动检测（`auto` 模式）

**检测逻辑**：
- Ollama 检测：执行 `ollama list` 命令，成功返回则认为可用
- API 检测：检查环境变量 `OPENAI_API_KEY` 是否存在
- 关键词降级：ripgrep 始终可用

**验收条件**：
- `--provider ollama` 强制使用 Ollama，不可用时报错
- `--provider auto` 自动选择最优 provider
- 未指定参数时，读取配置文件（默认：`auto`）

**关联契约**：CT-EMB-001

#### Scenario: SC-EMB-004
- **Given**: 配置 `embedding.provider: ollama`，Ollama 和 OpenAI 均可用
- **When**: 执行 `./tools/devbooks-embedding.sh search "test" --provider openai`
- **Then**: CLI 参数覆盖配置，使用 OpenAI API

---

### Requirement: REQ-EMB-004 向后兼容性

**描述**：新功能必须保持向后兼容，不破坏现有调用方。

**优先级**：P0（必须）

**兼容性要求**：
- 不带新参数时，行为与原版一致（使用 OpenAI API）
- 原有配置格式仍可读取
- 现有调用方（hooks、用户脚本）不需要修改

**验收条件**：
- 旧版本脚本调用 `devbooks-embedding.sh search "query"` 仍正常工作
- 旧配置文件不包含 `embedding.provider` 时，默认使用 OpenAI API
- 所有现有测试用例仍通过

**关联契约**：CT-EMB-003

#### Scenario: SC-EMB-005
- **Given**: 配置文件为旧版本（无 `embedding.provider` 字段），`OPENAI_API_KEY` 已设置
- **When**: 执行 `./tools/devbooks-embedding.sh search "test"`
- **Then**: 使用 OpenAI API（原有行为）

---

### Requirement: REQ-EMB-005 性能要求

**描述**：本地 Embedding 性能必须与 API 持平。

**优先级**：P1（高）

**性能指标**：
- P50 延迟：< 1.5s
- P95 延迟：< 3s
- P99 延迟：< 5s
- 首次模型加载：< 10s（用户可接受等待）

**验收条件**：
- 100 次查询的 P95 延迟 < 3s
- 内存占用增长 < 500MB（模型加载后）
- CPU 占用峰值 < 80%（单核）

**关联契约**：CT-EMB-004

#### Scenario: SC-EMB-006
- **Given**: Ollama 服务运行中，模型已加载
- **When**: 执行 100 次向量搜索查询
- **Then**: P95 延迟 < 3s

---

### Requirement: REQ-EMB-006 质量差异说明

**描述**：文档必须清晰说明本地模型与 API 的质量差异。

**优先级**：P1（高）

**质量差异**：
- 本地模型质量比 OpenAI API 低 4-8%（基于 MTEB 基准测试）
- 对于代码搜索场景，实际影响更小（约 2-5%）
- 企业/隐私场景下，质量差异可接受

**验收条件**：
- `docs/embedding-quickstart.md` 包含质量对比章节
- `使用说明书.md` 包含使用建议
- CLI 输出提示用户质量差异（首次使用时）

**关联契约**：无（文档要求）

#### Scenario: SC-EMB-007
- **Given**: 用户首次使用 Ollama 本地模型
- **When**: 执行向量搜索
- **Then**: 输出包含质量差异提示

---

### Requirement: REQ-EMB-007 模型下载提示

**描述**：首次使用 Ollama 时，必须提示用户下载模型。

**优先级**：P1（高）

**提示信息**：
- 模型名称：`nomic-embed-text`（默认）或 `mxbai-embed-large`
- 模型大小：`nomic-embed-text` 约 274MB，`mxbai-embed-large` 约 670MB
- 下载命令：`ollama pull <model>`
- 预计下载时间：取决于网络速度

**验收条件**：
- 模型不存在时，输出清晰的下载命令
- 等待下载时，显示友好提示
- 下载失败时，自动降级到 API

**关联契约**：CT-EMB-002

#### Scenario: SC-EMB-008
- **Given**: Ollama 服务运行中，模型 `nomic-embed-text` 未下载
- **When**: 执行 `./tools/devbooks-embedding.sh search "test" --provider ollama`
- **Then**: 输出包含下载命令 `ollama pull nomic-embed-text`

---

## 2. Scenarios（场景）

### SC-EMB-001: Ollama 可用时自动使用本地模型

**场景描述**：用户在本地安装了 Ollama 并启动服务，执行向量搜索时自动使用本地模型。

**Given（前置条件）**：
- Ollama 服务已安装且运行中（`ollama list` 返回成功）
- 配置 `embedding.provider: auto` 或未配置（默认）
- 本地模型 `nomic-embed-text` 已下载

**When（操作）**：
```bash
./tools/devbooks-embedding.sh search "authentication logic" --format json
```

**Then（预期结果）**：
- 日志输出：`使用 Ollama 本地模型: nomic-embed-text`
- 返回 JSON 包含：
  ```json
  {
    "source": "ollama",
    "model": "nomic-embed-text",
    "candidates": [
      {
        "file_path": "src/auth/login.ts",
        "relevance_score": 0.85,
        ...
      }
    ]
  }
  ```
- 延迟 < 3s
- 无网络请求（完全本地）

**关联需求**：REQ-EMB-001, REQ-EMB-003, REQ-EMB-005

---

### SC-EMB-002: Ollama 不可用时降级到 OpenAI API

**场景描述**：Ollama 未安装或服务未启动，系统自动降级到 OpenAI API。

**Given（前置条件）**：
- Ollama 未安装或服务未启动（`ollama list` 失败）
- 环境变量 `OPENAI_API_KEY` 已设置
- 配置 `embedding.provider: auto`

**When（操作）**：
```bash
./tools/devbooks-embedding.sh search "authentication logic" --format json
```

**Then（预期结果）**：
- 日志输出：`Ollama 不可用，降级到 OpenAI API`
- 返回 JSON 包含：
  ```json
  {
    "source": "openai",
    "model": "text-embedding-3-small",
    "candidates": [...]
  }
  ```
- 调用 OpenAI API 成功
- 结果质量与原版一致

**关联需求**：REQ-EMB-002, REQ-EMB-003

---

### SC-EMB-003: API 不可用时降级到关键词搜索

**场景描述**：Ollama 和 OpenAI API 均不可用，系统降级到关键词搜索。

**Given（前置条件）**：
- Ollama 不可用
- 环境变量 `OPENAI_API_KEY` 未设置或无效
- 配置 `embedding.fallback_to_keyword: true`

**When（操作）**：
```bash
./tools/devbooks-embedding.sh search "authentication" --format json
```

**Then（预期结果）**：
- 日志输出：`Embedding 不可用，降级到关键词搜索`
- 返回 JSON 包含：
  ```json
  {
    "source": "keyword",
    "query": "authentication",
    "candidates": [
      {
        "file_path": "src/auth/login.ts",
        "relevance_score": null,
        "match_lines": [10, 25, 42]
      }
    ]
  }
  ```
- 使用 ripgrep 全文搜索
- 结果按文件路径排序（无相关性评分）

**关联需求**：REQ-EMB-002, REQ-EMB-003

---

### SC-EMB-004: 强制使用 Ollama（企业场景）

**场景描述**：企业环境禁止使用外部 API，强制使用本地模型。

**Given（前置条件）**：
- 配置 `embedding.provider: ollama`（强制本地）
- Ollama 服务运行中

**When（操作）**：
```bash
./tools/devbooks-embedding.sh search "test" --format json
```

**Then（预期结果）**：
- 使用 Ollama 本地模型
- 无网络请求
- 如果 Ollama 不可用，报错退出（不降级到 API）

**关联需求**：REQ-EMB-003

---

### SC-EMB-005: 首次使用提示下载模型

**场景描述**：用户首次使用 Ollama，模型尚未下载。

**Given（前置条件）**：
- Ollama 服务运行中
- 模型 `nomic-embed-text` 未下载（`ollama list` 不包含该模型）

**When（操作）**：
```bash
./tools/devbooks-embedding.sh search "test" --provider ollama
```

**Then（预期结果）**：
- 日志输出：
  ```
  模型 'nomic-embed-text' 未找到。
  下载命令：ollama pull nomic-embed-text
  模型大小：274 MB
  ```
- 等待用户确认后开始下载
- 或自动降级到 API（如果配置允许）

**关联需求**：REQ-EMB-007

---

### SC-EMB-006: 向后兼容旧版本调用

**场景描述**：现有脚本不带新参数调用，应保持原有行为。

**Given（前置条件）**：
- 配置文件为旧版本（无 `embedding.provider` 字段）
- 环境变量 `OPENAI_API_KEY` 已设置

**When（操作）**：
```bash
./tools/devbooks-embedding.sh search "test"  # 旧版本调用方式
```

**Then（预期结果）**：
- 使用 OpenAI API（原有行为）
- 不尝试检测 Ollama
- 结果与原版一致

**关联需求**：REQ-EMB-004

---

### SC-EMB-007: CLI 参数覆盖配置

**场景描述**：CLI 参数优先级高于配置文件。

**Given（前置条件）**：
- 配置 `embedding.provider: ollama`
- Ollama 和 OpenAI API 均可用

**When（操作）**：
```bash
./tools/devbooks-embedding.sh search "test" --provider openai
```

**Then（预期结果）**：
- 使用 OpenAI API（CLI 参数覆盖配置）
- 忽略配置文件中的 `ollama` 设置

**关联需求**：REQ-EMB-003

---

## 3. API Specification（API 规范）

### 3.1 CLI 接口

#### `devbooks-embedding.sh search`

**新增参数**：

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `--provider` | string | 否 | `auto` | 指定 provider：`auto`, `ollama`, `openai`, `keyword` |
| `--ollama-model` | string | 否 | `nomic-embed-text` | Ollama 模型名称 |
| `--ollama-endpoint` | string | 否 | `http://localhost:11434` | Ollama API 地址 |
| `--timeout` | int | 否 | `30` | 超时时间（秒） |

**原有参数**（保持不变）：
- `<query>`：搜索查询
- `--format`：输出格式（`json` 或 `text`）
- `--top-k`：返回结果数量

**示例**：
```bash
# 自动选择 provider
./tools/devbooks-embedding.sh search "auth logic" --format json

# 强制使用 Ollama
./tools/devbooks-embedding.sh search "auth logic" --provider ollama

# 指定 Ollama 模型
./tools/devbooks-embedding.sh search "auth logic" --provider ollama --ollama-model mxbai-embed-large
```

---

### 3.2 配置文件 Schema

#### `.devbooks/config.yaml` - embedding 部分

**新增字段**：

```yaml
embedding:
  # Provider 选择（新增）
  provider: auto  # auto | ollama | openai | keyword

  # Ollama 配置（新增）
  ollama:
    model: nomic-embed-text  # 或 mxbai-embed-large
    endpoint: http://localhost:11434
    timeout: 30

  # OpenAI 配置（原有，扩展）
  openai:
    model: text-embedding-3-small
    api_key: ${OPENAI_API_KEY}
    base_url: https://api.openai.com/v1
    timeout: 30

  # 降级配置（原有）
  auto_build: true
  fallback_to_keyword: true
```

**字段说明**：

| 字段路径 | 类型 | 必填 | 默认值 | 说明 |
|---------|------|------|--------|------|
| `embedding.provider` | string | 否 | `auto` | Provider 选择 |
| `embedding.ollama.model` | string | 否 | `nomic-embed-text` | Ollama 模型名称 |
| `embedding.ollama.endpoint` | string | 否 | `http://localhost:11434` | Ollama API 地址 |
| `embedding.ollama.timeout` | int | 否 | `30` | 超时时间（秒） |

---

### 3.3 JSON 输出 Schema

#### 成功响应（Ollama）

```json
{
  "schema_version": "1.0",
  "source": "ollama",  // 新增字段
  "model": "nomic-embed-text",  // 新增字段
  "query": "authentication logic",
  "token_count": 3,
  "candidates": [
    {
      "file_path": "src/auth/login.ts",
      "line_start": 10,
      "line_end": 25,
      "content": "...",
      "relevance_score": 0.85,
      "embedding_dim": 768  // 新增字段
    }
  ],
  "metadata": {
    "provider": "ollama",
    "model": "nomic-embed-text",
    "endpoint": "http://localhost:11434",
    "latency_ms": 1250
  }
}
```

#### 降级响应（关键词搜索）

```json
{
  "schema_version": "1.0",
  "source": "keyword",  // 新增字段
  "query": "authentication",
  "degraded_reason": "embedding_unavailable",  // 新增字段
  "candidates": [
    {
      "file_path": "src/auth/login.ts",
      "relevance_score": null,
      "match_lines": [10, 25, 42]
    }
  ],
  "metadata": {
    "provider": "ripgrep",
    "total_matches": 15
  }
}
```

---

## 4. Quality Attributes（质量属性）

### 4.1 性能

| 指标 | 目标值 | 测量方式 |
|------|--------|---------|
| P50 延迟 | < 1.5s | 100 次查询统计 |
| P95 延迟 | < 3s | 100 次查询统计 |
| P99 延迟 | < 5s | 100 次查询统计 |
| 内存占用 | < 500MB | 模型加载后峰值 |

### 4.2 可用性

| 指标 | 目标值 | 测量方式 |
|------|--------|---------|
| Ollama 可用时成功率 | 99% | 1000 次查询统计 |
| 降级成功率 | 100% | 关键词搜索始终可用 |
| 错误提示清晰度 | 用户可理解 | 人工评审 |

### 4.3 安全性

| 要求 | 说明 |
|------|------|
| 本地模型隔离 | Ollama 不联网，代码不上传云端 |
| API Key 保护 | 不写入日志或代码 |
| 降级安全 | 关键词搜索不泄漏敏感文件 |

---

## 5. Contract Tests（契约测试计划）

### CT-EMB-001: Ollama Provider 基础功能

**测试类型**：集成测试

**前置条件**：
- Ollama 服务运行中
- 模型 `nomic-embed-text` 已下载

**测试步骤**：
1. 执行：`./tools/devbooks-embedding.sh search "test" --provider ollama --format json`
2. 验证 JSON 输出：
   - `source` = `"ollama"`
   - `model` = `"nomic-embed-text"`
   - `candidates` 不为空
   - `relevance_score` > 0

**通过标准**：
- 响应时间 < 3s
- JSON Schema 校验通过
- 无错误日志

---

### CT-EMB-002: 三级降级机制

**测试类型**：集成测试

**测试用例 2.1**：Ollama → OpenAI API

**步骤**：
1. 停止 Ollama 服务
2. 设置 `OPENAI_API_KEY`
3. 执行：`./tools/devbooks-embedding.sh search "test" --provider auto --format json`
4. 验证：`source` = `"openai"`

**测试用例 2.2**：OpenAI API → 关键词搜索

**步骤**：
1. 停止 Ollama 服务
2. 清除 `OPENAI_API_KEY`
3. 执行：`./tools/devbooks-embedding.sh search "test" --provider auto --format json`
4. 验证：`source` = `"keyword"`

---

### CT-EMB-003: 向后兼容性

**测试类型**：回归测试

**测试用例 3.1**：旧版本调用

**步骤**：
1. 删除配置中的 `embedding.provider` 字段
2. 设置 `OPENAI_API_KEY`
3. 执行：`./tools/devbooks-embedding.sh search "test"`
4. 验证：使用 OpenAI API（原有行为）

**测试用例 3.2**：旧配置格式兼容

**步骤**：
1. 使用旧版本配置文件（无 `ollama` 字段）
2. 执行：`./tools/devbooks-embedding.sh status`
3. 验证：无报错，正常读取配置

---

### CT-EMB-004: 性能基准测试

**测试类型**：性能测试

**测试用例 4.1**：Ollama 延迟测试

**步骤**：
1. 执行 100 次查询（不同 query）
2. 记录每次延迟
3. 计算 P50、P95、P99

**通过标准**：
- P50 < 1.5s
- P95 < 3s
- P99 < 5s

---

### CT-EMB-005: 错误处理

**测试类型**：异常测试

**测试用例 5.1**：模型未下载

**步骤**：
1. 删除模型：`ollama rm nomic-embed-text`
2. 执行：`./tools/devbooks-embedding.sh search "test" --provider ollama`
3. 验证：
   - 输出下载提示
   - 提供下载命令
   - 或自动降级（取决于配置）

**测试用例 5.2**：Ollama 服务崩溃

**步骤**：
1. 强制终止 Ollama 进程
2. 执行：`./tools/devbooks-embedding.sh search "test" --provider auto`
3. 验证：
   - 检测到 Ollama 不可用
   - 自动降级到 API
   - 日志清晰说明降级原因

---

## 6. Migration & Rollback（迁移与回滚）

### 6.1 迁移步骤

#### 对现有用户

1. **零配置用户**（使用默认配置）：
   - 无需任何操作
   - 首次运行时自动检测 Ollama，不可用时降级到 API
   - 行为与原版一致

2. **配置 OpenAI API 的用户**：
   - 无需修改配置
   - 可选：增加 `embedding.provider: openai` 强制使用 API

3. **希望使用 Ollama 的用户**：
   - 安装 Ollama：`brew install ollama`（macOS）
   - 下载模型：`ollama pull nomic-embed-text`
   - 配置：`embedding.provider: auto`（或留空，使用默认）

### 6.2 回滚策略

#### 配置回滚

**方法 1**：强制使用 OpenAI API
```yaml
embedding:
  provider: openai  # 强制使用 API，忽略 Ollama
```

**方法 2**：恢复到原版配置
```yaml
embedding:
  # 删除所有新增字段，只保留原有字段
  auto_build: true
  fallback_to_keyword: true
```

#### 代码回滚

- 所有新功能封装在独立函数中
- 通过 `git revert` 可完全回滚
- 回滚后自动恢复到原有行为

---

## 7. Dependencies（依赖）

### 7.1 外部依赖

| 依赖 | 版本 | 必须？ | 说明 |
|------|------|--------|------|
| Ollama | >= 0.1.0 | 否 | 本地模型推理引擎 |
| `nomic-embed-text` | latest | 否 | 默认 Embedding 模型 |
| OpenAI API | - | 否 | 降级选项 |
| ripgrep | >= 13.0 | 是 | 关键词搜索（兜底） |

### 7.2 内部依赖

| 组件 | 依赖关系 | 说明 |
|------|---------|------|
| `embedding-helper.py` | `devbooks-embedding.sh` | 被调用，负责向量计算 |
| `.devbooks/config.yaml` | 所有 tools | 读取配置 |
| hooks | `devbooks-embedding.sh` | 调用方 |

---

## 8. Open Issues（待解决问题）

| 问题 ID | 问题描述 | 状态 | 优先级 |
|--------|---------|------|--------|
| ISSUE-EMB-001 | Ollama 模型选择：`nomic-embed-text` vs `mxbai-embed-large`？需实测对比质量与速度 | Open | P1 |
| ISSUE-EMB-002 | 首次模型下载是否需要进度条？（可能需要 Python 脚本支持） | Open | P2 |
| ISSUE-EMB-003 | Ollama 超时时间设置为 30s 是否合理？（模型加载可能较慢） | Open | P2 |

---

## 9. References（参考资料）

| 资料 | 路径/链接 |
|------|---------|
| 设计文档 | `openspec/changes/boost-local-intelligence/design.md` |
| Ollama 官方文档 | https://github.com/ollama/ollama |
| nomic-embed-text 文档 | https://ollama.com/library/nomic-embed-text |
| MTEB 基准测试 | https://huggingface.co/spaces/mteb/leaderboard |
| 原有 Embedding 实现 | `tools/devbooks-embedding.sh`（当前版本） |

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
