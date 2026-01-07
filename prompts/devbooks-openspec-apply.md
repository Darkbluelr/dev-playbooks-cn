---
description: 用 DevBooks 角色隔离执行 OpenSpec apply（test owner / coder / reviewer），保持 tasks 与闸门一致
argument-hint: role + change-id (e.g. "test-owner <id>" | "coder <id>" | "reviewer <id>")
---

$ARGUMENTS

你正在执行 **OpenSpec 的 apply 阶段**，但要求使用 **DevBooks 的角色隔离与质量闸门** 来交付结果。

---

## 第一步：配置发现（必须完成）

按以下顺序查找配置（找到后停止）：
1. `.devbooks/config.yaml`（如存在）
2. `openspec/project.md`（如存在）
3. `project.md`（如存在）

如果找到 `agents_doc`（规则文档），**必须先阅读该文档**再继续。

---

## 第二步：输入检查（必须完成，否则停止）

从 $ARGUMENTS 中提取 `role` 和 `change-id`。

### 如果无法确定 role：

**停止执行**，输出以下菜单并等待用户输入：

```
╔═══════════════════════════════════════════════════════════╗
║           Apply 阶段需要指定角色                           ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  可用角色：                                               ║
║                                                           ║
║  [1] test-owner                                           ║
║      → 产出 verification.md + tests/                      ║
║      → 先跑 Red 基线，记录失败证据                        ║
║      → 必须独立对话（与 coder 隔离）                      ║
║                                                           ║
║  [2] coder                                                ║
║      → 按 tasks.md 实现，让闸门 Green                     ║
║      → 禁止修改 tests/（需改测试请交还 test-owner）       ║
║      → 必须独立对话（与 test-owner 隔离）                 ║
║                                                           ║
║  [3] reviewer                                             ║
║      → 输出评审意见（坏味道/依赖/一致性）                 ║
║      → 不改代码，不改测试                                 ║
║                                                           ║
╠═══════════════════════════════════════════════════════════╣
║  用法：/openspec:apply <role> <change-id>                 ║
║  例如：/openspec:apply coder feature-123                  ║
╚═══════════════════════════════════════════════════════════╝
```

**禁止猜测或自动选择角色。必须等待用户输入。**

### 如果无法确定 change-id：

1. 列出 `openspec/changes/` 下所有目录
2. 显示列表并询问用户选择
3. **停止执行，等待用户输入**

---

## 第三步：角色执行

确认 role 和 change-id 后，输出确认信息：

```
角色：{role}
变更包：{change-id}
开始执行...
```

---

## 硬约束（必须遵守）

- 先读再写：必须先阅读 `openspec/changes/<id>/proposal.md`、`design.md`（如有）、`tasks.md`，以及本次 `specs/**` deltas（如有）。
- **角色隔离**：Test Owner 与 Coder 必须独立对话/独立实例；允许并行但不得共享上下文。
- Coder **禁止修改** `tests/**`；如需调整测试只能交还 Test Owner。

---

## 执行方式（按 role 分支）

### A) role = test-owner

目标：把 design/spec 转成可执行验收锚点

产物：
- `openspec/changes/<id>/verification.md`
- `tests/**`（按仓库惯例）

要求：
1. 先把测试跑到 **Red**（或至少证明当前基线不满足 AC）
2. 把失败证据记录到 `openspec/changes/<id>/evidence/**`（按需创建）
3. 在 `verification.md` 写追溯：AC-xxx → tests/证据（最小矩阵即可）

推荐调用 Skill：`devbooks-test-owner`

### B) role = coder

目标：严格按 `tasks.md` 实现，让闸门 **Green**

要求：
1. 顺序执行 tasks；每完成一项再勾选 `- [x]`
2. 不改 tests；以测试/静态检查/构建为唯一完成判据

推荐调用 Skill：`devbooks-coder`

### C) role = reviewer

目标：输出可执行的坏味道/依赖/一致性建议（不争论业务正确性）

要求：
1. 检查任务勾选是否与事实一致
2. 关注结构质量守门（耦合/依赖方向/复杂度/可测试性）

推荐调用 Skill：`devbooks-code-review`

---

## 输出要求

- 你识别到的 role 与 change-id
- 你修改/新增的文件清单（reviewer 仅输出评审意见）
- 下一步建议（例如：reviewer 完成后进入 archive）

---

## 补充（推荐的确定性脚本）

先设置：
```bash
DEVBOOKS_SCRIPTS="${CODEX_HOME:-$HOME/.codex}/skills/devbooks-delivery-workflow/scripts"
```

- **Test Owner 结构校验**：
  ```bash
  "$DEVBOOKS_SCRIPTS/change-check.sh" <change-id> --mode apply --role test-owner \
      --project-root "$(pwd)" --change-root openspec/changes --truth-root openspec/specs
  ```

- **Test Owner 证据落盘**：
  ```bash
  "$DEVBOOKS_SCRIPTS/change-evidence.sh" <change-id> --label red-baseline \
      --project-root "$(pwd)" --change-root openspec/changes -- <test-command>
  ```

- **Coder 结构校验**：
  ```bash
  "$DEVBOOKS_SCRIPTS/change-check.sh" <change-id> --mode apply --role coder \
      --project-root "$(pwd)" --change-root openspec/changes --truth-root openspec/specs
  ```
