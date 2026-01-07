# setup/（上下文协议适配器）

目标：把 **DevBooks Skills（`devbooks-*`）** 接入你的“上下文协议/上下文管理工具”，让项目具备统一、可追溯的落盘约定。

关键点：
- DevBooks Skills 本身是 **协议无关** 的；它们只依赖两个目录根的定义：
  - `<truth-root>`：当前真理目录根（默认建议 `specs/`）
  - `<change-root>`：变更包目录根（默认建议 `changes/`）
- 不同上下文协议只是把这两个目录根“映射”到各自的目录与项目指路牌文件里。

## 目录

- `template/`：协议无关的集成模板与安装提示词（可用于任意项目/任意协议）
- `openspec/`：OpenSpec 适配器（把 `<truth-root>`/`<change-root>` 映射到 `openspec/specs/` 与 `openspec/changes/`）

