---
description: 用 DevBooks 归档前检查 + OpenSpec archive 完成合并，并严格 validate
argument-hint: change-id
---

$ARGUMENTS

你正在执行 **OpenSpec 的 archive 阶段**，目标是把已交付的变更包安全归档并更新 specs 真理源。

硬约束（必须遵守）：
- 必须确认 change-id 存在且可归档；不明确就先 `openspec list` 再问用户确认。
- 归档后必须跑 `openspec validate --strict` 并处理所有问题。

步骤（按顺序执行）：
1) 确定 change-id
   - 如果参数里有 id：使用它（trim whitespace）
   - 否则：运行 `openspec list`，展示候选并让用户确认
2) 归档前检查（最小集）
   - `openspec/changes/<id>/tasks.md` 是否都已完成（与事实一致）
   - tests/闸门是否为 Green（以仓库惯例命令为准）
   - 若本次产生了 spec deltas：建议先做一次“规格园丁”修剪（去重/合并/删除过时），再归档
   - （推荐）DevBooks 严格校验：先设置 `DEVBOOKS_SCRIPTS="${CODEX_HOME:-$HOME/.codex}/skills/devbooks-delivery-workflow/scripts"`，再运行：`"$DEVBOOKS_SCRIPTS/change-check.sh" <id> --mode strict --project-root "$(pwd)" --change-root openspec/changes --truth-root openspec/specs`
3) 执行归档
   - 运行 `openspec archive <id> --yes`
4) 严格验证
   - 运行 `openspec validate --strict`
5) 输出结果
   - 归档命令输出摘要
   - specs 更新是否符合预期（必要时用 `openspec list --specs` 或 `openspec show <spec>` 检查）
