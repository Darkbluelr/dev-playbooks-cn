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

生成索引后，建议用户配置自动更新（二选一）：

1. **Git Hook（本地开发）**：
   ```bash
   echo 'scip-typescript index --output index.scip &' >> .git/hooks/post-commit
   chmod +x .git/hooks/post-commit
   ```

2. **CI Pipeline（团队协作）**：
   在 CI 中生成并上传 index.scip 作为 artifact

## 注意事项

- 大型项目首次索引可能需要 1-5 分钟
- 索引文件建议加入 `.gitignore`（或作为 CI artifact 共享）
- 索引过期不影响功能，只是图数据可能不完整
