---
skill: devbooks-router
---

# DevBooks: Start

Start 是默认入口，用于判定当前阶段并给出下一步路由建议。

## 用法

/devbooks:start [参数]

## 参数

$ARGUMENTS

## 说明

- 当不确定下一步时，从 Start 进入。
- Router 会读取配置映射与现有产物，给出最短闭环路径。
- 如果已知 change-id，可在参数中提供以减少询问。
