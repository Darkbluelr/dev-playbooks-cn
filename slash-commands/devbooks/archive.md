<!-- DEVBOOKS:START -->
# /devbooks:archive

归档变更包。

## 前置条件

- 所有测试通过（Green）
- 代码审查完成
- `verification.md` 中的追溯矩阵已填写

## 执行流程

1. 验证变更包完整性
2. 将 `specs/` 中的 delta 合并到 `<truth_root>`
3. 更新 `design.md` 状态为 Archived
4. 生成 `ARCHIVE-SUMMARY.md`

## 闸门检查

归档前必须通过：
- [ ] 所有 AC-xxx 已追溯到测试
- [ ] Red 基线和 Green 证据已记录
- [ ] 角色隔离已遵守

## 产物

- 更新后的 `<truth_root>/specs/`
- `ARCHIVE-SUMMARY.md`: 归档摘要

<!-- DEVBOOKS:END -->
