<!-- DEVBOOKS:START -->
# /devbooks:quick

快速模式 - 用于小变更。

## 适用场景

- 影响文件数 ≤ 5 个
- 不跨模块
- 不涉及对外接口变更
- 不需要复杂 AC 追溯

## 执行流程

快速模式合并了 proposal → apply → archive：

1. 创建简化的 `proposal.md`
2. 直接进入实现（跳过 design）
3. 完成后自动归档

## 约束

如果变更超出快速模式边界，系统将提示使用完整流程：
- `/devbooks:proposal`
- `/devbooks:design`
- `/devbooks:apply`
- `/devbooks:archive`

## 超限检测

| 维度 | 快速模式上限 |
|------|--------------|
| 影响文件数 | ≤ 5 个 |
| 跨模块变更 | 否 |
| 对外接口变更 | 否 |
| 需要 AC 追溯 | 否 |

<!-- DEVBOOKS:END -->
