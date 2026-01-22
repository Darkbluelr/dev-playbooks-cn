# Design: 文档一致性工具优化

---
**元信息**：
- **版本**: v1.0
- **状态**: Draft
- **创建时间**: 2026-01-22
- **最后更新**: 2026-01-22
- **适用范围**: DevBooks 文档一致性检查工具
- **Owner**: Design Owner
- **last_verified**: 2026-01-22
- **freshness_check**: 1 Month
---

## Acceptance Criteria（验收标准）

### AC-001 (A): Skill 改名完成且别名生效
- **Pass 判据**:
  - `skills/devbooks-docs-consistency/` 目录存在
  - `skills/devbooks-docs-sync/` 目录不存在或为软链接
  - 调用 `devbooks-docs-sync` 能正常工作（别名机制）
- **验收方式**: A（机器裁判）
- **验收命令**: `test -d skills/devbooks-docs-consistency && ls -la skills/ | grep docs-sync`

### AC-002 (A): 自定义规则引擎工作正常
- **Pass 判据**:
  - 支持持续规则（配置文件）
  - 支持一次性任务（命令行参数 `--once "remove:@augment"`）
  - 规则引擎能正确解析和执行规则
- **验收方式**: A（机器裁判）
- **验收命令**: 单元测试 `test-rules-engine.bats`

### AC-003 (A): 增量扫描 token 消耗 < 全量扫描 20%
- **Pass 判据**:
  - 增量扫描只处理变更文件
  - Token 消耗量 < 全量扫描的 20%
  - 记录 token 消耗日志到 `evidence/token-usage.log`
- **验收方式**: A（机器裁判）
- **验收命令**: `bash scripts/benchmark-scan.sh`
- **阈值**: 增量扫描 token < 全量扫描 token * 0.2

### AC-004 (B): 完备性检查覆盖所有维度
- **Pass 判据**:
  - 检查维度包含：环境依赖、安全权限、故障排查、配置说明、API 文档
  - 每个维度有明确的检查规则
  - 检查结果输出到 `evidence/completeness-report.md`
- **验收方式**: B（工具证据+人签核）
- **证据位置**: `evidence/completeness-report.md`

### AC-005 (A): 文档分类正确
- **Pass 判据**:
  - 能区分活体文档（README.md、docs/*.md）
  - 能区分历史文档（CHANGELOG.md）
  - 能区分概念性文档（architecture/*.md）
  - 分类规则可配置
- **验收方式**: A（机器裁判）
- **验收命令**: 单元测试 `test-doc-classification.bats`

### AC-006 (A): 共享方法论文档可引用
- **Pass 判据**:
  - `skills/_shared/references/完备性思维框架.md` 存在
  - 内容从 `/Users/ozbombor/Projects/dev-playbooks-cn/如何构建完备的系统.md` 迁移
  - 至少 3 个 skills 引用该文档
- **验收方式**: A（机器裁判）
- **验收命令**: `test -f skills/_shared/references/完备性思维框架.md && grep -r "完备性思维框架" skills/*/skill.md | wc -l`

### AC-007 (A): 与其他 skills 集成成功
- **Pass 判据**:
  - `devbooks-archiver` 在归档前调用 docs-consistency
  - `devbooks-brownfield-bootstrap` 初始化时生成 `docs-maintenance.md`
  - `devbooks-proposal-author` 包含 Challenger 审视部分
- **验收方式**: A（机器裁判）
- **验收命令**: `grep -q "devbooks-docs-consistency" skills/devbooks-archiver/skill.md`

### AC-008 (B): 浮夸词语已去除
- **Pass 判据**:
  - 所有 skill 描述中不包含："最强大脑"、"智能"、"高效"、"强大"、"优雅"、"完美"、"革命性"、"颠覆性"
  - 检查结果输出到 `evidence/fancy-words-removal.md`
- **验收方式**: B（工具证据+人签核）
- **证据位置**: `evidence/fancy-words-removal.md`
- **检查命令**: `grep -rE "(最强大脑|智能|高效|强大|优雅|完美|革命性|颠覆性)" skills/*/skill.md`

### AC-009 (A): MCP 增强功能已删除
- **Pass 判据**:
  - 所有 skill 中不包含 "MCP 增强" 章节
  - 所有 skill 中不包含 "依赖的 MCP 服务" 说明
  - 所有 skill 中不包含 "增强模式 vs 基础模式" 对比
- **验收方式**: A（机器裁判）
- **验收命令**: `! grep -r "MCP 增强" skills/*/skill.md`

### AC-010 (A): 专家角色声明机制已实现
- **Pass 判据**:
  - 每个 skill.md 包含 `recommended_experts` 字段
  - `AI行为规范.md` 包含专家角色声明协议
  - `skills/_shared/references/专家列表.md` 存在
- **验收方式**: A（机器裁判）
- **验收命令**: `grep -q "recommended_experts" skills/devbooks-proposal-author/skill.md`

### AC-011 (A): 文档风格偏好已持久化
- **Pass 判据**:
  - `dev-playbooks/specs/_meta/docs-maintenance.md` 存在
  - 包含 `style_preferences` 字段
  - 包含 `use_emoji: false` 和 `use_fancy_words: false`
- **验收方式**: A（机器裁判）
- **验收命令**: `test -f dev-playbooks/specs/_meta/docs-maintenance.md && grep -q "style_preferences" dev-playbooks/specs/_meta/docs-maintenance.md`

### AC-012 (A): 扫描速度 < 10 秒
- **Pass 判据**:
  - 增量扫描完成时间 < 10 秒
  - 记录扫描时间到 `evidence/scan-performance.log`
- **验收方式**: A（机器裁判）
- **验收命令**: `bash scripts/benchmark-scan.sh | grep "Scan time" | awk '{print $3}' | awk -F. '{print $1 < 10}'`

## ⚡ Goals / Non-goals + Red Lines

### Goals（目标）
1. **改名**: `devbooks-docs-sync` → `devbooks-docs-consistency`，更准确反映职责
2. **自定义规则**: 支持项目特定的文档规范（持续规则 + 一次性任务）
3. **增量扫描**: 利用 git 历史，只扫描变更文件，减少 token 消耗 90%
4. **完备性检查**: 覆盖环境依赖、安全权限、故障排查等多个维度
5. **文档分类**: 区分活体文档、历史文档、概念性文档
6. **方法论共享**: 提取完备性思维框架为共享文档
7. **简化描述**: 去除所有浮夸词语，回归本质描述
8. **边界清晰**: 删除 MCP 增强功能，保持职责单一
9. **角色明确**: 所有 skill 使用时声明专家角色
10. **风格持久化**: 文档风格偏好记录在版本控制中

### Non-goals（明确不做）
1. **不修改用户文档**: 不修改用户项目中的 README、CHANGELOG 等
2. **不修改历史文档**: 不修改已归档的变更包文档
3. **不修改测试代码**: 不修改 `tests/` 目录
4. **不修改其他 skills 核心逻辑**: 只修改集成调用部分
5. **不维护用户项目的 dev-playbooks/ 目录**: 这些是 DevBooks 工具自身的模板

### Red Lines（不可破的约束）
1. **向后兼容**: 提供别名机制，保留 6 个月后废弃
2. **零配置可用**: 不强制配置，提供合理默认值
3. **不破坏现有文档结构**: 只检查和建议，不强制修改
4. **职责单一**: 只负责文档一致性检查，不处理 MCP 相关逻辑
5. **可降级**: 增量扫描失败时自动回退到全量扫描

## 执行摘要

本次变更优化 DevBooks 文档一致性检查工具，核心矛盾是**效率与完备性的平衡**：
- **效率问题**: 全量扫描浪费 token，增量扫描可减少 90% 消耗
- **完备性问题**: 当前检查维度不足，需要覆盖环境依赖、安全权限等
- **边界问题**: MCP 增强功能越界，应该由 MCP 自身处理
- **描述问题**: 浮夸词语影响专业性，需要回归本质描述

解决方案：改名 + 增量扫描 + 完备性检查 + 自定义规则 + 简化描述 + 边界清晰。

## Problem Context（问题背景）

### 为什么要解决这个问题？

**业务驱动**：
- DevBooks 作为规范驱动开发工具，文档与代码的一致性是核心价值
- 文档不一致会导致用户困惑、实现偏差、维护成本上升

**技术债**：
- 当前 `devbooks-docs-sync` 命名不准确，"sync"暗示双向同步，实际是单向检查
- 全量扫描每次消耗大量 token，在大型项目中不可持续
- 检查维度不完备，只覆盖 API 和配置，缺少环境依赖、安全权限等

**用户痛点**：
- 无法添加项目特定的文档规范（如"删除所有 @augment 引用"）
- 扫描速度慢，影响开发体验
- 浮夸词语影响专业性，降低工具可信度
- MCP 增强功能越界，增加理解成本

### 当前系统在哪里产生了摩擦或瓶颈？

**摩擦点 1：命名不准确**
- "docs-sync"暗示会修改文档，实际只检查
- 用户期望与实际行为不符

**摩擦点 2：token 消耗**
- 全量扫描每次读取所有文档和代码
- 在 1000+ 文件的项目中，单次扫描消耗 10k+ tokens
- 频繁运行导致成本上升

**摩擦点 3：检查不完备**
- 只检查 API 和配置，遗漏环境依赖（如 Node.js 版本要求）
- 遗漏安全权限说明（如文件权限、环境变量）
- 遗漏故障排查指南

**摩擦点 4：无法自定义**
- 项目特定规范无法配置（如"禁止使用 emoji"）
- 一次性清理任务需要手动执行

### 若不解决会有什么后果？

- **效率下降**：token 消耗持续上升，影响工具可用性
- **质量下降**：文档不完备导致用户无法正确使用工具
- **可维护性下降**：浮夸词语和越界功能增加理解成本
- **用户流失**：工具不专业，用户信任度下降

## 价值链映射

**Goal（目标）**：提升文档一致性检查的效率和完备性

**阻碍（Blockers）**：
1. 全量扫描 token 消耗高
2. 检查维度不完备
3. 无法自定义规则
4. 命名和描述不专业

**杠杆（Levers）**：
1. 利用 git 历史实现增量扫描
2. 引入完备性思维框架
3. 设计规则引擎
4. 清理浮夸词语和越界功能

**最小方案**：
1. 改名 + 别名（向后兼容）
2. 增量扫描（减少 90% token）
3. 完备性检查（覆盖 5 个维度）
4. 自定义规则（持续 + 一次性）
5. 去除浮夸词语
6. 删除 MCP 增强功能
7. 专家角色声明机制

## 背景与现状评估

### 现有资产

**已有功能**：
- 文档与代码一致性检查（API、配置）
- 文档分类（活体/历史）
- 与 archiver 集成

**已有基础设施**：
- Git 历史记录
- DevBooks 变更包机制
- Skill 调用框架

**已有文档**：
- `如何构建完备的系统.md`（完备性思维框架）
- `AI行为规范.md`（行为约束）

### 主要风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 改名后用户无法找到工具 | 中 | 中 | 提供别名，保留 6 个月 |
| 增量扫描遗漏新增代码 | 低 | 高 | 提供全量扫描回退 |
| 元数据维护成为负担 | 中 | 中 | 自动维护，零配置可用 |
| 规则引擎过于复杂 | 中 | 中 | 提供合理默认值 |
| 完备性检查过于严格 | 低 | 低 | 只警告，不阻塞 |

## 设计原则

### 核心原则

1. **效率优先**：增量扫描为默认，全量扫描为回退
2. **完备性优先**：覆盖多个维度，避免遗漏
3. **零配置可用**：提供合理默认值，不强制配置
4. **向后兼容**：提供别名机制，平滑迁移
5. **职责单一**：只负责文档一致性检查，不处理 MCP

### 变化点识别（Variation Points）

**变化点 1：检查规则**
- 封装方式：规则引擎 + 配置文件
- 扩展点：`docs-rules.yaml`

**变化点 2：文档分类**
- 封装方式：分类器 + 配置
- 扩展点：`doc-classification.yaml`

**变化点 3：扫描策略**
- 封装方式：策略模式（增量/全量）
- 扩展点：命令行参数 `--scan-mode`

**变化点 4：完备性维度**
- 封装方式：维度检查器 + 配置
- 扩展点：`completeness-dimensions.yaml`

## 目标架构

### Bounded Context（边界上下文）

```
┌─────────────────────────────────────────────────────────┐
│ devbooks-docs-consistency (文档一致性检查)              │
├─────────────────────────────────────────────────────────┤
│ - 规则引擎 (RulesEngine)                                │
│ - 扫描器 (Scanner: Incremental / Full)                  │
│ - 完备性检查器 (CompletenessChecker)                    │
│ - 文档分类器 (DocClassifier)                            │
│ - 风格检查器 (StyleChecker)                             │
└─────────────────────────────────────────────────────────┘
         ↓ 调用                    ↓ 调用
┌──────────────────┐      ┌──────────────────┐
│ devbooks-archiver│      │ brownfield-      │
│ (归档前检查)     │      │ bootstrap        │
│                  │      │ (初始化生成元数据)│
└──────────────────┘      └──────────────────┘
```

### 依赖方向

- **向内依赖**：其他 skills → docs-consistency
- **向外依赖**：docs-consistency → git、文件系统、配置文件
- **禁止依赖**：docs-consistency ✗→ MCP

### 关键扩展点

1. **规则扩展点**：`references/docs-rules-schema.yaml`
2. **维度扩展点**：`references/completeness-dimensions.yaml`
3. **分类扩展点**：`references/doc-classification.yaml`
4. **风格扩展点**：`specs/_meta/docs-maintenance.md` 中的 `style_preferences`

### Testability & Seams（可测试性与接缝）

**测试接缝（Seams）**：
- `RulesEngine.loadRules(configPath)` - 可注入测试配置
- `Scanner.getChangedFiles(gitRef)` - 可注入 mock git 输出
- `CompletenessChecker.checkDimension(doc, dimension)` - 可独立测试每个维度

**Pinch Points（汇点）**：
- `docs-consistency.sh` 主入口 - 3 条路径汇聚（增量/全量/一次性）
- `RulesEngine.applyRules()` - 所有规则执行汇聚点

**依赖隔离策略**：
- Git 操作 → 通过 `GitAdapter` 接口隔离，测试时用 `MockGitAdapter`
- 文件系统 → 通过 `FileSystemAdapter` 接口隔离
- 配置读取 → 通过 `ConfigLoader` 接口隔离

## 领域模型（Domain Model）

### Data Model

**@Entity: DocConsistencyReport**
- 属性：
  - `report_id`: 唯一标识
  - `scan_mode`: 扫描模式（incremental/full）
  - `scan_time`: 扫描时间
  - `token_usage`: token 消耗量
  - `issues_found`: 发现的问题数量
  - `issues`: 问题列表
- 生命周期：创建 → 填充 → 输出 → 归档

**@ValueObject: DocIssue**
- 属性：
  - `file_path`: 文件路径
  - `issue_type`: 问题类型（missing_doc/outdated_doc/style_violation）
  - `severity`: 严重程度（error/warning/info）
  - `message`: 问题描述
  - `suggestion`: 修复建议
- 不可变，无标识

**@ValueObject: DocRule**
- 属性：
  - `rule_id`: 规则 ID
  - `rule_type`: 规则类型（persistent/once）
  - `pattern`: 匹配模式
  - `action`: 执行动作（check/remove/replace）
  - `target`: 目标（content/filename/structure）
- 不可变，无标识

**@ValueObject: StylePreference**
- 属性：
  - `use_emoji`: 是否使用 emoji
  - `use_fancy_words`: 是否使用浮夸词语
  - `forbidden_words`: 禁用词列表
  - `heading_style`: 标题风格
  - `code_block_style`: 代码块风格
- 不可变，无标识

### Business Rules

**BR-001: 增量扫描触发条件**
- 触发条件：存在 git 历史且未指定 `--full`
- 约束内容：只扫描自上次扫描以来变更的文件
- 违反时行为：回退到全量扫描

**BR-002: 完备性检查维度**
- 触发条件：文档类型为活体文档
- 约束内容：必须检查 5 个维度（环境依赖、安全权限、故障排查、配置说明、API 文档）
- 违反时行为：输出警告，不阻塞

**BR-003: 风格偏好优先级**
- 触发条件：存在 `docs-maintenance.md`
- 约束内容：命令行参数 > 配置文件 > 默认值
- 违反时行为：使用默认值

**BR-004: 别名机制**
- 触发条件：调用 `devbooks-docs-sync`
- 约束内容：重定向到 `devbooks-docs-consistency`，输出弃用警告
- 违反时行为：无（兼容性保证）

### Invariants（固定规则）

**[Invariant] token 消耗量必须记录**
- 每次扫描必须记录 token 消耗量到日志
- 用于性能监控和优化

**[Invariant] 增量扫描不能遗漏文件**
- 增量扫描必须覆盖所有变更文件
- 通过 git diff 确保完整性

**[Invariant] 规则引擎必须幂等**
- 同一规则多次执行结果一致
- 避免重复修改

### Integrations（集成边界）

**集成 1：devbooks-archiver**
- 外部模型：归档检查清单
- 内部模型：DocConsistencyReport
- ACL：`ArchiverAdapter` 转换报告格式为归档清单项

**集成 2：devbooks-brownfield-bootstrap**
- 外部模型：初始化配置
- 内部模型：StylePreference
- ACL：`BootstrapAdapter` 生成默认风格偏好

**集成 3：Git**
- 外部模型：git diff 输出
- 内部模型：ChangedFileList
- ACL：`GitAdapter` 解析 git 输出为文件列表

## 核心数据与事件契约

### Artifacts（产物）

**1. docs-maintenance.md**
```yaml
version: 1.0
last_full_scan: 2026-01-22
style_preferences:
  use_emoji: false
  use_fancy_words: false
  forbidden_words: [...]
critical_docs: [...]
automated_docs: [...]
known_mappings: [...]
```
- **schema_version**: 1.0
- **兼容策略**: 向后兼容，新增字段不破坏旧版本
- **迁移策略**: 自动迁移，保留旧字段

**2. completeness-report.md**
```markdown
# 完备性检查报告
- 环境依赖: ✓ / ✗
- 安全权限: ✓ / ✗
- 故障排查: ✓ / ✗
- 配置说明: ✓ / ✗
- API 文档: ✓ / ✗
```
- **schema_version**: 1.0
- **兼容策略**: 向后兼容

**3. token-usage.log**
```
2026-01-22 10:00:00 | incremental | 500 tokens
2026-01-22 11:00:00 | full | 10000 tokens
```
- **schema_version**: 1.0
- **兼容策略**: 追加模式，不修改历史记录

### Event Envelope（事件信封）

**DocConsistencyCheckCompleted**
```json
{
  "event_id": "uuid",
  "event_type": "DocConsistencyCheckCompleted",
  "timestamp": "2026-01-22T10:00:00Z",
  "payload": {
    "scan_mode": "incremental",
    "issues_count": 5,
    "token_usage": 500
  },
  "schema_version": "1.0"
}
```
- **idempotency_key**: `event_id`
- **兼容策略**: 向后兼容，新增字段不破坏旧版本

## 关键机制

### 质量闸门

**闸门 1：增量扫描完整性**
- 检查点：扫描前
- 检查内容：git diff 是否覆盖所有变更文件
- 失败行为：回退到全量扫描

**闸门 2：规则引擎幂等性**
- 检查点：规则执行前
- 检查内容：规则是否已执行
- 失败行为：跳过重复规则

**闸门 3：token 消耗阈值**
- 检查点：扫描后
- 检查内容：token 消耗是否超过阈值（10k）
- 失败行为：输出警告，建议优化

### 预算化

**token 预算**：
- 单次扫描预算：2k tokens（增量）/ 10k tokens（全量）
- 超预算处理：输出警告，记录日志

### 隔离

**文档类型隔离**：
- 活体文档：完整检查
- 历史文档：跳过检查
- 概念性文档：只检查结构

### 回放

**扫描历史回放**：
- 记录每次扫描的 token 消耗和问题数量
- 支持回放历史扫描，对比变化趋势

### 审计

**审计日志**：
- 记录每次扫描的参数、结果、token 消耗
- 支持审计追溯

## 可观测性与验收

### Metrics/KPI/SLO

**KPI 1：token 消耗减少率**
- 目标：增量扫描 token 消耗 < 全量扫描 20%
- 测量方式：对比 `token-usage.log`
- SLO：p95 < 20%

**KPI 2：扫描速度**
- 目标：增量扫描 < 10 秒
- 测量方式：记录扫描时间
- SLO：p99 < 10 秒

**KPI 3：问题检出率**
- 目标：完备性检查检出率提升 50%
- 测量方式：对比检出问题数量
- SLO：检出率 > 基线 * 1.5

**Metrics 收集**：
- `token_usage_total`: 累计 token 消耗
- `scan_duration_seconds`: 扫描耗时
- `issues_found_total`: 发现问题总数
- `scan_mode`: 扫描模式（incremental/full）

## 安全、合规与多租户隔离

### 安全

**敏感信息保护**：
- 不记录文件内容到日志
- 只记录文件路径和问题类型

**权限控制**：
- 只读取文档和配置文件
- 不修改文件（只检查）

### 合规

**数据保留**：
- 扫描日志保留 90 天
- 报告保留在变更包中

### 多租户隔离

**不适用**：本工具为单租户工具，不涉及多租户

## 里程碑

**Phase 1：核心功能（Week 1-2）**
- 改名 + 别名机制
- 增量扫描
- 规则引擎（基础）

**Phase 2：完备性检查（Week 3）**
- 5 个维度检查
- 完备性报告

**Phase 3：集成与清理（Week 4）**
- 与其他 skills 集成
- 去除浮夸词语
- 删除 MCP 增强功能
- 专家角色声明机制

**Phase 4：文档与测试（Week 5）**
- 共享方法论文档
- 单元测试
- 集成测试

## Deprecation Plan

### 弃用项：devbooks-docs-sync

**标记阶段（Month 1-3）**：
- 调用 `devbooks-docs-sync` 时输出弃用警告
- 警告内容："`devbooks-docs-sync` 已弃用，请使用 `devbooks-docs-consistency`"
- 功能正常工作（别名机制）

**警告阶段（Month 4-6）**：
- 增加警告频率（每次调用都警告）
- 在文档中标注弃用状态

**移除阶段（Month 7+）**：
- 移除别名机制
- 调用 `devbooks-docs-sync` 返回错误
- 提示用户使用 `devbooks-docs-consistency`

### 弃用项：MCP 增强功能

**立即移除**：
- 删除所有 skill 中的 "MCP 增强" 章节
- 删除 MCP 可用性检测代码
- 删除降级提示

**理由**：
- MCP 增强功能越界，应该由 MCP 自身处理
- 保持 skills 职责单一

## Design Rationale（设计决策理由）

### 决策 1：为什么改名？

**备选方案**：
- A：保持 `devbooks-docs-sync` 名称
- B：改名为 `devbooks-docs-consistency`
- C：改名为 `devbooks-docs-checker`

**选择 B 的理由**：
- "consistency"准确反映职责（一致性检查）
- "sync"暗示双向同步，容易误导
- "checker"过于通用，不够专业

### 决策 2：为什么使用增量扫描？

**备选方案**：
- A：全量扫描
- B：增量扫描
- C：混合模式（自动判断）

**选择 C 的理由**：
- 增量扫描减少 90% token 消耗
- 全量扫描作为回退，确保完整性
- 自动判断（存在 git 历史 → 增量，否则 → 全量）

**技术依据**：
- Git diff 可靠性高，能准确识别变更文件
- 增量扫描不会遗漏文件（通过 git diff 确保）

### 决策 3：为什么使用规则引擎？

**备选方案**：
- A：硬编码规则
- B：规则引擎 + 配置文件
- C：插件系统

**选择 B 的理由**：
- 规则引擎灵活，支持自定义规则
- 配置文件易于维护，不需要修改代码
- 插件系统过于复杂，不符合零配置原则

### 决策 4：为什么删除 MCP 增强功能？

**备选方案**：
- A：保留 MCP 增强功能
- B：简化 MCP 增强功能
- C：完全删除 MCP 增强功能

**选择 C 的理由**：
- MCP 增强功能越界，应该由 MCP 自身处理
- 保持 skills 职责单一，降低理解成本
- MCP 可用性检测应该由 MCP 自身提供

## Trade-offs（权衡取舍）

### 权衡 1：增量扫描 vs 完整性

**放弃**：绝对的完整性保证（依赖 git 历史）
**换取**：90% token 消耗减少
**接受的不完美**：如果 git 历史不准确，可能遗漏文件
**缓解措施**：提供全量扫描回退

### 权衡 2：规则引擎 vs 简单性

**放弃**：极简的硬编码规则
**换取**：灵活的自定义规则
**接受的不完美**：规则引擎增加复杂度
**缓解措施**：提供合理默认值，零配置可用

### 权衡 3：完备性检查 vs 性能

**放弃**：极致的扫描速度
**换取**：完备的检查维度
**接受的不完美**：扫描时间可能增加
**缓解措施**：增量扫描 + 并行检查

### 权衡 4：向后兼容 vs 清晰命名

**放弃**：立即改名，不考虑兼容性
**换取**：平滑迁移，用户无感知
**接受的不完美**：6 个月内维护两个名称
**缓解措施**：别名机制 + 弃用警告

## Technical Debt（技术债务）

### TD-001 [Architecture] 规则引擎未抽象为独立模块

**原因**：Phase 1 快速验证，规则引擎与扫描器耦合
**影响**：Medium - 规则引擎难以复用
**偿还计划**：Phase 2 后抽取为独立模块
**触发条件**：其他 skills 需要使用规则引擎

### TD-002 [Test] 增量扫描缺少边界测试

**原因**：Mock git 输出复杂度高
**影响**：High - 增量扫描变更风险
**偿还计划**：Phase 4 补充边界测试
**触发条件**：增量扫描逻辑变更前

### TD-003 [Code] 完备性维度硬编码

**原因**：Phase 2 快速实现，未抽取配置
**影响**：Low - 新增维度需要修改代码
**偿还计划**：Phase 3 移入配置文件
**触发条件**：需要新增维度时

### TD-004 [Doc] 浮夸词语清理未自动化

**原因**：Phase 3 手动清理，未建立自动检查
**影响**：Medium - 可能再次引入浮夸词语
**偿还计划**：Phase 4 建立自动检查（风格检查器）
**触发条件**：发现新的浮夸词语时

## 风险与降级策略

### 风险 1：增量扫描遗漏文件

**Failure Mode**：git diff 不准确或 git 历史损坏
**影响**：High - 遗漏文档问题
**Degrade Path**：自动回退到全量扫描
**检测方式**：git diff 返回错误或为空

### 风险 2：规则引擎执行失败

**Failure Mode**：规则配置错误或规则冲突
**影响**：Medium - 规则无法执行
**Degrade Path**：跳过失败规则，继续执行其他规则
**检测方式**：规则执行抛出异常

### 风险 3：完备性检查过于严格

**Failure Mode**：检查规则过于严格，大量误报
**影响**：Low - 用户体验下降
**Degrade Path**：只输出警告，不阻塞归档
**检测方式**：用户反馈

### 风险 4：token 消耗超预算

**Failure Mode**：增量扫描失效，回退到全量扫描
**影响**：Medium - token 消耗上升
**Degrade Path**：输出警告，建议优化
**检测方式**：token 消耗超过阈值（10k）

### 风险 5：别名机制失效

**Failure Mode**：别名配置错误或路径问题
**影响**：High - 用户无法使用旧名称
**Degrade Path**：输出错误信息，提示使用新名称
**检测方式**：别名调用失败

## ⚡ DoD 完成定义（Definition of Done）

### 本设计何时算"完成"？

**功能完成**：
- 所有 AC 通过（AC-001 ~ AC-012）
- 所有功能正常工作
- 所有集成测试通过

**质量完成**：
- 单元测试覆盖率 > 80%
- 所有 lint 检查通过
- 代码审查通过

**文档完成**：
- skill.md 更新
- references/ 文档完整
- 共享方法论文档迁移完成

**证据完成**：
- `evidence/token-usage.log` 存在
- `evidence/completeness-report.md` 存在
- `evidence/fancy-words-removal.md` 存在
- `evidence/scan-performance.log` 存在

### 必须通过的闸门清单

- [ ] 所有单元测试通过（`bats tests/`）
- [ ] 所有集成测试通过
- [ ] Shellcheck 静态检查通过
- [ ] 代码审查通过（Reviewer 签核）
- [ ] 文档完整性检查通过（docs-consistency 自检）
- [ ] 性能基准测试通过（token 消耗 < 20%）

### 必须产出的证据

**证据目录**：`dev-playbooks/changes/20260122-0827-enhance-docs-consistency/evidence/`

**必须产出**：
1. `token-usage.log` - token 消耗记录
2. `completeness-report.md` - 完备性检查报告
3. `fancy-words-removal.md` - 浮夸词语清理报告
4. `scan-performance.log` - 扫描性能记录
5. `test-results.log` - 测试结果
6. `integration-test-results.log` - 集成测试结果

### 与 AC 的交叉引用

- AC-001 → 闸门：目录结构检查
- AC-002 → 闸门：单元测试 `test-rules-engine.bats`
- AC-003 → 证据：`token-usage.log`
- AC-004 → 证据：`completeness-report.md`
- AC-005 → 闸门：单元测试 `test-doc-classification.bats`
- AC-006 → 闸门：文件存在性检查
- AC-007 → 闸门：集成测试
- AC-008 → 证据：`fancy-words-removal.md`
- AC-009 → 闸门：grep 检查
- AC-010 → 闸门：文件存在性检查
- AC-011 → 闸门：文件存在性检查
- AC-012 → 证据：`scan-performance.log`

## Open Questions

1. **规则引擎复杂度**：是否需要支持规则优先级和规则依赖？
   - 当前方案：简单规则，按顺序执行
   - 备选方案：支持优先级和依赖
   - 建议：Phase 1 使用简单规则，根据反馈决定是否增强

2. **完备性检查严格程度**：是否应该阻塞归档？
   - 当前方案：只警告，不阻塞
   - 备选方案：阻塞归档，强制修复
   - 建议：Phase 2 只警告，Phase 3 根据反馈决定是否阻塞

3. **文档风格偏好范围**：是否应该扩展到代码注释？
   - 当前方案：只检查文档
   - 备选方案：扩展到代码注释
   - 建议：Phase 1 只检查文档，Phase 4 根据需求决定是否扩展

## Documentation Impact（文档影响）

### 需要更新的文档

| 文档 | 更新原因 | 优先级 |
|------|----------|--------|
| skills/devbooks-docs-consistency/skill.md | 新 skill 文档 | P0 |
| skills/devbooks-docs-consistency/references/*.md | 新增规则 schema、完备性维度等 | P0 |
| skills/_shared/references/完备性思维框架.md | 迁移共享方法论 | P0 |
| skills/_shared/references/AI行为规范.md | 新增专家角色声明协议 | P0 |
| skills/_shared/references/专家列表.md | 新增通用专家列表 | P0 |
| skills/devbooks-archiver/skill.md | 集成 docs-consistency 调用 | P1 |
| skills/devbooks-brownfield-bootstrap/skill.md | 集成 docs-maintenance.md 生成 | P1 |
| skills/devbooks-proposal-author/skill.md | 新增 Challenger 审视部分 | P1 |
| README.md | 更新 skill 列表（改名） | P1 |
| CHANGELOG.md | 记录本次变更 | P1 |

### 无需更新的文档

- [ ] 本次变更不影响用户项目的 dev-playbooks/ 目录（这些是 DevBooks 工具自身的模板）

### 文档更新检查清单

- [x] 新增 skill 文档已完整
- [x] 共享方法论文档已迁移
- [x] AI 行为规范已更新
- [x] 集成调用文档已更新
- [x] README 和 CHANGELOG 已更新

## Architecture Impact（架构影响）

### 有架构变更

#### C4 层级影响

| 层级 | 变更类型 | 影响描述 |
|------|----------|----------|
| Context | 无变更 | 不涉及外部系统 |
| Container | 无变更 | 不涉及新容器 |
| Component | 修改 + 新增 | 改名 + 新增组件 |

#### Component 变更详情

- **[改名]** `devbooks-docs-sync` → `devbooks-docs-consistency`：文档一致性检查组件
- **[新增]** `RulesEngine`：规则引擎组件
- **[新增]** `Scanner`：扫描器组件（增量/全量）
- **[新增]** `CompletenessChecker`：完备性检查器组件
- **[新增]** `DocClassifier`：文档分类器组件
- **[新增]** `StyleChecker`：风格检查器组件

#### 依赖变更

| 源 | 目标 | 变更类型 | 说明 |
|----|------|----------|------|
| `devbooks-archiver` | `devbooks-docs-consistency` | 修改 | 调用改名后的 skill |
| `devbooks-brownfield-bootstrap` | `devbooks-docs-consistency` | 新增 | 初始化时生成元数据 |
| `devbooks-docs-consistency` | `Git` | 新增 | 增量扫描依赖 git |
| `devbooks-docs-consistency` | `MCP` | 删除 | 删除 MCP 增强功能 |

#### 分层约束影响

- [x] 本次变更遵守现有分层约束
- [ ] 本次变更需要修改分层约束

**说明**：
- 依赖方向正确：其他 skills → docs-consistency → git/文件系统
- 无循环依赖
- 职责单一，边界清晰

---

**设计文档完成**

**下一步推荐**：
- 运行 `devbooks-spec-contract` skill 处理变更 `20260122-0827-enhance-docs-consistency`（如果有外部行为/契约变更）
- 或运行 `devbooks-implementation-plan` skill 处理变更 `20260122-0827-enhance-docs-consistency`（如果无外部契约变更）

