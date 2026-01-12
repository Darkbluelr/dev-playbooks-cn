<!-- DEVBOOKS:START -->
# /devbooks:proposal

创建变更提案。

## 触发条件

当用户需要：
- 提出新功能或变更
- 重大架构变更
- 性能/安全优化

## 执行流程

1. 读取 `.devbooks/config.yaml` 确定 `change_root`
2. 为变更生成唯一 ID
3. 创建 `<change_root>/<id>/proposal.md`
4. 填写 Why/What/Impact/Risks/Validation

## 产物

- `proposal.md`: 变更提案文档

## 参考

- 阅读 `dev-playbooks/project.md` 了解项目约定
- 遵循 `dev-playbooks/constitution.md` 中的原则

<!-- DEVBOOKS:END -->
