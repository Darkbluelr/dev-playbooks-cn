# 编码计划：enhance-code-intelligence

---
maintainer: Planner (AI)
change_id: enhance-code-intelligence
design_doc: openspec/changes/enhance-code-intelligence/design.md
spec_delta: openspec/changes/enhance-code-intelligence/specs/global-hooks/spec.md
created: 2026-01-08
---

## 【模式选择】

**当前模式**: `主线计划模式`

---

## 主线计划区 (Main Plan Area)

### MP1 - 复杂度计算工具

**目的 (Why)**: 提供独立的复杂度计算能力，支持多语言、多工具适配与降级策略。

**交付物 (Deliverables)**:
- `tools/devbooks-complexity.sh`

**影响范围 (Files/Modules)**:
- 新增: `tools/devbooks-complexity.sh`

**验收标准 (Acceptance Criteria)**:
- [ ] 脚本接受文件路径参数，输出数字复杂度值
- [ ] Python 文件使用 radon，JS/TS/Go 文件使用 scc
- [ ] 工具缺失时返回默认值 `1` 并输出安装提示到 stderr
- [ ] 单文件计算超时 1s 时返回默认值 `1`
- [ ] `shellcheck tools/devbooks-complexity.sh` 无 Error
- Trace: AC-001, AC-002

**依赖 (Dependencies)**: 无

**风险 (Risks)**:
- macOS 默认 grep 不支持 `-P`，需检测并降级

---

#### MP1.1 - 工具检测函数

**子任务**: 实现 `check_complexity_tools()` 函数

**接口签名**:
```
check_complexity_tools() -> void
# 输出: 安装提示到 stderr（如有缺失工具）
# 副作用: 无
```

**行为边界**:
- 检测 radon、scc、gocyclo 可用性
- 全部缺失时输出安装提示
- 至少一个存在时不输出

**验收锚点**: CT-002（工具缺失提示测试）

---

#### MP1.2 - 统一复杂度函数

**子任务**: 实现 `get_complexity(file)` 函数

**接口签名**:
```
get_complexity(file: string) -> integer
# 输入: 文件绝对路径
# 输出: 复杂度分数（>=1）
# 副作用: 可能调用外部工具
```

**行为边界**:
- 根据文件扩展名选择工具
- 超时 1s 返回默认值 1
- 解析失败返回默认值 1
- 工具不存在返回默认值 1

**验收锚点**: CT-001（复杂度输出测试）

---

### MP2 - 热点算法升级

**目的 (Why)**: 将热点计算从纯频率升级为频率 × 复杂度。

**交付物 (Deliverables)**:
- 修改 `setup/global-hooks/augment-context-global.sh`

**影响范围 (Files/Modules)**:
- 修改: `setup/global-hooks/augment-context-global.sh`

**验收标准 (Acceptance Criteria)**:
- [ ] 热点输出格式包含 `complexity: N` 字段
- [ ] 热点分数 = freq × complexity
- [ ] 最多计算 5 个热点文件的复杂度
- [ ] 总执行时间 < 5s
- [ ] 现有输出格式向后兼容
- Trace: AC-001, AC-004, AC-005

**依赖 (Dependencies)**: MP1 完成

**风险 (Risks)**:
- 输出格式变更可能影响下游解析（已确认向后兼容）

---

#### MP2.1 - 集成复杂度计算

**子任务**: 在热点计算循环中调用 `get_complexity()`

**行为边界**:
- 仅对 Top 5 热点文件计算复杂度
- 超时/失败时使用默认值 1
- 保持原有频率计算逻辑不变

**验收锚点**: AC-001, AC-005

---

#### MP2.2 - 输出格式扩展

**子任务**: 扩展热点输出格式

**输出格式变更**:
```
# 旧格式
🔥 file.py (5 changes)

# 新格式（向后兼容）
🔥 file.py (5 changes, complexity: 12, score: 60)
```

**验收锚点**: CT-001

---

### MP3 - CKB 索引引导

**目的 (Why)**: 帮助用户发现并启用 CKB 图分析能力。

**交付物 (Deliverables)**:
- 修改 `setup/global-hooks/augment-context-global.sh`
- 修改 `skills/devbooks-index-bootstrap/SKILL.md`

**影响范围 (Files/Modules)**:
- 修改: `setup/global-hooks/augment-context-global.sh`
- 修改: `skills/devbooks-index-bootstrap/SKILL.md`

**验收标准 (Acceptance Criteria)**:
- [ ] 索引存在时输出"索引可用"
- [ ] 索引不存在时输出引导提示
- [ ] 检测为纯本地文件 I/O（无 MCP 调用）
- [ ] 不阻塞 Hook 主流程
- Trace: AC-003

**依赖 (Dependencies)**: 无（可与 MP2 并行）

**风险 (Risks)**:
- 索引文件路径可能因 CKB 版本变化而变更

---

#### MP3.1 - 本地索引检测函数

**子任务**: 实现 `check_index_local()` 函数

**接口签名**:
```
check_index_local() -> void
# 输出: 状态信息到 stdout
# 副作用: 无
```

**行为边界**:
- 检查 `$CWD/index.scip`
- 检查 `$CWD/.git/ckb/`
- 检查 `$CWD/.devbooks/embeddings/index.tsv`
- 任一存在 → 输出状态
- 全部不存在 → 输出引导提示

**验收锚点**: CT-003, AC-003

---

#### MP3.2 - SKILL.md 引导说明

**子任务**: 完善 `devbooks-index-bootstrap/SKILL.md` 中的引导说明

**交付物**:
- 添加 CKB 索引生成说明
- 添加检测路径说明
- 添加常见问题解答

**验收锚点**: 文档审查

---

### MP4 - 配置文件扩展

**目的 (Why)**: 提供功能开关与可配置参数。

**交付物 (Deliverables)**:
- 修改 `.devbooks/config.yaml`

**影响范围 (Files/Modules)**:
- 修改: `.devbooks/config.yaml`

**验收标准 (Acceptance Criteria)**:
- [ ] 新增 `features.complexity_weighted_hotspot` 配置项
- [ ] 新增 `features.ckb_status_hint` 配置项
- [ ] 新增 `features.hotspot_limit` 配置项
- [ ] 配置项不存在时使用默认值
- Trace: 设计文档 §核心数据与事件契约

**依赖 (Dependencies)**: 无（可与 MP1-3 并行）

**风险 (Risks)**:
- 配置解析逻辑需要在 Hook 中实现

---

### MP5 - 证据收集与验收

**目的 (Why)**: 收集验收证据，确认所有 AC 通过。

**交付物 (Deliverables)**:
- `evidence/hotspot-output.log`
- `evidence/fallback.log`
- `evidence/ckb-hint.log`
- `evidence/performance-baseline.log`

**影响范围 (Files/Modules)**:
- 新增: `openspec/changes/enhance-code-intelligence/evidence/` 目录

**验收标准 (Acceptance Criteria)**:
- [ ] AC-001 证据: 热点输出包含 complexity 字段
- [ ] AC-002 证据: 无工具环境的降级输出
- [ ] AC-003 证据: 索引引导提示输出
- [ ] AC-004/005 证据: 性能基线数据

**依赖 (Dependencies)**: MP1-4 全部完成

---

## 临时计划区 (Temporary Plan Area)

*当前无临时任务*

---

## 计划细化区

### Scope & Non-goals

**In Scope**:
- 热点算法复杂度加权
- CKB 索引本地检测与引导
- 配置文件扩展

**Non-goals**:
- MCP 调用（禁止）
- SCIP 索引自动生成
- 意图分类
- 依赖卫士

### Architecture Delta

**新增模块**:
- `tools/devbooks-complexity.sh` - 独立的复杂度计算工具

**修改模块**:
- `setup/global-hooks/augment-context-global.sh` - 热点算法 + 索引检测

**依赖方向**:
```
augment-context-global.sh
    ↓ (调用)
devbooks-complexity.sh
    ↓ (可选调用)
radon / scc / gocyclo
```

### Data Contracts

| 契约 | 版本策略 | 兼容窗口 |
|------|----------|----------|
| Hook 输出格式 | 扩展字段 | 无限（向后兼容） |
| config.yaml | 可选配置项 | 无限（有默认值） |

### Milestones

| Phase | 任务 | 验收口径 |
|-------|------|----------|
| Phase 1 | MP1 + MP4 | 复杂度工具可用，配置就绪 |
| Phase 2 | MP2 + MP3 | 热点算法升级，索引引导就绪 |
| Phase 3 | MP5 | 证据收集，全部 AC 通过 |

### Work Breakdown

**可并行点**:
- MP1 (复杂度工具) ∥ MP3 (索引引导) ∥ MP4 (配置)

**依赖关系**:
- MP2 (热点升级) → 依赖 MP1 完成
- MP5 (证据收集) → 依赖 MP1-4 全部完成

**PR 切分建议**:
1. PR#1: MP1 + MP4（复杂度工具 + 配置）
2. PR#2: MP2 + MP3（热点升级 + 索引引导）
3. PR#3: MP5（证据收集，可合并到 PR#2）

### Quality Gates

| 闸门 | 命令 | 通过标准 |
|------|------|----------|
| ShellCheck | `shellcheck tools/*.sh setup/global-hooks/*.sh` | 无 Error |
| 性能测试 | `time ./augment-context-global.sh` | < 5s |
| 功能回归 | 现有输出格式兼容 | 通过 |

### Algorithm Spec - 热点分数计算

**Inputs**:
- `files[]`: 项目文件列表
- `days`: 时间窗口（默认 30）
- `limit`: 热点数量限制（默认 5）

**Outputs**:
- `hotspots[]`: `{file, freq, complexity, score}`

**Invariants**:
- `score = freq × complexity`
- `complexity >= 1`
- `len(hotspots) <= limit`

**核心流程**:
```
1. GET git log within `days` window
2. COUNT changes per file -> freq_map
3. SORT by freq DESC
4. FOR EACH top `limit` files:
   a. CALL get_complexity(file)
   b. IF timeout OR error THEN complexity = 1
   c. score = freq × complexity
5. OUTPUT sorted by score DESC
```

**复杂度上限**:
- 时间: O(limit × timeout) = O(5 × 1s) = 5s 最大
- 空间: O(n) 文件数

**边界条件与测试要点**:
1. 无 git 历史 → 跳过热点计算
2. 复杂度工具全部缺失 → 所有 complexity = 1
3. 文件数 < limit → 输出实际文件数
4. 单文件超时 → 该文件 complexity = 1，继续下一个
5. 空项目 → 无热点输出

### Risks & Edge Cases

| 风险 | 概率 | 降级策略 |
|------|------|----------|
| macOS grep 兼容性 | 中 | 使用 sed 或检测 ggrep |
| scc JSON 格式变更 | 低 | 验证 jq 解析，失败返回 1 |
| 配置文件格式错误 | 低 | 解析失败使用默认值 |

### Open Questions

1. 是否需要在 `SKILL.md` 中添加 GNU grep 安装指引？
2. 配置解析是否需要引入 YAML 解析工具（如 yq）？
3. 是否需要缓存复杂度计算结果以提升性能？

---

## 断点区 (Context Switch Breakpoint Area)

*当前无断点*

---

*文档版本*: 1.0
*生成时间*: 2026-01-08
*下一步*: 进入 Apply 阶段，执行 `/openspec:apply test-owner enhance-code-intelligence`
