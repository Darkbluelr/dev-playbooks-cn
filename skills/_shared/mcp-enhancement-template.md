# MCP 增强模板（MCP Enhancement Template）

> 本模板供各 SKILL.md 引用，定义 MCP 运行时检测与降级策略的标准章节格式。

---

## 核心原则

1. **2s 超时**：所有 MCP 调用必须在 2s 内返回，否则视为不可用
2. **优雅降级**：MCP 不可用时，Skill 继续执行基础功能，不阻塞
3. **静默检测**：检测过程对用户透明，只在降级时输出提示

---

## 标准章节格式

每个 SKILL.md 的"MCP 增强"章节应包含以下内容：

```markdown
## MCP 增强

本 Skill 支持 MCP 运行时增强，自动检测并启用高级功能。

### 依赖的 MCP 服务

| 服务 | 用途 | 超时 |
|------|------|------|
| `mcp__ckb__getStatus` | 检测 CKB 索引可用性 | 2s |
| `mcp__ckb__getHotspots` | 获取热点文件 | 2s |

### 检测流程

1. 调用 `mcp__ckb__getStatus`（2s 超时）
2. 若返回成功 → 启用增强模式
3. 若超时或失败 → 降级到基础模式

### 增强模式 vs 基础模式

| 功能 | 增强模式 | 基础模式 |
|------|----------|----------|
| 热点检测 | CKB 实时分析 | Git 历史统计 |
| 影响分析 | 符号级引用 | 文件级 grep |
| 调用图 | 精确调用链 | 不可用 |

### 降级提示

当 MCP 不可用时，输出以下提示：

```
⚠️ CKB 不可用（超时或未配置），使用基础模式执行。
如需启用增强功能，请运行 /devbooks:index 生成索引。
```
```

---

## 按 Skill 分类

### 无 MCP 依赖的 Skills

以下 Skills 不依赖 MCP，无需 MCP 增强章节：

- devbooks-design-doc（纯文档生成）
- devbooks-implementation-plan（纯计划生成）
- devbooks-proposal-author（纯文档生成）
- devbooks-proposal-challenger（纯评审）
- devbooks-proposal-judge（纯裁决）
- devbooks-proposal-debate-workflow（流程编排）
- devbooks-design-backport（文档回写）
- devbooks-spec-gardener（文件整理）
- devbooks-test-reviewer（测试评审）

对于这些 Skills，MCP 增强章节应写：

```markdown
## MCP 增强

本 Skill 不依赖 MCP 服务，无需运行时检测。
```

### 有 MCP 依赖的 Skills

以下 Skills 依赖 MCP，需要完整 MCP 增强章节：

| Skill | MCP 依赖 | 增强功能 |
|-------|----------|----------|
| devbooks-coder | mcp__ckb__getHotspots | 热点文件预警 |
| devbooks-code-review | mcp__ckb__getHotspots | 热点文件高亮 |
| devbooks-impact-analysis | mcp__ckb__analyzeImpact, findReferences | 精确影响分析 |
| devbooks-brownfield-bootstrap | mcp__ckb__* | COD 模型生成 |
| devbooks-index-bootstrap | mcp__ckb__getStatus | 索引状态检测 |
| devbooks-federation | mcp__ckb__*, mcp__github__* | 跨仓库分析 |
| devbooks-router | mcp__ckb__getStatus | 索引可用性检测 |
| devbooks-c4-map | mcp__ckb__getArchitecture | 模块依赖图 |
| devbooks-spec-contract | mcp__ckb__findReferences | 引用检测 |
| devbooks-entropy-monitor | mcp__ckb__getHotspots | 热点趋势分析 |
| devbooks-delivery-workflow | mcp__ckb__getStatus | 索引检测 |
| devbooks-test-owner | mcp__ckb__analyzeImpact | 测试覆盖分析 |

---

## 检测代码示例

### Bash 检测脚本

```bash
#!/bin/bash
# mcp-detect.sh - MCP 可用性检测

TIMEOUT=2

# 检测 CKB
check_ckb() {
  # 模拟 MCP 调用（实际由 Claude Code 执行）
  # 若 2s 内无响应，返回降级状态
  echo "⚠️ CKB 检测需要在 Claude Code 环境中执行"
}

# 输出检测结果
detect_mcp() {
  local ckb_status="unknown"

  # 检查 index.scip 文件是否存在（文件级检测）
  if [ -f "index.scip" ]; then
    ckb_status="available (file-based)"
  else
    ckb_status="unavailable"
  fi

  echo "MCP 检测结果："
  echo "- CKB 索引：$ckb_status"
}

detect_mcp
```

---

## 注意事项

1. **不要在 SKILL.md frontmatter 中添加不存在的 MCP 工具**
2. **超时检测应在 Skill 执行开始时进行，不要多次检测**
3. **降级后不要重复提示，只在首次检测时输出一次**
4. **增强功能是可选的，基础功能必须完整可用**
