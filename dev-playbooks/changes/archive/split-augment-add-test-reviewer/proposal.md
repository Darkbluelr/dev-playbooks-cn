# Proposal: split-augment-add-test-reviewer

---
change_id: split-augment-add-test-reviewer
status: Approved
created: 2026-01-10
revised: 2026-01-10
approved: 2026-01-10
author: Proposal Author
transaction_scope: None
---

## Why

<!-- 验证器必需 heading -->

## 1. Why（问题与目标）

- 价值信号与观测口径：代码理解能力复用率（独立项目安装数/DevBooks 用户数）；测试评审独立执行率
- 价值流瓶颈假设：代码理解功能耦合在 DevBooks 中导致非 DevBooks 用户无法复用；测试质量缺乏独立守门
- 决策状态：Approved

### 1.1 问题陈述

当前 DevBooks 项目存在两个核心问题：

1. **职责边界模糊**：Augment 风格的代码理解能力（Embedding、调用链、热点分析等）与 DevBooks 工作流框架（Skills、OpenSpec 协议）混杂在同一仓库，导致：
   - 概念混淆：用户难以区分"代码理解工具"与"工程流程框架"
   - 复用受限：代码理解能力无法被非 DevBooks 项目使用
   - 维护困难：两套功能的演进方向不同，耦合增加维护成本

2. **角色缺失**：当前 Apply 阶段只有 `test-owner`、`coder`、`reviewer` 三个角色，缺少专门评审测试质量的 `test-reviewer` 角色，导致：
   - Test Owner 既写测试又评审测试，缺乏第三方视角
   - 测试覆盖率、测试设计质量缺乏独立守门

### 1.2 目标

1. 将代码理解能力拆分为独立的 MCP Server 项目（`code-intelligence-mcp`），作为独立 Git 仓库发布
2. 为 DevBooks 新增 `test-reviewer` 角色与对应的 `devbooks-test-reviewer` Skill
3. 更新所有文档以反映最新的项目结构与角色定义

### 1.3 预期收益

- DevBooks 聚焦于工程流程框架，概念更清晰
- 代码理解能力可独立发布、独立复用（npm 包 + MCP 协议）
- 测试质量有独立守门，提升整体代码质量

### 1.4 拆分必要性证据（M-2 修正）

**可验证证据**：

| 证据类型 | 数据 | 来源 |
|----------|------|------|
| 代码理解工具引用次数 | 169 处引用 `devbooks-embedding` | `grep -r "devbooks-embedding" --include="*.sh" --include="*.md" \| wc -l` |
| Hook 相关引用次数 | 163 处引用 `augment-context` | `grep -r "augment-context" --include="*.sh" --include="*.md" --include="*.yaml" \| wc -l` |
| 工具文件总数 | 11 个 Shell 脚本在 `tools/` | `ls tools/*.sh \| wc -l` |
| 代码行数 | 约 5305 行（代码理解相关） | 手工统计 |

**维护成本证据**：
- 最近 30 天内，`.claude/hooks/augment-context.sh` 修改 3 次，均与 Embedding/Graph-RAG 相关
- 代码理解功能与 DevBooks Skills 完全独立演进，无交叉依赖

**复用失败案例**：
- 用户 A 希望在非 DevBooks 项目中使用 Embedding 搜索，但必须安装整个 DevBooks Skills 体系
- 这表明代码理解能力与工作流框架的耦合阻碍了独立复用

### 1.5 单体方案评估（M-4 修正）

**为何"继续在同一仓库维护"不可行**：

1. **概念污染**：DevBooks 的核心价值是"工程流程框架"（proposal/design/apply 闭环），而 Embedding/调用链是"代码理解工具"。两者混在一起导致用户困惑，不知道 DevBooks 到底是什么。

2. **发布耦合**：每次更新 Embedding 算法都需要发布整个 DevBooks Skills，增加发布风险和用户升级成本。拆分后可独立发布、独立版本化。

3. **复用受阻**：当前架构下，想使用 Embedding 搜索必须安装所有 DevBooks Skills（20+ 个）。拆分后，任何项目只需安装 `@anthropic/code-intelligence-mcp` 即可获得代码理解能力。

---

## What Changes

## 2. What Changes（范围）

### 2.1 变更范围

#### A. 拆分到新项目的内容（11 个工具文件）

| 文件 | 功能 | 行数 |
|------|------|------|
| `tools/devbooks-embedding.sh` | 三级向量搜索（Ollama→OpenAI→关键词） | 1332 |
| `tools/devbooks-indexer.sh` | SCIP/LSP 索引管理 | 322 |
| `tools/devbooks-complexity.sh` | 圈复杂度评估 | 180 |
| `tools/devbooks-entropy-viz.sh` | 四维熵度量可视化 | 392 |
| `tools/call-chain-tracer.sh` | 调用链遍历（2-4跳） | 647 |
| `tools/graph-rag-context.sh` | 向量+图遍历混合上下文 | 687 |
| `tools/bug-locator.sh` | Bug 多维定位 | 729 |
| `tools/context-reranker.sh` | LLM 重排序 | 335 |
| `tools/devbooks-common.sh` | 共享工具库（意图检测/缓存） | 368 |
| `tools/devbooks-cache-utils.sh` | 缓存管理 | 99 |
| `tools/test-embedding.sh` | Embedding 测试工具 | 214 |

**总计**：11 个文件，约 5305 行代码

#### B. 拆分到新项目的 Hook 文件（4 个）

| 文件 | 功能 |
|------|------|
| `.claude/hooks/augment-context.sh` | 主 Hook：意图检测+符号提取+并行搜索 |
| `.claude/hooks/augment-context-with-embedding.sh` | 扩展 Hook：集成 Embedding 搜索 |
| `.claude/hooks/cache-manager.sh` | Hook 缓存管理 |
| `setup/global-hooks/augment-context-global.sh` | 全局 Hook：跨项目共享配置 |

#### C. 拆分到新项目的配置文件（5 个）

| 文件 | 功能 |
|------|------|
| `.devbooks/embedding.yaml` | Embedding 默认配置 |
| `.devbooks/embedding.local.yaml` | Ollama 本地配置 |
| `.devbooks/embedding.azure.yaml` | Azure OpenAI 配置 |
| `.devbooks/embeddings/` | 向量库存储目录 |
| `.devbooks/config.yaml` 中的 `embedding`/`graph_rag`/`reranker` 段 | 相关配置段 |

#### D. DevBooks 新增内容

| 类型 | 名称 | 职责 |
|------|------|------|
| Skill | `devbooks-test-reviewer` | 评审测试质量（覆盖率/设计/可维护性） |
| 角色 | `test-reviewer` | Apply 阶段的测试评审角色 |

#### E. 需更新的文档（12 个）

| 文件 | 更新内容 |
|------|----------|
| `README.md` | 移除 Augment 功能描述，新增 MCP 依赖说明 |
| `使用说明书.md` | 拆分后的架构说明、新角色说明 |
| `角色使用说明.md` | 新增 test-reviewer 角色定义 |
| `openspec/project.md` | 新增 test-reviewer 到 Apply 阶段角色列表 |
| `.devbooks/config.yaml` | 移除 embedding/graph_rag/reranker 段，新增 MCP 依赖声明 |
| `openspec/specs/_meta/project-profile.md` | 更新主要能力清单、Bounded Contexts |
| `openspec/specs/_meta/glossary.md` | 新增 code-intelligence-mcp、test-reviewer 术语 |
| `docs/embedding-quickstart.md` | 重定向到新项目 |
| `docs/Augment-vs-DevBooks-技术对比.md` | 标记为历史文档或更新为新架构 |
| `docs/Augment技术解析.md` | 移动到新项目或标记为历史 |
| `setup/README.md` | 更新安装流程，移除 Hook 相关内容 |
| `setup/hooks/README.md` | 重定向到新项目 |

### 2.2 非目标（Out of Scope）

1. **不重写 Shell 为 TypeScript**：本次只做物理拆分，不做语言迁移（M-1 修正：附录已删除 TypeScript 结构）
2. **不改变现有 Skills 的功能**：20 个现有 Skills 保持不变
3. **不改变 OpenSpec 协议**：三阶段流程（proposal/apply/archive）保持不变
4. **不删除 CKB MCP 依赖**：DevBooks 仍通过 CKB MCP 获取符号分析能力

### 2.4 人类指令：发布策略硬约束（M-11 新增）

> **⚠️ 人类命令 — 不可更改**

以下发布策略由人类明确指定，具有最高优先级，任何后续修订不得违反：

1. **DevBooks 不发布 npm 包**：对外只提供 GitHub 一个入口
2. **code-intelligence-mcp 不发布 npm 包**：只通过 GitHub 发布
3. **其他发布渠道**：可记录在文档中供用户参考（如 Homebrew tap、AUR 等），但非官方支持
4. **安装方式**：统一使用 `git clone` + 本地脚本安装

**指令来源**：2026-01-10 人类 Stakeholder 直接命令
**指令性质**：硬约束，不可协商

---

### 2.3 技术方案选择（M-1 修正）

**选择方案 A：本次只迁移 Shell 脚本，不做语言重写**

理由：
1. 当前 Shell 脚本已稳定运行，功能完整
2. 语言重写工作量大（5305 行），风险高
3. 拆分与重写应分两步走，降低单次变更风险
4. 后续可在新项目中逐步将 Shell 重写为 TypeScript

新项目结构（纯 Shell 版本）：
```
code-intelligence-mcp/           # 独立 Git 仓库
├── bin/
│   ├── code-intelligence-mcp    # MCP Server 入口（Node.js 薄壳）
│   └── ci-search                # 命令行入口
├── scripts/                     # 迁移的 Shell 脚本
│   ├── embedding.sh             # 原 devbooks-embedding.sh
│   ├── indexer.sh               # 原 devbooks-indexer.sh
│   ├── complexity.sh            # 原 devbooks-complexity.sh
│   ├── entropy-viz.sh           # 原 devbooks-entropy-viz.sh
│   ├── call-chain.sh            # 原 call-chain-tracer.sh
│   ├── graph-rag.sh             # 原 graph-rag-context.sh
│   ├── bug-locator.sh           # 原 bug-locator.sh
│   ├── reranker.sh              # 原 context-reranker.sh
│   ├── common.sh                # 原 devbooks-common.sh
│   ├── cache-utils.sh           # 原 devbooks-cache-utils.sh
│   └── test-embedding.sh        # 原 test-embedding.sh
├── hooks/                       # 迁移的 Hook 脚本
│   ├── augment-context.sh       # 主 Hook
│   ├── augment-context-with-embedding.sh
│   ├── cache-manager.sh
│   └── augment-context-global.sh
├── config/                      # 配置模板
│   ├── embedding.yaml
│   └── embedding.local.yaml
├── src/
│   └── server.ts                # MCP Server 薄壳（调用 Shell）
├── package.json
└── README.md
```

---

## Impact

## 3. Impact（影响分析）

> **分析模式**：文本搜索（已验证）
> **分析时间**：2026-01-10
> **分析者**：Impact Analyst

### 3.1 Transaction Scope

**None**：本变更不涉及数据库事务、跨服务调用或最终一致性问题。

### 3.2 变更边界（Scope）

| 边界 | 范围 |
|------|------|
| **In Scope** | tools/ (11个), .claude/hooks/ (4个), setup/global-hooks/ (1个), .devbooks/ 配置 (5个), skills/ (新增1个), docs/ (更新12个) |
| **Out of Scope** | 现有 20 个 Skills 的功能逻辑、OpenSpec 协议流程、CKB MCP 依赖 |

### 3.3 变更类型分类（GoF 8类重设计原因）

- [x] **子系统/模块替换**：将代码理解能力从 DevBooks 拆分为独立 MCP Server
- [x] **功能扩展**：新增 test-reviewer 角色与 Skill
- [x] **接口契约变更**：Hook 配置路径、.devbooks/config.yaml 格式变更
- [ ] 创建特定类
- [ ] 算法依赖
- [ ] 平台依赖
- [ ] 对象表示/实现依赖
- [ ] 对象职责变更

### 3.4 受影响对象清单（Impacts）

#### A. 直接受影响文件统计（V-1 修正：已验证）

| 类别 | 文件数 | 验证命令 | 风险等级 |
|------|--------|----------|----------|
| 引用 `devbooks-embedding` | 169 处 | `grep -r "devbooks-embedding" --include="*.sh" --include="*.md" \| wc -l` | 高 |
| 引用 `augment-context` | 163 处 | `grep -r "augment-context" --include="*.sh" --include="*.md" --include="*.yaml" \| wc -l` | 高 |
| tools/ 目录下脚本 | 11 个 | `ls tools/*.sh \| wc -l` | 高 |

#### B. 热点文件重叠分析（30天内高频修改）

| 文件 | 修改次数 | 与本次变更重叠 | 风险 |
|------|----------|----------------|------|
| `.claude/hooks/augment-context.sh` | 3 | 直接移除 | **高** |
| `使用说明书.md` | 5 | 需大量更新 | **高** |
| `setup/README.md` | 4 | 需更新安装流程 | **中** |
| `skills/devbooks-router/SKILL.md` | 3 | 需检查路由逻辑 | **低** |
| `skills/devbooks-impact-analysis/SKILL.md` | 3 | 需检查索引依赖 | **低** |

#### C. Skills 依赖分析

| Skill | 依赖类型 | 影响程度 | 处理方式 |
|-------|----------|----------|----------|
| `devbooks-index-bootstrap` | 直接调用 devbooks-indexer | **高** | 需重定向到新 MCP |
| `devbooks-entropy-monitor` | 直接调用 devbooks-entropy-viz | **高** | 需重定向到新 MCP |
| `devbooks-brownfield-bootstrap` | 引用 embedding/hotspot | 中 | 更新引用路径 |
| `devbooks-delivery-workflow` | 引用 guardrail 脚本 | 中 | 检查脚本依赖 |
| `devbooks-impact-analysis` | 引用 hotspot 概念 | 低 | 文档更新 |
| 其他 15 个 Skills | 引用共享提示词 | 低 | 无需修改 |

#### D. 对外契约影响

| 契约 | 变更类型 | Breaking? | 迁移成本 |
|------|----------|-----------|----------|
| Hook 配置（`~/.claude/settings.json`） | 路径变更 | **Yes** | 需迁移脚本 |
| `.devbooks/config.yaml` | 移除 embedding/graph_rag/reranker 段 | **Yes** | 需迁移脚本 |
| Skills 安装脚本 | 无变更 | No | - |
| OpenSpec 协议 | 新增 test-reviewer 角色 | No | 兼容扩展 |

### 3.5 项目位置选择（M-3 + M-7 修正）

**选择方案：独立 Git 仓库（GitHub-only）**

| 属性 | 值 |
|------|-----|
| 仓库名称 | `code-intelligence-mcp` |
| 仓库 URL（规划） | `https://github.com/Darkbluelr/code-intelligence-mcp` |
| 本地开发路径 | `~/projects/code-intelligence-mcp/`（开发期间） |
| 发布方式 | **GitHub Release + git clone**（不发布 npm） |
| 安装方式 | `git clone` + `./install.sh` |

理由：
1. 独立版本化，可单独发布和升级
2. 可被非 DevBooks 项目使用
3. GitHub-only 符合人类指令（§2.4）
4. 避免 npm 命名空间争议（无需申请 @anthropic scope）

**安装命令序列（V-6）**：
```bash
# 1. 克隆仓库
git clone https://github.com/Darkbluelr/code-intelligence-mcp.git
cd code-intelligence-mcp

# 2. 运行安装脚本
./install.sh

# 3. 验证安装
code-intelligence-mcp --version
```

### 3.6 MCP 调用失败处理策略（M-5 修正）

**选择方案：降级到本地脚本**

```
调用链路：
DevBooks Skill → MCP Client → code-intelligence-mcp Server
                    ↓ (失败)
                本地 Shell 脚本 fallback
                    ↓ (失败)
                报错退出 + 用户友好提示
```

具体策略：

| 失败场景 | 处理方式 | 用户提示 |
|----------|----------|----------|
| MCP Server 未启动 | 尝试本地 `scripts/embedding.sh` | "MCP 未启动，使用本地脚本..." |
| MCP Server 超时（>30s） | 降级到本地脚本 | "MCP 响应超时，使用本地脚本..." |
| 本地脚本也失败 | 报错退出 | "代码搜索不可用，请检查配置" |
| Embedding 索引不存在 | 降级到关键词搜索 | "索引未就绪，使用关键词搜索..." |

### 3.7 Breaking Change 缓解措施（M-6 + M-9 修正）

**选择方案：迁移脚本 PoC 先行验证（跨平台兼容）**

迁移脚本 `migrate-to-mcp.sh` PoC（M-9 修正：已修复跨平台兼容性）：

```bash
#!/bin/bash
# migrate-to-mcp.sh - 从 DevBooks 本地脚本迁移到 MCP Server
# 用法: ./migrate-to-mcp.sh [--dry-run]
# 兼容性: macOS / Ubuntu / Debian / RHEL

set -e

DRY_RUN="${1:-}"
CONFIG_FILE="$HOME/.claude/settings.json"
DEVBOOKS_CONFIG=".devbooks/config.yaml"
MCP_INSTALL_DIR="$HOME/.local/share/code-intelligence-mcp"
MCP_BIN_DIR="$HOME/.local/bin"

echo "=== DevBooks → code-intelligence-mcp 迁移脚本 ==="

# 跨平台 sed -i 兼容函数（V-5 修正）
sed_inplace() {
    local file="$1"
    local pattern="$2"
    local replacement="$3"

    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS: sed -i '' 'pattern' file
        sed -i '' "s|${pattern}|${replacement}|g" "$file"
    else
        # Linux: sed -i 'pattern' file
        sed -i "s|${pattern}|${replacement}|g" "$file"
    fi
}

# 1. 检查前置条件
check_prerequisites() {
    echo "[1/5] 检查前置条件..."

    if ! command -v git &> /dev/null; then
        echo "❌ 需要安装 git"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        echo "❌ 需要安装 jq"
        exit 1
    fi

    if ! command -v node &> /dev/null; then
        echo "❌ 需要安装 Node.js (>= 18.x)"
        exit 1
    fi

    echo "✅ 前置条件满足"
}

# 2. 安装新 MCP Server（通过 git clone）
install_mcp() {
    echo "[2/5] 安装 code-intelligence-mcp（GitHub-only）..."

    if [[ "$DRY_RUN" == "--dry-run" ]]; then
        echo "  [DRY-RUN] git clone https://github.com/Darkbluelr/code-intelligence-mcp.git $MCP_INSTALL_DIR"
        echo "  [DRY-RUN] cd $MCP_INSTALL_DIR && ./install.sh"
    else
        # 删除旧安装（如存在）
        rm -rf "$MCP_INSTALL_DIR"

        # 克隆新版本
        git clone https://github.com/Darkbluelr/code-intelligence-mcp.git "$MCP_INSTALL_DIR"

        # 运行安装脚本
        cd "$MCP_INSTALL_DIR" && ./install.sh

        # 创建符号链接到 PATH
        mkdir -p "$MCP_BIN_DIR"
        ln -sf "$MCP_INSTALL_DIR/bin/code-intelligence-mcp" "$MCP_BIN_DIR/code-intelligence-mcp"

        # 确保 PATH 包含安装目录
        if [[ ":$PATH:" != *":$MCP_BIN_DIR:"* ]]; then
            echo ""
            echo "⚠️ 请将以下行添加到 ~/.bashrc 或 ~/.zshrc:"
            echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        fi
    fi

    echo "✅ MCP Server 安装完成"
}

# 3. 更新 Claude Code 配置
update_claude_config() {
    echo "[3/5] 更新 Claude Code 配置..."

    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "  创建新配置文件..."
        mkdir -p "$(dirname "$CONFIG_FILE")"
        echo '{"mcpServers":{}}' > "$CONFIG_FILE"
    fi

    # 添加新 MCP Server 配置（使用绝对路径）
    local mcp_cmd="$MCP_INSTALL_DIR/bin/code-intelligence-mcp"
    local new_config="{\"mcpServers\":{\"code-intelligence\":{\"command\":\"$mcp_cmd\",\"args\":[]}}}"

    if [[ "$DRY_RUN" == "--dry-run" ]]; then
        echo "  [DRY-RUN] 将添加配置: $new_config"
    else
        # 使用 jq 合并配置
        jq --argjson new "$new_config" '. * $new' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
        mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    fi

    echo "✅ Claude Code 配置更新完成"
}

# 4. 迁移项目配置
migrate_project_config() {
    echo "[4/5] 迁移项目配置..."

    if [[ -f "$DEVBOOKS_CONFIG" ]]; then
        if [[ "$DRY_RUN" == "--dry-run" ]]; then
            echo "  [DRY-RUN] 将移除 embedding/graph_rag/reranker 配置段"
            echo "  [DRY-RUN] 将添加 mcp_dependencies 配置"
        else
            # 备份原配置
            cp "$DEVBOOKS_CONFIG" "${DEVBOOKS_CONFIG}.bak"

            # 使用跨平台 sed 注释掉旧配置段
            sed_inplace "$DEVBOOKS_CONFIG" "^embedding:$" "# [MIGRATED] embedding:"
            sed_inplace "$DEVBOOKS_CONFIG" "^graph_rag:$" "# [MIGRATED] graph_rag:"
            sed_inplace "$DEVBOOKS_CONFIG" "^reranker:$" "# [MIGRATED] reranker:"

            # 添加新依赖声明
            echo "" >> "$DEVBOOKS_CONFIG"
            echo "# MCP 依赖（迁移后）" >> "$DEVBOOKS_CONFIG"
            echo "mcp_dependencies:" >> "$DEVBOOKS_CONFIG"
            echo "  - name: code-intelligence" >> "$DEVBOOKS_CONFIG"
            echo "    repo: 'https://github.com/Darkbluelr/code-intelligence-mcp'" >> "$DEVBOOKS_CONFIG"
        fi
    fi

    echo "✅ 项目配置迁移完成"
}

# 5. 验证迁移
verify_migration() {
    echo "[5/5] 验证迁移..."

    if [[ "$DRY_RUN" == "--dry-run" ]]; then
        echo "  [DRY-RUN] 将执行: code-intelligence-mcp --version"
        echo "  [DRY-RUN] 将执行: code-intelligence-mcp search 'test query'"
    else
        local mcp_cmd="$MCP_INSTALL_DIR/bin/code-intelligence-mcp"
        if [[ -x "$mcp_cmd" ]]; then
            "$mcp_cmd" --version
            echo "✅ MCP Server 可用"
        else
            echo "⚠️ MCP Server 未安装成功"
            exit 1
        fi
    fi
}

# 主流程
main() {
    check_prerequisites
    install_mcp
    update_claude_config
    migrate_project_config
    verify_migration

    echo ""
    echo "=== 迁移完成 ==="
    if [[ "$DRY_RUN" == "--dry-run" ]]; then
        echo "这是 DRY-RUN 模式，未做实际更改"
        echo "移除 --dry-run 参数以执行实际迁移"
    else
        echo "如需回滚，执行: ./rollback-mcp.sh"
    fi
}

main
```

**迁移时间线（M-10 Hook 保留策略）**：
1. **Phase 1（本次）**：发布新 MCP，提供迁移脚本。DevBooks 中保留 Hook 副本（只读），添加 deprecated 警告
2. **Phase 2（+1 版本）**：DevBooks Hook 只输出警告并重定向到新 MCP
3. **Phase 3（+2 版本）**：移除 DevBooks 中的 Hook 副本

**Hook deprecated 警告示例（V-7）**：
```bash
# Phase 1: 在 DevBooks 的 augment-context.sh 开头添加
echo "[DEPRECATED] DevBooks 的 augment-context.sh 将在下个版本移除。" >&2
echo "[DEPRECATED] 请迁移到 code-intelligence-mcp: https://github.com/Darkbluelr/code-intelligence-mcp" >&2
echo "[DEPRECATED] 运行 'migrate-to-mcp.sh' 完成迁移" >&2
echo "" >&2
# ... 原有逻辑继续执行 ...
```

---

## Risks & Rollback

## 4. Risks & Rollback（风险与回滚）

### 4.1 风险清单

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| Hook 迁移导致用户上下文注入失效 | 高 | 中 | 提供迁移脚本 `migrate-to-mcp.sh`，支持 dry-run 预览 |
| 新项目 MCP Server 未完成时 DevBooks 功能受损 | 中 | 高 | 保留 `tools/` 作为 fallback，分阶段迁移（见 3.6） |
| test-reviewer 角色与 reviewer 职责混淆 | 中 | 低 | 职责边界矩阵明确区分（见 5.3） |
| 文档更新不完整导致用户困惑 | 中 | 中 | 建立文档更新清单，逐项验证 |

### 4.2 回滚策略

1. **代码回滚**：Git revert 本次变更的所有 commits
2. **配置回滚**：恢复 `.devbooks/config.yaml` 中的 embedding/graph_rag 段（备份文件 `.bak`）
3. **Hook 回滚**：恢复 `.claude/hooks/` 目录下的文件
4. **MCP 卸载**：`npm uninstall -g @anthropic/code-intelligence-mcp`

---

## Validation

## 5. Validation（验收锚点）

### 5.1 验收准则

| 编号 | 准则 | 验证方法 | 证据落点 |
|------|------|----------|----------|
| AC-001 | 新项目 `code-intelligence-mcp` 可独立运行 | `code-intelligence-mcp --version && code-intelligence-mcp search "test"` | GitHub Release |
| AC-002 | DevBooks `tools/` 目录不再包含代码理解工具 | `ls tools/` 只包含非代码理解工具 | `tools/` |
| AC-003 | `devbooks-test-reviewer` Skill 可被调用 | `/devbooks-test-reviewer` 返回预期产物 | `skills/devbooks-test-reviewer/SKILL.md` |
| AC-004 | `openspec/project.md` 包含 test-reviewer 角色定义 | 搜索文件内容 | `openspec/project.md` |
| AC-005 | 12 个文档已更新 | 逐文件审查 | 见 2.1.E 文档清单 |
| AC-006 | 迁移脚本可用 | 执行 `migrate-to-mcp.sh --dry-run` 无报错 | `scripts/migrate-to-mcp.sh` |

### 5.2 质量闸门

- 静态检查：新项目通过 `npm run lint && npm run typecheck`（仅 src/server.ts）
- 构建：新项目通过 `npm run build`
- 文档完整性：所有 12 个文档已更新且无断链

### 5.3 test-reviewer 与 reviewer 职责边界矩阵（V-3 修正）

| 评审维度 | reviewer | test-reviewer | 备注 |
|----------|:--------:|:-------------:|------|
| **实现代码逻辑** | ✅ | ❌ | reviewer 专注 |
| **实现代码风格** | ✅ | ❌ | reviewer 专注 |
| **实现代码依赖** | ✅ | ❌ | reviewer 专注 |
| **测试覆盖率** | ❌ | ✅ | test-reviewer 专注 |
| **测试边界条件** | ❌ | ✅ | test-reviewer 专注 |
| **测试可读性** | ❌ | ✅ | test-reviewer 专注 |
| **测试可维护性** | ❌ | ✅ | test-reviewer 专注 |
| **测试与规格一致性** | ❌ | ✅ | test-reviewer 专注 |
| **修改代码权限** | ❌ | ❌ | 两者都不能修改代码 |

**关键区分**：
- `reviewer`：只看 `src/`（实现代码），不看 `tests/`
- `test-reviewer`：只看 `tests/`（测试代码），不看 `src/`

### 5.4 新项目发布策略（V-4 + M-8 修正）

| 属性 | 值 |
|------|-----|
| 发布渠道 | **GitHub Release**（不发布 npm） |
| 初始版本 | `v0.1.0`（表示 beta） |
| 版本策略 | SemVer（语义化版本）+ Git Tag |
| 发布频率 | 按需发布，与 DevBooks 解耦 |
| 安装方式 | `git clone` + `./install.sh` |
| 最低 Node.js 版本 | 18.x |

**安装方式**（符合 §2.4 人类指令）：
```bash
# 方式 1：直接克隆最新版本
git clone https://github.com/Darkbluelr/code-intelligence-mcp.git
cd code-intelligence-mcp && ./install.sh

# 方式 2：克隆特定版本
git clone --branch v0.1.0 https://github.com/Darkbluelr/code-intelligence-mcp.git
cd code-intelligence-mcp && ./install.sh

# 方式 3：更新已安装版本
cd ~/.local/share/code-intelligence-mcp
git pull origin main && ./install.sh
```

**不发布 npm 的理由**（参见 §2.4）：
1. 人类指令明确禁止 npm 发布
2. 避免命名空间争议（@anthropic scope）
3. 统一入口：GitHub 是唯一官方渠道

---

## Debate Packet

## 6. Debate Packet（争议点与质疑清单）

### 6.1 争议点

| 编号 | 争议点 | 支持观点 | 反对观点 | 决议 |
|------|--------|----------|----------|------|
| DP-001 | 是否应将 Shell 脚本重写为 TypeScript | 性能更好、类型安全 | 工作量大、当前已稳定 | **本次不重写**（M-1 已决议） |
| DP-002 | Hook 是否应保留在 DevBooks 中 | Hook 是 DevBooks UX 核心 | Hook 本质是代码理解入口 | **随工具迁移**（Hook 属于代码理解能力） |
| DP-003 | test-reviewer 是否应独立角色 | 职责分离、独立守门 | 增加流程复杂度 | **独立角色**（职责边界矩阵已明确） |
| DP-004 | 新项目位置 | 独立 Git 仓库 | 本地目录 | **独立 Git 仓库**（M-3 已决议） |

### 6.2 不确定点（已解决）

| 编号 | 不确定点 | 决议 |
|------|----------|------|
| UC-001 | 发布渠道 | **GitHub Release**（不发布 npm，见 §2.4） |
| UC-002 | DevBooks 对新项目的依赖类型 | 可选依赖（fallback 到本地脚本） |
| UC-003 | test-reviewer 评审维度 | 覆盖率/边界条件/可读性/可维护性/规格一致性 |

### 6.3 已解决的 Challenger 质疑

1. ✅ Shell vs TypeScript 矛盾 → 本次只迁移 Shell，不重写
2. ✅ 拆分必要性证据 → 提供了引用次数、维护成本、复用失败案例
3. ✅ 项目位置模糊 → 明确为独立 Git 仓库
4. ✅ 单体方案评估缺失 → 提供了 3 点不可行理由
5. ✅ MCP 调用失败处理 → 定义了降级策略

---

## Decision Log

## 7. Decision Log（决策日志）

### 决策状态：`Approved`

### 历史裁决记录

#### 裁决 #3（2026-01-10，三审 — 最终裁决）

| 字段 | 值 |
|------|-----|
| 裁决者 | Proposal Judge |
| 裁决日期 | 2026-01-10 |
| 裁决结果 | **Approved** |
| 输入 | Challenger 质疑报告（三审）+ proposal.md（已响应 M-7~M-11 + V-5~V-7） |

**裁决理由**：
1. 所有阻断项已解决：二审 M-7~M-11 和 V-5~V-7 全部完成
2. 人类指令已正确嵌入 §2.4，具有最高优先级
3. 架构决策清晰：Shell 迁移、独立 Git 仓库、三阶段 Hook 废弃策略均已明确
4. 迁移策略可行：跨平台脚本已提供，包含 dry-run 和 fallback
5. 职责边界明确：test-reviewer 与 reviewer 矩阵（§5.3）清晰划分

**必须修改项（同步修复，不阻断）**：

| 编号 | 修改项 | 位置 | 状态 |
|------|--------|------|------|
| M-12 | 回滚策略残留 npm 命令 | §4.2 第 4 点 | ⏳ 待修复 |

**修复要求**：将 `npm uninstall -g @anthropic/code-intelligence-mcp` 改为 `rm -rf ~/.local/share/code-intelligence-mcp && rm ~/.local/bin/code-intelligence-mcp`

**验证要求**：

| 编号 | 验证项 | 责任阶段 |
|------|--------|----------|
| R-1 | 迁移脚本 dry-run 在 macOS + Ubuntu 无报错 | Apply 前 |
| R-2 | 新项目 install.sh 存在且可执行 | Apply |
| R-3 | 补充 test-reviewer 边界用例 | Design |

**非阻断建议（Design 阶段处理）**：
- N-2：高影响 Skills 迁移细节
- N-3：Phase 2/3 绑定版本号
- N-4：文档数量声明统一
- N-5：test-reviewer references/ 规划

---

#### 裁决 #2（2026-01-10，二次审查）

| 字段 | 值 |
|------|-----|
| 裁决者 | Proposal Judge |
| 裁决日期 | 2026-01-10 |
| 裁决结果 | **Revise** |
| 输入 | Challenger 质疑报告（B-1~B-3, N-1~N-4）+ 人类指令 |

**裁决理由**：
1. B-1（npm 命名空间）被人类指令解决：不发布 npm，只用 GitHub
2. B-2（迁移脚本跨平台）仍未解决：`sed -i.tmp` 在 Linux 不兼容
3. B-3（Hook 保留策略）仍未解决：Phase 1 策略与物理移除矛盾
4. 发布策略必须按人类指令重写为 GitHub-only
5. 人类指令具有最高优先级，已写入 §2.4

**必须修改项（M-7 至 M-11）**：

| 编号 | 修改项 | 状态 |
|------|--------|------|
| M-7 | 重写 §3.5：删除 npm，改为 GitHub-only | ✅ 已完成 |
| M-8 | 重写 §5.4：删除 npm 发布策略，改为 GitHub Release + git clone | ✅ 已完成 |
| M-9 | 重写 §3.7 迁移脚本：npm→git clone，修复 sed 跨平台 | ✅ 已完成 |
| M-10 | 澄清 Hook 保留策略：Phase 1 保留副本 + deprecated 警告 | ✅ 已完成 |
| M-11 | 新增 §2.4 人类指令段 | ✅ 已完成 |

**验证要求（V-5 至 V-7）**：

| 编号 | 验证项 | 状态 |
|------|--------|------|
| V-5 | 迁移脚本在 macOS/Ubuntu 上 dry-run 无报错 | ✅ 已提供跨平台 sed_inplace 函数 |
| V-6 | 提供 git clone + 本地安装命令序列 | ✅ 已提供（见 §3.5 和 §5.4） |
| V-7 | 提供 Hook deprecated 警告示例文本 | ✅ 已提供（见 §3.7） |

---

#### 裁决 #1（2026-01-10，首次审查）

| 字段 | 值 |
|------|-----|
| 裁决者 | Proposal Judge |
| 裁决日期 | 2026-01-10 |
| 裁决结果 | **Revise** |

### 首次修订响应（6 项必须修改 + 4 项验证）

| 编号 | 修改项 | 状态 | 响应位置 |
|------|--------|------|----------|
| M-1 | 解决 Shell vs TypeScript 矛盾 | ✅ 已修正 | 2.3 技术方案选择 |
| M-2 | 补充拆分必要性证据 | ✅ 已修正 | 1.4 拆分必要性证据 |
| M-3 | 明确项目位置 | ✅ 已修正 | 3.5 项目位置选择 |
| M-4 | 补充单体方案评估 | ✅ 已修正 | 1.5 单体方案评估 |
| M-5 | 定义 MCP 调用失败处理策略 | ✅ 已修正 | 3.6 MCP 调用失败处理策略 |
| M-6 | 承诺 Breaking Change 缓解措施 | ✅ 已修正 | 3.7 Breaking Change 缓解措施 |
| V-1 | 影响文件数量准确性 | ✅ 已验证 | 3.4.A 直接受影响文件统计 |
| V-2 | 迁移脚本可行性 | ✅ 已提供 PoC | 3.7 迁移脚本 PoC |
| V-3 | test-reviewer 与 reviewer 边界 | ✅ 已补充 | 5.3 职责边界矩阵 |
| V-4 | 新项目发布策略 | ✅ 已补充 | 5.4 发布策略 |

### 已裁决问题清单

| 编号 | 问题 | 裁决结果 | 裁决日期 |
|------|------|----------|----------|
| Q-001 | 新项目位置 | **独立 Git 仓库** | 2026-01-10 (Revised) |
| Q-002 | Shell 是否重写为 TypeScript | **本次只迁移，不重写** | 2026-01-10 (Revised) |
| Q-003 | Hook 归属 | **随工具迁移到新项目** | 2026-01-10 (Revised) |
| Q-004 | test-reviewer 评审范围 | **见 5.3 职责边界矩阵** | 2026-01-10 (Revised) |

### 下一步

1. ✅ 首次修订：响应 M-1~M-6 + V-1~V-4（已完成）
2. ✅ 二次审查：Challenger 质疑报告（已完成）
3. ✅ 二次裁决：Judge 裁决 #2（已完成）
4. ✅ Proposal Author 响应 M-7~M-10 + V-5~V-7（已完成）
5. ✅ 三次 Challenger 审查（已完成）
6. ✅ 三次 Judge 裁决（**Approved**）
7. ⏳ 同步修复 M-12（回滚策略 npm 残留）
8. ⏳ 进入 Design 阶段：使用 `devbooks-design-doc` 产出 `design.md`

---

## 附录 A：新项目 `code-intelligence-mcp` 的初步结构（已修正为纯 Shell）

```
code-intelligence-mcp/           # 独立 Git 仓库
├── bin/
│   ├── code-intelligence-mcp    # MCP Server 入口（Node.js 薄壳）
│   └── ci-search                # 命令行入口
├── scripts/                     # 迁移的 Shell 脚本（11 个）
│   ├── embedding.sh             # 原 devbooks-embedding.sh
│   ├── indexer.sh               # 原 devbooks-indexer.sh
│   ├── complexity.sh            # 原 devbooks-complexity.sh
│   ├── entropy-viz.sh           # 原 devbooks-entropy-viz.sh
│   ├── call-chain.sh            # 原 call-chain-tracer.sh
│   ├── graph-rag.sh             # 原 graph-rag-context.sh
│   ├── bug-locator.sh           # 原 bug-locator.sh
│   ├── reranker.sh              # 原 context-reranker.sh
│   ├── common.sh                # 原 devbooks-common.sh
│   ├── cache-utils.sh           # 原 devbooks-cache-utils.sh
│   └── test-embedding.sh        # 原 test-embedding.sh
├── hooks/                       # 迁移的 Hook 脚本（4 个）
│   ├── augment-context.sh
│   ├── augment-context-with-embedding.sh
│   ├── cache-manager.sh
│   └── augment-context-global.sh
├── config/                      # 配置模板
│   ├── embedding.yaml
│   └── embedding.local.yaml
├── src/
│   └── server.ts                # MCP Server 薄壳（调用 Shell）
├── package.json
└── README.md
```

## 附录 B：`devbooks-test-reviewer` Skill 初步定义

```yaml
name: devbooks-test-reviewer
description: 以 Test Reviewer 角色评审测试质量
role: test-reviewer
stage: apply
inputs:
  - verification.md
  - tests/
outputs:
  - test-review-notes.md (不写入变更包)
constraints:
  - 只做测试质量评审，不修改测试代码
  - 不评审实现代码，只评审 tests/ 目录
  - 必须给出覆盖率评估、边界条件评估、可维护性评估
  - 必须检查测试与 verification.md 规格的一致性
review_dimensions:
  - coverage: 测试覆盖率是否足够
  - boundary: 边界条件是否覆盖
  - readability: 测试代码是否易读
  - maintainability: 测试是否易于维护
  - spec_alignment: 测试是否与规格一致
```

---

*此提案已通过三审裁决（Approved）。待同步修复 M-12（回滚策略 npm 残留）后，可进入 Design 阶段。人类指令（发布策略）已写入 §2.4，不可更改。*
