# setup/openspec（一次性）

目标：把 DevBooks 的协议无关约定映射到 OpenSpec（让 OpenSpec 项目使用 DevBooks Skills 稳定落盘）。

## 映射关系（OpenSpec）

| 协议无关变量 | OpenSpec 映射 |
|-------------|---------------|
| `<truth-root>` | `openspec/specs/` |
| `<change-root>` | `openspec/changes/` |
| `<agents-doc>` | `openspec/project.md` |

## 安装后你会得到什么

安装后，你的项目将获得：

1. **配置发现入口**（`.devbooks/config.yaml`）
   - 让所有 Skills 自动发现协议类型和目录映射
   - AI 会自动读取规则文档

2. **协议规则**（写入 `openspec/project.md` + 根 `AGENTS.md`）
   - Test Owner 与 Coder 必须独立对话/独立实例
   - Coder 禁止修改 tests/
   - 结构质量守门：遇到代理指标驱动要求必须停线评估
   - 提案对辩：proposal 阶段使用 Author/Challenger/Judge 三角色

3. **角色检查机制**
   - `/openspec:apply` 必须指定角色（test-owner / coder / reviewer）
   - 未指定角色时显示菜单等待用户输入

4. **DevBooks Skills**
   - 变更管理工作流（proposal → apply → archive）
   - 角色隔离执行（Test Owner / Coder / Reviewer）
   - 热点感知（需要 CKB MCP Server 可用）

## 你会改动哪些东西（最小且可持续）

只修改三处可持久化文件（避免被 `openspec update` 覆盖）：
- `.devbooks/config.yaml`（新增）
- `openspec/project.md`
- 根 `AGENTS.md`（放在 OpenSpec managed block 之外）

## 不要改什么

- 不要直接修改 `openspec/AGENTS.md`（会被 OpenSpec 刷新覆盖）

## 资料

- 可复制模板：`OpenSpec集成模板（project.md 与 AGENTS附加块）.md`
- 配置文件模板：`template.devbooks-config.yaml`
- 让 AI 自动完成接线：`安装提示词.md`

## 安装方式

### 方式 1：让 AI 自动安装

复制 `安装提示词.md` 的内容，发送给 AI。

### 方式 2：手动安装

1. 复制 `template.devbooks-config.yaml` 到项目的 `.devbooks/config.yaml`
2. 复制 `OpenSpec集成模板（project.md 与 AGENTS附加块）.md` 中的内容到对应文件

## Codex 命令入口（可选，但推荐）

如果你主要用 Codex（而不是 Claude Code 的 `/openspec:proposal` 入口），建议额外安装 DevBooks 的 Codex prompts：

```bash
./scripts/install-skills.sh --with-codex-prompts
```

安装后可用命令：
- `/devbooks-openspec-proposal`
- `/devbooks-openspec-apply`（必须带 role 参数）
- `/devbooks-openspec-archive`

这些 prompts 不会被 `openspec update` 覆盖，可作为更稳定的"质量优先入口"。

## Apply 阶段角色说明

`/openspec:apply` 必须指定角色：

```
/openspec:apply test-owner <change-id>  # 产出 verification.md + tests/
/openspec:apply coder <change-id>        # 按 tasks.md 实现
/openspec:apply reviewer <change-id>     # 输出评审意见
```

如果不指定角色，会显示菜单等待用户选择。

## Protocol Discovery Layer

安装完成后，项目支持 Protocol Discovery Layer：

```
用户调用 devbooks-* Skill
        ↓
Skill 读取 .devbooks/config.yaml
        ↓
发现协议类型 + 目录映射 + 规则文档
        ↓
先读取规则文档（agents_doc）
        ↓
按协议规则执行
```

这解决了之前"Skills 与 OpenSpec 独立运行"的问题。

## 自动化配置（可选但推荐）

安装后可额外配置自动化：

1. **CI/CD 集成**：PR 时自动架构合规检查
   ```bash
   cp templates/ci/devbooks-guardrail.yml .github/workflows/
   cp templates/ci/devbooks-cod-update.yml .github/workflows/
   ```

详见 `templates/ci/README.md`
