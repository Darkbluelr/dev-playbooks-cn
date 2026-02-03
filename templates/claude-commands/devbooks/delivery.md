---
skill: devbooks-delivery-workflow
---

# DevBooks: 交付工作流

使用 devbooks-delivery-workflow 作为**唯一入口**：自动识别请求类型并路由到**最小充分闭环**（debug / change / epic / void / bootstrap / governance）。

## 用法

/devbooks:delivery [参数]

## 参数

$ARGUMENTS

## 说明

你不需要记忆其它入口命令；所有请求都从这里进入。

路由结果会落盘为可审计产物（至少包含 `proposal.md` front matter 的 `request_kind` / `change_type` / `risk_level`，以及对应的 RUNBOOK）。

若项目没有上游 SSOT（需求真相文档库），Delivery 会先在 `<truth-root>/ssot/` 下落盘最小 SSOT 包（`SSOT.md` + `requirements.index.yaml`），再继续后续闭环。

闭环选择原则：
- `request_kind=debug`：先复现/定位（必要时再进入修复变更包）
- `request_kind=change`：单变更包闭环（按风险与合同派生闸门）
- `request_kind=epic`：强制 Knife 切片 → 多变更包队列
- `request_kind=void`：高熵研究/原型验证 → ADR/Freeze/Thaw → 再回流
- `request_kind=bootstrap`：基线与术语/边界对齐（DoR 不满足则阻断）
- `request_kind=governance`：协议/闸门/真理工件治理变更（更严格证据与归档）
  - 包括：修改/同步 SSOT、更新 `requirements.index.yaml`、刷新 `requirements.ledger.yaml`（derived cache）
