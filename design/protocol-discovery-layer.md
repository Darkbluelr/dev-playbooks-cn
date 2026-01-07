# Protocol Discovery Layer 设计文档

> 解决 dev-playbooks 与 openspec 融合问题的架构设计

## 问题陈述

### 当前问题

1. **Skills 硬编码问题**：Skills 中直接写死 `openspec/project.md`、`openspec/specs/`
2. **角色检查缺失**：`/openspec:apply` 直接执行，不等待用户指定角色
3. **规则文档未读取**：AI 不会自动读取 `openspec/AGENTS.md` 或 `openspec/project.md`
4. **两系统独立**：dev-playbooks 与 openspec 之间缺少桥接层

### 期望效果

```
新项目 → openspec init → 复制 dev-playbooks → setup/openspec 安装
    ↓
调用 dev-playbook 提示词时 → AI 自动发现并读取 openspec 规则
    ↓
/openspec:apply → 显示角色菜单 → 等待用户选择 → 执行
```

---

## 解决方案

### 核心：引入 Protocol Discovery Layer

```
┌─────────────────────────────────────────────────────────────┐
│                     项目工作区                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   .devbooks/config.yaml  ←── 配置入口（新增）               │
│          ↓                                                  │
│   ┌───────────────────────────────────────────────────┐    │
│   │         Protocol Discovery Layer                   │    │
│   │                                                    │    │
│   │  输入：.devbooks/config.yaml                       │    │
│   │       （或 openspec/project.md 或 project.md）     │    │
│   │                                                    │    │
│   │  输出：                                            │    │
│   │    - protocol: openspec | template                 │    │
│   │    - truth_root: openspec/specs/ | specs/          │    │
│   │    - change_root: openspec/changes/ | changes/     │    │
│   │    - agents_doc: openspec/project.md | ...         │    │
│   │    - constraints: { apply_requires_role: true }    │    │
│   └───────────────────────────────────────────────────┘    │
│          ↓                                                  │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│   │ devbooks-*  │  │ devbooks-*  │  │ devbooks-*  │       │
│   │   Skills    │  │   Skills    │  │   Skills    │       │
│   └─────────────┘  └─────────────┘  └─────────────┘       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 详细设计

### 1. 配置文件格式（`.devbooks/config.yaml`）

```yaml
# .devbooks/config.yaml
# DevBooks 协议发现配置

# 协议类型：openspec | template | custom
protocol: openspec

# 目录根映射
truth_root: openspec/specs/
change_root: openspec/changes/

# 规则文档位置（AI 必须先读取）
agents_doc: openspec/project.md

# 项目画像（可选，用于快速上下文）
project_profile: openspec/specs/_meta/project-profile.md

# 协议特定约束
constraints:
  # apply 阶段是否必须指定角色
  apply_requires_role: true

  # apply 阶段可用角色
  apply_roles:
    - test-owner
    - coder
    - reviewer

  # Test Owner 与 Coder 是否必须独立对话
  role_isolation: true

  # Coder 是否禁止修改 tests/
  coder_no_tests: true
```

### 2. 配置发现脚本（`scripts/config-discovery.sh`）

```bash
#!/bin/bash
# scripts/config-discovery.sh
# 发现并输出当前项目的 DevBooks 配置
# 返回格式：key=value（每行一个）

set -euo pipefail

PROJECT_ROOT="${1:-.}"

# 优先级 1：.devbooks/config.yaml
if [ -f "$PROJECT_ROOT/.devbooks/config.yaml" ]; then
    echo "config_source=.devbooks/config.yaml"
    # 使用 yq 或 grep 解析（简化版用 grep）
    grep -E "^(protocol|truth_root|change_root|agents_doc):" "$PROJECT_ROOT/.devbooks/config.yaml" | \
        sed 's/: /=/' | sed 's/ *$//'
    exit 0
fi

# 优先级 2：openspec/project.md（存在即为 OpenSpec 协议）
if [ -f "$PROJECT_ROOT/openspec/project.md" ]; then
    echo "config_source=openspec/project.md"
    echo "protocol=openspec"
    echo "truth_root=openspec/specs/"
    echo "change_root=openspec/changes/"
    echo "agents_doc=openspec/project.md"
    echo "apply_requires_role=true"
    exit 0
fi

# 优先级 3：project.md（通用模板协议）
if [ -f "$PROJECT_ROOT/project.md" ]; then
    echo "config_source=project.md"
    echo "protocol=template"
    echo "truth_root=specs/"
    echo "change_root=changes/"
    echo "agents_doc=project.md"
    echo "apply_requires_role=false"
    exit 0
fi

# 未找到配置
echo "config_source=none"
echo "protocol=unknown"
exit 1
```

### 3. Skills SKILL.md 标准化模板

所有 Skills 的 SKILL.md 都应该使用统一的配置发现前置：

```markdown
## 前置：配置发现（协议无关）

执行前**必须**按以下顺序查找配置（找到后停止）：

1. `.devbooks/config.yaml`（如存在）→ 解析其中的映射
2. `openspec/project.md`（如存在）→ 使用 OpenSpec 默认映射
3. `project.md`（如存在）→ 使用 template 默认映射
4. 若仍无法确定 → **停止并询问用户**

从配置中获取：
- `truth_root`：真理目录根
- `change_root`：变更目录根
- `agents_doc`：规则文档位置

**关键约束**：
- 如果 `agents_doc` 存在，**必须先阅读该文档**再执行任何操作
- 禁止猜测目录根
- 禁止跳过规则文档阅读

推荐：运行 `"$DEVBOOKS_SCRIPTS/config-discovery.sh"` 获取配置。
```

### 4. `/openspec:apply` 行为修改

修改 `prompts/devbooks-openspec-apply.md`：

```markdown
---
description: 用 DevBooks 角色隔离执行 OpenSpec apply
argument-hint: role + change-id (e.g. "test-owner <id>" | "coder <id>" | "reviewer <id>")
---

$ARGUMENTS

你正在执行 **OpenSpec 的 apply 阶段**。

## 第一步：输入检查（必须完成，否则停止）

1. 从 $ARGUMENTS 中提取 `role` 和 `change-id`

2. **如果无法确定 role**：
   ```
   === Apply 阶段需要指定角色 ===

   可用角色：
   - test-owner：产出 verification.md + tests/（先跑 Red 基线）
   - coder：按 tasks.md 实现，让闸门 Green（禁止改 tests）
   - reviewer：输出评审意见（不改代码）

   请输入：/openspec:apply <role> <change-id>
   例如：/openspec:apply coder feature-123
   ```
   **停止执行，等待用户输入。禁止猜测或自动选择角色。**

3. **如果无法确定 change-id**：
   - 列出 `openspec/changes/` 下所有目录
   - 显示列表并询问用户
   - **停止执行，等待用户输入**

## 第二步：配置发现

运行配置发现（参考 Skills 的标准前置）。

## 第三步：角色执行

（原有逻辑...）
```

### 5. setup 安装流程更新

更新 `setup/openspec/安装提示词.md`，添加配置文件创建：

```markdown
任务（按顺序执行）：

1) **创建 `.devbooks/config.yaml`**（新增）：
   ```yaml
   protocol: openspec
   truth_root: openspec/specs/
   change_root: openspec/changes/
   agents_doc: openspec/project.md
   project_profile: openspec/specs/_meta/project-profile.md
   constraints:
     apply_requires_role: true
     apply_roles: [test-owner, coder, reviewer]
     role_isolation: true
     coder_no_tests: true
   ```

2) 打开 `OpenSpec集成模板（project.md 与 AGENTS附加块）.md`...
   （原有步骤）

3) 校验...
   （原有步骤，增加 `.devbooks/config.yaml` 检查）
```

---

## 修改清单

### 新增文件

| 文件 | 用途 |
|------|------|
| `scripts/config-discovery.sh` | 配置发现脚本 |
| `setup/openspec/template.devbooks-config.yaml` | 配置文件模板 |
| `.devbooks/config.yaml`（项目级） | 项目配置（安装时生成） |

### 修改文件

| 文件 | 修改内容 |
|------|----------|
| `skills/*/SKILL.md`（所有 19 个） | 统一"前置：配置发现"部分 |
| `prompts/devbooks-openspec-apply.md` | 添加角色检查与菜单逻辑 |
| `setup/openspec/安装提示词.md` | 添加 `.devbooks/config.yaml` 创建步骤 |
| `setup/openspec/README.md` | 更新说明 |

---

## 方案优势

1. **解耦**：Skills 不再硬编码 openspec 路径，通过配置发现层获取
2. **可扩展**：支持 openspec / template / 自定义协议
3. **强制约束**：`/openspec:apply` 必须指定角色，不会直接执行
4. **规则发现**：AI 会自动读取 `agents_doc` 中的规则
5. **向后兼容**：即使没有 `.devbooks/config.yaml`，也能通过 `openspec/project.md` 发现协议

---

## 实现步骤

### Phase 1：基础设施（本次）

1. 创建 `scripts/config-discovery.sh`
2. 创建 `setup/openspec/template.devbooks-config.yaml`
3. 修改 `prompts/devbooks-openspec-apply.md`

### Phase 2：Skills 迁移

1. 创建标准化的"前置：配置发现"模板
2. 批量更新所有 Skills 的 SKILL.md

### Phase 3：文档与测试

1. 更新 `setup/openspec/安装提示词.md`
2. 更新 `使用说明书.md`
3. 创建验证测试

---

## 替代方案考虑

### 方案 A：拆分 `/openspec:apply` 命令

```
/openspec:apply:test-owner <id>
/openspec:apply:coder <id>
/openspec:apply:reviewer <id>
```

**优点**：命令更明确，不会混淆
**缺点**：需要修改 openspec 的命令系统（可能涉及 `.claude/commands/`）

### 方案 B：仅修改 prompts

只修改 `devbooks-openspec-apply.md`，强化检查逻辑。

**优点**：改动最小
**缺点**：不解决 Skills 硬编码问题

### 选择

推荐**主方案（Protocol Discovery Layer）**，因为它从根本上解决了问题，且具有良好的扩展性。

---

## 待讨论

1. 配置文件格式：YAML vs JSON vs TOML？
2. 是否需要支持环境变量覆盖？
3. 是否需要支持多协议混合（同一项目同时使用 openspec + 自定义规则）？
