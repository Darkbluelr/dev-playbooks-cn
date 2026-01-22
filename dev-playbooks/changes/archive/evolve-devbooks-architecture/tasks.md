# Tasks: evolve-devbooks-architecture

> 产物落点：`openspec/changes/evolve-devbooks-architecture/tasks.md`
>
> 状态：**Draft**
> 日期：2026-01-11
> 依赖：design.md

---

## 主线计划（Main Track）

### Phase 1: 目录结构与基础设施

#### T1.1 创建 dev-playbooks/ 目录结构 [AC-E01]

**优先级**：P0
**依赖**：无
**产物**：目录结构

**任务内容**：
1. 创建 `dev-playbooks/` 根目录
2. 创建子目录结构：
   - `specs/`
   - `specs/_meta/`
   - `specs/_meta/anti-patterns/`
   - `specs/_staged/`
   - `specs/architecture/`
   - `changes/`
   - `changes/archive/`
   - `scripts/`
3. 验证目录结构符合 design.md §4.1

**验收锚点**：
- [ ] `dev-playbooks/` 存在
- [ ] 所有子目录已创建
- [ ] 结构符合设计

---

#### T1.2 创建 constitution.md 模板 [AC-E02]

**优先级**：P0
**依赖**：T1.1
**产物**：`dev-playbooks/constitution.md`

**任务内容**：
1. 按 design.md A.1 模板创建 `constitution.md`
2. 包含章节：
   - Part Zero：强制指令
   - 全局不可违背原则（GIP-01 ~ GIP-04）
   - 逃生舱口

**验收锚点**：
- [ ] 文件存在
- [ ] 包含所有必需章节
- [ ] 格式正确

---

#### T1.3 创建 project.md [AC-E01]

**优先级**：P0
**依赖**：T1.1
**产物**：`dev-playbooks/project.md`

**任务内容**：
1. 从现有 `openspec/project.md` 提取项目上下文部分
2. 移除重复的宪法内容（已拆分到 constitution.md）
3. 保留技术栈、约定、领域上下文等

**验收锚点**：
- [ ] 文件存在
- [ ] 内容不与 constitution.md 重复

---

#### T1.4 创建/更新 .devbooks/config.yaml [AC-E01]

**优先级**：P0
**依赖**：T1.1
**产物**：`.devbooks/config.yaml`

**任务内容**：
1. 创建新格式配置文件
2. 配置项：
   - root: dev-playbooks/
   - constitution: constitution.md
   - project: project.md
   - paths 子配置
   - constraints 子配置
   - fitness 子配置
   - tracing 子配置

**验收锚点**：
- [ ] 文件存在
- [ ] 格式符合 spec（config-protocol/spec.md REQ-CFG-002）

---

#### T1.5 迁移 openspec/specs/ 内容 [AC-E01]

**优先级**：P0
**依赖**：T1.1
**产物**：`dev-playbooks/specs/` 内容

**任务内容**：
1. 复制 `openspec/specs/` → `dev-playbooks/specs/`
2. 保留目录结构
3. 验证文件完整性

**验收锚点**：
- [ ] 所有文件已迁移
- [ ] 目录结构保持一致

---

#### T1.6 迁移 openspec/changes/ 内容 [AC-E01]

**优先级**：P0
**依赖**：T1.1
**产物**：`dev-playbooks/changes/` 内容

**任务内容**：
1. 复制 `openspec/changes/` → `dev-playbooks/changes/`
2. 包括 archive/ 目录
3. 验证文件完整性

**验收锚点**：
- [ ] 所有文件已迁移
- [ ] archive/ 内容完整

---

### Phase 2: 宪法与配置发现机制

#### T2.1 实现 constitution-check.sh [AC-E03]

**优先级**：P0
**依赖**：T1.2
**产物**：`skills/devbooks-delivery-workflow/scripts/constitution-check.sh`

**任务内容**：
1. 实现宪法检查脚本
2. 检查项：
   - 文件存在
   - Part Zero 章节
   - GIP-xxx 规则
   - 逃生舱口章节
3. 支持 --help 参数
4. 遵守退出码契约（0/1/2）

**验收锚点**：
- [ ] 脚本可执行
- [ ] --help 输出正确
- [ ] 检查逻辑正确
- [ ] 退出码符合契约

---

#### T2.2 修改 config-discovery.sh 支持新路径 [AC-E02]

**优先级**：P0
**依赖**：T1.4
**产物**：修改后的 `config-discovery.sh`（或新建）

**任务内容**：
1. 实现 `resolve_truth_root()` 函数
   - 优先检查 dev-playbooks/
   - 回退到 openspec/（兼容）
2. 实现 `load_constitution()` 函数
   - 强制加载宪法（如配置要求）
3. 实现纯 Bash YAML 解析（无 yq 依赖）
4. 输出新格式环境变量

**验收锚点**：
- [ ] 新路径正确识别
- [ ] 旧路径兼容
- [ ] 宪法自动加载
- [ ] 无 yq 依赖

---

#### T2.3 修改 change-check.sh 增加宪法检查 [AC-E03]

**优先级**：P0
**依赖**：T2.1, T2.2
**产物**：修改后的 `change-check.sh`

**任务内容**：
1. 在检查流程中调用 `constitution-check.sh`
2. strict 模式下宪法检查失败则整体失败
3. 输出宪法检查结果

**验收锚点**：
- [ ] strict 模式包含宪法检查
- [ ] 检查失败时输出清晰

---

### Phase 3: AC 追溯与适应度检查

#### T3.1 实现 ac-trace-check.sh [AC-E05]

**优先级**：P0
**依赖**：T1.6
**产物**：`skills/devbooks-delivery-workflow/scripts/ac-trace-check.sh`

**任务内容**：
1. 实现 AC-ID 提取逻辑（从 design.md）
2. 实现任务 AC 提取（从 tasks.md）
3. 实现测试 AC 提取（从 tests/）
4. 计算覆盖率
5. 支持 --threshold 参数
6. 支持 --output json 格式
7. 支持 --help 参数

**验收锚点**：
- [ ] 正确提取 AC-ID
- [ ] 覆盖率计算正确
- [ ] 输出格式清晰
- [ ] 退出码符合契约

---

#### T3.2 实现 fitness-check.sh [AC-E04]

**优先级**：P1
**依赖**：T1.1
**产物**：`skills/devbooks-delivery-workflow/scripts/fitness-check.sh`

**任务内容**：
1. 实现规则文件解析
2. 实现分层架构检查（FR-001）
3. 实现循环依赖检查（FR-002，基础版）
4. 实现敏感文件守护（FR-003）
5. 支持 --mode warn/error
6. 支持 --help 参数

**验收锚点**：
- [ ] 规则解析正确
- [ ] 检查逻辑有效
- [ ] mode 参数生效
- [ ] 退出码符合契约

---

#### T3.3 创建 fitness-rules.md 模板 [AC-E04]

**优先级**：P1
**依赖**：T1.1
**产物**：`dev-playbooks/specs/architecture/fitness-rules.md`

**任务内容**：
1. 按 design.md A.2 模板创建规则文件
2. 包含规则：
   - FR-001：分层架构检查
   - FR-002：禁止循环依赖
   - FR-003：敏感文件守护

**验收锚点**：
- [ ] 文件存在
- [ ] 规则格式正确

---

#### T3.4 修改 change-check.sh 增加适应度检查 [AC-E04]

**优先级**：P1
**依赖**：T3.2, T3.3
**产物**：修改后的 `change-check.sh`

**任务内容**：
1. 在检查流程中调用 `fitness-check.sh`
2. 根据配置 fitness.mode 决定是否阻断
3. 输出适应度检查结果

**验收锚点**：
- [ ] 适应度检查集成
- [ ] mode 配置生效

---

### Phase 4: 三层同步脚本

#### T4.1 实现 spec-preview.sh [AC-E06]

**优先级**：P1
**依赖**：T1.6
**产物**：`skills/devbooks-delivery-workflow/scripts/spec-preview.sh`

**任务内容**：
1. 读取变更包的 spec delta
2. 检查 _staged/ 中的冲突
3. 检测文件级冲突
4. 检测内容级冲突（REQ-xxx）
5. 输出冲突报告
6. 支持 --help 参数

**验收锚点**：
- [ ] 正确检测文件级冲突
- [ ] 冲突报告清晰
- [ ] 退出码符合契约

---

#### T4.2 实现 spec-stage.sh [AC-E06]

**优先级**：P1
**依赖**：T4.1
**产物**：`skills/devbooks-delivery-workflow/scripts/spec-stage.sh`

**任务内容**：
1. 调用 spec-preview 检查冲突
2. 无冲突时复制到 _staged/
3. 有冲突时报错（除非 --force）
4. 支持 --dry-run 参数
5. 支持 --help 参数

**验收锚点**：
- [ ] 正确复制文件
- [ ] 冲突处理正确
- [ ] dry-run 不修改文件

---

#### T4.3 实现 spec-promote.sh [AC-E06]

**优先级**：P1
**依赖**：T4.2
**产物**：`skills/devbooks-delivery-workflow/scripts/spec-promote.sh`

**任务内容**：
1. 检查前置条件（已 stage）
2. 移动 _staged/ 内容到 specs/
3. 清理 _staged/ 目录
4. 支持 --dry-run 参数
5. 支持 --help 参数

**验收锚点**：
- [ ] 前置条件检查有效
- [ ] 文件正确移动
- [ ] 暂存目录已清理

---

#### T4.4 实现 spec-rollback.sh [AC-E06]

**优先级**：P2
**依赖**：T4.3
**产物**：`skills/devbooks-delivery-workflow/scripts/spec-rollback.sh`

**任务内容**：
1. 支持回滚到 staged 或 draft
2. 清理相应层的文件
3. 保留变更包中的 spec delta
4. 支持 --dry-run 参数
5. 支持 --help 参数

**验收锚点**：
- [ ] 回滚逻辑正确
- [ ] 变更包内容保留
- [ ] dry-run 不修改文件

---

### Phase 5: 反模式库与迁移脚本

#### T5.1 创建反模式文档 AP-001 [AC-E09]

**优先级**：P2
**依赖**：T1.1
**产物**：`dev-playbooks/specs/_meta/anti-patterns/AP-001-direct-db-in-controller.md`

**任务内容**：
1. 按 design.md A.3 模板创建
2. 描述 Controller 直接访问数据库的反模式
3. 给出正确做法

**验收锚点**：
- [ ] 文件存在
- [ ] 格式正确

---

#### T5.2 创建反模式文档 AP-002 [AC-E09]

**优先级**：P2
**依赖**：T1.1
**产物**：`dev-playbooks/specs/_meta/anti-patterns/AP-002-god-class.md`

**任务内容**：
1. 描述 God Class 反模式
2. 给出识别标准和正确做法

**验收锚点**：
- [ ] 文件存在
- [ ] 格式正确

---

#### T5.3 创建反模式文档 AP-003 [AC-E09]

**优先级**：P2
**依赖**：T1.1
**产物**：`dev-playbooks/specs/_meta/anti-patterns/AP-003-circular-dependency.md`

**任务内容**：
1. 描述循环依赖反模式
2. 给出检测方法和正确做法

**验收锚点**：
- [ ] 文件存在
- [ ] 格式正确

---

#### T5.4 实现 migrate-to-devbooks-2.sh [AC-E08]

**优先级**：P1
**依赖**：T1.1 ~ T1.6
**产物**：`skills/devbooks-delivery-workflow/scripts/migrate-to-devbooks-2.sh`

**任务内容**：
1. 实现状态检查点机制
2. 实现目录创建步骤
3. 实现内容迁移步骤
4. 实现引用更新步骤（批量替换）
5. 支持 --dry-run 参数
6. 支持 --keep-old 参数
7. 支持 --force 参数
8. 支持 --help 参数
9. 幂等执行

**验收锚点**：
- [ ] 迁移流程完整
- [ ] 幂等性有效
- [ ] 引用更新正确
- [ ] 参数生效

---

#### T5.5 实现 rollback-to-openspec.sh [AC-E10]

**优先级**：P2
**依赖**：T5.4
**产物**：`skills/devbooks-delivery-workflow/scripts/rollback-to-openspec.sh`

**任务内容**：
1. 按 proposal §4.5.2 实现回滚脚本
2. 恢复 openspec/ 结构
3. 设置 legacy 模式
4. 记录耗时

**验收锚点**：
- [ ] 回滚逻辑正确
- [ ] 耗时 < 15 分钟

---

### Phase 6: 收尾与清理

#### T6.1 更新所有文档路径引用 [AC-E07]

**优先级**：P1
**依赖**：T5.4
**产物**：更新后的文档

**任务内容**：
1. 搜索所有 `openspec/` 引用
2. 批量替换为 `dev-playbooks/`
3. 验证替换正确

**验收锚点**：
- [ ] 无残留的 openspec/ 引用

---

#### T6.2 删除 openspec/ 目录 [AC-E07]

**优先级**：P0（最后执行）
**依赖**：T6.1，所有测试通过
**产物**：无（删除）

**任务内容**：
1. 确认所有内容已迁移
2. 确认所有引用已更新
3. 删除 openspec/ 目录

**验收锚点**：
- [ ] openspec/ 不存在
- [ ] 功能正常

---

#### T6.3 执行回滚演练 [AC-E10]

**优先级**：P1
**依赖**：T5.5
**产物**：`evidence/rollback-drill.log`

**任务内容**：
1. 在测试分支执行完整变更
2. 执行全量回滚
3. 记录耗时
4. 验证回滚后功能正常

**验收锚点**：
- [ ] 耗时 < 15 分钟
- [ ] 回滚后功能正常

---

## 临时计划（Spike/Research）

### SP-1: fitness-check.sh 性能基准测试

**触发条件**：T3.2 完成后
**目标**：验证 fitness-check.sh 在大型项目上 <5s

**任务**：
1. 准备测试数据集（模拟大型项目）
2. 执行性能测试
3. 记录结果到 `evidence/fitness-perf.log`

---

## 断点区（Breakpoints）

| 断点 | 条件 | 处置 |
|------|------|------|
| BP-1 | config-discovery.sh 路径解析失败 | 回退到旧路径，记录问题 |
| BP-2 | 迁移脚本引用更新不完整 | 手动补充，更新脚本 |
| BP-3 | 测试覆盖率 <80% | 补充测试后继续 |

---

## AC → 任务映射

| AC ID | 任务 |
|-------|------|
| AC-E01 | T1.1, T1.3, T1.4, T1.5, T1.6 |
| AC-E02 | T1.2, T2.2 |
| AC-E03 | T2.1, T2.3 |
| AC-E04 | T3.2, T3.3, T3.4 |
| AC-E05 | T3.1 |
| AC-E06 | T4.1, T4.2, T4.3, T4.4 |
| AC-E07 | T6.1, T6.2 |
| AC-E08 | T5.4 |
| AC-E09 | T5.1, T5.2, T5.3 |
| AC-E10 | T5.5, T6.3 |

---

## 执行顺序建议

```
Phase 1 (P0) ────────────────────────────────────────────────►
  T1.1 → T1.2 → T1.3 → T1.4 → T1.5 → T1.6

Phase 2 (P0) ────────────────────────────────────────────────►
  T2.1 → T2.2 → T2.3

Phase 3 (P0/P1) ─────────────────────────────────────────────►
  T3.1 → T3.2 → T3.3 → T3.4

Phase 4 (P1) ────────────────────────────────────────────────►
  T4.1 → T4.2 → T4.3 → T4.4

Phase 5 (P1/P2) ─────────────────────────────────────────────►
  T5.1, T5.2, T5.3（可并行）
  T5.4 → T5.5

Phase 6 (P0/P1) ─────────────────────────────────────────────►
  T6.1 → T6.2 → T6.3
```

---

**编码计划完成**

下一步：
1. Test Owner 产出 `verification.md` + 测试用例（独立对话）
2. Coder 按此计划实现（独立对话）
