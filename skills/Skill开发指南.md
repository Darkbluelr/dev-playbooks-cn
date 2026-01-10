# DevBooks Skill 开发指南

本文档定义了开发新 Skill 时必须遵循的设计原则和约束。

---

## 1) 核心设计原则

### 1.1 单一职责原则（UNIX 哲学）

- **每个 Skill 只做一件事**：一个 Skill 只负责一个明确的职责，不要混合多个职责
- **通过文件系统传递信息**：Skill 之间通过 `<change-root>/<change-id>/` 目录下的文件交换数据，而非共享内存或会话状态
- **产物必须是纯文本**：所有产物使用 Markdown/JSON 格式，便于版本控制和人工审查

### 1.2 幂等性设计原则（强制）

**幂等性定义**：重复执行相同操作得到相同结果，不产生副作用累积。

| Skill 类型 | 幂等性要求 | 示例 |
|------------|------------|------|
| **验证/检查类** | 必须幂等（不修改文件） | `change-check.sh`、`guardrail-check.sh`、`devbooks-code-review` |
| **生成类** | 必须明确"覆盖/增量"行为 | `change-scaffold.sh`、`devbooks-design-doc`、`devbooks-proposal-author` |
| **修改类** | 必须可安全重跑 | `devbooks-spec-gardener`、`devbooks-design-backport` |

**验证/检查类 Skill 必须遵守**：
- [ ] 不修改任何文件（只读操作）
- [ ] 不修改数据库、缓存或外部状态
- [ ] 多次运行输出完全相同（给定相同输入）
- [ ] 失败时不留下部分状态

**生成类 Skill 必须遵守**：
- [ ] 明确声明是"覆盖模式"还是"增量模式"
- [ ] 覆盖模式：重复运行产生相同结果
- [ ] 增量模式：重复运行不产生重复内容（需要检测已存在内容）
- [ ] 失败时回滚到运行前状态（或明确说明无法回滚）

**修改类 Skill 必须遵守**：
- [ ] 修改前备份原文件（或可通过 git 恢复）
- [ ] 多次运行不产生累积副作用
- [ ] 提供"dry-run"模式预览变更

### 1.3 强制验证前置原则（借鉴 VS Code）

**核心要求**：生成/修改类 Skill 在输出文件后，**必须运行验证**，验证失败时禁止进入下一步。

| Skill 类型 | 验证要求 | 失败处理 |
|------------|----------|----------|
| 代码生成 | 编译检查（TypeScript/ESLint） | 必须修复后才能继续 |
| 测试生成 | 运行测试（预期 Red 或 Green） | 记录结果到 verification.md |
| 配置生成 | 格式验证（JSON/YAML schema） | 必须修复后才能继续 |
| 文档生成 | 链接检查、格式检查 | 警告但可继续 |

**强制验证检查清单**：

```markdown
## 验证前置检查（生成/修改类 Skill 必须执行）

- [ ] 输出文件后，立即运行相关验证命令
- [ ] 验证命令输出必须记录到证据文件
- [ ] 验证失败时，禁止声明"任务完成"
- [ ] 验证失败时，必须尝试修复或明确报告失败原因
- [ ] 禁止"假定成功"——必须实际查看命令输出
```

**示例：代码生成后的验证流程**

```bash
# 1. 生成代码
write_code_to_file "$output_file"

# 2. 立即验证（强制）
if ! npm run compile 2>&1 | tee "$evidence_dir/compile.log"; then
  echo "error: compilation failed, cannot proceed" >&2
  exit 1
fi

# 3. 运行 lint 检查
if ! npm run lint 2>&1 | tee "$evidence_dir/lint.log"; then
  echo "error: lint failed, cannot proceed" >&2
  exit 1
fi

# 4. 验证通过后才能继续
echo "ok: verification passed"
```

### 1.4 任务输出监控原则

**要求**：运行长时任务时，必须主动查看输出，避免"假定成功"的幻觉。

- [ ] 后台任务必须有超时机制
- [ ] 必须检查任务退出码
- [ ] 必须读取并分析任务输出
- [ ] 禁止仅凭"命令执行完毕"就声明成功

### 1.5 真理源分离原则

- **只读真理源**：Skill 只能读取 `<truth-root>/`，不能直接修改（除了 `spec-gardener` 等归档类 Skill）
- **写入工作区**：Skill 的写入目标是 `<change-root>/<change-id>/`
- **归档即合并**：归档操作将工作区内容合并回真理源

### 1.6 资源清理原则（借鉴 VS Code）

**要求**：无论成功失败，必须清理临时资源。

- [ ] 临时文件必须在退出时删除
- [ ] 后台进程必须在退出时终止
- [ ] 数据库连接必须在退出时关闭
- [ ] 使用 `trap` 确保异常退出时也能清理

```bash
# 示例：使用 trap 确保清理
cleanup() {
  rm -rf "$TEMP_DIR"
  kill "$BG_PID" 2>/dev/null || true
}
trap cleanup EXIT
```

---

## 2) Skill 目录结构

```
skills/
└── devbooks-<skill-name>/
    ├── SKILL.md           # Skill 定义（必须）
    ├── references/        # 参考文档（可选）
    │   ├── *.md           # 提示词、模板、清单等
    │   └── ...
    └── scripts/           # 可执行脚本（可选）
        ├── *.sh           # Shell 脚本
        └── ...
```

### 2.1 SKILL.md 模板

```markdown
---
name: devbooks-<skill-name>
description: 一句话描述 Skill 的职责和触发场景
---

# DevBooks：<Skill 名称>

## 前置：目录根（协议无关）

- `<truth-root>`：当前真理目录根
- `<change-root>`：变更包目录根

## 职责

<描述这个 Skill 做什么>

## 幂等性声明

- 类型：验证类 / 生成类 / 修改类
- 幂等性：是 / 否（说明原因）
- 重跑行为：<描述多次运行的行为>

## 参考文档

- `references/<文档名>.md`

## 脚本（如有）

- `scripts/<脚本名>.sh`
```

---

## 3) 脚本开发规范

### 3.1 必须支持的参数

所有脚本必须支持以下标准参数：

```bash
--project-root <path>    # 项目根目录（必须）
--change-root <path>     # 变更包目录根（必须）
--truth-root <path>      # 真理源目录根（必须）
--dry-run                # 预览模式，不实际修改（推荐）
--help                   # 显示帮助信息（必须）
```

### 3.2 退出码规范

| 退出码 | 含义 |
|--------|------|
| 0 | 成功 |
| 1 | 一般错误 |
| 2 | 参数错误 |
| 3 | 前置条件不满足 |
| 4 | 验证失败（用于检查类脚本） |

### 3.3 输出规范

- 正常输出到 stdout
- 错误信息到 stderr
- 支持 `--json` 输出机器可读格式（推荐）
- 不使用 ANSI 颜色码（除非检测到 TTY）

---

## 4) 质量检查清单

新 Skill 提交前必须通过以下检查：

- [ ] **单一职责**：Skill 只做一件事
- [ ] **幂等性声明**：SKILL.md 中明确声明幂等性行为
- [ ] **真理源分离**：不直接修改 `<truth-root>/`（除非是归档类 Skill）
- [ ] **参数完整**：脚本支持标准参数（`--project-root`、`--change-root`、`--truth-root`）
- [ ] **帮助信息**：`--help` 输出清晰的使用说明
- [ ] **退出码正确**：使用标准退出码
- [ ] **无副作用**：验证类 Skill 不修改文件
- [ ] **可测试**：提供测试用例或验证方法

---

## 5) 示例：验证类 Skill 的幂等性实现

```bash
#!/usr/bin/env bash
# change-check.sh - 验证类脚本示例

set -euo pipefail

# 验证类脚本：只读操作，不修改任何文件
readonly MODE="readonly"

check_change() {
    local change_id="$1"
    local change_path="$CHANGE_ROOT/$change_id"

    # 只读操作：检查文件是否存在
    [[ -f "$change_path/proposal.md" ]] || return 4
    [[ -f "$change_path/design.md" ]] || return 4
    [[ -f "$change_path/tasks.md" ]] || return 4

    # 只读操作：验证内容格式
    grep -q "^## Acceptance Criteria" "$change_path/design.md" || return 4

    return 0
}

# 多次运行输出相同，不产生副作用
check_change "$1"
```
