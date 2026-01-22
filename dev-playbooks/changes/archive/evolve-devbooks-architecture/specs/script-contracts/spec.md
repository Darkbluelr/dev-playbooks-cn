# Spec: DevBooks 脚本契约

> 产物落点：`openspec/changes/evolve-devbooks-architecture/specs/script-contracts/spec.md`
>
> 状态：Draft
> 版本：2.0.0
> 日期：2026-01-11

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

**输出**：
```
AC 追溯覆盖率: 85% (17/20)

已覆盖:
  AC-E01: design.md → tasks.md → test-dir-structure.bats
  AC-E02: design.md → tasks.md → test-constitution.bats
  ...

未覆盖:
  AC-E05: design.md → tasks.md → (无测试)

结论: OK (85% >= 80%)
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

**输出**：
```
适应度检查结果:

[PASS] FR-001: 分层架构检查
[FAIL] FR-002: 禁止循环依赖
  - src/serviceA.ts → src/serviceB.ts → src/serviceA.ts
[PASS] FR-003: 敏感文件守护

结论: FAIL (1/3 rules violated)
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

**输出**：
```
冲突预检: evolve-devbooks-architecture

检测到 1 个潜在冲突:

[CONFLICT] 文件级冲突
  文件: specs/config-protocol/spec.md
  已暂存: other-change-123
  当前: evolve-devbooks-architecture
  建议: 协调两个变更的合并顺序

无冲突文件:
  specs/script-contracts/spec.md

结论: 需要人工协调
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

**输出**：
```
暂存同步: evolve-devbooks-architecture

已暂存:
  specs/config-protocol/spec.md → _staged/evolve-devbooks-architecture/config-protocol/spec.md
  specs/script-contracts/spec.md → _staged/evolve-devbooks-architecture/script-contracts/spec.md

状态: 暂存完成
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

**输出**：
```
提升到真理层: evolve-devbooks-architecture

前置检查:
  [OK] 已暂存
  [OK] 测试 Green

已提升:
  _staged/evolve-devbooks-architecture/config-protocol/spec.md → specs/config-protocol/spec.md
  _staged/evolve-devbooks-architecture/script-contracts/spec.md → specs/script-contracts/spec.md

清理暂存:
  已删除 _staged/evolve-devbooks-architecture/

状态: 提升完成
```

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

**输出**：
```
回滚: evolve-devbooks-architecture → draft

已回滚:
  specs/config-protocol/spec.md → 已删除
  specs/script-contracts/spec.md → 已删除
  _staged/evolve-devbooks-architecture/ → 已删除

状态: 回滚完成（spec delta 保留在变更包中）
```

---

### 2.8 migrate-to-devbooks-2.sh

**职责**：将现有项目从 openspec/ 迁移到 dev-playbooks/。

**接口**：
```bash
migrate-to-devbooks-2.sh [OPTIONS]

Options:
  -h, --help              显示帮助
  --project-root DIR      项目根目录（默认当前目录）
  --dry-run               仅预览，不执行
  --keep-old              保留旧目录（不删除 openspec/）
  --force                 强制覆盖已存在的 dev-playbooks/
```

**幂等性**：支持重复执行，通过状态检查点实现。

**状态检查点**：
| 状态码 | 描述 |
|--------|------|
| 0 | 未开始 |
| 1 | 目录已创建 |
| 2 | 内容已迁移 |
| 3 | 引用已更新 |
| 4 | 已完成 |

**输出**：
```
迁移状态: 内容已迁移 (2/4)

继续迁移...

[STEP 3] 更新引用
  已更新 57 个文件中的路径引用

[STEP 4] 完成
  迁移完成，耗时 45 秒

验证:
  [OK] dev-playbooks/ 存在
  [OK] constitution.md 存在
  [OK] config.yaml 格式正确

下一步:
  1. 执行 ./constitution-check.sh 验证宪法
  2. 执行 ./change-check.sh <id> --mode strict 验证变更包
  3. 可选：删除 openspec/ 目录
```

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

---

**Spec 完成**
