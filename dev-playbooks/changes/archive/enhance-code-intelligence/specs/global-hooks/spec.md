# global-hooks spec delta

---
owner: Spec Owner (AI)
change_id: enhance-code-intelligence
last_verified: 2026-01-08
status: Draft
freshness_check: 3 Months
---

## 目标路径

- `openspec/changes/enhance-code-intelligence/specs/global-hooks/spec.md`（本文件）

---

## MODIFIED Requirements

### Requirement: Hook 提供热点文件列表

系统 MUST 提供热点文件列表，使用频率 × 复杂度加权算法计算热点分数。

#### Scenario: 热点文件输出包含复杂度分数

- **GIVEN** 代码项目目录存在 `.git` 历史
- **AND** 至少有 1 个文件在过去 30 天内有提交记录
- **WHEN** Hook 执行热点计算
- **THEN** 输出格式包含 `complexity: N` 字段
- **AND** 热点分数 = 变更频率 × 圈复杂度
- **AND** 最多输出 5 个热点文件

**Trace**: AC-001

#### Scenario: 复杂度工具缺失时降级

- **GIVEN** 系统未安装 radon、scc 或 gocyclo 任一工具
- **WHEN** Hook 执行热点计算
- **THEN** 复杂度默认值为 1（热点分数退化为纯频率）
- **AND** 输出包含工具安装提示
- **AND** Hook 正常完成，不报错退出

**Trace**: AC-002

#### Scenario: 复杂度计算超时时降级

- **GIVEN** 单个文件复杂度计算耗时超过 1 秒
- **WHEN** Hook 执行热点计算
- **THEN** 该文件复杂度使用默认值 1
- **AND** 继续处理下一个文件
- **AND** 总计算时间不超过 5 秒（最多 5 个文件）

**Trace**: AC-004, AC-005

---

## ADDED Requirements

### Requirement: Hook 提供 CKB 索引状态引导

系统 MUST 检测本地索引文件状态，无索引时输出引导提示帮助用户启用图分析能力。

#### Scenario: 本地索引存在时显示状态

- **GIVEN** 项目目录存在以下任一文件/目录：
  - `index.scip`（SCIP 索引）
  - `.git/ckb/`（CKB 本地缓存）
  - `.devbooks/embeddings/index.tsv`（Embedding 索引）
- **WHEN** Hook 执行索引检测
- **THEN** 输出"索引可用"状态信息

**Trace**: AC-003

#### Scenario: 本地索引不存在时显示引导提示

- **GIVEN** 项目目录不存在上述任一索引文件
- **WHEN** Hook 执行索引检测
- **THEN** 输出引导提示："可启用 CKB 加速代码分析，运行：/devbooks-index-bootstrap"
- **AND** 不阻塞 Hook 主流程

**Trace**: AC-003

---

## 数据驱动实例

### 热点分数计算示例

| 文件 | 变更频率 (30天) | 圈复杂度 | 热点分数 | 说明 |
|------|----------------|----------|----------|------|
| `core/auth.py` | 5 | 12 | 60 | 高频 + 高复杂度 → 热点 |
| `config.yaml` | 10 | 1 | 10 | 高频 + 低复杂度 → 非热点 |
| `db/schema.go` | 2 | 15 | 30 | 低频 + 高复杂度 → 中等 |
| `utils/helper.ts` | 3 | 3 | 9 | 中频 + 低复杂度 → 非热点 |

### 复杂度工具适配示例

| 文件扩展名 | 优先工具 | 降级工具 | 输出统一化 |
|-----------|----------|----------|-----------|
| `.py` | radon | scc | 提取最大复杂度值 |
| `.js`, `.ts`, `.tsx` | scc | - | JSON Complexity 字段 |
| `.go` | gocyclo | scc | 第一列数值 |
| 其他 | scc | - | JSON Complexity 字段 |

---

## 契约与数据定义计划

### A) 需要新增/更新的契约

| 契约 | 类型 | 变更类型 | 兼容策略 |
|------|------|----------|----------|
| Hook 输出格式 | 文本输出 | 扩展 | 向后兼容（新增可选字段） |
| `.devbooks/config.yaml` | 配置文件 | 扩展 | 向后兼容（新增可选配置项，有默认值） |

### B) 配置契约草案

```yaml
# .devbooks/config.yaml schema v1.1
features:
  complexity_weighted_hotspot: boolean  # 默认 true
  ckb_status_hint: boolean              # 默认 true
  hotspot_limit: integer                # 默认 5，范围 1-10

ckb:
  index_hint_enabled: boolean           # 默认 true
  index_file_paths: string[]            # 默认见下
    # - index.scip
    # - .git/ckb/
    # - .devbooks/embeddings/index.tsv
```

**兼容策略**：
- 配置项不存在时使用硬编码默认值
- 未知配置项忽略（不报错）
- 无 schema_version 要求（配置简单，无迁移需求）

### C) Contract Tests

| Test ID | 断言点 | 验证方式 |
|---------|--------|----------|
| CT-001 | Hook 输出包含 `complexity:` 字段 | 正则匹配输出 |
| CT-002 | 无工具时输出包含安装提示 | 字符串匹配 |
| CT-003 | 无索引时输出包含引导提示 | 字符串匹配 |
| CT-004 | 配置项缺失时使用默认值 | 删除配置项后运行 Hook |

---

## 追溯摘要

| AC/Requirement | 契约/Test |
|----------------|-----------|
| AC-001 热点输出包含复杂度 | CT-001, Hook 输出格式 |
| AC-002 工具缺失降级 | CT-002, 降级策略 |
| AC-003 索引检测引导 | CT-003, 索引检测逻辑 |
| AC-004 Hook < 5s | 性能测试 |
| AC-005 复杂度计算 < 5s | 性能测试 |
| 热点算法修改 | CT-001, CT-004, Hook 输出格式 |
| CKB 索引引导新增 | CT-003, 配置契约 |

---

*文档版本*: 1.0
*生成时间*: 2026-01-08
