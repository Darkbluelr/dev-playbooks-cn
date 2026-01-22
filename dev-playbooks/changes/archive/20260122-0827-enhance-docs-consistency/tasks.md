# 编码计划：文档一致性工具优化

**元信息**:
- 维护者: Implementation Planner
- 关联设计: `design.md`
- 关联规格: `specs/*/spec.md` (8 个能力模块)
- 输入材料: design.md, specs/docs-consistency-core/spec.md, specs/completeness-check/spec.md, specs/doc-classification/spec.md, specs/shared-methodology/spec.md, specs/skills-integration/spec.md, specs/style-cleanup/spec.md, specs/expert-roles/spec.md, specs/style-persistence/spec.md
- 创建时间: 2026-01-22
- 模式: 主线计划模式

---

## 主线计划区 (Main Plan Area)

### MP1: Skill 改名与别名机制 (AC-001)

**目的**: 将 `devbooks-docs-sync` 改名为 `devbooks-docs-consistency`,提供别名机制确保向后兼容。

**交付物**:
- 新目录 `skills/devbooks-docs-consistency/`
- 别名脚本或软链接
- 弃用警告机制

**影响范围**:
- `skills/devbooks-docs-sync/` → `skills/devbooks-docs-consistency/`
- 调用该 skill 的其他 skills

**验收标准**:
- 目录 `skills/devbooks-docs-consistency/` 存在
- 调用 `devbooks-docs-sync` 能正常工作并输出弃用警告
- 单元测试: 别名机制测试

**依赖**: 无

**风险**: 别名机制失效导致用户无法使用旧名称

- [x] MP1.1 创建 `skills/devbooks-docs-consistency/` 目录结构,复制 `devbooks-docs-sync/` 内容
- [x] MP1.2 实现别名机制(软链接或重定向脚本)
- [x] MP1.3 添加弃用警告输出逻辑
- [x] MP1.4 更新 skill.md 文档

### MP2: 自定义规则引擎 (AC-002)

**目的**: 支持持续规则(配置文件)和一次性任务(命令行参数)。

**交付物**:
- 规则引擎模块
- 规则配置 schema
- 命令行参数解析

**影响范围**:
- `skills/devbooks-docs-consistency/scripts/rules-engine.sh`
- `skills/devbooks-docs-consistency/references/docs-rules-schema.yaml`

**验收标准**:
- 支持持续规则和一次性任务
- 规则引擎幂等
- 单元测试: `test-rules-engine.bats`

**依赖**: MP1

**风险**: 规则引擎过于复杂,影响可维护性

- [x] MP2.1 设计规则引擎接口(loadRules, applyRules, validateRules)
- [x] MP2.2 实现规则配置解析器(支持 YAML 格式)
- [x] MP2.3 实现规则执行引擎(支持 check/remove/replace 动作)
- [x] MP2.4 实现命令行参数解析(--once 参数)
- [x] MP2.5 实现规则幂等性检查
- [x] MP2.6 创建规则 schema 文档 `references/docs-rules-schema.yaml`

### MP3: 增量扫描 (AC-003, AC-012)

**目的**: 利用 git 历史只扫描变更文件,减少 token 消耗 90%。

**交付物**:
- 增量扫描模块
- Git 适配器
- Token 消耗日志

**影响范围**:
- `skills/devbooks-docs-consistency/scripts/scanner.sh`
- `skills/devbooks-docs-consistency/scripts/git-adapter.sh`

**验收标准**:
- 增量扫描 token 消耗 < 全量扫描 20%
- 扫描时间 < 10 秒
- 自动回退到全量扫描
- 性能基准测试: `scripts/benchmark-scan.sh`

**依赖**: MP1

**风险**: git diff 不准确导致遗漏文件

- [x] MP3.1 实现 Git 适配器(getChangedFiles, getDiff)
- [x] MP3.2 实现增量扫描策略(只处理变更文件)
- [x] MP3.3 实现全量扫描回退逻辑
- [x] MP3.4 实现 token 消耗记录(写入 evidence/token-usage.log)
- [x] MP3.5 实现扫描时间记录(写入 evidence/scan-performance.log)
- [x] MP3.6 创建性能基准测试脚本 `scripts/benchmark-scan.sh`

### MP4: 完备性检查 (AC-004)

**目的**: 检查文档完备性,覆盖 5 个维度(环境依赖、安全权限、故障排查、配置说明、API 文档)。

**交付物**:
- 完备性检查器模块
- 维度配置文件
- 完备性报告

**影响范围**:
- `skills/devbooks-docs-consistency/scripts/completeness-checker.sh`
- `skills/devbooks-docs-consistency/references/completeness-dimensions.yaml`

**验收标准**:
- 覆盖 5 个维度
- 生成完备性报告到 `evidence/completeness-report.md`
- 只警告,不阻塞归档

**依赖**: MP1

**风险**: 检查过于严格导致大量误报

- [x] MP4.1 设计完备性检查器接口(checkDimension, generateReport)
- [x] MP4.2 实现 5 个维度检查逻辑(环境依赖、安全权限、故障排查、配置说明、API 文档)
- [x] MP4.3 实现完备性报告生成器
- [x] MP4.4 创建维度配置文件 `references/completeness-dimensions.yaml`
- [x] MP4.5 实现维度可配置扩展机制

### MP5: 文档分类 (AC-005)

**目的**: 区分活体文档、历史文档、概念性文档,应用不同检查策略。

**交付物**:
- 文档分类器模块
- 分类规则配置

**影响范围**:
- `skills/devbooks-docs-consistency/scripts/doc-classifier.sh`
- `skills/devbooks-docs-consistency/references/doc-classification.yaml`

**验收标准**:
- 正确分类三种文档类型
- 分类规则可配置
- 单元测试: `test-doc-classification.bats`

**依赖**: MP1

**风险**: 分类规则不准确导致检查策略错误

- [x] MP5.1 设计文档分类器接口(classifyDoc, loadClassificationRules)
- [x] MP5.2 实现文档类型识别逻辑(基于路径模式匹配)
- [x] MP5.3 实现分类规则配置解析器
- [x] MP5.4 创建默认分类规则 `references/doc-classification.yaml`
- [x] MP5.5 实现检查策略路由(根据文档类型选择检查策略)

### MP6: 共享方法论文档 (AC-006)

**目的**: 迁移完备性思维框架到共享目录,供多个 skills 引用。

**交付物**:
- `skills/_shared/references/完备性思维框架.md`
- 至少 3 个 skills 的引用更新

**影响范围**:
- `skills/_shared/references/完备性思维框架.md`
- `skills/devbooks-docs-consistency/skill.md`
- `skills/devbooks-proposal-author/skill.md`
- `skills/devbooks-design-doc/skill.md`

**验收标准**:
- 文件 `skills/_shared/references/完备性思维框架.md` 存在
- 至少 3 个 skills 引用该文档
- 验收命令: `grep -r "完备性思维框架" skills/*/skill.md | wc -l`

**依赖**: 无

**风险**: 引用路径错误导致文档无法访问

- [x] MP6.1 复制 `/Users/ozbombor/Projects/dev-playbooks-cn/如何构建完备的系统.md` 到 `skills/_shared/references/完备性思维框架.md`
- [x] MP6.2 更新 `skills/devbooks-docs-consistency/skill.md` 添加引用
- [x] MP6.3 更新 `skills/devbooks-proposal-author/skill.md` 添加引用
- [x] MP6.4 更新 `skills/devbooks-design-doc/skill.md` 添加引用

### MP7: Skills 集成 (AC-007)

**目的**: 与其他 skills 集成,确保文档一致性检查在关键流程中执行。

**交付物**:
- `devbooks-archiver` 集成调用
- `devbooks-brownfield-bootstrap` 元数据生成
- `devbooks-proposal-author` Challenger 审视

**影响范围**:
- `skills/devbooks-archiver/skill.md`
- `skills/devbooks-brownfield-bootstrap/skill.md`
- `skills/devbooks-proposal-author/skill.md`

**验收标准**:
- archiver 归档前调用 docs-consistency
- brownfield-bootstrap 生成 docs-maintenance.md
- proposal-author 包含 Challenger 审视
- 集成测试通过

**依赖**: MP1, MP4, MP8

**风险**: 集成调用破坏现有流程

- [x] MP7.1 更新 `skills/devbooks-archiver/skill.md` 添加 docs-consistency 调用
- [x] MP7.2 更新 `skills/devbooks-brownfield-bootstrap/skill.md` 添加 docs-maintenance.md 生成逻辑
- [x] MP7.3 更新 `skills/devbooks-proposal-author/skill.md` 添加 Challenger 审视章节

### MP8: 风格清理 (AC-008, AC-009)

**目的**: 去除浮夸词语,删除 MCP 增强功能。

**交付物**:
- 浮夸词语检测脚本
- MCP 增强章节删除
- 清理报告

**影响范围**:
- 所有 `skills/*/skill.md`

**验收标准**:
- 所有浮夸词语已删除
- 所有 MCP 增强章节已删除
- 清理报告: `evidence/fancy-words-removal.md`
- 验收命令: `! grep -rE "(最强大脑|智能|高效|强大|优雅|完美|革命性|颠覆性)" skills/*/skill.md`

**依赖**: 无

**风险**: 过度清理导致功能描述不准确

- [x] MP8.1 创建浮夸词语检测脚本 `scripts/detect-fancy-words.sh`
- [x] MP8.2 扫描所有 skills 检测浮夸词语
- [x] MP8.3 手动清理浮夸词语(保持功能描述准确性)
- [x] MP8.4 扫描所有 skills 检测 MCP 增强章节
- [x] MP8.5 删除所有 MCP 增强相关内容
- [x] MP8.6 生成清理报告 `evidence/fancy-words-removal.md`

### MP9: 专家角色声明机制 (AC-010)

**目的**: 建立专家角色声明协议,帮助 AI 选择合适的角色执行任务。

**交付物**:
- 专家列表文档
- AI 行为规范更新
- 所有 skills 的 recommended_experts 字段

**影响范围**:
- `skills/_shared/references/专家列表.md`
- `skills/_shared/references/AI行为规范.md`
- 所有 `skills/*/skill.md`

**验收标准**:
- 文件 `skills/_shared/references/专家列表.md` 存在
- AI 行为规范包含角色声明协议
- 至少 5 个 skills 包含 recommended_experts 字段
- 验收命令: `grep -q "recommended_experts" skills/devbooks-proposal-author/skill.md`

**依赖**: 无

**风险**: 角色定义不清晰导致 AI 选择错误

- [x] MP9.1 创建专家列表文档 `skills/_shared/references/专家列表.md`(包含常用角色及职责)
- [x] MP9.2 更新 `skills/_shared/references/AI行为规范.md` 添加角色声明协议
- [x] MP9.3 为所有 skills 添加 recommended_experts 字段(至少 5 个)

### MP10: 文档风格偏好持久化 (AC-011)

**目的**: 创建文档维护元数据文件,记录文档风格偏好。

**交付物**:
- `dev-playbooks/specs/_meta/docs-maintenance.md`
- 风格偏好优先级逻辑

**影响范围**:
- `dev-playbooks/specs/_meta/docs-maintenance.md`
- `skills/devbooks-docs-consistency/scripts/style-checker.sh`

**验收标准**:
- 文件 `dev-playbooks/specs/_meta/docs-maintenance.md` 存在
- 包含 style_preferences 字段
- 包含 use_emoji: false 和 use_fancy_words: false
- 验收命令: `test -f dev-playbooks/specs/_meta/docs-maintenance.md && grep -q "style_preferences" dev-playbooks/specs/_meta/docs-maintenance.md`

**依赖**: MP1

**风险**: 优先级逻辑不清晰导致配置冲突

- [x] MP10.1 创建 `dev-playbooks/specs/_meta/` 目录
- [x] MP10.2 创建 `docs-maintenance.md` 文件(包含 version, style_preferences, forbidden_words)
- [x] MP10.3 实现风格偏好加载逻辑(命令行参数 > 配置文件 > 默认值)
- [x] MP10.4 实现风格检查器 `scripts/style-checker.sh`

---

## 临时计划区 (Temporary Plan Area)

(预留,用于计划外紧急任务)

---

## 计划细化区

### Scope & Non-goals

**Scope**:
- Skill 改名与别名机制
- 自定义规则引擎
- 增量扫描
- 完备性检查(5 个维度)
- 文档分类
- 共享方法论文档迁移
- Skills 集成
- 风格清理(浮夸词语、MCP 增强)
- 专家角色声明机制
- 文档风格偏好持久化

**Non-goals**:
- 不修改用户项目文档
- 不修改历史文档
- 不修改测试代码
- 不修改其他 skills 核心逻辑
- 不维护用户项目的 dev-playbooks/ 目录

### Architecture Delta

**新增模块**:
- `RulesEngine`: 规则引擎
- `Scanner`: 扫描器(增量/全量)
- `CompletenessChecker`: 完备性检查器
- `DocClassifier`: 文档分类器
- `StyleChecker`: 风格检查器
- `GitAdapter`: Git 适配器

**依赖方向**:
- 其他 skills → docs-consistency
- docs-consistency → git、文件系统、配置文件
- 禁止依赖: docs-consistency ✗→ MCP

**扩展点**:
- 规则扩展: `references/docs-rules-schema.yaml`
- 维度扩展: `references/completeness-dimensions.yaml`
- 分类扩展: `references/doc-classification.yaml`
- 风格扩展: `specs/_meta/docs-maintenance.md`

### Data Contracts

**Artifacts**:

1. `docs-maintenance.md`
```yaml
version: 1.0
last_full_scan: 2026-01-22
style_preferences:
  use_emoji: false
  use_fancy_words: false
  forbidden_words: [...]
critical_docs: [...]
automated_docs: [...]
known_mappings: [...]
```
- schema_version: 1.0
- 兼容策略: 向后兼容,新增字段不破坏旧版本

2. `completeness-report.md`
```markdown
# 完备性检查报告
- 环境依赖: ✓ / ✗
- 安全权限: ✓ / ✗
- 故障排查: ✓ / ✗
- 配置说明: ✓ / ✗
- API 文档: ✓ / ✗
```
- schema_version: 1.0
- 兼容策略: 向后兼容

3. `token-usage.log`
```
2026-01-22 10:00:00 | incremental | 500 tokens
2026-01-22 11:00:00 | full | 10000 tokens
```
- schema_version: 1.0
- 兼容策略: 追加模式

### Milestones

**Phase 1: 核心功能 (Week 1-2)**
- MP1: Skill 改名与别名机制
- MP2: 自定义规则引擎
- MP3: 增量扫描
- 验收口径: AC-001, AC-002, AC-003, AC-012 通过

**Phase 2: 完备性与分类 (Week 3)**
- MP4: 完备性检查
- MP5: 文档分类
- 验收口径: AC-004, AC-005 通过

**Phase 3: 集成与清理 (Week 4)**
- MP6: 共享方法论文档
- MP7: Skills 集成
- MP8: 风格清理
- 验收口径: AC-006, AC-007, AC-008, AC-009 通过

**Phase 4: 角色与持久化 (Week 5)**
- MP9: 专家角色声明机制
- MP10: 文档风格偏好持久化
- 验收口径: AC-010, AC-011 通过

### Work Breakdown

**PR 切分建议**:
- PR1: MP1 (Skill 改名与别名)
- PR2: MP2 + MP3 (规则引擎 + 增量扫描)
- PR3: MP4 + MP5 (完备性检查 + 文档分类)
- PR4: MP6 (共享方法论)
- PR5: MP7 (Skills 集成)
- PR6: MP8 (风格清理)
- PR7: MP9 + MP10 (专家角色 + 风格持久化)

**可并行点**:
- MP1 与 MP6 可并行
- MP2 与 MP5 可并行
- MP4 与 MP5 可并行
- MP8 与 MP9 可并行

**依赖关系**:
- MP2, MP3, MP4, MP5, MP10 依赖 MP1
- MP7 依赖 MP1, MP4, MP8

### Deprecation & Cleanup

**弃用项: devbooks-docs-sync**
- 标记阶段(Month 1-3): 输出弃用警告,功能正常
- 警告阶段(Month 4-6): 增加警告频率
- 移除阶段(Month 7+): 移除别名,返回错误

**弃用项: MCP 增强功能**
- 立即移除: 删除所有 MCP 增强章节

### Dependency Policy

- 无外部依赖
- 只依赖 git、bash、标准 Unix 工具

### Quality Gates

- Shellcheck 静态检查通过
- 单元测试覆盖率 > 80%
- 所有 lint 检查通过
- 代码审查通过

### Guardrail Conflicts

**小变更约束评估**:
- MP1: ~50 行(改名 + 别名)
- MP2: ~200 行(规则引擎)
- MP3: ~150 行(增量扫描)
- MP4: ~200 行(完备性检查)
- MP5: ~100 行(文档分类)
- MP6: ~10 行(文档迁移)
- MP7: ~50 行(集成调用)
- MP8: ~100 行(风格清理)
- MP9: ~100 行(专家角色)
- MP10: ~50 行(风格持久化)

所有任务预期代码改动量 ≤ 200 行,符合小变更约束。

### Observability

**Metrics**:
- `token_usage_total`: 累计 token 消耗
- `scan_duration_seconds`: 扫描耗时
- `issues_found_total`: 发现问题总数
- `scan_mode`: 扫描模式(incremental/full)

**KPI**:
- token 消耗减少率: 增量扫描 < 全量扫描 20%
- 扫描速度: < 10 秒
- 问题检出率: 提升 50%

**SLO**:
- token 消耗 p95 < 20%
- 扫描时间 p99 < 10 秒

### Rollout & Rollback

**灰度策略**:
- Phase 1: 在测试项目验证
- Phase 2: 在 DevBooks 自身项目使用
- Phase 3: 推广到所有项目

**回滚条件**:
- 别名机制失效
- 增量扫描遗漏文件
- 完备性检查误报率 > 50%

**回滚方案**:
- 恢复 devbooks-docs-sync 为主名称
- 禁用增量扫描,使用全量扫描
- 降低完备性检查严格程度

### Risks & Edge Cases

**风险 1: 增量扫描遗漏文件**
- 检测: git diff 返回错误或为空
- 降级: 自动回退到全量扫描

**风险 2: 规则引擎执行失败**
- 检测: 规则执行抛出异常
- 降级: 跳过失败规则,继续执行其他规则

**风险 3: 完备性检查过于严格**
- 检测: 用户反馈
- 降级: 只输出警告,不阻塞归档

**风险 4: token 消耗超预算**
- 检测: token 消耗超过阈值(10k)
- 降级: 输出警告,建议优化

**风险 5: 别名机制失效**
- 检测: 别名调用失败
- 降级: 输出错误信息,提示使用新名称

### Open Questions

1. **规则引擎复杂度**: 是否需要支持规则优先级和规则依赖?
   - 建议: Phase 1 使用简单规则,根据反馈决定是否增强

2. **完备性检查严格程度**: 是否应该阻塞归档?
   - 建议: Phase 2 只警告,Phase 3 根据反馈决定是否阻塞

3. **文档风格偏好范围**: 是否应该扩展到代码注释?
   - 建议: Phase 1 只检查文档,Phase 4 根据需求决定是否扩展

---

## 断点区 (Context Switch Breakpoint Area)

**当前模式**: 主线计划模式

**断点信息**: (留空,用于未来切换主线/临时计划时记录)

**恢复指令**: (留空)

---

**计划完成**
