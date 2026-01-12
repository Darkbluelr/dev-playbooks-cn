# call-chain（Spec Delta）

---
change_id: achieve-augment-parity
capability: call-chain
delta_type: ADDED
trace: AC-004
---

## 目的

描述新增的多跳调用链追踪能力：封装 CKB traceUsage 和 getCallGraph，支持 2-3 跳调用链分析。

---

## ADDED Requirements

### Requirement: REQ-CHAIN-001 多跳调用链追踪

系统 **SHALL** 提供调用链追踪工具，支持从目标符号追踪 callers 和 callees。

- 追踪深度：2-3 跳（可配置）
- 输入：目标符号名称或 CKB 符号 ID
- 输出：调用链 JSON 结构

#### Scenario: SC-CHAIN-001 追踪函数调用方

- **GIVEN** CKB 索引可用且目标符号 `processOrder` 存在
- **WHEN** 执行 `call-chain-tracer.sh --symbol processOrder --direction callers --depth 2`
- **THEN** 输出包含调用 `processOrder` 的函数列表
- **AND** 输出结构为嵌套的调用链 JSON

Trace: AC-004

#### Scenario: SC-CHAIN-002 追踪函数被调用方

- **GIVEN** CKB 索引可用且目标符号 `processOrder` 存在
- **WHEN** 执行 `call-chain-tracer.sh --symbol processOrder --direction callees --depth 2`
- **THEN** 输出包含 `processOrder` 调用的函数列表
- **AND** 输出结构为嵌套的调用链 JSON

Trace: AC-004

---

### Requirement: REQ-CHAIN-002 入口路径追溯

系统 **SHALL** 支持从系统入口追溯到目标符号的调用路径。

- 使用 CKB `traceUsage` API
- 输出多条可能的调用路径
- 路径按长度排序（短路径优先）

#### Scenario: SC-CHAIN-003 追溯入口路径

- **GIVEN** CKB 索引可用且目标符号存在
- **WHEN** 执行 `call-chain-tracer.sh --symbol targetFunc --trace-usage`
- **THEN** 输出从入口到 `targetFunc` 的调用路径
- **AND** 路径包含每一跳的 `file_path`、`line`、`symbol_name`

Trace: AC-004

---

### Requirement: REQ-CHAIN-003 循环依赖检测

系统 **SHALL** 在图遍历过程中检测并处理循环依赖，避免无限递归。

- 记录已访问节点
- 检测到循环时标记并终止该分支遍历
- 输出中标注循环点

#### Scenario: SC-CHAIN-004 循环依赖处理

- **GIVEN** 代码中存在 A → B → C → A 的循环调用
- **WHEN** 追踪从 A 开始的调用链
- **THEN** 遍历在检测到 A 重复时停止
- **AND** 输出中标注 `cycle_detected: true`

Trace: AC-004

---

## 数据驱动实例

### 调用链输出结构

```json
{
  "schema_version": "1.0",
  "target_symbol": "processOrder",
  "depth": 3,
  "direction": "callers",
  "paths": [
    {
      "symbol_id": "ckb:repo:sym:abc123",
      "symbol_name": "handleRequest",
      "file_path": "src/handlers/order.ts",
      "line": 42,
      "depth": 1,
      "callers": [
        {
          "symbol_id": "ckb:repo:sym:def456",
          "symbol_name": "main",
          "file_path": "src/index.ts",
          "line": 15,
          "depth": 2,
          "callers": []
        }
      ]
    }
  ],
  "cycle_detected": false
}
```

### 命令行参数对照表

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| --symbol | string | 必填 | 目标符号名称 |
| --direction | enum | both | callers \| callees \| both |
| --depth | number | 2 | 追踪深度 (1-4) |
| --trace-usage | flag | false | 启用入口路径追溯 |
| --mock-ckb | flag | false | 使用预置调用图（测试用） |
| --output | enum | json | json \| tree \| markdown |

---

*Spec delta 由 devbooks-spec-contract 生成*
