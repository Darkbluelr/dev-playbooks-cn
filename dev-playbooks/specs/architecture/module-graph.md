# 模块依赖图（目录级）

## 范围与来源

- 范围：仓库顶层目录与关键脚本的引用关系
- 来源：`scripts/install-skills.sh`，`setup/README.md`，`docs/embedding-quickstart.md`

## 模块节点

- `skills/`
- `prompts/`
- `scripts/`
- `setup/`
- `mcp/`
- `tools/`
- `templates/`
- `docs/`
- `dev-playbooks/`

## 依赖关系（基于脚本与文档引用）

1. `scripts/install-skills.sh` → `skills/`
   - 说明：安装脚本复制 `skills/devbooks-*` 到用户目录
   - 证据：`scripts/install-skills.sh`
2. `scripts/install-skills.sh` → `prompts/`
   - 说明：可选安装 `prompts/devbooks-*.md`
   - 证据：`scripts/install-skills.sh`
3. `setup/` → `scripts/`
   - 说明：安装文档引导执行安装脚本
   - 证据：`setup/README.md`
4. `docs/` → `tools/`
   - 说明：Embedding 文档引导执行工具脚本
   - 证据：`docs/embedding-quickstart.md`

## 边界说明

- `mcp/devbooks-mcp-server/` 为独立 Node 子项目
- `tools/` 脚本与 `docs/` 文档为工具使用入口
- `dev-playbooks/` 为协议与规则文档
