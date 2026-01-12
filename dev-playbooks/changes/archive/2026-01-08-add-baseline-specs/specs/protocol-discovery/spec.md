# protocol-discovery

## 修改需求

### 需求：提供协议发现脚本并输出关键映射

系统必须提供协议发现脚本，并输出协议类型与目录映射信息。

#### 场景：存在 `.devbooks/config.yaml`
- **当** 执行 `./scripts/config-discovery.sh`
- **那么** 输出包含 `protocol`、`truth_root`、`change_root` 与 `agents_doc`
- **证据**：`scripts/config-discovery.sh`

### 需求：提供协议发现配置模板

系统必须提供协议发现配置模板以描述协议类型与目录映射。

#### 场景：使用 OpenSpec 模板生成配置
- **当** 以 `setup/openspec/template.devbooks-config.yaml` 作为模板
- **那么** 配置包含 `protocol`、`truth_root`、`change_root` 与角色约束
- **证据**：`setup/openspec/template.devbooks-config.yaml`

### 需求：提供协议发现层说明

系统必须提供协议发现层说明文档，明确优先级与映射关系。

#### 场景：查看集成文档
- **当** 阅读 `setup/openspec/README.md`
- **那么** 可以看到配置发现的优先级与映射关系
- **证据**：`setup/openspec/README.md`
