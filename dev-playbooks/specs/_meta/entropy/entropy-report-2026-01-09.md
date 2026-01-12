# 系统熵度量报告 / System Entropy Report

> 生成时间: 2026-01-09T12:00:00Z
> 项目路径: /Users/ozbombor/Projects/dev-playbooks
> 分析周期: 30 天

---

## 概览 / Overview

| 维度 | 健康状态 | 主要指标 | 说明 |
|------|---------|---------|------|
| 结构熵 | 🔴 | 文件行数 P95: **750** | 超阈值 (>500) |
| 变更熵 | 🟢 | 热点文件占比: **0/156 = 0%** | 健康 (<10%) |
| 测试熵 | 🔴 | 测试/代码比: **403/10112 = 0.04** | 严重不足 (<0.5) |
| 依赖熵 | 🟢 | 过期依赖占比: **0%** | 健康 |

**健康维度**: 2/4 | **告警数**: 2

---

## A) 结构熵 / Structural Entropy

> 来源: 静态代码分析

| 指标 | 当前值 | 阈值 | 状态 |
|------|-------|------|------|
| 文件行数 P95 | **750** | < 500 | 🔴 超阈值 |
| 文件行数均值 | ~200 | - | ⚪ |
| 圈复杂度均值 | N/A | < 10 | ⚪ 未采集 |
| 圈复杂度 P95 | N/A | < 20 | ⚪ 未采集 |

### 大文件清单 (>300行)

| 文件 | 行数 | 建议 |
|------|------|------|
| `mcp/devbooks-mcp-server/src/index.ts` | 750 | 🔴 拆分为多个模块 |
| `tools/devbooks-embedding.sh` | 692 | 🟡 考虑拆分 |
| `mcp/devbooks-mcp-server/dist/index.js` | 654 | ⚪ 构建产物，忽略 |
| `setup/global-hooks/augment-context-global.sh` | 541 | 🟡 考虑拆分 |
| `skills/devbooks-delivery-workflow/scripts/change-check.sh` | 528 | 🟡 考虑拆分 |
| `skills/devbooks-delivery-workflow/scripts/guardrail-check.sh` | 518 | 🟡 考虑拆分 |

**建议**: 优先拆分 `mcp/devbooks-mcp-server/src/index.ts` (750行)，可按功能模块拆分为：
- `handlers/` - 各类请求处理器
- `tools/` - 工具函数
- `types.ts` - 类型定义

---

## B) 变更熵 / Change Entropy

> 来源: Git 历史分析 (过去 30 天)

| 指标 | 当前值 | 阈值 | 状态 |
|------|-------|------|------|
| 热点文件数 | 0 / 156 | - | 🟢 |
| 热点文件占比 | **0%** | < 10% | 🟢 健康 |
| 最高修改频率 | 5次 | - | ⚪ |

### 频繁修改文件 (30天内)

| 文件 | 修改次数 | 风险等级 |
|------|---------|---------|
| `使用说明书.md` | 5 | ⚪ 文档 |
| `setup/README.md` | 4 | ⚪ 文档 |
| `setup/template/DevBooks集成模板...md` | 4 | ⚪ 文档 |
| `skills/devbooks-spec-delta/SKILL.md` | 3 | ⚪ 配置 |
| `.claude/hooks/augment-context.sh` | 3 | 🟡 脚本 |

**热点定义**: 在分析周期内被修改超过 5 次的文件

**结论**: 无热点文件（修改>5次），变更熵健康。

---

## C) 测试熵 / Test Entropy

> 来源: 测试文件统计

| 指标 | 当前值 | 阈值 | 状态 |
|------|-------|------|------|
| 测试代码行数 | **403** | - | ⚪ |
| 生产代码行数 | **10,112** | - | ⚪ |
| 测试/代码比 | **0.04** | > 0.5 | 🔴 严重不足 |
| Flaky 测试占比 | N/A | < 0.01 | ⚪ 未采集 |
| 代码覆盖率 | N/A | > 0.7 | ⚪ 未采集 |

### 测试文件清单

| 文件 | 行数 | 类型 |
|------|------|------|
| `tests/enhance-code-intelligence/test_performance.bats` | 172 | BATS |
| `tests/enhance-code-intelligence/test_hotspot.bats` | 133 | BATS |
| `tests/enhance-code-intelligence/test_index_detection.bats` | 98 | BATS |
| **合计** | **403** | - |

**建议**: 测试/代码比仅为 4%，远低于 50% 健康阈值。优先补充测试：
1. 🔴 `mcp/devbooks-mcp-server/` - 0% 覆盖，需要单元测试
2. 🔴 `skills/*/scripts/` - Shell 脚本需要 BATS 测试
3. 🟡 `tools/devbooks-embedding.sh` - 需要集成测试

---

## D) 依赖熵 / Dependency Entropy

> 来源: 依赖分析

| 指标 | 当前值 | 阈值 | 状态 |
|------|-------|------|------|
| npm 依赖数 | 0 | - | ⚪ |
| 过期依赖数 | 0 | - | 🟢 |
| 过期依赖占比 | 0% | < 20% | 🟢 健康 |
| 安全漏洞数 | 0 | = 0 | 🟢 |

**说明**: 项目主要为 Shell 脚本，无外部 npm 依赖。MCP Server 使用独立的 package.json。

---

## 告警详情 / Alerts

- **[WARNING]** structural: file_lines_p95 (750) 超过阈值 (500)
- **[WARNING]** test: test_code_ratio (0.04) 低于阈值 (0.5)

---

## 趋势分析 / Trend Analysis

> 首次采集，暂无历史趋势数据

---

## 行动建议 / Recommended Actions

### 高优先级 (P0)

1. **补充测试** - 测试/代码比仅 4%，建议：
   - 为 `mcp/devbooks-mcp-server/src/index.ts` 添加单元测试
   - 为 `setup/global-hooks/augment-context-global.sh` 增加 BATS 测试覆盖
   - 目标：测试/代码比提升至 30%+

### 中优先级 (P1)

2. **拆分大文件** - `mcp/devbooks-mcp-server/src/index.ts` (750行)：
   - 建议发起重构提案：`/devbooks-proposal-author`
   - 按职责拆分为 handlers/tools/types 模块

3. **Shell 脚本模块化** - 5个脚本超过 500 行：
   - 提取公共函数到 `lib/common.sh`
   - 拆分主逻辑为独立函数

### 低优先级 (P2)

4. **持续监控** - 建议每周运行熵度量，跟踪趋势

---

## 量化摘要

| 维度 | 得分 | 等级 |
|------|------|------|
| 结构熵 | 60/100 | C |
| 变更熵 | 95/100 | A |
| 测试熵 | 20/100 | F |
| 依赖熵 | 100/100 | A |
| **综合** | **68.75/100** | **D** |

> 综合得分计算：(60+95+20+100)/4 = 68.75

---

*报告由 DevBooks Entropy Monitor 生成*
*参考: 《人月神话》第16章"没有银弹" — 控制复杂性是软件开发的关键*
