# Spec: DevBooks 脚本契约

---
owner: Spec Gardener
last_verified: 2026-01-11
status: Active
freshness_check: 3 Months
source_change: evolve-devbooks-architecture
---

## 1. Requirements（需求）

### REQ-SCR-001: 退出码契约

**描述**：所有 DevBooks 脚本必须遵守统一的退出码契约。

**退出码定义**：
| 退出码 | 含义 | 示例 |
|--------|------|------|
| 0 | 成功 | 检查通过、操作完成 |
| 1 | 检查失败（可预期） | 宪法违规、覆盖率不达标 |
| 2 | 用法错误 | 参数缺失、参数无效 |

**验收条件**：
- 所有新增脚本遵守此契约
- 现有脚本逐步适配

---

### REQ-SCR-002: 帮助文档

**描述**：所有脚本必须支持 `--help` 参数，输出用法说明。

**帮助文档格式**：
```
Usage: <script-name> [OPTIONS] <ARGS>

Description:
  <one-line description>

Arguments:
  <arg-name>    <description>

Options:
  -h, --help    Show this help message
  --mode MODE   <description>

Examples:
  <script-name> --mode strict my-change
```

**验收条件**：
- `<script> --help` 输出用法
- 退出码为 0

---

### REQ-SCR-003: 错误信息格式

**描述**：脚本错误信息必须清晰、可操作。

**格式规范**：
```
ERROR: <简短描述>
  Location: <文件:行号>（如适用）
  Expected: <预期行为>
  Actual: <实际行为>
  Fix: <修复建议>
```

**验收条件**：
- 错误信息输出到 stderr
- 包含修复建议

---

## 2. 脚本规格

### 2.1 constitution-check.sh

**职责**：检查宪法文件是否存在且格式正确。

**接口**：
```bash
constitution-check.sh [OPTIONS] [PROJECT_ROOT]

Options:
  -h, --help      显示帮助
  --strict        严格模式（缺少可选章节也报错）

Arguments:
  PROJECT_ROOT    项目根目录（默认当前目录）
```

**输出**：
- 成功：`OK: constitution.md 检查通过`
- 失败：`FAIL: <具体原因>`

**检查项**：
| 检查项 | 严格模式 | 宽松模式 |
|--------|----------|----------|
| 文件存在 | 必需 | 必需 |
| Part Zero 章节 | 必需 | 必需 |
| GIP-xxx 规则 | 必需 | 必需 |
| 逃生舱口章节 | 必需 | 可选 |

---

### 2.2 ac-trace-check.sh

**职责**：检查 AC-ID 从设计到测试的追溯覆盖率。

**接口**：
```bash
ac-trace-check.sh [OPTIONS] <CHANGE_ID>

Options:
  -h, --help              显示帮助
  --threshold PERCENT     覆盖率阈值（默认 80）
  --output FORMAT         输出格式：text | json（默认 text）

Arguments:
  CHANGE_ID               变更包 ID
```

**退出码**：
- 0：覆盖率 >= 阈值
- 1：覆盖率 < 阈值

---

### 2.3 fitness-check.sh

**职责**：执行架构适应度函数检查。

**接口**：
```bash
fitness-check.sh [OPTIONS] [PROJECT_ROOT]

Options:
  -h, --help              显示帮助
  --rules FILE            规则文件（默认 specs/architecture/fitness-rules.md）
  --mode MODE             warn | error（默认 warn）
  --format FORMAT         输出格式：text | json

Arguments:
  PROJECT_ROOT            项目根目录
```

**退出码**：
- 0：所有规则通过（或 mode=warn）
- 1：有规则失败且 mode=error

---

### 2.4 spec-preview.sh

**职责**：预检 spec delta 与现有暂存的冲突。

**接口**：
```bash
spec-preview.sh [OPTIONS] <CHANGE_ID>

Options:
  -h, --help              显示帮助
  --staged-dir DIR        暂存目录

Arguments:
  CHANGE_ID               变更包 ID
```

**退出码**：
- 0：无冲突
- 1：有冲突

---

### 2.5 spec-stage.sh

**职责**：将变更包的 spec delta 同步到暂存层。

**接口**：
```bash
spec-stage.sh [OPTIONS] <CHANGE_ID>

Options:
  -h, --help              显示帮助
  --force                 强制覆盖冲突
  --dry-run               仅预览，不执行

Arguments:
  CHANGE_ID               变更包 ID
```

**退出码**：
- 0：暂存成功
- 1：有冲突且未使用 --force

---

### 2.6 spec-promote.sh

**职责**：将暂存层的 spec delta 提升到真理层。

**接口**：
```bash
spec-promote.sh [OPTIONS] <CHANGE_ID>

Options:
  -h, --help              显示帮助
  --dry-run               仅预览，不执行

Arguments:
  CHANGE_ID               变更包 ID
```

**前置条件**：
- 变更包已通过 `spec-stage`
- 所有测试已 Green

**退出码**：
- 0：提升成功
- 1：前置条件不满足

---

### 2.7 spec-rollback.sh

**职责**：回滚 spec 变更。

**接口**：
```bash
spec-rollback.sh [OPTIONS] <CHANGE_ID> <TARGET>

Options:
  -h, --help              显示帮助
  --dry-run               仅预览，不执行

Arguments:
  CHANGE_ID               变更包 ID
  TARGET                  回滚目标：staged | draft
```

---

### 2.8 migrate-to-devbooks-2.sh

**职责**：将现有项目从 dev-playbooks/ 迁移到 dev-playbooks/。

**接口**：
```bash
migrate-to-devbooks-2.sh [OPTIONS]

Options:
  -h, --help              显示帮助
  --project-root DIR      项目根目录（默认当前目录）
  --dry-run               仅预览，不执行
  --keep-old              保留旧目录（不删除 dev-playbooks/）
  --force                 强制覆盖已存在的 dev-playbooks/
```

**幂等性**：支持重复执行，通过状态检查点实现。

---

## 3. Contract Tests

| ID | 脚本 | 场景 | 断言 |
|----|------|------|------|
| CT-SCR-001 | constitution-check.sh | 宪法存在且完整 | 退出码 0 |
| CT-SCR-002 | constitution-check.sh | 宪法缺失 | 退出码 1，错误信息清晰 |
| CT-SCR-003 | constitution-check.sh | --help | 输出用法，退出码 0 |
| CT-SCR-004 | ac-trace-check.sh | 覆盖率达标 | 退出码 0 |
| CT-SCR-005 | ac-trace-check.sh | 覆盖率不达标 | 退出码 1，列出未覆盖 AC |
| CT-SCR-006 | fitness-check.sh | 所有规则通过 | 退出码 0 |
| CT-SCR-007 | fitness-check.sh | 有规则失败 + mode=error | 退出码 1 |
| CT-SCR-008 | fitness-check.sh | 有规则失败 + mode=warn | 退出码 0，输出警告 |
| CT-SCR-009 | spec-preview.sh | 无冲突 | 退出码 0 |
| CT-SCR-010 | spec-preview.sh | 有冲突 | 退出码 1，冲突详情 |
| CT-SCR-011 | spec-stage.sh | 正常暂存 | 退出码 0，文件复制到 _staged/ |
| CT-SCR-012 | spec-stage.sh | 有冲突不 force | 退出码 1 |
| CT-SCR-013 | spec-promote.sh | 前置条件满足 | 退出码 0，文件移动到 specs/ |
| CT-SCR-014 | spec-promote.sh | 未先 stage | 退出码 1 |
| CT-SCR-015 | spec-rollback.sh | 回滚到 draft | 退出码 0，清理暂存和真理层 |
| CT-SCR-016 | migrate-to-devbooks-2.sh | 完整迁移 | 退出码 0，结构正确 |
| CT-SCR-017 | migrate-to-devbooks-2.sh | 幂等执行 | 重复执行无副作用 |
| CT-SCR-018 | migrate-to-devbooks-2.sh | --dry-run | 无文件变更 |
