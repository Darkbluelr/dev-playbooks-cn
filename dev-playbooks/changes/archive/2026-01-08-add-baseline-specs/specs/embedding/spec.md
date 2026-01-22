# embedding

## 修改需求

### 需求：提供 Embedding 工具脚本与索引能力

系统必须提供 Embedding 工具脚本以构建与更新语义检索索引。

#### 场景：构建 Embedding 索引
- **当** 执行 `./tools/devbooks-embedding.sh build`
- **那么** 在 `.devbooks/embeddings/` 生成索引文件
- **证据**：`tools/devbooks-embedding.sh`，`docs/embedding-guide.md`

### 需求：提供 Embedding 配置文件与多供应商模板

系统必须提供 Embedding 配置文件与多供应商模板以切换配置来源。

#### 场景：切换 Embedding 配置
- **当** 将 `.devbooks/embedding.azure.yaml` 或 `.devbooks/embedding.local.yaml` 复制为 `.devbooks/embedding.yaml`
- **那么** Embedding 脚本按新配置运行
- **证据**：`.devbooks/embedding.azure.yaml`，`.devbooks/embedding.local.yaml`，`docs/embedding-quickstart.md`

### 需求：提供 Embedding 快速开始与使用指南

系统必须提供 Embedding 快速开始与使用指南，覆盖配置与运行步骤。

#### 场景：查看 Embedding 文档
- **当** 阅读 Embedding 文档
- **那么** 可以获得配置、构建、搜索与更新的使用步骤
- **证据**：`docs/embedding-quickstart.md`，`docs/embedding-guide.md`
