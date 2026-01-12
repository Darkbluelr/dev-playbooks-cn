# Spec: DevBooks 配置协议 v2

> 产物落点：`openspec/changes/evolve-devbooks-architecture/specs/config-protocol/spec.md`
>
> 状态：Draft
> 版本：2.0.0
> 日期：2026-01-11

---

## 1. Requirements（需求）

### REQ-CFG-001: 集中式配置目录

**描述**：DevBooks 配置和管理内容必须集中在单一目录（`dev-playbooks/`），不污染项目根目录。

**验收条件**：
- 所有 DevBooks 管理的文件位于 `dev-playbooks/` 目录下
- 项目根目录只有 `.devbooks/config.yaml` 指向管理目录

---

### REQ-CFG-002: 配置文件格式

**描述**：`.devbooks/config.yaml` 采用新格式，支持更丰富的配置项。

**配置格式**：
```yaml
# .devbooks/config.yaml (v2)

root: dev-playbooks/              # 管理目录根（必需）
constitution: constitution.md     # 宪法文件（相对于 root）
project: project.md               # 项目上下文

paths:
  specs: specs/                   # 真理源目录
  changes: changes/               # 变更包目录
  scripts: scripts/               # 项目级脚本

constraints:
  role_isolation: true            # 角色隔离（默认 true）
  coder_no_tests: true            # Coder 禁止改测试（默认 true）
  require_constitution: true      # 强制宪法（默认 true）

fitness:
  enabled: true                   # 启用适应度检查
  mode: warn                      # warn | error
  rules_file: specs/architecture/fitness-rules.md

tracing:
  ac_required: true               # AC 追溯必需
  coverage_threshold: 80          # 覆盖率阈值（0-100）

conflict:
  human_timeout: 24h              # 人工裁决超时
  escalation_timeout: 48h         # 升级超时
```

**验收条件**：
- `config-discovery.sh` 能正确解析新格式
- 所有配置项有合理默认值

---

### REQ-CFG-003: 向后兼容

**描述**：保留对旧配置格式（v1）的兼容，持续 3 个版本。

**旧格式**：
```yaml
# .devbooks/config.yaml (v1)
truth_root: openspec/
```

**兼容策略**：
- 检测到旧格式时自动适配
- 输出警告建议迁移
- 旧格式在 v2.3.0 后废弃

**验收条件**：
- 使用旧格式的项目仍能正常运行
- 日志中输出迁移警告

---

### REQ-CFG-004: 宪法强制加载

**描述**：当 `require_constitution: true` 时，所有 Skills 执行前必须加载宪法。

**加载机制**：
1. `config-discovery.sh` 在配置解析后、返回结果前加载宪法
2. 宪法内容作为上下文的一部分返回
3. 若宪法缺失且强制要求，返回错误

**验收条件**：
- 宪法内容出现在 Skill 执行上下文中
- 宪法缺失时返回退出码 1

---

### REQ-CFG-005: 路径解析优先级

**描述**：配置发现按以下优先级解析管理目录：

1. `.devbooks/config.yaml` 中的 `root` 配置
2. `dev-playbooks/` 目录（如存在）
3. `openspec/` 目录（兼容期）

**验收条件**：
- 优先使用显式配置
- 自动检测遵循优先级

---

## 2. Scenarios（场景）

### SC-CFG-001: 新项目初始化

**Given**：一个不含 DevBooks 配置的项目
**When**：执行 `devbooks-brownfield-bootstrap`
**Then**：
- 创建 `dev-playbooks/` 目录结构
- 创建 `.devbooks/config.yaml`
- 创建 `constitution.md` 模板

---

### SC-CFG-002: 旧项目迁移

**Given**：一个使用 `openspec/` 结构的项目
**When**：执行 `migrate-to-devbooks-2.sh`
**Then**：
- `openspec/` 内容迁移到 `dev-playbooks/`
- `openspec/project.md` 拆分为 `constitution.md` + `project.md`
- 所有路径引用更新
- 旧目录可选删除

---

### SC-CFG-003: 配置发现（新格式）

**Given**：项目包含新格式 `.devbooks/config.yaml`
**When**：执行任意 Skill
**Then**：
- `config-discovery.sh` 解析配置
- 返回正确的路径变量
- 宪法内容被加载（如配置要求）

---

### SC-CFG-004: 配置发现（旧格式兼容）

**Given**：项目包含旧格式配置（`truth_root: openspec/`）
**When**：执行任意 Skill
**Then**：
- 配置正确解析
- 输出迁移警告
- Skill 正常执行

---

### SC-CFG-005: 宪法缺失处理

**Given**：`require_constitution: true` 但 `constitution.md` 不存在
**When**：执行任意 Skill
**Then**：
- 返回错误信息："宪法文件缺失"
- 退出码 1
- Skill 不执行

---

### SC-CFG-006: 宪法可选

**Given**：`require_constitution: false` 且 `constitution.md` 不存在
**When**：执行任意 Skill
**Then**：
- 无警告
- Skill 正常执行

---

## 3. API 变更

### 3.1 config-discovery.sh 输出格式

**旧输出**：
```bash
TRUTH_ROOT=openspec
```

**新输出**：
```bash
CONFIG_VERSION=2
ROOT=dev-playbooks
CONSTITUTION_LOADED=true
SPECS_DIR=dev-playbooks/specs
CHANGES_DIR=dev-playbooks/changes
SCRIPTS_DIR=dev-playbooks/scripts
REQUIRE_CONSTITUTION=true
FITNESS_ENABLED=true
FITNESS_MODE=warn
AC_COVERAGE_THRESHOLD=80
```

### 3.2 环境变量

| 变量 | 描述 | 默认值 |
|------|------|--------|
| `DEVBOOKS_ROOT` | 管理目录根 | `dev-playbooks/` |
| `DEVBOOKS_REQUIRE_CONSTITUTION` | 是否强制宪法 | `true` |
| `DEVBOOKS_FITNESS_MODE` | 适应度模式 | `warn` |

---

## 4. Contract Tests

| ID | 场景 | 断言 |
|----|------|------|
| CT-CFG-001 | 新配置格式解析 | 所有字段正确解析 |
| CT-CFG-002 | 旧配置格式兼容 | 返回正确路径 + 警告 |
| CT-CFG-003 | 宪法强制加载 | 宪法内容在输出中 |
| CT-CFG-004 | 宪法缺失错误 | 退出码 1，错误信息清晰 |
| CT-CFG-005 | 路径优先级 | 按优先级返回正确路径 |
| CT-CFG-006 | 默认值填充 | 缺失配置项使用默认值 |

---

## 5. 迁移指南

### 5.1 自动迁移

```bash
# 执行迁移脚本
./migrate-to-devbooks-2.sh --project-root "$(pwd)"

# 验证迁移结果
./constitution-check.sh
./change-check.sh <change-id> --mode strict
```

### 5.2 手动迁移步骤

1. 创建 `dev-playbooks/` 目录结构
2. 移动 `openspec/specs/` → `dev-playbooks/specs/`
3. 移动 `openspec/changes/` → `dev-playbooks/changes/`
4. 拆分 `openspec/project.md` → `constitution.md` + `project.md`
5. 更新 `.devbooks/config.yaml` 为新格式
6. 搜索替换所有 `openspec/` 引用
7. 删除 `openspec/` 目录（可选）

---

**Spec 完成**
