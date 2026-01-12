# automation-guardrails

---
owner: devbooks-spec-gardener
last_verified: 2026-01-10
status: Draft
freshness_check: 3 Months
---

## 目的

描述自动化守门相关脚本与模板的现状能力与验收场景。

## 需求

### 需求：提供 CI 模板用于守门与 COD 更新

系统必须提供 CI 模板以支持架构守门与 COD 模型更新。

#### 场景：复制 CI 模板到项目
- **当** 将 `templates/ci/devbooks-guardrail.yml` 与 `templates/ci/devbooks-cod-update.yml` 复制到 `.github/workflows/`
- **那么** CI 可执行架构合规检查与 COD 模型更新
- **证据**：`templates/ci/README.md`，`templates/ci/devbooks-guardrail.yml`，`templates/ci/devbooks-cod-update.yml`
