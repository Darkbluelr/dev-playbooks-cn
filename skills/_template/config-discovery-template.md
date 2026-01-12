# Skills 配置发现标准模板

> 此模板定义了所有 `devbooks-*` Skills 在执行前必须遵循的配置发现流程。

---

## 前置：配置发现（协议无关）

执行任何操作前，**必须**按以下顺序查找配置（找到后停止）：

### 查找顺序

1. `.devbooks/config.yaml`（如存在）→ 解析其中的映射
2. `dev-playbooks/project.md`（如存在）→ 使用 DevBooks 默认映射
3. `project.md`（如存在）→ 使用 template 默认映射
4. 若仍无法确定 → **停止并询问用户**

### 默认映射表

| 协议 | truth_root | change_root | agents_doc |
|------|------------|-------------|------------|
| devbooks | `dev-playbooks/specs/` | `dev-playbooks/changes/` | `dev-playbooks/project.md` |
| template | `specs/` | `changes/` | `project.md` |

### 从配置中获取

- `truth_root`：真理目录根（当前系统规格的最终版本）
- `change_root`：变更目录根（每次变更的所有产物）
- `agents_doc`：规则文档位置（AI 必须先阅读）
- `project_profile`：项目画像位置（可选，用于快速上下文）

### 关键约束

1. **如果 `agents_doc` 存在，必须先阅读该文档再执行任何操作**
2. 禁止猜测目录根
3. 禁止跳过规则文档阅读
4. 禁止在未确定配置的情况下执行

### 推荐方式

运行配置发现脚本：

```bash
DEVBOOKS_SCRIPTS="${CODEX_HOME:-$HOME/.codex}/skills/devbooks-delivery-workflow/scripts"
# 或
DEVBOOKS_SCRIPTS="${CLAUDE_CODE_HOME:-$HOME/.claude-code}/skills/devbooks-delivery-workflow/scripts"

source <("$DEVBOOKS_SCRIPTS/../config-discovery.sh")
# 现在可以使用 $truth_root, $change_root, $agents_doc 等变量
```

---

## 如何在 SKILL.md 中使用此模板

在每个 SKILL.md 文件的开头，添加以下内容：

```markdown
## 前置：配置发现（协议无关）

- `<truth-root>`：当前真理目录根
- `<change-root>`：变更包目录根

执行前**必须**按以下顺序查找配置（找到后停止）：
1. `.devbooks/config.yaml`（如存在）
2. `dev-playbooks/project.md`（如存在）
3. `project.md`（如存在）
4. 若仍无法确定 → **停止并询问用户**

**关键约束**：如果配置中指定了 `agents_doc`（规则文档），必须先阅读该文档再执行任何操作。
```

---

## 示例：更新后的 SKILL.md

### 更新前（硬编码）

```markdown
## 前置：目录根（协议无关）

- `<truth-root>`：当前真理目录根（默认建议 `specs/`；DevBooks 项目为 `dev-playbooks/specs/`）
- `<change-root>`：变更包目录根（默认建议 `changes/`；DevBooks 项目为 `dev-playbooks/changes/`）

执行前必须先尝试读取 `dev-playbooks/project.md`（如存在）以确定 `<truth-root>/<change-root>`；禁止猜测目录根。若仍无法确定，再询问用户确认。
```

### 更新后（协议发现）

```markdown
## 前置：配置发现（协议无关）

- `<truth-root>`：当前真理目录根
- `<change-root>`：变更包目录根

执行前**必须**按以下顺序查找配置（找到后停止）：
1. `.devbooks/config.yaml`（如存在）→ 解析并使用其中的映射
2. `dev-playbooks/project.md`（如存在）→ DevBooks 协议，使用默认映射
3. `project.md`（如存在）→ template 协议，使用默认映射
4. 若仍无法确定 → **停止并询问用户**

**关键约束**：
- 如果配置中指定了 `agents_doc`，必须先阅读该文档再执行任何操作
- 禁止猜测目录根
- 禁止跳过规则文档阅读
```

---

## 批量更新脚本（参考）

```bash
#!/bin/bash
# 批量更新所有 Skills 的 SKILL.md

OLD_PATTERN='执行前必须先尝试读取 `dev-playbooks/project.md`'
NEW_TEXT='执行前**必须**按以下顺序查找配置'

for skill_dir in skills/devbooks-*/; do
    skill_md="$skill_dir/SKILL.md"
    if [ -f "$skill_md" ] && grep -q "$OLD_PATTERN" "$skill_md"; then
        echo "Updating: $skill_md"
        # 实际更新需要更复杂的 sed 命令
    fi
done
```
