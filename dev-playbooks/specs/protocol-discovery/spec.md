# protocol-discovery

---
owner: devbooks-spec-gardener
last_verified: 2026-01-11
status: Deprecated
freshness_check: 3 Months
deprecated_by: config-protocol
deprecation_note: 此规格已被 config-protocol v2 扩展替代，保留作为历史参考。
---

> ⚠️ **已废弃**：请使用 `specs/config-protocol/spec.md` 作为 DevBooks 配置协议的权威规格。

## 目的

描述协议发现脚本与配置模板的现状能力与验收场景。
## 需求
### 需求：提供协议发现脚本并输出关键映射

系统必须提供协议发现脚本，并输出协议类型与目录映射信息。

#### 场景：存在 `.devbooks/config.yaml`
- **当** 执行 `./scripts/config-discovery.sh`
- **那么** 输出包含 `protocol`、`truth_root`、`change_root` 与 `agents_doc`
- **证据**：`scripts/config-discovery.sh`

### 需求：提供协议发现配置模板

系统必须提供协议发现配置模板以描述协议类型与目录映射。

#### 场景：使用 DevBooks 模板生成配置
- **当** 以 `setup/dev-playbooks/template.devbooks-config.yaml` 作为模板
- **那么** 配置包含 `protocol`、`truth_root`、`change_root` 与角色约束
- **证据**：`setup/dev-playbooks/template.devbooks-config.yaml`

### 需求：提供协议发现层说明

系统必须提供协议发现层说明文档，明确优先级与映射关系。

#### 场景：查看集成文档
- **当** 阅读 `setup/dev-playbooks/README.md`
- **那么** 可以看到配置发现的优先级与映射关系
- **证据**：`setup/dev-playbooks/README.md`

