# Design Doc: enhance-code-intelligence

---
version: 1.0
status: Draft
owner: Design Owner (AI)
created: 2026-01-08
last_verified: 2026-01-08
freshness_check: 3 Months
scope: Hook 热点算法 + CKB 索引引导
---

## ⚡ Acceptance Criteria（验收标准）

| AC-ID | 验收标准 | Pass/Fail 判据 | 验收方式 |
|-------|----------|----------------|----------|
| AC-001 | 热点输出包含复杂度分数 | Hook 输出格式包含 `complexity: N` 字段 | A（脚本输出检查） |
| AC-002 | 复杂度工具缺失时降级 | 无 radon/scc/gocyclo 环境下 Hook 正常运行，输出安装提示 | A（隔离环境测试） |
| AC-003 | 本地索引检测正确 | 存在 `index.scip` 或 `.git/ckb/` 时显示"索引可用"，否则显示引导提示 | A（文件存在性测试） |
| AC-004 | Hook 总执行时间 < 5s | `time ./augment-context-global.sh` < 5s（中型项目 100+ 文件） | A（性能测试） |
| AC-005 | 热点文件复杂度计算总耗时 < 5s | 5 个热点文件 × 1s/文件 = 5s 最大 | A（性能基线测试） |

---

## ⚡ Goals / Non-goals / Red Lines

### Goals（本次目标）

1. **热点算法增强**：将热点计算从纯频率 (`Freq`) 升级为频率 × 复杂度 (`Freq × Complexity`)
2. **CKB 索引引导**：Hook 检测本地索引文件，不存在时输出引导提示

### Non-goals（不做）

1. 意图分类与动态 Token 预算（移至 `enhance-context-engine`）
2. 依赖卫士功能（移至 `add-dependency-guard`）
3. Embedding 语义搜索优化（移至 `enhance-embedding`）
4. SCIP 索引自动生成（与 Hook 同步架构冲突）
5. Hook 内调用 MCP 服务（违反纯函数约束）

### Red Lines（不可破约束）

1. **Hook 必须是纯函数或本地 I/O**：禁止网络调用、禁止 MCP 调用
2. **向后兼容**：现有 Hook 输出格式必须兼容，新字段为扩展
3. **性能不退化**：Hook 总执行时间 ≤ 5s
4. **工具缺失不阻塞**：复杂度工具不存在时必须降级，不得报错退出

---

## 执行摘要

DevBooks 当前热点算法仅使用变更频率（`git commit count`），缺失复杂度维度，导致高频但简单的文件被过度关注。本设计通过集成圈复杂度计算（radon/scc/gocyclo），将热点算法升级为 `Freq × Complexity`，同时添加 CKB 索引检测以引导用户启用图分析能力。

---

## Problem Context（问题背景）

### 为什么要解决

根据 `docs/Augment-vs-DevBooks-技术对比.md` 分析：
- Augment 热点算法：`Hotspot = Freq × Complexity`
- DevBooks 当前：`Hotspot = Freq`（仅频率）

单一频率指标的问题：
1. 高频修改的配置文件被误判为热点
2. 低频但高复杂度的核心模块被忽略
3. Bug 定位准确率约 60%，目标提升至 75%

### 若不解决的后果

- AI 上下文注入偏离真正的风险区域
- Bug 定位效率低于竞品（Augment）
- 用户体验差距持续扩大

---

## 价值链映射

```
Goal: 提升热点预测准确率至 75%
  ↓
阻碍: 缺失复杂度维度
  ↓
杠杆: 集成圈复杂度计算
  ↓
最小方案: 多工具适配 + 降级策略 + 本地索引检测
```

---

## 设计原则

### 变化点识别（Variation Points）

| 变化点 | 可能的变化 | 封装策略 |
|--------|-----------|----------|
| 复杂度工具 | 新工具出现/旧工具停更 | 通过 `case` 语句隔离，易于添加新分支 |
| 输出格式 | 不同工具输出格式不同 | 统一化函数 `get_complexity()` 封装 |
| 索引文件位置 | CKB/SCIP 路径可能变化 | 配置文件化（`.devbooks/config.yaml`） |
| 超时阈值 | 可能需要调整 | 配置项 `hotspot_limit` 和超时值 |

---

## 目标架构

### Bounded Context

```
[augment-context-global.sh]
    ├── 热点计算模块（修改）
    │   ├── git_commit_count()  ← 现有
    │   └── get_complexity()    ← 新增（调用外部工具）
    ├── 索引检测模块（新增）
    │   └── check_index_local()
    └── 输出格式化模块（扩展）

[tools/devbooks-complexity.sh]（新增）
    └── 独立的复杂度计算工具
```

### 依赖方向

```
augment-context-global.sh
    ↓ (调用)
devbooks-complexity.sh
    ↓ (调用，可选)
radon / scc / gocyclo (外部工具，可缺失)
```

### C4 Delta

**新增元素**：
- Component: `tools/devbooks-complexity.sh` - 复杂度计算工具

**修改元素**：
- Component: `setup/global-hooks/augment-context-global.sh` - 热点算法升级
- Component: `skills/devbooks-index-bootstrap/SKILL.md` - 引导说明完善
- Config: `.devbooks/config.yaml` - 新增功能开关

---

## 领域模型（Domain Model）

### Data Model

| 对象 | 类型 | 说明 |
|------|------|------|
| `HotspotScore` | @ValueObject | `{file: string, freq: int, complexity: int, score: int}` |
| `IndexStatus` | @ValueObject | `{type: 'scip'|'ckb'|'embedding', available: bool}` |
| `ComplexityResult` | @ValueObject | `{file: string, score: int, tool: string|null}` |

### Business Rules

| BR-ID | 规则 | 触发条件 | 约束 | 违反行为 |
|-------|------|----------|------|----------|
| BR-001 | 热点分数计算 | 热点文件列表生成时 | `score = freq × complexity` | 无（必须执行） |
| BR-002 | 复杂度降级 | 工具不存在或超时 | 使用默认值 `1` | 输出安装提示 |
| BR-003 | 热点数量限制 | 复杂度计算时 | 最多 5 个文件 | 跳过第 6+ 个 |
| BR-004 | 单文件超时 | 复杂度计算时 | ≤ 1s/文件 | 超时返回默认值 `1` |

### Invariants

- `[Invariant]` 热点分数 ≥ 0（freq ≥ 0, complexity ≥ 1）
- `[Invariant]` Hook 执行不阻塞主流程（超时/错误均降级处理）
- `[Invariant]` 输出格式向后兼容（新字段为扩展，不破坏现有解析）

---

## 核心数据与事件契约

### Hook 输出格式扩展

**现有格式**：
```
🔥 热点文件：
  🔥 file1.py (5 changes)
  🔥 file2.ts (3 changes)
```

**扩展格式**（向后兼容）：
```
🔥 热点文件：
  🔥 file1.py (5 changes, complexity: 12, score: 60)
  🔥 file2.ts (3 changes, complexity: 8, score: 24)
```

### 配置项契约

```yaml
# .devbooks/config.yaml 扩展
features:
  complexity_weighted_hotspot: true  # 默认 true
  ckb_status_hint: true              # 默认 true
  hotspot_limit: 5                   # 默认 5

ckb:
  index_hint_enabled: true
  index_file_paths:
    - index.scip
    - .git/ckb/
    - .devbooks/embeddings/index.tsv
```

**兼容策略**：配置项不存在时使用默认值，不报错

---

## 关键机制

### 复杂度工具适配

| 语言 | 工具 | 输出统一化 |
|------|------|-----------|
| Python (.py) | radon | `grep -oP '(?<=\()[0-9.]+(?=\))' \| sort -rn \| head -1` |
| JS/TS/Go/通用 | scc | `jq -r '.[0].Complexity // 1'` |
| Go (.go) | gocyclo | `awk '{print $1}' \| sort -rn \| head -1` |
| 其他 | scc (降级) | 同上 |

### 降级策略

```
1. 检测工具可用性（command -v）
2. 工具不存在 → 输出安装提示，返回 complexity=1
3. 工具超时（>1s） → 返回 complexity=1
4. 解析失败 → 返回 complexity=1
```

### 索引检测机制

```
1. 检查 $CWD/index.scip（SCIP 索引）
2. 检查 $CWD/.git/ckb/（CKB 本地缓存）
3. 检查 $CWD/.devbooks/embeddings/index.tsv（Embedding 索引）
4. 任一存在 → 输出"索引可用"
5. 全部不存在 → 输出引导提示
```

---

## Testability & Seams（可测试性与接缝）

### Seams（测试接缝）

- `get_complexity()` 函数可独立测试（输入文件路径，输出数字）
- `check_index_local()` 函数可独立测试（输入目录，输出状态）
- 外部工具调用通过环境变量可 Mock（如 `COMPLEXITY_TOOL_OVERRIDE`）

### Pinch Points（汇点）

- `augment-context-global.sh` 主函数：热点生成 + 索引检测汇聚点
- `get_complexity()` 函数：工具调用 + 格式统一汇聚点

### 依赖隔离

- 外部工具（radon/scc/gocyclo）：通过 `command -v` 检测，缺失时降级
- 文件系统：直接访问，无需隔离
- 无网络依赖、无 MCP 依赖

---

## 风险与降级策略

| 风险 | 概率 | 降级路径 |
|------|------|----------|
| 复杂度工具缺失 | 中 | 返回 `1`，输出安装提示 |
| 工具执行超时 | 低 | `timeout 1s` 后返回 `1` |
| macOS grep 不支持 `-P` | 中 | 使用 `sed` 或检测 `ggrep` |
| 配置文件不存在 | 低 | 使用硬编码默认值 |

---

## ⚡ DoD 完成定义（Definition of Done）

### 必须通过的闸门

| 闸门 | 命令 | 通过标准 |
|------|------|----------|
| 脚本语法检查 | `shellcheck tools/*.sh setup/global-hooks/*.sh` | 无 Error |
| Hook 执行时间 | `time ./augment-context-global.sh` | < 5s |
| 功能回归 | 现有 Hook 输出格式兼容 | 全部通过 |

### 必须产出的证据

| 证据 | 落点 | 内容 |
|------|------|------|
| 热点输出示例 | `evidence/hotspot-output.log` | 包含 complexity 字段的输出 |
| 降级测试 | `evidence/fallback.log` | 无工具环境的运行结果 |
| 索引引导 | `evidence/ckb-hint.log` | 无索引时的提示输出 |
| 性能基线 | `evidence/performance-baseline.log` | 5 文件复杂度计算耗时 |

### AC 交叉引用

- AC-001 ↔ `evidence/hotspot-output.log`
- AC-002 ↔ `evidence/fallback.log`
- AC-003 ↔ `evidence/ckb-hint.log`
- AC-004, AC-005 ↔ `evidence/performance-baseline.log`

---

## Open Questions

1. **macOS 兼容性**：是否需要在 `SKILL.md` 中添加 GNU grep 安装指引？
2. **scc 输出稳定性**：scc JSON 格式在不同版本间是否稳定？需要验证。
3. **配置热加载**：未来是否需要支持配置文件变更后无需重启？

---

*文档版本*: 1.0
*生成时间*: 2026-01-08
*下一步*: 规格与契约（devbooks-spec-contract）或编码计划（devbooks-implementation-plan）
