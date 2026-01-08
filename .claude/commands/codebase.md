---
description: 搜索整个代码库（类似 Augment @codebase）
argument-hint: <搜索词或问题>
allowed-tools:
  - Grep
  - Glob
  - Read
  - mcp__ckb__searchSymbols
  - mcp__ckb__findReferences
  - mcp__ckb__getCallGraph
  - mcp__ckb__analyzeImpact
  - mcp__ckb__explainFile
  - mcp__ckb__traceUsage
---

# @codebase 全库搜索

用户请求在整个代码库中搜索: `$ARGUMENTS`

## 执行策略

### 1. 智能识别搜索类型

根据用户输入判断搜索类型：

- **符号搜索**: 如果输入看起来像函数名/类名（如 `getUserById`, `UserService`）
  - 使用 `mcp__ckb__searchSymbols` 搜索符号定义
  - 使用 `mcp__ckb__findReferences` 查找所有引用

- **概念搜索**: 如果输入是自然语言问题（如"用户认证如何工作"）
  - 使用 Grep 搜索关键词（auth, user, login 等）
  - 使用 `mcp__ckb__explainFile` 解释相关文件

- **文件搜索**: 如果输入包含文件路径或扩展名
  - 使用 Glob 查找匹配文件
  - 使用 Read 读取内容

- **影响分析**: 如果输入涉及"影响"、"依赖"、"调用"
  - 使用 `mcp__ckb__analyzeImpact` 分析影响
  - 使用 `mcp__ckb__getCallGraph` 获取调用图

### 2. 搜索执行

1. 先用 Grep/searchSymbols 快速定位
2. 对找到的符号用 findReferences 扩展
3. 对关键文件用 explainFile 解释
4. 汇总结果，按相关性排序

### 3. 结果格式

返回结构化结果：

```
📍 找到 N 处相关代码

1. [文件路径:行号] - 简短描述
   └── 代码片段预览

2. [文件路径:行号] - 简短描述
   └── 代码片段预览

💡 建议下一步：
- 查看 xxx 文件了解详情
- 使用 analyzeImpact 分析修改影响
```

## 开始搜索

请根据用户输入 `$ARGUMENTS` 执行上述策略，返回最相关的代码位置和解释。
