# Design: evolve-devbooks-architecture

> 产物落点：`openspec/changes/evolve-devbooks-architecture/design.md`
>
> 状态：**Ready**（已完成 Design Backport）
> 日期：2026-01-11
> 更新：2026-01-11（回写断点策略 BP-1/BP-2/BP-3）
> 依赖：proposal.md（已 Approved）

---

## 1. What（设计范围）

### 1.1 核心交付物

本设计实现 **DevBooks 架构演进**，将 OpenSpec 核心能力整合到 DevBooks，实现：

1. **目录结构重构**：`openspec/` → `dev-playbooks/` 集中式管理
2. **宪法优先机制**：每个 Skill 执行前强制加载 `constitution.md`
3. **架构适应度函数**：声明式规则检查 + 自动化验证
4. **AC-ID 全程追溯**：设计 → 任务 → 测试 → 证据的完整追溯链
5. **三层同步模型**：Draft → Staged → Truth 实时架构反馈
6. **反模式库**：常见反模式的知识库与自动检测

### 1.2 模块清单

| 模块 | 类型 | 职责 | 优先级 |
|------|------|------|--------|
| `dev-playbooks/` 目录结构 | 结构 | 集中式管理目录 | P0 |
| `constitution.md` | 文档 | 项目宪法（不可违背原则） | P0 |
| `config.yaml` | 配置 | 新格式配置文件 | P0 |
| `constitution-check.sh` | 脚本 | 宪法合规检查 | P0 |
| `ac-trace-check.sh` | 脚本 | AC-ID 追溯覆盖率检查 | P0 |
| `fitness-check.sh` | 脚本 | 架构适应度检查 | P1 |
| `fitness-rules.md` | 文档 | 适应度规则定义 | P1 |
| `spec-preview.sh` | 脚本 | 冲突预检 | P1 |
| `spec-stage.sh` | 脚本 | 暂存同步 | P1 |
| `spec-promote.sh` | 脚本 | 提升到真理层 | P1 |
| `spec-rollback.sh` | 脚本 | 回滚 | P2 |
| `migrate-to-devbooks-2.sh` | 脚本 | 现有项目迁移 | P1 |
| `anti-patterns/` | 目录 | 反模式库 | P2 |

---

## 2. Constraints（约束与边界）

### 2.1 人类明确要求（不可违背）

1. **自包含原则**：设计内容必须完整自包含，禁止"引用自XXX"表述
2. **不可拆分原则**：所有内容必须作为一个完整变更包实施，禁止拆分

### 2.2 技术约束

#### C-01: 配置发现统一入口

**约束**：所有 Skills 的配置发现必须通过 `config-discovery.sh` 单一入口。

**理由**：
- 符合"最小改动面策略"（proposal §3.6）
- 统一宪法加载逻辑，避免分散硬编码

**实现**：
```bash
# config-discovery.sh 增加宪法加载逻辑
source_constitution() {
  local config_root="$1"
  local constitution="${config_root}/constitution.md"
  [[ -f "$constitution" ]] && cat "$constitution"
}
```

#### C-02: 纯 Bash 实现（无 yq 依赖）

**约束**：配置解析使用纯 Bash 实现，不依赖 yq。

**理由**：
- 减少外部依赖，提高可移植性
- proposal 中 D-01 要求明确 yq 依赖或改用纯 bash

**实现**：使用 `grep`/`sed`/`awk` 解析 YAML 子集：
```bash
# 读取简单键值对
get_yaml_value() {
  local file="$1" key="$2"
  grep "^${key}:" "$file" | sed 's/^[^:]*: *//' | tr -d '"'"'"
}
```

#### C-03: 向后兼容

**约束**：保留旧路径（`openspec/`）3 个版本的兼容期。

**实现**：
```bash
# config-discovery.sh 路径映射逻辑
resolve_truth_root() {
  # 优先检查新路径
  [[ -d "dev-playbooks" ]] && echo "dev-playbooks" && return
  # 回退到旧路径（兼容期）
  [[ -d "openspec" ]] && echo "openspec" && return
  echo ""
}
```

#### C-04: 回滚时间约束

**约束**：完整回滚必须在 15 分钟内完成。

**验证**：回滚演练记录到 `evidence/rollback-drill.log`。

### 2.3 架构约束

#### C-05: 角色隔离不变

**约束**：Test Owner 与 Coder 仍必须独立对话，本次变更不改变此约束。

#### C-06: 脚本退出码契约

**约束**：所有新增脚本必须遵守退出码契约：
- `0` = 成功
- `1` = 检查失败（可预期）
- `2` = 用法错误

#### C-07: 脚本帮助文档

**约束**：所有新增脚本必须支持 `--help` 参数，输出用法说明。

---

## 3. Design Rationale（设计决策理由）

### DR-01: 选择 config-discovery.sh 注入宪法（非 SKILL.md 模板）

**决策**：宪法加载在 `config-discovery.sh` 中统一注入，而非修改每个 SKILL.md。

**理由**：
1. **单点控制**：21 个 Skills 只需修改 1 处
2. **强制执行**：宪法不可绕过
3. **零维护**：新 Skill 自动继承

**权衡**：牺牲了 Skill 级别的灵活性，但宪法本就不应被选择性绕过。

### DR-02: 三层同步模型设计

**决策**：采用 Draft → Staged → Truth 三层模型。

**理由**：
1. 解决"真理源更新滞后"问题
2. 并行变更冲突在暂存时暴露
3. 提供"实时架构反馈"

**冲突处理协议**：
- 检测规则：文件级 + 内容级 + 依赖级
- 优先级：先提交者优先 > 按变更类型 > 人工裁决
- 超时：冲突检测 30s，人工裁决 24h，升级 48h

### DR-03: AC 覆盖率阈值可配置

**决策**：`coverage_threshold` 默认 80%，项目级可覆盖。

**理由**：
1. DORA 报告：高绩效团队通常 80%+ 覆盖率
2. 行业惯例：Google/Microsoft 采用 80% 作为健康门槛
3. 渐进采纳：新项目可从 60% 起步

---

## 4. Architecture（架构设计）

### 4.1 新目录结构

```
project-root/
├── dev-playbooks/                    # DevBooks 管理目录（集中式）
│   ├── constitution.md               # 项目宪法（不可违背原则）
│   ├── project.md                    # 项目上下文（技术栈、约定）
│   │
│   ├── specs/                        # 真理源
│   │   ├── _meta/
│   │   │   ├── project-profile.md
│   │   │   ├── glossary.md
│   │   │   └── anti-patterns/        # 反模式库
│   │   │       ├── AP-001-direct-db-in-controller.md
│   │   │       ├── AP-002-god-class.md
│   │   │       └── AP-003-circular-dependency.md
│   │   ├── _staged/                  # 暂存层（实时同步）
│   │   │   └── [change-id]/
│   │   ├── architecture/
│   │   │   ├── c4.md
│   │   │   └── fitness-rules.md
│   │   └── [capability]/
│   │       └── spec.md
│   │
│   ├── changes/                      # 变更包
│   │   ├── [change-id]/
│   │   │   ├── proposal.md
│   │   │   ├── design.md
│   │   │   ├── tasks.md
│   │   │   ├── verification.md
│   │   │   ├── specs/                # Spec Delta
│   │   │   └── evidence/
│   │   └── archive/
│   │
│   └── scripts/                      # 项目级脚本（可选覆盖）
│       └── fitness-check.sh
│
├── .devbooks/
│   └── config.yaml                   # 配置文件
│
└── [项目代码目录]
```

### 4.2 配置发现流程

```
Skill 启动
    │
    ▼
config-discovery.sh
    │
    ├─► 解析 .devbooks/config.yaml
    │       │
    │       ├─► 定位 truth_root（dev-playbooks/ 或 openspec/）
    │       ├─► 加载 constitution.md（强制）
    │       └─► 返回路径配置
    │
    ▼
Skill 执行
```

### 4.3 三层同步流程

```
┌─────────────────────────────────────────────────────────────┐
│                    三层同步模型                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   Draft (changes/)                                          │
│      │                                                      │
│      │ spec-preview（冲突预检）                             │
│      ▼                                                      │
│   Staged (_staged/)  ◄─── spec-stage（Red 基线后）          │
│      │                                                      │
│      │ spec-promote（Green 后）                             │
│      ▼                                                      │
│   Truth (specs/)                                            │
│                                                             │
│   spec-rollback ───► 回滚到任意层                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 4.4 宪法加载机制

```bash
# config-discovery.sh 伪代码

load_constitution() {
  local config_root="$1"
  local constitution_file="${config_root}/constitution.md"

  if [[ -f "$constitution_file" ]]; then
    echo "## 项目宪法（强制加载）"
    cat "$constitution_file"
    echo ""
    return 0
  else
    local require_constitution
    require_constitution=$(get_yaml_value ".devbooks/config.yaml" "require_constitution")

    if [[ "$require_constitution" == "true" ]]; then
      echo "ERROR: 宪法文件缺失：$constitution_file" >&2
      return 1
    fi
    return 0
  fi
}

discover_config() {
  local truth_root
  truth_root=$(resolve_truth_root)

  # 强制加载宪法
  load_constitution "$truth_root" || return 1

  # 返回配置
  echo "TRUTH_ROOT=$truth_root"
  echo "SPECS_DIR=${truth_root}/specs"
  echo "CHANGES_DIR=${truth_root}/changes"
}
```

---

## 5. Component Design（组件设计）

### 5.1 constitution-check.sh

**职责**：检查宪法文件是否存在且格式正确。

**输入**：项目根目录

**输出**：
- 退出码 0 = 宪法存在且有效
- 退出码 1 = 宪法缺失或无效

**检查项**：
1. `constitution.md` 文件存在
2. 包含 "Part Zero" 章节
3. 包含 "GIP-" 前缀的规则
4. 包含 "逃生舱口" 章节

```bash
#!/bin/bash
# constitution-check.sh

check_constitution() {
  local root="${1:-.}"
  local config_root
  config_root=$(resolve_truth_root "$root")
  local constitution="${config_root}/constitution.md"

  [[ -f "$constitution" ]] || { echo "FAIL: constitution.md 不存在"; return 1; }

  grep -q "## Part Zero" "$constitution" || { echo "FAIL: 缺少 Part Zero"; return 1; }
  grep -q "^### GIP-" "$constitution" || { echo "FAIL: 缺少 GIP 规则"; return 1; }
  grep -q "## 逃生舱口" "$constitution" || { echo "FAIL: 缺少逃生舱口"; return 1; }

  echo "OK: constitution.md 检查通过"
  return 0
}
```

### 5.2 ac-trace-check.sh

**职责**：检查 AC-ID 从设计到测试的追溯覆盖率。

**输入**：change-id

**输出**：
- 覆盖率百分比
- 未覆盖的 AC 列表
- 退出码（基于阈值）

**算法**：
```
1. 从 design.md 提取所有 AC-xxx
2. 从 tasks.md 提取任务中引用的 AC-xxx
3. 从 tests/ 提取测试标记的 AC-xxx
4. 计算：覆盖率 = (已追溯 AC 数) / (总 AC 数) × 100%
5. 对比阈值，返回退出码
```

```bash
#!/bin/bash
# ac-trace-check.sh

extract_ac_ids() {
  local file="$1"
  grep -oE "AC-[A-Z0-9]+" "$file" 2>/dev/null | sort -u
}

check_ac_trace() {
  local change_id="$1"
  local threshold="${2:-80}"
  local change_dir
  change_dir=$(resolve_change_dir "$change_id")

  local design_acs tasks_acs test_acs
  design_acs=$(extract_ac_ids "${change_dir}/design.md")
  tasks_acs=$(extract_ac_ids "${change_dir}/tasks.md")
  test_acs=$(find tests/ -name "*.test.*" -exec grep -ohE "AC-[A-Z0-9]+" {} \; 2>/dev/null | sort -u)

  local total covered
  total=$(echo "$design_acs" | wc -l)
  covered=$(echo "$design_acs" | while read ac; do
    echo "$test_acs" | grep -q "^${ac}$" && echo "$ac"
  done | wc -l)

  local coverage
  coverage=$((covered * 100 / total))

  echo "AC 追溯覆盖率: ${coverage}% (${covered}/${total})"

  if [[ $coverage -lt $threshold ]]; then
    echo "FAIL: 覆盖率 ${coverage}% 低于阈值 ${threshold}%"
    return 1
  fi

  echo "OK: 覆盖率达标"
  return 0
}
```

### 5.3 fitness-check.sh

**职责**：执行架构适应度函数检查。

**输入**：项目根目录、规则文件路径

**输出**：
- 规则检查结果
- 违规详情

**支持的规则类型**：
- `FR-xxx-layered-arch`：分层架构检查
- `FR-xxx-no-cycle`：循环依赖检查
- `FR-xxx-sensitive-file`：敏感文件守护

```bash
#!/bin/bash
# fitness-check.sh

check_layered_arch() {
  # 检查 Controller 是否直接调用 Repository
  local violations
  violations=$(grep -rn "Repository\." src/controllers/ 2>/dev/null || true)

  if [[ -n "$violations" ]]; then
    echo "FAIL: 分层架构违规"
    echo "$violations"
    return 1
  fi
  return 0
}

check_no_cycle() {
  # 使用依赖分析工具检查循环
  # 具体实现依赖于项目技术栈
  return 0
}
```

### 5.4 spec-stage.sh

**职责**：将变更包的 spec delta 同步到暂存层。

**输入**：change-id

**输出**：
- 暂存成功/失败
- 冲突报告（如有）

**冲突检测算法**：
```
1. 读取 _staged/ 目录现有变更包列表
2. 对当前变更包的每个 spec delta 文件：
   a. 检查 _staged/ 中是否有相同目标文件
   b. 若有，标记为"文件级冲突"
3. 检测内容级冲突（同一 REQ-xxx 被修改）
4. 输出冲突报告
```

**冲突解决优先级**：
1. 先提交者优先（默认）
2. 按变更类型（安全 > Bug > 功能 > 重构）
3. 人工裁决

### 5.5 migrate-to-devbooks-2.sh

**职责**：将现有项目从 openspec/ 迁移到 dev-playbooks/。

**幂等性**：支持重复执行，通过状态检查点实现。

**状态检查点**：
- STATE_NOT_STARTED = 0
- STATE_DIRS_CREATED = 1
- STATE_CONTENT_MIGRATED = 2
- STATE_REFS_UPDATED = 3
- STATE_COMPLETED = 4

---

## 6. Skills 修改清单

### 6.1 统一修改（21 个 Skills）

所有 Skills 需要：
1. 支持新路径 `dev-playbooks/`
2. 自动加载 `constitution.md`

**实现方式**：修改 `config-discovery.sh`，所有 Skills 自动继承。

### 6.2 特定修改

| Skill | 额外修改 |
|-------|----------|
| `devbooks-delivery-workflow` | change-check.sh 增加宪法/适应度检查 |
| `devbooks-router` | 路由逻辑支持新目录结构 |
| `devbooks-spec-gardener` | 支持三层同步的合并逻辑 |

---

## 7. Acceptance Criteria（验收标准）

### AC-E01: 目录结构符合设计

**验收条件**：`dev-playbooks/` 目录结构符合 §4.1 设计。

**验证方式**：
```bash
./scripts/verify-dir-structure.sh dev-playbooks/
```

**证据落点**：`evidence/dir-structure.txt`

---

### AC-E02: 宪法被所有 Skills 加载

**验收条件**：执行任意 Skill 时，`constitution.md` 内容出现在上下文中。

**验证方式**：
1. 代码审查：`config-discovery.sh` 包含 `load_constitution` 调用
2. 集成测试：执行 Skill 并检查输出

**证据落点**：`evidence/skill-constitution-test.log`

---

### AC-E03: change-check.sh 包含宪法检查

**验收条件**：`change-check.sh --mode strict` 执行宪法合规检查。

**验证方式**：
```bash
./change-check.sh evolve-devbooks-architecture --mode strict 2>&1 | grep -q "constitution"
```

**证据落点**：`evidence/change-check-test.log`

---

### AC-E04: fitness-check.sh 能检测架构违规

**验收条件**：故意违反分层架构时，脚本返回非零退出码。

**验证方式**：
```bash
# 创建违规代码
echo 'Repository.find()' > /tmp/test-controller.js
./fitness-check.sh --file /tmp/test-controller.js
# 预期退出码 1
```

**证据落点**：`evidence/fitness-check-test.log`

---

### AC-E05: ac-trace-check.sh 能检测 AC 覆盖缺失

**验收条件**：当测试未覆盖某个 AC 时，脚本报告缺失并返回非零退出码（如低于阈值）。

**验证方式**：
```bash
./ac-trace-check.sh evolve-devbooks-architecture --threshold 100
# 预期输出未覆盖的 AC 列表
```

**证据落点**：`evidence/ac-trace-test.log`

---

### AC-E06: 三层同步脚本工作正常

**验收条件**：
- `spec-preview` 能检测冲突
- `spec-stage` 能暂存 spec delta
- `spec-promote` 能提升到真理层
- `spec-rollback` 能回滚

**验证方式**：集成测试

**证据落点**：`evidence/sync-test.log`

---

### AC-E07: openspec/ 目录已删除

**验收条件**：项目根目录不再包含 `openspec/` 目录。

**验证方式**：
```bash
[[ ! -d openspec ]] && echo "OK" || echo "FAIL"
```

**证据落点**：`evidence/openspec-removed.txt`

---

### AC-E08: 迁移脚本可正常工作

**验收条件**：在测试项目上执行 `migrate-to-devbooks-2.sh`，成功完成迁移。

**验证方式**：
1. 创建测试项目（含 openspec/ 结构）
2. 执行迁移脚本
3. 验证 dev-playbooks/ 结构正确

**证据落点**：`evidence/migration-test.log`

---

### AC-E09: 反模式库至少包含 3 个反模式

**验收条件**：`dev-playbooks/specs/_meta/anti-patterns/` 包含至少 3 个 AP-xxx.md 文件。

**验证方式**：
```bash
ls dev-playbooks/specs/_meta/anti-patterns/AP-*.md | wc -l
# 预期 >= 3
```

**证据落点**：`evidence/anti-patterns-count.txt`

---

### AC-E10: 回滚可在 15 分钟内完成

**验收条件**：执行完整回滚（RB-05），耗时 < 15 分钟。

**验证方式**：回滚演练

**证据落点**：`evidence/rollback-drill.log`

---

## 8. C4 Delta（架构变更）

### 8.1 C2 容器级变更

| 变更类型 | 容器 | 说明 |
|----------|------|------|
| **新增** | `dev-playbooks/` | 集中式管理目录，替代 `openspec/` |
| **新增** | `dev-playbooks/specs/_staged/` | 暂存层 |
| **新增** | `dev-playbooks/specs/_meta/anti-patterns/` | 反模式库 |
| **删除** | `openspec/` | 迁移到 `dev-playbooks/` |

### 8.2 C3 组件级变更

| 变更类型 | 组件 | 说明 |
|----------|------|------|
| **新增** | `constitution-check.sh` | 宪法合规检查脚本 |
| **新增** | `ac-trace-check.sh` | AC 追溯覆盖率检查 |
| **新增** | `fitness-check.sh` | 架构适应度检查 |
| **新增** | `spec-preview.sh` | 冲突预检 |
| **新增** | `spec-stage.sh` | 暂存同步 |
| **新增** | `spec-promote.sh` | 提升到真理层 |
| **新增** | `spec-rollback.sh` | 回滚 |
| **新增** | `migrate-to-devbooks-2.sh` | 迁移脚本 |
| **修改** | `config-discovery.sh` | 增加宪法加载逻辑 |
| **修改** | `change-check.sh` | 增加宪法/适应度检查 |

### 8.3 依赖方向变化

```
skills/
    │
    ├──► config-discovery.sh ──► constitution.md（新增）
    │
    ├──► change-check.sh
    │       │
    │       ├──► constitution-check.sh（新增）
    │       ├──► ac-trace-check.sh（新增）
    │       └──► fitness-check.sh（新增）
    │
    └──► spec-*.sh（新增同步脚本）
```

**无反向依赖引入**：新增脚本遵循现有依赖方向约束。

### 8.4 建议的 Architecture Guardrails

#### FT-004: 宪法加载入口唯一性

**规则**：宪法加载只能通过 `config-discovery.sh`，禁止在各 Skill 中分散实现。

**检查命令**：
```bash
# 检查 SKILL.md 文件是否直接引用 constitution.md
rg "constitution\.md" skills/*/SKILL.md && echo "FAIL" || echo "OK"
```

**严重程度**：High

#### FT-005: 三层同步顺序约束

**规则**：`spec-promote` 只能在 `spec-stage` 之后调用。

**检查方式**：脚本内置状态检查

**严重程度**：Critical

---

## 9. Contract（契约变更）

### 9.1 Skills 配置协议变更

**变更类型**：Breaking Change（需迁移）

**旧协议**：
```yaml
# .devbooks/config.yaml
truth_root: openspec/
```

**新协议**：
```yaml
# .devbooks/config.yaml
root: dev-playbooks/
constitution: constitution.md
project: project.md
paths:
  specs: specs/
  changes: changes/
  scripts: scripts/
```

**兼容策略**：
- 保留旧路径 3 个版本
- `config-discovery.sh` 自动检测并适配
- 迁移脚本自动转换

### 9.2 Contract Test IDs

| ID | 契约 | 验证方式 |
|----|------|----------|
| CT-CFG-001 | 新配置格式解析 | BATS 测试 |
| CT-CFG-002 | 旧配置格式兼容 | BATS 测试 |
| CT-CFG-003 | 宪法强制加载 | BATS 测试 |
| CT-SYNC-001 | spec-stage 冲突检测 | BATS 测试 |
| CT-SYNC-002 | spec-promote 状态检查 | BATS 测试 |

---

## 10. D-Items 处理（proposal §8.4.2）

| 编号 | 事项 | 处置 |
|------|------|------|
| D-01 | 明确 yq 依赖或改用纯 bash | ✅ 选择纯 bash（§2.2 C-02） |
| D-02 | fitness-check.sh 性能基准测试 | 延迟到实现阶段验证，目标 <5s |
| D-03 | 在 dev-playbooks 自身执行迁移演练 | 作为 AC-E08 验证项 |
| D-04 | 人工裁决超时可配置 | 写入 config.yaml：`conflict.human_timeout: 24h` |
| D-05 | 反模式库扩展到 5 个 | 当前保持 3 个，后续迭代扩展 |
| D-06 | 新旧路径映射具体实现 | ✅ 见 §2.2 C-03 |

---

## 11. Test Strategy（测试策略）

### 11.1 Pinch Point 测试

| 测试组 | 覆盖范围 | 预计用例数 |
|--------|----------|------------|
| config-discovery | 21 个 Skills 配置发现 | 5 |
| change-check | 变更包校验模式 | 8 |
| config-format | 新旧配置兼容 | 4 |

### 11.2 新脚本单元测试

| 脚本 | 用例数 |
|------|--------|
| constitution-check.sh | 4 |
| ac-trace-check.sh | 5 |
| fitness-check.sh | 4 |
| spec-preview.sh | 3 |
| spec-stage.sh | 5 |
| spec-promote.sh | 4 |
| spec-rollback.sh | 3 |
| migrate-to-devbooks-2.sh | 5 |

**总计**：约 50 个测试用例

---

## 12. Risk Mitigation（风险缓解）

### 高风险

| 风险 | 缓解措施 |
|------|----------|
| 迁移成本 | 提供自动化迁移脚本 + 详细文档 |
| 宪法规则过严 | 提供逃生舱口 + 可配置开关 |

### 中风险

| 风险 | 缓解措施 |
|------|----------|
| AC 标记不一致 | 强制检查 + 模板示例 |
| 适应度误报 | 初期使用 warn 模式 |

### 实施断点策略（Breakpoint Handling）

> 以下断点策略从实施计划回写，确保运维降级路径可追溯。

| 断点 ID | 触发条件 | 处置策略 |
|---------|----------|----------|
| BP-1 | config-discovery.sh 路径解析失败 | 回退到旧路径（openspec/），记录问题到日志 |
| BP-2 | 迁移脚本引用更新不完整 | 手动补充遗漏引用，更新脚本逻辑后重试 |
| BP-3 | AC 追溯覆盖率 <80% | 补充测试用例后继续，不阻断主流程 |

---

**设计完成**

下一步：
1. Test Owner 产出 `verification.md` + 测试用例
2. Planner 产出 `tasks.md`
