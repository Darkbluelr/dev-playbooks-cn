# Spec Delta: config-discovery (complete-devbooks-independence)

> 产物落点：`dev-playbooks/changes/complete-devbooks-independence/specs/config-discovery/spec.md`
>
> 状态：**Merged**（已合并到真理源 `dev-playbooks/specs/config-protocol/spec.md`）
> Owner：Spec Owner
> last_verified：2026-01-12
> merged_by：Spec Gardener
> merge_date：2026-01-12
> merge_note：合并到 config-protocol/spec.md（REQ-CFG-005、REQ-CFG-006）

---

## MODIFIED Requirements

### Requirement: REQ-CFG-001 配置发现优先级（修改）

系统 SHALL 按以下顺序查找配置（找到后停止）：

1. `.devbooks/config.yaml`（如存在）
2. `project.md`（如存在）
3. 若仍无法确定 → 停止并询问用户

**变更说明**：移除原有的 `openspec/project.md` 特殊处理。

**Trace**: AC-019

---

### Requirement: REQ-CFG-002 配置文件 Schema

`.devbooks/config.yaml` 文件 SHALL 遵循以下 schema：

**必填字段**：
| 字段 | 类型 | 说明 |
|------|------|------|
| `root` | string | DevBooks 管理目录 |
| `constitution` | string | 宪法文件相对路径 |
| `project` | string | 项目上下文相对路径 |

**路径配置**（必填）：
| 字段 | 类型 | 说明 |
|------|------|------|
| `paths.specs` | string | 真理源目录 |
| `paths.changes` | string | 变更包目录 |

**可选字段**：
| 字段 | 类型 | 说明 |
|------|------|------|
| `paths.scripts` | string | 脚本目录 |
| `paths.staged` | string | 暂存目录 |

**Trace**: AC-013, AC-019

---

### Requirement: REQ-CFG-003 向后兼容别名（过渡期）

系统 SHOULD 在 3 个版本周期内支持以下别名映射：
- `truth_root` → `paths.specs`
- `change_root` → `paths.changes`

系统 SHALL 在检测到使用别名时输出弃用警告。

**Trace**: AC-019

---

## REMOVED Requirements

### Requirement: REQ-CFG-R01 移除 OpenSpec 协议检测

系统 SHALL 移除以下配置发现逻辑：
- 检测 `openspec/project.md` 并使用 OpenSpec 默认映射
- 处理 `protocol: openspec` 配置字段

**Trace**: AC-001, AC-019

---

## Scenarios

### Scenario: SC-CFG-001 标准配置发现

- **GIVEN** 项目根目录存在 `.devbooks/config.yaml`
- **WHEN** 任意 Skill 执行配置发现
- **THEN** 系统解析 `.devbooks/config.yaml`
- **AND** 系统返回配置中的 `root`、`paths.specs`、`paths.changes` 值

**Trace**: AC-019

---

### Scenario: SC-CFG-002 配置文件缺失

- **GIVEN** 项目根目录不存在 `.devbooks/config.yaml`
- **AND** 不存在 `project.md`
- **WHEN** Skill 执行配置发现
- **THEN** 系统停止并提示用户运行 `npx create-devbooks` 初始化

**Trace**: AC-019

---

### Scenario: SC-CFG-003 使用弃用别名

- **GIVEN** `.devbooks/config.yaml` 使用 `truth_root` 而非 `paths.specs`
- **WHEN** Skill 执行配置发现
- **THEN** 系统正常解析并返回配置
- **AND** 系统输出弃用警告：建议迁移到 `paths.specs`

**Trace**: AC-019

---

### Scenario: SC-CFG-004 所有 Skills 统一配置发现

- **GIVEN** 21 个 DevBooks Skills
- **WHEN** 检查每个 Skill 的配置发现逻辑
- **THEN** 所有 Skills 均通过 `config-discovery.sh` 获取配置
- **AND** 无 Skill 包含 OpenSpec 特殊处理逻辑

**Trace**: AC-019, AC-020

---

### Scenario: SC-CFG-005 配置文件无 OpenSpec 引用

- **GIVEN** 任意 `.devbooks/config.yaml` 文件
- **WHEN** 检查文件内容
- **THEN** 文件不包含 `openspec` 或 `OpenSpec` 字符串
- **AND** 文件不包含 `protocol: openspec` 配置

**Trace**: AC-001
