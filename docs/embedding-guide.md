# DevBooks Embedding 使用指南

## 简介

DevBooks Embedding 为代码库提供语义搜索能力，通过将代码转换为向量表示，实现基于含义的智能搜索，而非简单的关键词匹配。

## 快速开始

### 1. 配置 API

编辑 `.devbooks/embedding.yaml`：

```yaml
enabled: true

api:
  model: text-embedding-3-small
  api_key: ${OPENAI_API_KEY}  # 或直接填写: sk-xxx
  base_url: https://api.openai.com/v1
```

或设置环境变量：

```bash
export OPENAI_API_KEY="sk-xxx"
```

### 2. 构建索引

首次使用需要构建向量索引：

```bash
./tools/devbooks-embedding.sh build
```

这会：
- 扫描项目中的所有代码文件
- 调用 API 将代码转换为向量
- 保存到 `.devbooks/embeddings/` 目录

**注意**：首次构建可能需要几分钟，取决于项目大小。

### 3. 语义搜索

现在可以使用自然语言搜索代码：

```bash
# 搜索特定功能
./tools/devbooks-embedding.sh search "用户认证相关的函数"

# 搜索实现模式
./tools/devbooks-embedding.sh search "如何处理异步错误"

# 搜索业务逻辑
./tools/devbooks-embedding.sh search "支付流程的实现"
```

### 4. 增量更新

代码修改后，更新索引：

```bash
./tools/devbooks-embedding.sh update
```

只会重新向量化修改过的文件。

## 命令详解

### build - 构建完整索引

```bash
./tools/devbooks-embedding.sh build
```

从零开始构建向量索引。会删除已有索引并重建。

### update - 增量更新

```bash
./tools/devbooks-embedding.sh update
```

只更新自上次索引后修改过的文件。更快更高效。

### search - 语义搜索

```bash
./tools/devbooks-embedding.sh search "查询内容" [选项]
```

选项：
- `--top-k N`：返回 N 个结果（默认 5）
- `--threshold 0.7`：相似度阈值（0-1）

示例：

```bash
# 返回 10 个结果
./tools/devbooks-embedding.sh search "数据库连接" --top-k 10

# 设置更高的相似度阈值
./tools/devbooks-embedding.sh search "缓存实现" --threshold 0.8
```

### status - 查看状态

```bash
./tools/devbooks-embedding.sh status
```

显示：
- 索引文件数量
- 向量维度
- 使用的模型
- 索引大小
- 创建和更新时间

### config - 显示配置

```bash
./tools/devbooks-embedding.sh config
```

### clean - 清理索引

```bash
./tools/devbooks-embedding.sh clean
```

删除所有向量数据。

## 集成到工作流

### 1. 集成到 Claude Context Hook

DevBooks 已提供集成示例：`.claude/hooks/augment-context-with-embedding.sh`

使用方式：

```bash
# 复制示例文件
cp .claude/hooks/augment-context-with-embedding.sh .claude/hooks/augment-context.sh

# 或者手动启用
export USE_EMBEDDING=true
```

现在 Claude 会自动使用语义搜索来查找相关代码！

### 2. 集成到 Git Hooks

在 pre-commit 中自动更新索引：

```bash
# .git/hooks/pre-commit
#!/bin/bash
./tools/devbooks-embedding.sh update > /dev/null 2>&1 || true
```

### 3. 集成到 CI/CD

```yaml
# .github/workflows/embedding.yml
name: Update Embedding Index

on:
  push:
    branches: [main]

jobs:
  update-index:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Update Embedding Index
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
        run: |
          ./tools/devbooks-embedding.sh update
      - name: Commit Index
        run: |
          git add .devbooks/embeddings/
          git commit -m "Update embedding index" || true
          git push
```

## 高级配置

### 自定义文件过滤

编辑 `.devbooks/embedding.yaml`：

```yaml
filters:
  include_extensions:
    - .ts
    - .py
    - .go
    # 添加更多...

  exclude_dirs:
    - node_modules
    - dist
    # 添加更多...

  exclude_patterns:
    - "*.test.ts"
    - "*.min.js"
    # 添加更多...
```

### 调整搜索参数

```yaml
search:
  top_k: 10                    # 默认返回结果数
  similarity_threshold: 0.75   # 相似度阈值（更高 = 更严格）
  include_snippet: true        # 是否显示代码片段
  snippet_max_lines: 30        # 片段最大行数
```

### 性能优化

```yaml
performance:
  max_concurrent_requests: 10  # 并发请求数（更快但可能触发限流）
  cache_size_mb: 200           # 缓存大小
  enable_compression: true     # 启用压缩（减少存储）
```

### 使用其他 API

#### Azure OpenAI

```yaml
api:
  model: text-embedding-ada-002
  api_key: ${AZURE_OPENAI_KEY}
  base_url: https://your-resource.openai.azure.com/openai/deployments/your-deployment
```

#### 本地模型（实验性）

```yaml
api:
  base_url: http://localhost:8000/v1
  model: BAAI/bge-small-zh-v1.5

experimental:
  use_local_model: true
  local_model_path: /path/to/model
```

## 最佳实践

### 1. 定期更新索引

建议：
- 开发时：手动运行 `update`
- 提交前：在 Git Hook 中自动更新
- 主分支：在 CI 中自动更新

### 2. 优化搜索查询

**好的查询**：
- "处理用户登录的认证逻辑"
- "实现 API 限流的中间件"
- "解析 JWT token 的工具函数"

**不好的查询**：
- "login"（太短）
- "代码"（太宽泛）
- "bug"（缺乏上下文）

### 3. 平衡索引大小与成本

- 使用 `exclude_patterns` 排除测试文件、生成文件
- 大型项目可以只索引核心模块
- 使用 `text-embedding-3-small` 而非 `large`（性价比更高）

### 4. 结合其他工具

Embedding 搜索与传统搜索各有优势：

| 工具 | 优势 | 适用场景 |
|------|------|----------|
| Embedding | 理解含义、跨语言 | 模糊需求、架构探索 |
| grep/rg | 精确、快速 | 已知关键词、重构 |
| SCIP 索引 | 类型准确、依赖关系 | 代码导航、影响分析 |

建议三者结合使用。

## 故障排查

### Q: API 调用失败

检查：
1. API Key 是否正确
2. 网络连接是否正常
3. API 配额是否用尽
4. base_url 是否正确

```bash
# 测试 API 连接
curl -H "Authorization: Bearer $OPENAI_API_KEY" \
  https://api.openai.com/v1/models
```

### Q: 搜索结果不相关

尝试：
1. 调整 `similarity_threshold`（降低以获得更多结果）
2. 改进查询描述（更具体、更完整）
3. 重建索引：`./tools/devbooks-embedding.sh build`

### Q: 索引构建太慢

优化：
1. 增加 `batch_size`（如 100）
2. 增加 `max_concurrent_requests`（如 10）
3. 使用更快的模型（如 `text-embedding-3-small`）
4. 排除不必要的文件

### Q: 索引占用空间太大

解决：
1. 启用压缩：`enable_compression: true`
2. 使用更小的模型（1536 维 vs 3072 维）
3. 排除大文件和生成文件
4. 定期清理旧索引：`./tools/devbooks-embedding.sh clean`

## 成本估算

以 OpenAI `text-embedding-3-small` 为例：

- 价格：$0.02 / 1M tokens
- 平均代码文件：~500 tokens
- 1000 个文件 ≈ 500K tokens ≈ $0.01

**建议**：
- 中小项目（< 1000 文件）：成本可忽略
- 大型项目（> 10000 文件）：约 $0.10-0.50
- 使用增量更新而非全量重建

## 示例场景

### 场景 1：探索陌生代码库

```bash
# 找到入口点
./tools/devbooks-embedding.sh search "应用的主入口和初始化"

# 理解核心架构
./tools/devbooks-embedding.sh search "路由配置和中间件设置"

# 查找特定功能
./tools/devbooks-embedding.sh search "数据库连接池和事务管理"
```

### 场景 2：重构准备

```bash
# 找到所有相关实现
./tools/devbooks-embedding.sh search "使用旧认证库的代码" --top-k 20

# 找到替代方案
./tools/devbooks-embedding.sh search "新的认证实现示例"
```

### 场景 3：问题定位

```bash
# 查找可能的 bug 源
./tools/devbooks-embedding.sh search "处理空指针和边界条件"

# 查找类似问题的解决方案
./tools/devbooks-embedding.sh search "异常处理和错误恢复"
```

## 与 DevBooks 其他工具集成

| 工具 | 集成点 | 说明 |
|------|--------|------|
| devbooks-indexer | 互补 | SCIP 索引结构，Embedding 索引语义 |
| augment-context | Hook | 自动注入相关代码到 AI 上下文 |
| impact-analysis | 增强 | 用语义搜索找到隐式依赖 |
| code-review | 参考 | 查找类似代码的最佳实践 |

## 未来路线图

计划中的功能：
- [ ] 支持本地模型（无需 API Key）
- [ ] 代码间关系图谱
- [ ] 智能代码补全建议
- [ ] 多语言混合搜索优化
- [ ] 增量索引优化（更快的更新）
- [ ] Web UI 界面

## 相关资源

- OpenAI Embeddings API: https://platform.openai.com/docs/guides/embeddings
- 向量数据库对比: https://github.com/erikbern/ann-benchmarks
- DevBooks 文档: `/docs/`

## 支持

遇到问题？

1. 查看 `./tools/devbooks-embedding.sh --help`
2. 启用调试模式：`./tools/devbooks-embedding.sh --debug`
3. 查看日志：`.devbooks/embeddings/embedding.log`
4. 提交 Issue 到 DevBooks 项目
