---
name: devbooks-index-bootstrap
description: devbooks-index-bootstrap：自动检测项目语言栈并生成 SCIP 索引，激活图基代码理解能力。在首次进入大型项目、或 CKB 报告索引缺失时自动触发。
tools:
  - Glob
  - Read
  - Bash
  - mcp__ckb__getStatus
---

# DevBooks：索引引导（Index Bootstrap）

## 触发条件

以下任一条件满足时自动执行：
1. 用户说"初始化索引/建立代码图谱/激活图分析"
2. `mcp__ckb__getStatus` 返回 SCIP 后端 `healthy: false`
3. 进入新项目且 `index.scip` 不存在

## 执行流程

### Step 1: 检测项目语言栈

```bash
# 检测主要语言
if [ -f "package.json" ] || [ -f "tsconfig.json" ]; then
  echo "LANG=typescript"
elif [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ]; then
  echo "LANG=python"
elif [ -f "go.mod" ]; then
  echo "LANG=go"
elif [ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  echo "LANG=java"
elif [ -f "Cargo.toml" ]; then
  echo "LANG=rust"
else
  echo "LANG=unknown"
fi
```

### Step 2: 检查索引器是否已安装

| 语言 | 检查命令 | 安装命令 |
|------|----------|----------|
| TypeScript/JS | `which scip-typescript` | `npm install -g @sourcegraph/scip-typescript` |
| Python | `which scip-python` | `pip install scip-python` |
| Go | `which scip-go` | `go install github.com/sourcegraph/scip-go@latest` |
| Java | 检查 gradle/maven 插件 | 见 scip-java 文档 |
| Rust | `which rust-analyzer` | `rustup component add rust-analyzer` |

### Step 3: 生成索引

```bash
# TypeScript/JavaScript
scip-typescript index --output index.scip

# Python
scip-python index . --output index.scip

# Go
scip-go --output index.scip

# Rust (通过 rust-analyzer)
rust-analyzer scip . > index.scip
```

### Step 4: 验证索引

生成后调用 `mcp__ckb__getStatus`，确认 SCIP 后端变为 `healthy: true`。

## 输出

成功时输出：
```
✓ 检测到 TypeScript 项目
✓ scip-typescript 已安装
✓ index.scip 已生成 (2.3 MB, 15,234 symbols)
✓ CKB SCIP 后端已激活

图基能力已就绪：
- mcp__ckb__searchSymbols
- mcp__ckb__findReferences
- mcp__ckb__getCallGraph
- mcp__ckb__analyzeImpact
```

## 索引维护建议

生成索引后，建议配置自动更新以保持索引最新：

### 方式一：Git Hook（推荐）

```bash
# 创建 post-commit hook
cat > .git/hooks/post-commit << 'EOF'
#!/bin/bash
if command -v scip-typescript &> /dev/null; then
  scip-typescript index --output index.scip &
fi
EOF
chmod +x .git/hooks/post-commit
```

### 方式三：CI Pipeline（团队协作）

```yaml
# .github/workflows/index.yml
on:
  push:
    paths: ['src/**', 'lib/**']
jobs:
  index:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm install -g @anthropic-ai/scip-typescript
      - run: scip-typescript index --output index.scip
      - uses: actions/upload-artifact@v4
        with:
          name: scip-index
          path: index.scip
```

## 注意事项

- 大型项目首次索引可能需要 1-5 分钟
- 索引文件建议加入 `.gitignore`（或作为 CI artifact 共享）
- 索引过期不影响功能，只是图数据可能不完整

## CKB 索引检测路径

DevBooks 会自动检测以下路径来判断索引是否可用：

| 路径 | 说明 |
|------|------|
| `$CWD/index.scip` | SCIP 索引文件（推荐） |
| `$CWD/.git/ckb/` | CKB 本地缓存目录 |
| `$CWD/.devbooks/embeddings/index.tsv` | DevBooks Embedding 索引 |

任一路径存在即认为索引可用，Hook 输出会显示 `✅ 索引可用`。

## 常见问题

### Q: 为什么提示「可启用 CKB 加速代码分析」？

A: 这表示当前项目没有可用的代码索引。运行此 Skill 生成索引后，可启用以下高级功能：
- `mcp__ckb__searchSymbols` - 符号搜索
- `mcp__ckb__findReferences` - 引用查找
- `mcp__ckb__getCallGraph` - 调用图分析
- `mcp__ckb__analyzeImpact` - 影响分析

### Q: macOS 上 grep 不支持 `-P` 选项怎么办？

A: 安装 GNU grep：
```bash
brew install grep
# 使用 ggrep 替代 grep
```

### Q: 索引文件太大怎么办？

A: 建议将 `index.scip` 加入 `.gitignore`，在 CI 中生成并作为 artifact 共享：
```bash
echo "index.scip" >> .gitignore
```

### Q: 如何验证索引是否生效？

A: 使用 CKB 状态检查工具：
```
# 在 Claude Code 中
mcp__ckb__getStatus
```
应返回 `scip: { healthy: true }`。

---

## 上下文感知

本 Skill 在执行前自动检测上下文，选择合适的索引策略。

检测规则参考：`skills/_shared/context-detection-template.md`

### 检测流程

1. 检测 `index.scip` 是否存在
2. 调用 `mcp__ckb__getStatus` 检查 SCIP 后端状态
3. 检测项目语言栈

### 本 Skill 支持的模式

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| **首次索引** | index.scip 不存在 | 检测语言栈并生成索引 |
| **更新索引** | index.scip 存在但过期 | 重新生成索引 |
| **验证模式** | 带 --check 参数 | 只验证索引状态，不生成 |

### 检测输出示例

```
检测结果：
- index.scip：不存在
- CKB SCIP 后端：不可用
- 语言栈：TypeScript
- 运行模式：首次索引
```

---

## MCP 增强

本 Skill 支持 MCP 运行时增强，用于检测索引状态。

MCP 增强规则参考：`skills/_shared/mcp-enhancement-template.md`

### 依赖的 MCP 服务

| 服务 | 用途 | 超时 |
|------|------|------|
| `mcp__ckb__getStatus` | 检测 SCIP 后端状态 | 2s |

### 检测流程

1. 调用 `mcp__ckb__getStatus`（2s 超时）
2. 检查 SCIP 后端是否 healthy
3. 若不可用 → 触发索引生成流程

### 索引生成后激活的 MCP 能力

| 功能 | MCP 工具 |
|------|----------|
| 符号搜索 | `mcp__ckb__searchSymbols` |
| 引用查找 | `mcp__ckb__findReferences` |
| 调用图分析 | `mcp__ckb__getCallGraph` |
| 影响分析 | `mcp__ckb__analyzeImpact` |

### 降级提示

本 Skill 不需要降级，其目的就是生成索引以启用其他 Skill 的 MCP 增强能力。

