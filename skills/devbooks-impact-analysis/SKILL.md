---
name: devbooks-impact-analysis
description: devbooks-impact-analysis：跨模块/跨文件/对外契约变更前做影响分析，产出可直接写入 proposal.md 的 Impact 部分（Scope/Impacts/Risks/Minimal Diff/Open Questions）。用户说"做影响分析/改动面控制/引用查找/受影响模块/兼容性风险"等时使用。
tools:
  - Glob
  - Grep
  - Read
  - Bash
  - mcp__ckb__getStatus
  - mcp__ckb__searchSymbols
  - mcp__ckb__findReferences
  - mcp__ckb__getCallGraph
  - mcp__ckb__traceUsage
  - mcp__ckb__analyzeImpact
  - mcp__ckb__getHotspots
---

# DevBooks：影响分析（Impact Analysis）

## 前置：配置发现（协议无关）

- `<truth-root>`：当前真理目录根
- `<change-root>`：变更包目录根

执行前**必须**按以下顺序查找配置（找到后停止）：
1. `.devbooks/config.yaml`（如存在）→ 解析并使用其中的映射
2. `openspec/project.md`（如存在）→ OpenSpec 协议，使用默认映射
3. `project.md`（如存在）→ template 协议，使用默认映射
4. 若仍无法确定 → **停止并询问用户**

**关键约束**：
- 如果配置中指定了 `agents_doc`（规则文档），**必须先阅读该文档**再执行任何操作
- 禁止猜测目录根
- 禁止跳过规则文档阅读

## 前置：图索引检查与自动生成

执行影响分析前**必须**检查图索引状态，若缺失则**自动生成**：

### Step 1: 检查索引状态

调用 `mcp__ckb__getStatus`，检查 `backends.scip.healthy`

### Step 2: 索引缺失时自动生成

若 `healthy: false`，执行以下流程（无需用户确认）：

```bash
# 1. 检测项目语言
if [ -f "package.json" ] || [ -f "tsconfig.json" ]; then
  LANG="typescript"
  INDEXER="scip-typescript"
  INDEX_CMD="scip-typescript index --output index.scip"
elif [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ]; then
  LANG="python"
  INDEXER="scip-python"
  INDEX_CMD="scip-python index . --output index.scip"
elif [ -f "go.mod" ]; then
  LANG="go"
  INDEXER="scip-go"
  INDEX_CMD="scip-go --output index.scip"
else
  LANG="unknown"
fi

# 2. 检查索引器是否已安装
if ! command -v $INDEXER &> /dev/null; then
  echo "⚠️ 索引器 $INDEXER 未安装，降级为文本搜索模式"
  # 输出安装指南后继续（降级模式）
else
  # 3. 生成索引
  echo "🔄 自动生成 SCIP 索引..."
  $INDEX_CMD

  # 4. 验证
  if [ -f "index.scip" ]; then
    echo "✅ 索引生成成功，使用图基分析模式"
  else
    echo "⚠️ 索引生成失败，降级为文本搜索模式"
  fi
fi
```

### Step 3: 选择分析模式

| 条件 | 模式 |
|------|------|
| 索引存在且健康 | 图基分析（高精度） |
| 索引器已安装，索引刚生成 | 图基分析（高精度） |
| 索引器未安装 | 文本搜索（降级） |
| 语言不支持 | 文本搜索（降级） |

**模式对比**：

| 模式 | 检索方式 | 准确度 | 适用场景 |
|------|----------|--------|----------|
| 图基分析 | `analyzeImpact` + `findReferences` + `getCallGraph` | 高 | 大型项目、跨模块变更 |
| 文本搜索 | `Grep` + `Glob` | 中 | 小型项目、索引不可用时 |

## 产物落点

- 推荐写入：`<change-root>/<change-id>/proposal.md` 的 Impact 部分（或独立分析文档后再回填）

## 执行方式

### 图基分析模式（索引可用时）

1) **锚点识别**：从用户描述中提取核心符号
   - 调用 `mcp__ckb__searchSymbols` 模糊匹配函数/类/变量名
   - 确认目标符号的 `symbolId`

2) **影响图遍历**：
   - `mcp__ckb__analyzeImpact(symbolId, depth=2)` → 获取影响范围评估
   - `mcp__ckb__findReferences(symbolId)` → 找到所有直接引用点
   - `mcp__ckb__getCallGraph(symbolId, direction="callers", depth=2)` → 追溯调用者链

3) **热点叠加**：
   - `mcp__ckb__getHotspots(limit=20)` → 获取技术债热点
   - 如果影响范围与热点重叠 → 标记为高风险区域

4) **输出整合**：将图分析结果整理为 Impact 部分

### 文本搜索模式（索引不可用时）

1) 先阅读并遵守：`references/项目开发实用提示词.md`（可验证性 + 结构质量守门）。
2) 使用 `Grep` 搜索符号引用，`Glob` 查找相关文件。
3) 严格按完整提示词输出影响分析 Markdown：`references/6 影响分析提示词.md`。

### 输出格式

```markdown
## Impact Analysis

### 分析模式
- [x] 图基分析（SCIP 索引）
- [ ] 文本搜索（降级模式）

### Scope
- 直接影响：X 个文件
- 间接影响：Y 个文件
- 热点重叠：Z 个高风险区域

### Impacts
| 文件 | 影响类型 | 风险等级 | 热点? |
|------|----------|----------|-------|
| ... | 直接调用 | 高 | ⚠️ |

### Risks
- ...

### Minimal Diff
- ...

### Open Questions
- ...
```
