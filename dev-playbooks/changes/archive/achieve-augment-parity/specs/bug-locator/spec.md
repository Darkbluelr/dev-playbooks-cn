# bug-locator（Spec Delta）

---
change_id: achieve-augment-parity
capability: bug-locator
delta_type: ADDED
trace: AC-005
---

## 目的

描述新增的简化版 Bug 定位能力：基于调用链 + 变更历史的候选位置推荐。

---

## ADDED Requirements

### Requirement: REQ-BUG-001 候选位置推荐

系统 **SHALL** 基于错误信息和调用链分析，输出可能的 Bug 候选位置列表。

- 输入：错误信息（堆栈跟踪、错误类型、关键词）
- 输出：Top-5 候选位置，按置信度排序
- 定位：候选推荐（非精确定位）

#### Scenario: SC-BUG-001 TypeError 候选定位

- **GIVEN** 用户提供错误信息 "TypeError: Cannot read property 'x' of undefined"
- **WHEN** 执行 `bug-locator.sh --error "TypeError: Cannot read property 'x' of undefined"`
- **THEN** 输出包含 5 个候选位置
- **AND** 每个位置包含 `file_path`、`line_range`、`confidence`、`reason`

Trace: AC-005

#### Scenario: SC-BUG-002 堆栈跟踪分析

- **GIVEN** 用户提供包含堆栈跟踪的错误信息
- **WHEN** 执行 `bug-locator.sh --stacktrace "Error at foo.ts:42"`
- **THEN** 系统解析堆栈跟踪中的文件和行号
- **AND** 候选位置优先包含堆栈中提及的文件

Trace: AC-005

---

### Requirement: REQ-BUG-002 变更历史关联

系统 **SHALL** 将调用链结果与 Git 变更历史交叉分析，优先推荐最近修改过的代码。

- 最近 N 次提交中修改的文件优先级提高
- 默认 N=20，可配置
- 高频变更（热点）文件标记

#### Scenario: SC-BUG-003 优先推荐最近修改

- **GIVEN** 候选位置 A 最近 7 天内被修改，候选位置 B 30 天未修改
- **WHEN** 两者调用链相关性相同
- **THEN** 候选 A 的置信度高于候选 B
- **AND** 候选 A 排在输出列表更前位置

Trace: AC-005

---

### Requirement: REQ-BUG-003 热点交叉分析

系统 **SHALL** 将候选位置与项目热点文件交叉，标记高风险区域。

- 热点定义：变更频率 × 复杂度
- 热点重叠的候选位置标记 `is_hotspot: true`
- 热点信息来自 `devbooks-get-hotspots` 或 CKB

#### Scenario: SC-BUG-004 热点标记

- **GIVEN** 候选位置 `src/order.ts` 是项目热点文件（Top 5）
- **WHEN** Bug 定位分析完成
- **THEN** 该候选位置包含 `is_hotspot: true` 标记
- **AND** `reason` 中提及"热点文件"

Trace: AC-005

---

### Requirement: REQ-BUG-004 命中率验收标准

系统 **SHALL** 对预设评测集达到 Top-5 命中率 ≥ 60%。

- 评测集：10 个已知 Bug 的 case
- 命中定义：真实 Bug 位置出现在 Top-5 候选中
- 命中率 = 命中数 / 总 case 数

#### Scenario: SC-BUG-005 评测集验收

- **GIVEN** 10 个已知 Bug 的评测 case
- **WHEN** 对每个 case 执行 Bug 定位
- **THEN** 至少 6 个 case 的真实 Bug 位置出现在 Top-5 候选中
- **AND** 整体命中率 ≥ 60%

Trace: AC-005

---

## 数据驱动实例

### Bug 候选输出结构

```json
{
  "schema_version": "1.0",
  "query": "TypeError: Cannot read property 'x' of undefined",
  "candidates": [
    {
      "rank": 1,
      "file_path": "src/services/order.ts",
      "line_range": [142, 156],
      "confidence": 0.85,
      "reason": "调用链直接相关 + 最近 3 天内修改",
      "is_hotspot": true,
      "last_modified": "2026-01-07"
    },
    {
      "rank": 2,
      "file_path": "src/utils/parser.ts",
      "line_range": [23, 35],
      "confidence": 0.72,
      "reason": "调用链 2 跳内 + 包含类似错误模式",
      "is_hotspot": false,
      "last_modified": "2026-01-02"
    }
  ],
  "analysis_time_ms": 450,
  "fallback_used": false
}
```

### 置信度计算因子

| 因子 | 权重 | 说明 |
|------|------|------|
| 调用链相关性 | 0.4 | 目标符号与错误点的调用链距离 |
| 变更历史 | 0.3 | 最近修改时间，越近权重越高 |
| 热点匹配 | 0.15 | 是否为项目热点文件 |
| 错误模式匹配 | 0.15 | 代码中是否存在类似错误模式 |

### 命令行参数对照表

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| --error | string | 必填 | 错误信息或关键词 |
| --stacktrace | string | 可选 | 完整堆栈跟踪 |
| --top-n | number | 5 | 返回候选数量 |
| --history-depth | number | 20 | 分析的提交历史深度 |
| --output | enum | json | json \| markdown |

---

*Spec delta 由 devbooks-spec-contract 生成*
