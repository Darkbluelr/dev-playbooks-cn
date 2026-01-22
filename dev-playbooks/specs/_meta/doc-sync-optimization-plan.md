# Doc-Sync Skill 优化方案

## 一、核心问题分析

### 当前 doc-sync 的局限性

1. **缺少自定义规则支持**：无法添加项目特定的文档规范
2. **检查维度不完备**：缺少存在性矩阵和维护性分类
3. **缺少拓扑映射**：没有系统化的代码-文档触点扫描
4. **命名不够准确**："sync"暗示简单同步，实际是复杂的审计与维护

## 二、优化策略

### 1. 改名建议

**当前名称**：`devbooks-docs-consistency`

**建议改为**：`devbooks-docs-consistency`

**理由**：
- "consistency"更准确地反映了"一致性审计"的本质
- 涵盖了存在性检查、维护性分类、完整性验证等多维度
- 与对话中提到的"文档一致性审计 (Documentation Consistency Audit)"术语对齐

### 2. 自定义规则支持

#### 2.1 配置文件机制

在 `.devbooks/docs-rules.yaml` 中定义全局规则：

```yaml
# 文档一致性规则配置
version: 1.0

# 全局清理规则
global_cleanup:
  - name: "移除 Augment 引用"
    pattern: "@augment|Augment"
    action: "remove"
    scope: "all_docs"
    reason: "项目已迁移到其他工具"

  - name: "统一术语：变更包"
    pattern: "change package|变更集"
    replace: "变更包"
    scope: "all_docs"

  - name: "移除过时的配置说明"
    pattern: "legacy_mode|旧版模式"
    action: "flag_for_review"

# 存在性规则（必须有/不能有）
existence_rules:
  must_exist:
    - "README.md"
    - "LICENSE"
    - ".env.example"
    - "docs/installation.md"

  must_not_exist:
    - ".env"
    - "credentials.json"
    - "*.key"
    - "docs/internal/*"  # 内部文档不应在用户文档中

  conditional:
    - condition: "has_api_exports"
      then_must_exist: "docs/api.md"
    - condition: "has_cli_commands"
      then_must_exist: "docs/cli.md"

# 维护性分类
maintenance_policy:
  living_docs:  # 活体文档 - 强一致性
    - "README.md"
    - "docs/api.md"
    - "docs/configuration.md"
    - ".env.example"

  historical_docs:  # 历史快照 - 不可变
    - "CHANGELOG.md"
    - "dev-playbooks/changes/archive/**/*.md"
    - "docs/adr/*.md"  # Architecture Decision Records

  conceptual_docs:  # 概念性文档 - 弱一致性
    - "docs/tutorials/*.md"
    - "docs/philosophy.md"

# 拓扑映射规则
topology_mapping:
  input_surface:
    scan_patterns:
      - "os.getenv"
      - "process.env"
      - "argparse"
      - "config.load"
    doc_target: "docs/configuration.md"

  output_surface:
    scan_patterns:
      - "throw new Error"
      - "logger.error"
      - "console.error"
    doc_target: "docs/troubleshooting.md"

  dependency_surface:
    scan_patterns:
      - "import"
      - "require"
      - "FROM"  # Dockerfile
    doc_target: "docs/installation.md"

# 完备性检查维度
completeness_dimensions:
  - name: "环境依赖"
    check: "prerequisites_documented"
    target: "README.md#prerequisites"

  - name: "配置项审计"
    check: "all_env_vars_documented"
    target: "docs/configuration.md"

  - name: "安全权限"
    check: "api_scopes_documented"
    target: "docs/security.md"

  - name: "故障排查"
    check: "error_codes_documented"
    target: "docs/troubleshooting.md"

  - name: "架构数据流"
    check: "data_flow_documented"
    target: "docs/architecture.md"

  - name: "变更历史"
    check: "breaking_changes_documented"
    target: "CHANGELOG.md"
```

#### 2.2 命令行参数支持

```bash
# 应用全局规则
devbooks-docs-consistency --apply-rules

# 添加临时规则
devbooks-docs-consistency --custom-rule "remove:@augment:all"

# 检查模式（不修改）
devbooks-docs-consistency --check --rules-file custom-rules.yaml

# 只应用特定规则
devbooks-docs-consistency --rule "移除 Augment 引用"
```

### 3. 增强的检查维度

#### 3.1 存在性矩阵检查

```markdown
## 存在性检查报告

### 核心资产（Must Exist）
✅ README.md - 存在
✅ LICENSE - 存在
❌ .env.example - **缺失** [需要创建]

### 负向资产（Must Not Exist）
✅ .env - 不存在
⚠️ docs/internal/secrets.md - **存在** [安全风险，需要删除]

### 条件资产
✅ docs/api.md - 存在（因为检测到 API 导出）
⚠️ CONTRIBUTING.md - 缺失（开源项目建议添加）
```

#### 3.2 维护性分类检查

```markdown
## 维护性分类报告

### 活体文档（需要强一致性）
- README.md: ✅ 与代码一致
- docs/api.md: ❌ 缺少 3 个新增 API
- docs/configuration.md: ⚠️ timeout 默认值不一致

### 历史快照（不应修改）
- CHANGELOG.md: ✅ 历史记录完整
- dev-playbooks/changes/archive/: ✅ 归档文档未被篡改

### 概念性文档（弱一致性）
- docs/tutorials/: ℹ️ 建议更新（上次更新 6 个月前）
```

#### 3.3 拓扑映射检查

```markdown
## 代码-文档拓扑映射报告

### 输入触点扫描
发现 12 个环境变量：
- ✅ DATABASE_URL - 已在 docs/configuration.md 说明
- ✅ API_KEY - 已在 docs/configuration.md 说明
- ❌ REDIS_HOST - **未在文档中说明**
- ❌ LOG_LEVEL - **未在文档中说明**

### 输出触点扫描
发现 8 个错误类型：
- ✅ ConfigurationError - 已在 docs/troubleshooting.md 说明
- ❌ DatabaseConnectionError - **未在文档中说明**
- ❌ AuthenticationError - **未在文档中说明**

### 依赖触点扫描
发现 25 个外部依赖：
- ✅ 所有 npm 包已在 package.json
- ⚠️ 系统依赖 ImageMagick - **未在安装文档中说明**
- ⚠️ 需要 Python 3.9+ - **未在前置条件中说明**

### 逻辑触点扫描
发现 5 个关键默认值：
- ✅ timeout: 30s - 文档一致
- ❌ maxRetries: 3 - 文档写的是 5
- ❌ ci_federation 无配置时返回空 - **未在文档中说明**
```

### 4. 增强的执行流程

```
┌─────────────────────────────────────────────────────────────┐
│ 1. 加载配置                                                  │
│    - 读取 .devbooks/docs-rules.yaml                         │
│    - 合并命令行参数                                          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. 存在性检查                                                │
│    - 核心资产检查（Must Exist）                              │
│    - 负向资产检查（Must Not Exist）                          │
│    - 条件资产检查（Conditional）                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. 维护性分类                                                │
│    - 识别活体文档（需要强一致性）                            │
│    - 识别历史快照（不应修改）                                │
│    - 识别概念性文档（弱一致性）                              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. 拓扑映射扫描                                              │
│    - 输入触点：环境变量、配置、参数                          │
│    - 输出触点：错误、日志、返回值                            │
│    - 依赖触点：外部库、系统依赖                              │
│    - 逻辑触点：默认值、边缘情况                              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. 完备性检查                                                │
│    - 环境依赖完整性                                          │
│    - 配置项审计                                              │
│    - 安全权限说明                                            │
│    - 故障排查覆盖                                            │
│    - 架构数据流                                              │
│    - 变更历史记录                                            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. 应用自定义规则                                            │
│    - 全局清理规则（如删除 augment 引用）                     │
│    - 术语统一规则                                            │
│    - 格式规范规则                                            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 7. 生成报告并执行修复                                        │
│    - 输出差异报告                                            │
│    - 询问用户确认                                            │
│    - 执行修复操作                                            │
│    - 记录变更日志                                            │
└─────────────────────────────────────────────────────────────┘
```

## 三、其他需要优化的 Skills

### 1. devbooks-archiver

**优化点**：归档前确保文档完整性

```yaml
# 在归档前自动调用 docs-consistency
archiver_hooks:
  pre_archive:
    - skill: devbooks-docs-consistency
      mode: change_scoped
      rules: ["存在性检查", "维护性分类"]
      block_on_failure: true
```

### 2. devbooks-brownfield-bootstrap

**优化点**：初始化时生成完整的文档基线

```yaml
# 存量项目初始化时
bootstrap_docs:
  - 扫描现有代码生成文档骨架
  - 应用存在性规则创建缺失文档
  - 生成初始的 docs-rules.yaml
  - 执行首次完备性检查
```

### 3. devbooks-proposal-author

**优化点**：提案中包含文档影响分析

```markdown
## 文档影响分析

### 需要更新的文档
- [ ] README.md - 添加新功能说明
- [ ] docs/api.md - 添加新 API 文档
- [ ] docs/configuration.md - 添加新配置项

### 需要创建的文档
- [ ] docs/migration-v3.md - 破坏性变更迁移指南

### 文档一致性风险
- ⚠️ 新增 5 个环境变量，需要在配置文档中说明
- ⚠️ 修改了错误码，需要更新故障排查文档
```

### 4. devbooks-design-backport

**优化点**：回写设计时同步更新架构文档

```yaml
# 设计回写时
design_backport_hooks:
  post_backport:
    - 检查是否需要更新 docs/architecture.md
    - 检查是否需要更新 ADR
    - 标记需要同步的概念性文档
```

### 5. devbooks-impact-analysis

**优化点**：影响分析包含文档影响

```markdown
## 影响分析报告

### 代码影响
- 3 个模块受影响
- 12 个文件需要修改

### 文档影响
- 活体文档：2 个需要更新
- 历史文档：1 个需要新建（ADR）
- 用户文档：README.md, docs/api.md
```

## 四、实施优先级

### P0（立即实施）
1. ✅ 添加自定义规则支持（配置文件 + 命令行参数）
2. ✅ 增加拓扑映射扫描（输入/输出/依赖/逻辑触点）
3. ✅ 考虑改名为 devbooks-docs-consistency

### P1（近期实施）
1. 增加存在性矩阵检查
2. 增加维护性分类
3. 增强完备性检查维度（环境依赖、安全权限、故障排查等）

### P2（后续优化）
1. 与其他 skills 的集成（archiver、proposal-author 等）
2. MCP 增强模式优化
3. 自动化文档生成能力

## 五、示例：删除 Augment 引用的完整流程

### 1. 定义规则

在 `.devbooks/docs-rules.yaml` 中：

```yaml
global_cleanup:
  - name: "移除 Augment 引用"
    pattern: "@augment|Augment|augment"
    action: "remove_references"
    scope: "all_docs"
    exceptions:
      - "CHANGELOG.md"  # 历史记录不修改
      - "dev-playbooks/changes/archive/**"  # 归档不修改
    reason: "项目已从 Augment 迁移到 Claude Code"
```

### 2. 执行命令

```bash
# 检查模式（预览）
devbooks-docs-consistency --check --rule "移除 Augment 引用"

# 输出：
# 发现 15 处 Augment 引用：
# - README.md: 3 处
# - docs/setup.md: 5 处
# - docs/faq.md: 7 处
#
# 将跳过：
# - CHANGELOG.md: 2 处（历史文档）

# 应用修复
devbooks-docs-consistency --apply --rule "移除 Augment 引用"
```

### 3. 验证结果

```bash
# 再次检查
devbooks-docs-consistency --check --rule "移除 Augment 引用"

# 输出：
# ✅ 所有活体文档中的 Augment 引用已清理
# ℹ️ 历史文档保持不变（符合预期）
```

## 六、总结

通过以上优化，`devbooks-docs-consistency` 将成为一个：

1. **完备的文档审计系统**：覆盖存在性、维护性、完整性等多维度
2. **可定制的规则引擎**：支持项目特定的文档规范
3. **智能的拓扑映射工具**：自动发现代码-文档的触点
4. **集成的工作流组件**：与其他 skills 无缝协作

这将显著提升文档质量和一致性，减少用户因文档问题导致的困惑。
