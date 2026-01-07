# DevBooks CI/CD 集成模板

本目录包含 DevBooks 的 CI/CD 集成模板，用于自动化架构合规检查和 COD 模型更新。

## 模板说明

| 文件 | 用途 | 触发时机 |
|------|------|---------|
| `devbooks-guardrail.yml` | 架构合规检查（复杂度、热点、分层、循环依赖） | PR 时 |
| `devbooks-cod-update.yml` | COD 模型自动更新（模块图、热点、概念） | Push 到主分支时 |

## 安装方式

```bash
# 1. 复制模板到项目
mkdir -p .github/workflows
cp templates/ci/devbooks-guardrail.yml .github/workflows/
cp templates/ci/devbooks-cod-update.yml .github/workflows/

# 2. 根据项目调整配置
# 编辑 .github/workflows/devbooks-*.yml 中的 env 部分
```

## 配置项

### devbooks-guardrail.yml

```yaml
env:
  TRUTH_ROOT: 'specs'           # 真理目录
  CHANGE_ROOT: 'changes'        # 变更目录
  COMPLEXITY_THRESHOLD: 15      # 圈复杂度阈值
  HOTSPOT_THRESHOLD: 10         # 热点变更次数阈值
  FAIL_ON_LAYER_VIOLATION: true # 分层违规阻止合并
  FAIL_ON_CYCLE: true           # 循环依赖阻止合并
```

### devbooks-cod-update.yml

```yaml
env:
  TRUTH_ROOT: 'specs'  # 真理目录
```

## 检查项说明

### 复杂度检查

使用 `scc` 工具检测圈复杂度，超过阈值的文件会被标记警告。

安装：`go install github.com/boyter/scc/v3@latest`

### 热点检查

分析 Git 历史，标记 30 天内高频变更的文件。

高频变更 + 高复杂度 = 技术债高风险区域

### 分层违规检查

检查是否存在违反分层约束的导入（如 domain 层导入 infrastructure）。

需要在 `<truth-root>/architecture/layers.yaml` 中定义分层规则。

### 循环依赖检查

使用 `madge` 检测模块间的循环依赖。

安装：`npm install -g madge`

## 与 DevBooks Skill 的配合

CI 检查结果可以与 DevBooks Skills 配合使用：

1. **PR 检查失败** → 使用 `devbooks-impact-analysis` 分析影响范围
2. **热点警告** → 使用 `devbooks-code-review` 审查高风险区域
3. **分层违规** → 使用 `devbooks-c4-map` 更新架构图
4. **COD 更新** → 自动产出供 `devbooks-router` 使用的上下文

## OpenSpec 项目配置

```yaml
env:
  TRUTH_ROOT: 'openspec/specs'
  CHANGE_ROOT: 'openspec/changes'
```

## 故障排除

### 检查超时

大型项目的首次检查可能较慢，可以调整 `timeout-minutes`。

### 依赖工具缺失

确保 CI 环境中安装了必要的工具（scc、madge 等）。

### 权限问题

COD 自动提交需要 `contents: write` 权限。
