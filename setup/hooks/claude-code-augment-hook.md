# Claude Code Augment Hook 配置指南

> 目标：让 Augment 风格的功能（图分析、热点感知、COD）在**每次对话**中自动激活，无需显式调用 Skill。

## 原理

通过 Claude Code 的 `hooks` 配置，在每次对话/工具调用时自动注入检查逻辑。

## 配置方法

将以下配置添加到 `~/.claude/settings.yaml`（全局）或项目的 `.claude/settings.yaml`：

```yaml
hooks:
  # 对话开始时自动检查项目状态
  PreToolUse:
    - matcher: ".*"
      hooks:
        - type: command
          command: |
            # 只在首次工具调用时执行（避免重复）
            MARKER="/tmp/devbooks-session-$(pwd | md5sum | cut -d' ' -f1)"
            if [ -f "$MARKER" ]; then
              exit 0
            fi
            touch "$MARKER"

            # 1. 检查 SCIP 索引
            if [ ! -f "index.scip" ]; then
              echo "⚠️ [DevBooks] SCIP 索引不存在，图分析功能降级"
              echo "   运行 'devbooks-index-bootstrap' 激活完整能力"
            else
              AGE=$(( ($(date +%s) - $(stat -f%m index.scip 2>/dev/null || stat -c%Y index.scip 2>/dev/null)) / 3600 ))
              if [ $AGE -gt 24 ]; then
                echo "⚠️ [DevBooks] SCIP 索引已过期 ${AGE}h，建议更新"
              fi
            fi

            # 2. 检查 COD 产物
            TRUTH_ROOT="specs"
            [ -d "openspec/specs" ] && TRUTH_ROOT="openspec/specs"
            if [ ! -f "$TRUTH_ROOT/architecture/hotspots.md" ]; then
              echo "ℹ️ [DevBooks] COD 产物不存在，运行 cod-update.sh 生成"
            fi

            # 3. 检查联邦配置
            if [ -f ".devbooks/federation.yaml" ]; then
              echo "ℹ️ [DevBooks] 检测到联邦配置，跨仓库分析可用"
            fi

  # 文件修改前自动检查热点
  Edit:
    - matcher: ".*"
      hooks:
        - type: command
          command: |
            FILE="$1"
            # 检查是否为热点文件（简化版：检查 30 天内修改次数）
            if [ -d ".git" ] && [ -f "$FILE" ]; then
              CHANGES=$(git log --since="30 days ago" --oneline -- "$FILE" 2>/dev/null | wc -l)
              if [ "$CHANGES" -gt 10 ]; then
                echo "🔴 [DevBooks] 热点警告：$FILE 近30天修改 $CHANGES 次"
                echo "   建议：增加测试覆盖，谨慎修改"
              elif [ "$CHANGES" -gt 5 ]; then
                echo "🟡 [DevBooks] 注意：$FILE 为中等热点（$CHANGES 次修改）"
              fi
            fi
```

## 效果

配置后，每次对话会自动：

1. **检查索引状态** → 提示是否需要生成/更新
2. **检查 COD 产物** → 提示是否需要运行 `cod-update.sh`
3. **检测联邦配置** → 告知跨仓库分析是否可用
4. **编辑文件前检查热点** → 对高频修改文件发出警告

## 进阶：自动路由到 Skill

如果想让 AI **自动选择 Skill**（而不只是提示），需要在项目的 `AGENTS.md` 或 `CLAUDE.md` 中添加路由规则：

```markdown
## 自动 Skill 路由（强制）

在处理任何代码相关请求前，必须：

1. 若 `index.scip` 存在，调用 `mcp__ckb__getStatus` 确认图分析可用
2. 若涉及修改代码，调用 `mcp__ckb__getHotspots` 检查热点
3. 根据请求类型自动选择：
   - 修复 Bug → `devbooks-impact-analysis` → `devbooks-coder`
   - 新功能 → `devbooks-router` → 完整闭环
   - 重构 → `devbooks-code-review` → `devbooks-coder`
```

## 局限性

1. **Hooks 不能强制 AI 行为** — 只能提供信息，AI 是否使用取决于其判断
2. **没有真正的"拦截"** — Claude Code 不支持在 AI 响应前插入强制逻辑
3. **需要用户安装** — 配置不会自动生效

## 与 Augment Code 的差距

| 能力 | Augment | DevBooks + Hooks |
|------|---------|------------------|
| 自动索引 | 后台持续 | Git 事件触发 |
| 无感激活 | 100% 自动 | ~70%（需安装 Hooks + AGENTS 规则）|
| 热点检查 | 内置 | 需 Hooks 配置 |
| 图分析 | 默认开启 | 需索引存在 |

**结论**：通过 Hooks + AGENTS 规则可以接近"无感"，但达不到 Augment 的"零配置"体验。
