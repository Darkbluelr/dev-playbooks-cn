---
skill: devbooks-router
---

# DevBooks: 工作流路由

使用 devbooks-router 检测项目当前状态，给出最短闭环路径。

## 用法

/devbooks:router [参数]

## 参数

$ARGUMENTS

## 说明

Router 是 DevBooks 工作流的主入口，适用于复杂变更（>5文件或跨模块）：
- 读取 Impact 画像生成完整执行计划
- 检测项目当前状态
- 推荐下一步 Skill

对于已知具体要执行的 Skill，可直接使用对应的直达命令。
