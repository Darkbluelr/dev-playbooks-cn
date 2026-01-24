---
last_referenced_by: 20260124-0636-enhance-devbooks-longterm-guidance
last_verified: 2026-01-24
health: active
---

# 规格：风格清理

## ADDED Requirements

### Requirement: REQ-STYLE-001 去除浮夸词语

**描述**: 从所有 skill 描述中去除浮夸词语,包括"最强大脑"、"智能"、"高效"、"强大"、"优雅"、"完美"、"革命性"、"颠覆性"等。

**理由**: 浮夸词语影响专业性,降低工具可信度,应回归本质描述。

**优先级**: P0

**关联 AC**: AC-008

**依赖**: 无

**约束**:
- 检查所有 skills/*/skill.md
- 生成清理报告
- 不修改功能描述的准确性


#### Scenario: SC-STYLE-001-AUTO 去除浮夸词语 最小场景

- **Given**: 需求 STYLE-001 已实现
- **When**: 执行对应功能
- **Then**: 输出符合需求描述

**证据**: tests/20260122-0827-enhance-docs-consistency 或 evidence/ 对应日志
### Requirement: REQ-STYLE-002 清理 MCP 相关扩展表述

**描述**: 从所有 skill 中移除与 MCP 运行细节相关的扩展章节、服务清单说明、模式对比内容，允许保留推荐 MCP 能力类型小节且不得绑定具体 MCP 服务名称。

**理由**: MCP 运行细节不应进入技能说明,保持 skills 职责单一。

**优先级**: P0

**关联 AC**: AC-009

**依赖**: 无

**约束**:
- 检查所有 skills/*/skill.md
- 完全移除相关扩展表述
- 允许保留“推荐 MCP 能力类型”小节
- 小节中不得出现具体 MCP 服务名称


#### Scenario: SC-STYLE-001 检测浮夸词语

**关联需求**: REQ-STYLE-001

**Given**:
- `skills/example-skill/skill.md` 包含"这是一个智能的解决方案"
- 运行浮夸词语检查

**When**:
- 扫描所有 skill 文档

**Then**:
- 检测到违规词语"智能"
- 记录文件路径和行号
- 输出到 `evidence/fancy-words-removal.md`

**验收标准**:
- 所有违规词语被检测
- 报告包含文件路径和行号
- 报告格式清晰

#### Scenario: SC-STYLE-002 生成浮夸词语清理报告

**关联需求**: REQ-STYLE-001

**Given**:
- 扫描完成
- 发现 15 处浮夸词语

**When**:
- 生成清理报告

**Then**:
- 报告包含所有违规位置
- 每个位置包含文件路径、行号、违规词语
- 报告保存到 `evidence/fancy-words-removal.md`

**验收标准**:
- 报告格式正确
- 所有违规位置都有记录
- 文件路径正确

#### Scenario: SC-STYLE-003 验证浮夸词语已清理

**关联需求**: REQ-STYLE-001

**Given**:
- 浮夸词语已从所有 skill 中删除

**When**:
- 运行验证命令: `grep -rE "(最强大脑|智能|高效|强大|优雅|完美|革命性|颠覆性)" skills/*/skill.md`

**Then**:
- 命令无输出(未找到匹配)
- 退出码非 0

**验收标准**:
- 无浮夸词语残留
- 验证命令正确

#### Scenario: SC-STYLE-004 检测 MCP 增强章节

**关联需求**: REQ-STYLE-002

**Given**:
- `skills/example-skill/skill.md` 包含"## MCP 增强"章节
- 运行 MCP 增强检查

**When**:
- 扫描所有 skill 文档

**Then**:
- 检测到 MCP 增强章节
- 记录文件路径
- 输出警告

**验收标准**:
- 所有 MCP 增强章节被检测
- 报告包含文件路径
- 警告信息清晰

#### Scenario: SC-STYLE-005 验证 MCP 增强已删除

**关联需求**: REQ-STYLE-002

**Given**:
- MCP 增强章节已从所有 skill 中删除

**When**:
- 运行验证命令: `! grep -r "MCP 增强" skills/*/skill.md`

**Then**:
- 命令返回成功(退出码 0)
- 无 MCP 增强章节残留

**验收标准**:
- 无 MCP 增强章节残留
- 验证命令正确

#### Scenario: SC-STYLE-006 删除 MCP 服务依赖说明

**关联需求**: REQ-STYLE-002

**Given**:
- `skills/example-skill/skill.md` 包含"依赖的 MCP 服务"表格

**When**:
- 删除 MCP 相关内容

**Then**:
- "依赖的 MCP 服务"表格被删除
- 相关说明文字被删除
- 核心功能描述保留

**验收标准**:
- MCP 服务依赖说明完全删除
- 核心功能不受影响
- 文档结构完整

#### Scenario: SC-STYLE-007 删除增强模式对比

**关联需求**: REQ-STYLE-002

**Given**:
- `skills/example-skill/skill.md` 包含"增强模式 vs 基础模式"对比表

**When**:
- 删除 MCP 相关内容

**Then**:
- 对比表被删除
- 相关说明文字被删除
- 核心功能描述保留

**验收标准**:
- 增强模式对比完全删除
- 核心功能不受影响
- 文档结构完整

#### Scenario: SC-STYLE-008 保持功能描述准确性

**关联需求**: REQ-STYLE-001

**Given**:
- 原描述: "这是一个强大的规则引擎"
- 需要去除浮夸词语

**When**:
- 修改描述

**Then**:
- 新描述: "这是一个规则引擎,支持自定义规则和一次性任务"
- 去除"强大",增加具体功能说明
- 描述更准确

**验收标准**:
- 浮夸词语已删除
- 功能描述更准确
- 信息量不减少

#### Scenario: SC-STYLE-009 允许推荐 MCP 能力类型

**关联需求**: REQ-STYLE-002

**Given**:
- `skills/example-skill/skill.md` 包含“推荐 MCP 能力类型”小节
- 小节未绑定具体 MCP 服务名称

**When**:
- 执行风格清理检查

**Then**:
- 不产生 REQ-STYLE-002 的违规警告

**验收标准**:
- 允许保留该小节
- 未引入绑定具体 MCP 的内容
