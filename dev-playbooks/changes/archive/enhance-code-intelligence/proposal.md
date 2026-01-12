# Proposal: enhance-code-intelligence

> **Change ID**: `enhance-code-intelligence`
> **状态**: Approved
> **创建日期**: 2026-01-08
> **完成日期**: 2026-01-09
> **作者**: Proposal Author (AI)
> **裁决历史**: v1.0 Revise → v2.0 Revise → v3.0 Approved

---

## Why

### 问题陈述

根据 `docs/Augment-vs-DevBooks-技术对比.md` 的深度分析，DevBooks 当前代码智能能力约为 Augment Code 的 25-30%。**本次变更聚焦最高 ROI 的两项改进**：

| 维度 | Augment Code | DevBooks 当前 | 本次改进 |
|------|-------------|---------------|----------|
| 热点算法 | `Freq × Complexity` | 仅 `Freq` | **本次目标** |
| CKB 图能力 | 默认启用 | 需手动索引 | **本次目标** |
| 上下文注入 | 智能子图检索 | Hook 静态注入 | 后续变更 |
| Bug 定位 | 执行路径追踪 | 符号搜索 | 后续变更 |

### 目标（收缩后）

**本次目标**：实现热点算法增强 + CKB 索引引导，将代码智能能力提升至 **35-40%**

**具体可验证目标**（2 项）：
1. 热点算法集成圈复杂度加权：`Hotspot = Freq × Complexity`
2. CKB 索引引导：Hook 检测本地索引文件不存在时提示用户运行 `devbooks-index-bootstrap`

**移至后续变更**（4 项）：
- 意图分类与动态 Token 预算 → `enhance-context-engine`
- 依赖卫士功能 → `add-dependency-guard`
- Embedding 语义搜索优化 → `enhance-embedding`
- 上下文引擎升级 → `enhance-context-engine`

---

## What Changes

### 2.1 范围内（In Scope）

#### 2.1.1 热点算法增强

**当前实现**（证据：`docs/Augment-vs-DevBooks-技术对比.md:233-234`）：
```python
def devbooks_hotspot(file):
    change_freq = git_commit_count(file, days=30)
    return change_freq  # 缺失复杂度维度
```

**目标实现**：
```python
def enhanced_hotspot(file):
    change_freq = git_commit_count(file, days=30)  # 保持 30 天窗口
    complexity = get_complexity(file)  # 调用外部工具
    return change_freq * complexity
```

**技术方案**：

1. **多语言复杂度工具适配**（D-001 已裁决：Approved）：

   | 语言 | 工具 | 安装方式 | 维护状态 |
   |------|------|----------|----------|
   | Python | radon | `pip install radon` | 活跃 |
   | JavaScript/TypeScript | scc | `brew install scc` 或下载二进制 | 活跃 |
   | Go | gocyclo | `go install github.com/fzipp/gocyclo/cmd/gocyclo@latest` | 活跃 |
   | 通用（降级） | scc | `brew install scc` | 活跃 |

   > **注**：`escomplex` 已于 2018 年停止维护，替换为通用工具 `scc`（Sloc Cloc and Code）

2. **输出格式统一化**：

   不同工具的输出格式不一致，需统一为 `(filename, score)` 格式：

   ```bash
   # radon 输出示例（Python）
   # src/main.py
   #     F 10:0 main - A (5)
   # 统一化：提取最大复杂度
   radon cc "$file" -a -nc | grep -oP '(?<=\()[0-9.]+(?=\))' | sort -rn | head -1

   # scc 输出示例（通用）
   # 统一化：使用 Complexity 列
   scc "$file" --format json | jq '.[] | .Complexity'

   # gocyclo 输出示例（Go）
   # 5 main main.go:10:1
   # 统一化：提取第一列
   gocyclo "$file" | awk '{print $1}' | sort -rn | head -1
   ```

   **统一化函数**：
   ```bash
   get_complexity() {
       local file="$1"
       local ext="${file##*.}"
       local score=1  # 默认值

       case "$ext" in
           py)
               if command -v radon &>/dev/null; then
                   score=$(timeout 1s radon cc "$file" -a -nc 2>/dev/null | \
                           grep -oP '(?<=\()[0-9.]+(?=\))' | sort -rn | head -1)
               fi
               ;;
           js|ts|tsx|jsx|go|java|rs|c|cpp)
               if command -v scc &>/dev/null; then
                   score=$(timeout 1s scc "$file" --format json 2>/dev/null | \
                           jq -r '.[0].Complexity // 1')
               fi
               ;;
       esac

       echo "${score:-1}"
   }
   ```

3. **降级策略**（工具缺失时）：
   ```bash
   # 检测工具可用性并输出安装提示
   check_complexity_tools() {
       local has_tool=false
       if command -v radon &>/dev/null; then has_tool=true; fi
       if command -v scc &>/dev/null; then has_tool=true; fi
       if command -v gocyclo &>/dev/null; then has_tool=true; fi

       if [[ "$has_tool" == "false" ]]; then
           echo "💡 提示：安装复杂度工具可增强热点预测准确率"
           echo "   Python: pip install radon"
           echo "   通用:   brew install scc"
           echo "   Go:     go install github.com/fzipp/gocyclo/cmd/gocyclo@latest"
       fi
   }
   ```

4. **性能保证**：
   - 复杂度计算仅针对 **Top 5** 热点文件（避免超时）
   - 单文件复杂度计算超时 **1s** 则跳过（Bash `timeout` 最小粒度）
   - 总计算时间控制在 **5s** 内（5 文件 × 1s = 5s 最大）
   - 并行计算优化（后续版本）

**涉及文件**（本节 2 个，总计见附录 A）：
1. `setup/global-hooks/augment-context-global.sh` - 热点算法升级
2. `tools/devbooks-complexity.sh` - 新增复杂度计算工具

#### 2.1.2 CKB 索引引导

**当前状态**：CKB MCP 工具已集成，但 SCIP 索引需手动生成，用户不知道如何启用

**目标**（D-003 已裁决：方案 B - 手动触发，本地检测）：
1. Hook 启动时检测**本地索引文件**是否存在（纯本地 I/O，无 MCP 调用）
2. 若索引文件不存在，输出提示信息引导用户
3. 不自动生成索引，避免阻塞对话

**实现方式**（纯本地文件检测，符合 Hook 纯函数约束）：
```bash
# 检测本地索引文件（不调用 MCP）
check_index_local() {
    local status=""
    local has_index=false

    # 检查 SCIP 索引
    if [ -f "$CWD/index.scip" ]; then
        status="✅ SCIP 索引可用"
        has_index=true
    fi

    # 检查 CKB 本地缓存
    if [ -d "$CWD/.git/ckb" ]; then
        status="✅ CKB 索引可用"
        has_index=true
    fi

    # 检查 Embedding 索引
    if [ -f "$CWD/.devbooks/embeddings/index.tsv" ]; then
        status="✅ 语义索引可用"
        has_index=true
    fi

    # 无索引时输出提示
    if [[ "$has_index" == "false" ]]; then
        echo "💡 提示：可启用 CKB 加速代码分析"
        echo "   运行：/devbooks-index-bootstrap"
    else
        echo "$status"
    fi
}
```

> **重要**：本实现**不调用** `mcp__ckb__getStatus`，仅检查本地文件系统，符合"Hook 应为纯函数或本地 I/O"的最佳实践（B-001 修正）。

**涉及文件**（本节 2 个，总计见附录 A）：
1. `skills/devbooks-index-bootstrap/SKILL.md` - 完善引导说明
2. `.devbooks/config.yaml` - 添加 CKB 配置项

**配置项新增内容**：
```yaml
# .devbooks/config.yaml 新增内容
features:
  complexity_weighted_hotspot: true  # 启用复杂度加权热点
  ckb_status_hint: true              # 启用 CKB 索引提示
  hotspot_limit: 5                   # 热点文件数量限制

ckb:
  index_hint_enabled: true           # 索引引导开关
  index_file_paths:                  # 索引文件检测路径
    - index.scip
    - .git/ckb/
    - .devbooks/embeddings/index.tsv
```

### 2.2 范围外（Out of Scope - 本次变更）

1. **意图分类**：移至后续变更 `enhance-context-engine`（D-002 已裁决：Deferred）
2. **依赖卫士**：移至后续变更 `add-dependency-guard`（D-004 已裁决：本次仅本地脚本）
3. **Embedding 优化**：移至后续变更 `enhance-embedding`（D-005 已裁决：Deferred）
4. **影响分析多跳遍历**：现有实现已支持 `depth=2`，无需修改
5. **SCIP 索引自动生成**：与 Hook 同步架构冲突（D-003 已裁决：Rejected）
6. **MCP 调用检测索引状态**：违反 Hook 纯函数约束（B-001 修正）

---

## 3. Impact（影响分析）

### 3.1 Transaction Scope

**`Single-Process`**：所有变更均为本地脚本与配置，无跨服务事务，无 MCP 调用

### 3.2 对外契约影响

| 契约 | 变更类型 | 兼容性 |
|------|----------|--------|
| Hook 输出格式 | **扩展** | 向后兼容（新增复杂度字段） |
| `.devbooks/config.yaml` | **扩展** | 向后兼容（新增可选配置项） |
| CKB MCP 调用 | **无变更** | Hook 不调用 MCP |

### 3.3 模块影响矩阵

| 模块 | 影响类型 | 影响程度 | 证据 |
|------|----------|----------|------|
| `setup/global-hooks/` | **修改** | 中 | 热点算法 + 本地索引检测 |
| `tools/` | **新增** | 低 | 新增 1 个脚本 |
| `skills/devbooks-index-bootstrap/` | **修改** | 低 | 完善引导说明 |
| `.devbooks/` | **修改** | 低 | 扩展配置项 |

### 3.4 测试影响

1. **新增测试需求**：
   - 热点算法复杂度加权的单元测试
   - 复杂度工具降级策略测试
   - 本地索引检测测试
   - 输出格式统一化测试

2. **回归测试需求**：
   - Hook 输出格式兼容性测试

### 3.5 价值信号

| 信号 | 度量方式 | 基线 | 目标 |
|------|----------|------|------|
| 热点预测准确率 | 与实际 Bug 文件关联度 | 仅频率（约 60%） | 频率 × 复杂度（目标 75%） |
| CKB 使用率 | 启用图能力的用户比例 | 约 10%（手动配置） | 目标 40%（引导提示） |

---

## 4. Risks & Rollback（风险与回滚）

### 4.1 风险清单

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| **复杂度计算工具缺失** | 中 | 低 | 降级到纯频率算法，输出安装提示 |
| **复杂度计算超时** | 低 | 低 | 单文件 1s 超时，整体限制 5 个文件 |
| **本地索引检测失败** | 极低 | 极低 | 仅影响提示输出，不阻塞主流程 |
| **Hook 执行超时** | 低 | 中 | 5s 硬超时 + 降级策略（D-006 已裁决） |

### 4.2 回滚策略

1. **配置回滚**：`.devbooks/config.yaml` 新增配置项均有默认值
2. **脚本回滚**：`git revert` 即可回滚
3. **功能开关**：

```yaml
# .devbooks/config.yaml
features:
  complexity_weighted_hotspot: false  # 设为 false 禁用复杂度加权
  ckb_status_hint: false              # 设为 false 禁用 CKB 提示
```

---

## 5. Validation（验收锚点）

### 5.1 验收标准（Acceptance Criteria）

| AC-ID | 验收标准 | 验证方法 | 证据落点 |
|-------|----------|----------|----------|
| AC-001 | 热点算法输出包含复杂度分数 | 运行 Hook 检查输出格式 | `evidence/hotspot-output.log` |
| AC-002 | 复杂度工具缺失时降级并提示 | 在无 radon/scc 环境运行 | `evidence/fallback.log` |
| AC-003 | 本地索引不存在时输出引导提示 | 在无 `index.scip` 项目运行 | `evidence/ckb-hint.log` |
| AC-004 | Hook 执行时间 < 5s | 在中型项目实测 | `evidence/performance.log` |
| AC-005 | 5 个热点文件复杂度计算总耗时 < 5s | 在 100+ 文件项目实测 | `evidence/performance-baseline.log` |

### 5.2 质量闸门

| 闸门 | 命令/工具 | 通过标准 |
|------|-----------|----------|
| 脚本语法检查 | `shellcheck tools/*.sh setup/global-hooks/*.sh` | 无 Error |
| Hook 执行时间 | `time ./augment-context-global.sh` | < 5s |
| 功能回归 | 现有 Hook 输出格式兼容 | 全部通过 |

---

## 6. 技术可行性验证

### Q1: 为何不先实施"热点算法"单一改进，验证效果后再扩展？

**回答**：接受此建议。本次变更已收缩至 2 项核心改进：
1. 热点算法复杂度加权
2. CKB 索引引导提示（纯本地检测）

两者相互独立，可并行实施。意图分类、依赖卫士、Embedding 优化已移至后续独立变更。

### Q2: `devbooks-complexity.sh` 在 macOS/Linux/Windows Git Bash 的兼容性如何保证？

**回答**：
1. **工具检测**：使用 `command -v` 检测工具可用性，跨平台兼容
2. **降级策略**：工具缺失时降级到纯频率算法，不阻塞主流程
3. **安装引导**：输出平台特定的安装命令
4. **工具选型**：使用活跃维护的工具（radon、scc、gocyclo），替换停更的 `escomplex`

### Q3: Hook 执行超时（5s）时如何保证不阻塞？

**回答**：
1. **单文件超时**：使用 `timeout 1s` 控制单文件计算时间（Bash 最小粒度）
2. **文件数量限制**：仅计算 Top 5 热点文件（5 × 1s = 5s 最大）
3. **降级处理**：超时文件的复杂度默认为 1

```bash
# 超时保护实现
for file in $(get_top_hotspots 5); do
    complexity=$(timeout 1s get_complexity "$file" 2>/dev/null || echo "1")
    hotspot_scores["$file"]=$((freq * complexity))
done
```

### Q4: 意图分类的最坏情况延迟是多少？

**回答**：意图分类已移至后续变更（D-002 已裁决：Deferred），本次不实施。

### Q5: 4 个文件同时变更的回滚策略是什么？

**回答**：
1. **原子性**：所有变更在同一 Git 提交中完成
2. **回滚命令**：`git revert <commit-hash>` 一次性回滚全部
3. **功能开关**：即使代码已部署，可通过配置禁用新功能

---

## 7. Debate Packet（争议点与裁决）

### 7.1 已裁决争议点

| 编号 | 问题 | 裁决 | 说明 |
|------|------|------|------|
| D-001 | 复杂度计算工具选择 | ✅ Approved | 多工具适配 + 降级策略，替换停更的 escomplex |
| D-002 | 意图分类实现方式 | ⚠️ Deferred | 移至后续变更 |
| D-003 | SCIP 索引生成时机 | ✅ 方案 B | 手动触发，Hook 仅做本地文件检测（无 MCP 调用） |
| D-004 | 依赖卫士 CI 集成 | ⚠️ Deferred | 移至后续变更 |
| D-005 | Embedding 启用方式 | ⚠️ Deferred | 移至后续变更 |
| D-006 | Hook 超时策略 | ✅ Approved | 5s 硬超时 + 降级策略 |

### 7.2 无待决争议

所有争议点已在 v1.0/v2.0 裁决中解决，本版本无新增争议。

---

## 8. Decision Log（决策记录）

### 8.1 决策状态

**当前状态**：`Revised (v3.0)` - 待 Judge 确认

### 8.2 裁决历史

**2026-01-08 - Judge 初次裁决 (v1.0)**
- 裁决：`Revise`
- 阻断项：6 个（B-001 到 B-006）
- 要求：修正文件路径、收缩范围、补充可行性验证

**2026-01-08 - Author 修订 (v2.0)**
- 修复 B-001：文件路径已更正为 `SKILL.md`
- 修复 B-002：移除重复功能声明
- 修复 B-003：范围收缩至 4 个文件
- 修复 B-004：补充复杂度工具降级策略
- 修复 B-005：明确采用方案 B（手动触发）
- 修复 B-006：新增"技术可行性验证"章节

**2026-01-08 - Judge 二次裁决 (v2.0)**
- 裁决：`Revise`
- 阻断项：3 个（新 B-001、B-002、B-003）
- 非阻断项：2 个（N-001、N-002）
- 核心问题：
  1. Hook 中调用 MCP 工具违反纯函数约束（B-001）
  2. 复杂度工具选型存在维护性风险（B-002）
  3. 性能基线验证不足，超时声明不一致（B-003）

**2026-01-08 - Author 修订 (v3.0)**
- 修复 B-001：删除 MCP 调用，改为纯本地文件检测（2.1.2 节）
- 修复 B-002：替换 `escomplex` 为 `scc`，补充输出格式统一化（2.1.1 节）
- 修复 B-003：统一超时值为 1s，限制热点文件数为 5 个，补充 AC-005（2.1.1 节、5.1 节）
- 修复 N-001：明确说明涉及文件总数为 4 个（附录 A）
- 修复 N-002：统一热点时间窗口为 30 天（2.1.1 节伪代码）

### 8.3 验证完成情况

| 验证要求 | 状态 | 证据/说明 |
|----------|------|-----------|
| 文件路径验证 | ✅ 完成 | `ls -la skills/*/SKILL.md` 确认 |
| 范围收缩验证 | ✅ 完成 | 附录 A 文件数量 = 4 个 |
| MCP 调用移除 | ✅ 完成 | 2.1.2 节实现为纯本地文件检测 |
| 工具选型更新 | ✅ 完成 | 替换 escomplex 为 scc |
| 超时值统一 | ✅ 完成 | 单文件 1s，总计 5 个文件 |
| 性能基线验证 | 📝 待 Apply | AC-005 已加入验收标准 |

### 8.4 验证要求（Apply 阶段）

| 验证 ID | 验证内容 | 通过标准 | 证据落点 |
|---------|----------|----------|----------|
| V-001 | 性能基线验证 | Hook 总耗时 < 5s | `evidence/performance-baseline.log` |
| V-002 | 复杂度工具降级测试 | 无工具时降级成功 | `evidence/fallback.log` |
| V-003 | 输出格式统一性验证 | 所有工具输出统一 | `evidence/format-unified.log` |
| V-004 | Hook 超时保护验证 | 超时文件跳过不阻塞 | `evidence/timeout-handling.log` |

---

## 附录 A：文件变更清单

| 序号 | 文件路径 | 变更类型 | 说明 |
|------|----------|----------|------|
| 1 | `setup/global-hooks/augment-context-global.sh` | 修改 | 热点算法升级 + 本地索引检测 |
| 2 | `tools/devbooks-complexity.sh` | 新增 | 复杂度计算工具（多语言适配 + 格式统一化） |
| 3 | `skills/devbooks-index-bootstrap/SKILL.md` | 修改 | 完善引导说明 |
| 4 | `.devbooks/config.yaml` | 修改 | 新增功能开关与 CKB 配置项 |

**总计**：4 个文件（1 个新增，3 个修改）

---

## 附录 B：后续变更规划

| Change ID | 范围 | 优先级 | 依赖 |
|-----------|------|--------|------|
| `enhance-context-engine` | 意图分类 + 动态 Token 预算 | P1 | 本变更完成后 |
| `add-dependency-guard` | 依赖卫士本地脚本 | P2 | 无 |
| `enhance-embedding` | Embedding 引导启用 | P2 | 无 |
| `add-dependency-guard-ci` | 依赖卫士 CI 集成 | P3 | `add-dependency-guard` |

---

## 附录 C：技术对比参考

完整技术对比详见：
- `docs/Augment-vs-DevBooks-技术对比.md`
- `docs/Augment技术解析.md`

---

*文档版本*: 3.0 (Revised)
*生成时间*: 2026-01-08
*下一步*: 提交 Judge 确认或直接进入 Design 阶段 (`devbooks-design-doc`)
