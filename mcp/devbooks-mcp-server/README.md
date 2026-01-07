# DevBooks MCP Server

> 自动注入 Augment 风格的代码分析上下文

## 功能

1. **意图检测**：自动识别代码相关请求 vs 普通问答
2. **上下文注入**：为代码请求自动注入热点、索引状态等信息
3. **自动索引**：检测并自动生成 SCIP 索引
4. **热点感知**：基于 Git 历史识别高风险文件

## 安装

```bash
cd mcp/devbooks-mcp-server
npm install
npm run build
```

## 配置

在 Claude Code 配置文件中添加：

**全局配置**：`~/.claude/settings.yaml`
**项目配置**：`.claude/settings.yaml`

```yaml
mcpServers:
  devbooks:
    command: node
    args:
      - /path/to/dev-playbooks/mcp/devbooks-mcp-server/dist/index.js
    # 或使用 npx（开发模式）
    # command: npx
    # args:
    #   - tsx
    #   - /path/to/dev-playbooks/mcp/devbooks-mcp-server/src/index.ts
```

## 提供的工具

### devbooks_analyze_context

分析当前项目上下文，返回 Augment 风格的代码分析信息。

**参数**：
- `query` (必需): 用户的原始请求
- `targetFiles` (可选): 要分析的目标文件路径

**返回**：
- 是否为代码相关请求
- 项目语言、索引状态
- 热点文件列表
- 增强上下文字符串

### devbooks_ensure_index

确保 SCIP 索引存在，如果不存在则自动生成。

**参数**：
- `force` (可选): 强制重新生成索引

**支持的语言**：
- TypeScript/JavaScript (scip-typescript)
- Python (scip-python)
- Go (scip-go)

### devbooks_get_hotspots

获取项目热点文件（近30天高频修改）。

**参数**：
- `limit` (可选): 返回的热点数量，默认 10

## 工作原理

```
用户请求 → DevBooks MCP Server
              ↓
         意图检测
              ↓
      ┌───────┴───────┐
      ↓               ↓
  代码请求         非代码请求
      ↓               ↓
  注入上下文       直接返回
      ↓
  调用 CKB MCP 工具
```

## 与 CKB MCP 配合

DevBooks MCP Server 可以与 CKB MCP 配合使用：

```yaml
mcpServers:
  ckb:
    command: npx
    args: ["@anthropic/ckb-mcp"]
  devbooks:
    command: node
    args: ["/path/to/devbooks-mcp-server/dist/index.js"]
```

DevBooks MCP Server 会在上下文中建议使用 CKB 工具：
- `mcp__ckb__analyzeImpact` - 影响分析
- `mcp__ckb__findReferences` - 引用查找
- `mcp__ckb__getCallGraph` - 调用图

## 开发

```bash
# 开发模式运行
npm run dev

# 构建
npm run build

# 运行
npm start
```

## 限制

1. **不是真正的拦截**：MCP Server 提供工具，但 AI 是否调用取决于其判断
2. **需要索引器**：自动生成索引需要安装对应的 scip-* 工具
3. **Git 依赖**：热点检测依赖 Git 历史

## 与 Augment Code 对比

| 能力 | Augment Code | DevBooks MCP |
|------|--------------|--------------|
| 索引生成 | 后台自动 | 按需/首次 |
| 上下文注入 | 100% 自动 | 需调用工具 |
| 热点感知 | 内置 | 基于 Git |
| 图分析 | 默认开启 | 需 SCIP 索引 |
