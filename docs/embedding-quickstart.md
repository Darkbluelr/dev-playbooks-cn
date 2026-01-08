# DevBooks Embedding - 快速开始

语义搜索让 AI 更智能地理解你的代码库。

## 5 分钟上手

### 1. 设置 API Key

```bash
export OPENAI_API_KEY="sk-xxx"
```

### 2. 构建索引

```bash
./tools/devbooks-embedding.sh build
```

等待几分钟（取决于项目大小）...

### 3. 开始搜索

```bash
# 搜索功能实现
./tools/devbooks-embedding.sh search "用户认证相关代码"

# 搜索特定模式
./tools/devbooks-embedding.sh search "处理异步错误的方式"

# 搜索业务逻辑
./tools/devbooks-embedding.sh search "订单支付流程"
```

### 4. 集成到 Claude

```bash
# 启用语义搜索增强
cp .claude/hooks/augment-context-with-embedding.sh \
   .claude/hooks/augment-context.sh
```

现在 Claude 会自动使用语义搜索！

## 日常使用

### 代码更新后

```bash
./tools/devbooks-embedding.sh update
```

只更新修改的文件，很快。

### 查看状态

```bash
./tools/devbooks-embedding.sh status
```

### 测试一切是否正常

```bash
./tools/test-embedding.sh
```

## 配置（可选）

编辑 `.devbooks/embedding.yaml`：

```yaml
# 改变模型
api:
  model: text-embedding-3-large  # 更好但更贵

# 调整搜索参数
search:
  top_k: 10              # 返回更多结果
  similarity_threshold: 0.8  # 更严格的匹配
```

## 其他配置

- OpenAI（默认）：`.devbooks/embedding.yaml`
- Azure OpenAI：`.devbooks/embedding.azure.yaml`
- 本地模型：`.devbooks/embedding.local.yaml`

切换配置：

```bash
# 使用 Azure
cp .devbooks/embedding.azure.yaml .devbooks/embedding.yaml

# 使用本地模型
cp .devbooks/embedding.local.yaml .devbooks/embedding.yaml
```

## 需要帮助？

查看完整文档：`docs/embedding-guide.md`

## 常见问题

**Q: 安全吗？代码会被发送到哪里？**

A: 代码会发送到你配置的 API（OpenAI / Azure / 本地）进行向量化。向量存储在本地。

**Q: 成本多少？**

A: 很便宜。1000 个文件约 $0.01（OpenAI text-embedding-3-small）。

**Q: 与 grep/SCIP 索引有什么区别？**

A:
- grep：精确匹配关键词
- SCIP：代码结构和依赖关系
- Embedding：理解含义和上下文

三者互补，建议都用。

**Q: 可以离线使用吗？**

A: 可以，使用本地模型配置（`embedding.local.yaml`）。

**Q: 支持哪些语言？**

A: 所有主流语言：TS/JS/Python/Go/Rust/Java 等。

---

Made with ❤️ by DevBooks
