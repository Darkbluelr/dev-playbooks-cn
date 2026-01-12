---
name: devbooks-design-doc
description: devbooks-design-doc：产出变更包的设计文档（design.md），只写 What/Constraints 与 AC-xxx，不写实现步骤。用户说"写设计文档/Design Doc/架构设计/约束/验收标准/AC/C4 Delta"等时使用。
tools:
  - Glob
  - Grep
  - Read
  - Write
  - Edit
---

# DevBooks：设计文档（Design Doc）

## 前置：配置发现（协议无关）

- `<truth-root>`：当前真理目录根
- `<change-root>`：变更包目录根

执行前**必须**按以下顺序查找配置（找到后停止）：
1. `.devbooks/config.yaml`（如存在）→ 解析并使用其中的映射
2. `dev-playbooks/project.md`（如存在）→ DevBooks 2.0 协议，使用默认映射
4. `project.md`（如存在）→ template 协议，使用默认映射
5. 若仍无法确定 → **停止并询问用户**

**关键约束**：
- 如果配置中指定了 `agents_doc`（规则文档），**必须先阅读该文档**再执行任何操作
- 禁止猜测目录根
- 禁止跳过规则文档阅读

## 产物落点

- 设计文档：`<change-root>/<change-id>/design.md`

## 文档影响声明（必填）

设计文档中**必须**包含「文档影响」章节，声明本次变更对用户文档的影响。这是确保文档与代码同步的关键机制。

### 模板

```markdown
## Documentation Impact（文档影响）

### 需要更新的文档

| 文档 | 更新原因 | 优先级 |
|------|----------|--------|
| README.md | 新增功能 X 需要说明使用方法 | P0 |
| docs/使用说明书.md | 新增脚本 Y 需要补充用法 | P0 |
| CHANGELOG.md | 记录本次变更 | P1 |

### 无需更新的文档

- [ ] 本次变更为内部重构，不影响用户可见功能
- [ ] 本次变更仅修复 bug，不引入新功能或改变使用方式

### 文档更新检查清单

- [ ] 新增脚本/命令已在使用文档中说明
- [ ] 新增配置项已在配置文档中说明
- [ ] 新增工作流/流程已在指南中说明
- [ ] API/接口变更已在相关文档中更新
```

### 触发规则

以下变更类型**强制要求**更新对应文档：

| 变更类型 | 需更新文档 |
|----------|------------|
| 新增脚本（*.sh） | 使用说明、README |
| 新增 Skill | README、Skills 列表 |
| 修改工作流程 | 相关指南文档 |
| 新增配置项 | 配置文档 |
| 新增命令/CLI 参数 | 使用说明 |
| 对外 API 变更 | API 文档 |

## 执行方式

1) 先阅读并遵守：`_shared/references/通用守门协议.md`（可验证性 + 结构质量守门）。
2) 严格按完整提示词输出：`references/设计文档提示词.md`。

---

## 上下文感知

本 Skill 在执行前自动检测上下文，选择合适的运行模式。

检测规则参考：`skills/_shared/context-detection-template.md`

### 检测流程

1. 检测 `proposal.md` 是否存在（设计文档的输入）
2. 检测 `design.md` 是否已存在
3. 若存在，检测完整性（是否有 AC-xxx、是否有 `[TODO]`）

### 本 Skill 支持的模式

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| **新建设计** | `design.md` 不存在 | 创建完整设计文档 |
| **补充设计** | `design.md` 存在但有 `[TODO]` | 补充缺失章节 |
| **添加 AC** | 设计存在但 AC 不完整 | 补充验收标准 |

### 检测输出示例

```
检测结果：
- proposal.md：存在
- design.md：存在，有 5 个 [TODO]
- AC 数量：8 个
- 运行模式：补充设计
```

---

## MCP 增强

本 Skill 不依赖 MCP 服务，无需运行时检测。

MCP 增强规则参考：`skills/_shared/mcp-enhancement-template.md`

