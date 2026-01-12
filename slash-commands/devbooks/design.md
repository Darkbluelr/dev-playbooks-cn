<!-- DEVBOOKS:START -->
# /devbooks:design

创建设计文档。

## 前置条件

- `proposal.md` 已存在且状态为 Approved

## 执行流程

1. 读取 `proposal.md` 内容
2. 创建 `<change_root>/<id>/design.md`
3. 填写 What/Constraints + AC-xxx
4. **禁止**写实现步骤或函数体代码

## 产物

- `design.md`: 设计文档，包含验收标准（AC-xxx）

## 约束

- 只写 What/Constraints，不写 How
- AC 必须是可验证的 Pass/Fail 判据

<!-- DEVBOOKS:END -->
