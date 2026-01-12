# Proposal: redesign-slash-command-routing

---
status: Approved
author: Proposal Author
created: 2026-01-12
judge_date: 2026-01-12
revision: 3
revision_date: 2026-01-12
---

## Why（动机）

### 问题陈述

当前 DevBooks 的 Slash 命令设计存在以下问题：

1. **命令与 Skill 不对应**：现有 6 个命令（proposal, design, apply, review, archive, quick）无法覆盖 21 个 Skills
2. **阶段绑定过紧**：同一个 Skill（如 `devbooks-spec-contract`）在不同阶段需要不同的调用方式，用户需要记住"proposal 阶段的 spec-contract"和"apply 阶段的 spec-contract（补漏）"
3. **关键角色缺失入口**：Planner（生成 tasks.md）、Challenger、Judge、Impact Analyst 等关键角色没有直接入口
4. **MCP 增强提示词分离**：用户需要手动选择"基础提示词"还是"完全体提示词"
5. **用户认知负担高**：需要阅读完全体提示词文档才知道有哪些角色可用

### 业务影响

- 用户体验差：需要记忆大量命令和阶段组合
- 工作流断裂：关键步骤（如 Planner）没有入口，容易遗漏
- MCP 能力浪费：即使安装了 CKB/code-intelligence，用户可能不知道如何利用

### 根因分析

设计时将"阶段"作为一级维度，而非"Skill"。导致：
- 命令按阶段分组，而非按能力分组
- 同一 Skill 在不同阶段被当作不同命令处理
- Skill 缺乏上下文感知能力，依赖外部指定"模式"

---

## What（目标）

### 目标状态

1. **命令与 Skill 1:1 对应**：21 个 Skill → 21 个核心 Slash 命令（另有 3 个向后兼容命令，共 24 个文件）
2. **双入口模式**：
   - **主入口**：`/devbooks:router` —— 适用于复杂变更（>5文件或跨模块），Router 读取 Impact 画像生成完整执行计划
   - **直达入口**：`/devbooks:<skill>` —— 适用于已知要执行的具体 Skill（如专家用户、简单变更、调试场景）
3. **Skill 自动上下文感知**：Skill 内部检测已有产物、当前阶段，自动调整行为
4. **MCP 运行时检测**：执行时自动检测可用工具，注入增强或降级

### 非目标

- 不改变 Skill 的核心职责
- 不改变变更包目录结构
- 不改变角色隔离原则

### 成功标准

| 指标 | 当前 | 目标 |
|------|------|------|
| Slash 命令数量 | 6 | 24（21 核心 + 3 向后兼容） |
| 入口模式 | 6 阶段命令 | 双入口（Router + 直达） |
| MCP 增强覆盖 | 手动选择 | 自动检测 |
| Planner 入口 | 无 | `/devbooks:plan` |
| 上下文感知模板 | 无 | `skills/_shared/context-detection-template.md` |

---

## Impact（影响分析）

> 本节由 Impact Analyst 于 2026-01-12 完成深度分析。

### 影响画像

```yaml
impact_profile:
  external_api: false
  architecture_boundary: true    # 新增 templates/claude-commands/ 下的命令文件
  data_model: false
  cross_repo: false
  risk_level: medium
  scope:
    new_files: 18               # 新增 18 个 slash 命令模板（21 总计 - 3 已存在）
    modified_files: 28          # 21 SKILL.md + CLI + C4 + 验证脚本 + README 等
    deleted_files: 0
  affected_modules:
    - name: templates/claude-commands/devbooks/
      type: add
      files: 18
    - name: skills/devbooks-*/SKILL.md
      type: modify
      files: 21
    - name: dev-playbooks/specs/architecture/c4.md
      type: modify
      files: 1
    - name: verify-slash-commands.sh
      type: modify
      files: 1
```

### Scope（影响范围）

- **直接影响**：28 个文件
- **间接影响**：文档引用（README.md、AGENTS.md）、用户安装后的 `.claude/commands/devbooks/`

### Impacts（详细影响清单）

| 文件/模块 | 影响类型 | 风险等级 | 说明 |
|-----------|----------|----------|------|
| `templates/claude-commands/devbooks/` | 新增 18 个文件 | 中 | 新增 router.md, impact.md, challenger.md, judge.md, debate.md, spec.md, c4.md, plan.md, test.md, code.md, test-review.md, backport.md, gardener.md, entropy.md, federation.md, bootstrap.md, index.md, delivery.md（已存在：proposal.md, design.md, review.md）|
| `skills/devbooks-*/SKILL.md` (21 个) | 修改 | 中 | 添加"上下文感知"章节（检测产物存在性、当前阶段）、"MCP 增强"章节（自动检测工具可用性） |
| `bin/create-devbooks.js:128-149` | 无需修改 | 低 | `installSlashCommands()` 使用 `copyDirSync()` 递归复制，自动支持新增文件 |
| `dev-playbooks/specs/architecture/c4.md:110-123` | 修改 | 高 | 需更新 `templates/claude-commands/devbooks/ 组件` 表格，从 6 个命令扩展到 21 个 |
| `dev-playbooks/specs/architecture/c4.md:265-270` | 修改 | 高 | **FT-009 规则** 需从 `cmd_count -eq 6` 改为 `cmd_count -eq 21`（精确值，非 -ge） |
| `skills/devbooks-delivery-workflow/scripts/verify-slash-commands.sh` | 修改 | 高 | 需新增 AC-011 ~ AC-028 验证 18 个新命令存在性 |
| `skills/devbooks-router/SKILL.md` | 修改 | 中 | 更新"DevBooks 命令适配"章节，反映 21 命令入口 |
| `dev-playbooks/project-profile.md` | 修改 | 中 | 同步命令数量变更（V-03） |
| `README.md` | 修改 | 低 | 更新命令列表文档 |
| `setup/generic/安装提示词.md` | 修改 | 低 | 若引用命令列表需更新 |

### Risks（风险评估）

| 风险 | 概率 | 影响 | 严重程度 | 缓解措施 |
|------|------|------|----------|---------|
| FT-009 规则断言失败 | 高 | 高 | **Critical** | 必须同步修改 c4.md 中 FT-009 的检查条件 |
| verify-slash-commands.sh 不覆盖新命令 | 高 | 中 | High | 新增 AC-011 ~ AC-025 验证项 |
| **Router 解析失败** | 中 | 高 | **High** | 当 Router 无法解析 Impact 画像时：1) 输出错误提示 + 缺失字段清单；2) 提供降级方案：用户可使用直达命令 `/devbooks:<skill>` 手动执行 |
| **Router 推荐流程不完整** | 中 | 中 | Medium | Router 输出明确声明"建议流程"，允许用户跳过/增加步骤；新增 `--dry-run` 模式预览计划 |
| 命令数量过多，用户仍难记忆 | 中 | 中 | Medium | 双入口设计：新手用 Router，专家用直达命令 |
| Skill 上下文检测逻辑复杂 | 中 | 中 | Medium | 明确检测规则，基于文件存在性 + 完整性校验，写入标准模板 |
| MCP 检测失败导致功能降级 | 低 | 低 | Low | 设置 2s 超时，降级到基础提示词仍可用 |
| 现有用户 muscle memory | 低 | 低 | Low | 保留旧命令（proposal/design/apply/review/archive/quick）完全兼容 |

### Minimal Diff（最小变更路径）

按优先级执行：

1. **P0（阻断性）**：修改 `c4.md` 的 FT-009 规则
2. **P1（核心）**：创建 15 个新命令模板文件
3. **P2（验证）**：更新 `verify-slash-commands.sh` 新增验证项
4. **P3（文档）**：更新 C4 组件表、README、AGENTS.md
5. **P4（增强）**：为 21 个 SKILL.md 添加上下文感知/MCP 增强章节

### Open Questions

1. **Q**: 新命令是否需要在 `install-skills.sh` 中额外处理？
   - **A**: 否，`create-devbooks.js` 已使用递归复制，自动支持。

2. **Q**: 是否需要版本化命令模板（v1 vs v2）？
   - **A**: 建议暂不版本化，使用 `--update-skills` 覆盖即可。

3. **Q**: 上下文感知规则是否需要标准化模板？
   - **A**: 是，建议在 `skills/_shared/context-detection-template.md` 提供标准模板。

4. **Q**: MCP 检测超时后如何提示用户？
   - **A**: 在 Skill 输出开头显示 `[MCP 检测超时，已降级为基础模式]`

### Rollback（回滚方案）

**回滚触发条件**：
- FT-009 验证失败且无法快速修复
- 新命令导致 CLI 安装流程中断
- Router 解析失败率 > 50%

**回滚步骤**：

1. **恢复 FT-009 规则**（P0）
   ```bash
   git revert <commit-hash-of-c4-change>
   ```

2. **删除新增命令模板**（P1）
   ```bash
   rm -rf templates/claude-commands/devbooks/{router,impact,challenger,judge,debate,spec,c4,plan,test,code,test-review,backport,gardener,entropy,federation,bootstrap,index,delivery}.md
   ```

3. **恢复验证脚本**（P2）
   ```bash
   git checkout HEAD~1 -- skills/devbooks-delivery-workflow/scripts/verify-slash-commands.sh
   ```

4. **通知用户**（P3）
   - 在 README.md 发布变更回滚说明
   - 原有 6 命令入口保持可用，用户无感知

**回滚验证**：
```bash
./skills/devbooks-delivery-workflow/scripts/verify-slash-commands.sh
# 期望输出：AC-001 ~ AC-010 全部通过
```

**Dry-run 记录**（V-02：apply 阶段执行并记录）：
> 注：回滚命令需在 apply 阶段实际执行 dry-run，记录输出到 `evidence/rollback-dry-run.log`

---

## Constraints（约束）

### 技术约束

- C-01: 命令模板必须放在 `templates/claude-commands/devbooks/`，安装时复制到用户项目
- C-02: Skill 上下文检测只能基于文件存在性，不能依赖外部状态
- C-03: MCP 检测必须有超时机制，避免阻塞

### 业务约束

- C-04: 保持向后兼容，现有 6 个命令的调用方式不变
- C-05: 命令名称使用短横线分隔（如 `spec-contract`），与 Skill 名称一致

### 组织约束

- C-06: 变更不得影响现有变更包的归档流程

---

## Alternatives（备选方案）

### 方案 A：保持现状 + 补充文档

- **描述**：不改代码，完善用户文档
- **优点**：零风险，快速
- **缺点**：治标不治本，用户体验无改善
- **结论**：❌ 拒绝

### 方案 B：阶段入口 + 角色参数（当前设计的改进）

- **描述**：保持 6 个入口，增加 `--role` 参数细分
- **优点**：改动小
- **缺点**：部分 Skill（entropy-monitor, federation）不属于任何阶段
- **结论**：❌ 拒绝

### 方案 C：命令与 Skill 1:1 + Router 驱动（推荐）

- **描述**：21 个命令，Router 生成执行计划，Skill 自动感知上下文
- **优点**：概念清晰，用户认知负担最低，MCP 自动增强
- **缺点**：实现工作量大
- **结论**：✅ 采纳

### 方案 D：动态生成命令

- **描述**：CLI 在安装时扫描 SKILL.md 元数据，自动生成命令
- **优点**：最灵活，新增 Skill 自动有命令
- **缺点**：实现复杂，调试困难
- **结论**：⏳ 未来迭代考虑

---

## Proposal（提案内容）

### 1. 命令列表（21 个）

| 命令 | Skill | 自动感知上下文 |
|------|-------|---------------|
| `/devbooks:router` | devbooks-router | - |
| `/devbooks:proposal` | devbooks-proposal-author | - |
| `/devbooks:impact` | devbooks-impact-analysis | MCP 可用性 |
| `/devbooks:challenger` | devbooks-proposal-challenger | - |
| `/devbooks:judge` | devbooks-proposal-judge | - |
| `/devbooks:debate` | devbooks-proposal-debate-workflow | - |
| `/devbooks:design` | devbooks-design-doc | - |
| `/devbooks:spec` | devbooks-spec-contract | 是否已有 spec |
| `/devbooks:c4` | devbooks-c4-map | 是否已有 c4.md |
| `/devbooks:plan` | devbooks-implementation-plan | - |
| `/devbooks:test` | devbooks-test-owner | - |
| `/devbooks:code` | devbooks-coder | 热点检测、MCP |
| `/devbooks:review` | devbooks-code-review | 热点检测 |
| `/devbooks:test-review` | devbooks-test-reviewer | - |
| `/devbooks:backport` | devbooks-design-backport | - |
| `/devbooks:gardener` | devbooks-spec-gardener | - |
| `/devbooks:entropy` | devbooks-entropy-monitor | - |
| `/devbooks:federation` | devbooks-federation | - |
| `/devbooks:bootstrap` | devbooks-brownfield-bootstrap | - |
| `/devbooks:index` | devbooks-index-bootstrap | - |
| `/devbooks:delivery` | devbooks-delivery-workflow | - |

### 2. Router 输出格式

Router 读取 `proposal.md` 的 Impact 部分（结构化），输出执行计划：

```markdown
# 执行计划：<change-id>

## 影响画像
- 对外 API：是/否
- 架构边界：是/否
- 数据模型：是/否
- 跨仓库：是/否
- 风险等级：高/中/低

## 完整流程

### Phase 1: Proposal
| 序号 | 命令 | 状态 | 原因 |
|------|------|------|------|
| 1 | `/devbooks:proposal` | ✅/⬜ | - |
| 2 | `/devbooks:impact` | ✅/⬜ | - |
...

## 跳过的步骤（原因）
- `/devbooks:xxx` - 原因
```

### 3. Skill 上下文感知规则

以 `devbooks-spec-contract` 为例：

```markdown
## 上下文检测

执行时自动检测：

1. **产物存在性检测**
   - `<change-root>/<change-id>/specs/` 不存在 → "从零创建"模式
   - 存在但不完整 → "补漏"模式
   - 存在且完整 → "同步到真理源"模式

2. **完整性判断规则**（按 Req 分组校验，解决 B-01）

   **算法**：
   ```bash
   #!/bin/bash
   # completeness-check.sh <spec-delta-file>

   SPEC_FILE="$1"
   INCOMPLETE=0

   # 提取所有 Requirement ID
   REQ_IDS=$(grep -oP '(?<=^### Requirement: )REQ-\d+' "$SPEC_FILE")

   for REQ_ID in $REQ_IDS; do
     # 找到该 Requirement 块的起止行
     START=$(grep -n "^### Requirement: $REQ_ID" "$SPEC_FILE" | cut -d: -f1)
     END=$(awk -v start="$START" 'NR>start && /^### Requirement:/{print NR-1; exit}' "$SPEC_FILE")
     [ -z "$END" ] && END=$(wc -l < "$SPEC_FILE")

     # 在该块内检查 Scenario 存在性
     BLOCK=$(sed -n "${START},${END}p" "$SPEC_FILE")
     if ! echo "$BLOCK" | grep -q "^#### Scenario:"; then
       echo "INCOMPLETE: $REQ_ID 缺少 Scenario"
       INCOMPLETE=1
       continue
     fi

     # 检查每个 Scenario 是否有 Given/When/Then
     SCENARIOS=$(echo "$BLOCK" | grep -n "^#### Scenario:" | cut -d: -f1)
     for SCENARIO_LINE in $SCENARIOS; do
       SCENARIO_BLOCK=$(echo "$BLOCK" | awk -v start="$SCENARIO_LINE" 'NR>=start && NR<start+20')
       for KEYWORD in "Given" "When" "Then"; do
         if ! echo "$SCENARIO_BLOCK" | grep -q "^- $KEYWORD"; then
           echo "INCOMPLETE: $REQ_ID Scenario 缺少 $KEYWORD"
           INCOMPLETE=1
         fi
       done
     done
   done

   # 检查占位符
   if grep -qE '\[TODO\]|\[待补充\]' "$SPEC_FILE"; then
     echo "INCOMPLETE: 存在占位符"
     INCOMPLETE=1
   fi

   exit $INCOMPLETE
   ```

   **判定结果**：
   - 退出码 0 → 完整
   - 退出码 1 → 不完整，输出缺失项

3. **当前阶段检测**
   - 只有 proposal.md → proposal 阶段
   - 有 design.md + tasks.md → apply 阶段
   - 有 verification.md + 测试通过 → archive 阶段

4. **行为调整**
   - proposal 阶段：写 change 包内的 spec delta
   - archive 阶段：合并到 specs/（真理源）
```

### 3.1 边界场景测试（V-01）

| # | 场景 | spec-delta.md 内容 | 期望结果 |
|---|------|-------------------|----------|
| 1 | 空文件 | 无内容 | 完整（无 Req 需校验） |
| 2 | 单 Req 无 Scenario | `### Requirement: REQ-001` | 不完整：REQ-001 缺少 Scenario |
| 3 | 单 Req 单 Scenario 完整 | REQ-001 + Scenario + Given/When/Then | 完整 |
| 4 | 单 Req 单 Scenario 缺 Then | REQ-001 + Scenario + Given/When | 不完整：缺少 Then |
| 5 | 多 Req 部分完整 | REQ-001 完整 + REQ-002 缺 Scenario | 不完整：REQ-002 缺少 Scenario |
| 6 | 含占位符 | REQ-001 完整 + `[TODO]` | 不完整：存在占位符 |
| 7 | Scenario 跨 Req 误判 | REQ-001 无 Scenario + REQ-002 有 Scenario | 不完整：REQ-001 缺少 Scenario（按块分组，不会误判） |

### 4. MCP 自动检测机制

每个 Skill 执行时：

1. 调用 `mcp__ckb__getStatus()` 检测 CKB
2. 调用 `ci_index_status()` 检测 code-intelligence
3. 根据结果组合提示词：
   - 全有 → 完全体提示词
   - 部分有 → 对应增强提示词
   - 都没有 → 基础提示词（Grep + Glob）

### 5. 影响分析结构化输出

要求 Impact Analyst 输出结构化的影响画像：

```yaml
impact_profile:
  external_api: true/false
  architecture_boundary: true/false
  data_model: true/false
  cross_repo: true/false
  risk_level: high/medium/low
  affected_modules:
    - name: xxx
      type: add/modify/delete
```

Router 读取此画像，自动推导流程。

---

## Debate Packet

### 支持论点（Pro）

1. **概念统一**：命令与 Skill 1:1，无需记忆映射关系
2. **入口收敛**：Router 生成完整计划，用户只需跟着走
3. **智能适配**：MCP 自动检测，用户无感知升级/降级
4. **关键角色补齐**：Planner、Challenger、Judge 有了直接入口
5. **上下文无感**：Skill 自动识别阶段，用户无需手动指定

### 反对论点（Con）

1. **命令数量增加**：从 6 个增加到 21 个
   - 反驳：用户主要通过 Router，不需要记忆全部命令
2. **实现复杂度高**：上下文检测逻辑需要仔细设计
   - 反驳：检测逻辑基于文件存在性，规则明确
3. **向后兼容风险**：现有用户可能习惯旧命令
   - 反驳：旧命令保留，只是增加新命令

### 关键假设

1. 用户愿意通过 Router 获取执行计划，而非直接记忆命令（适用于复杂变更）
2. 影响分析能产出足够结构化的信息供 Router 推导
3. ~~Skill 的上下文检测规则能覆盖 95% 以上场景~~ （已删除：无测量依据）

### 待验证假设（需实测数据）

以下假设需在实现后通过实测验证：

| 假设 | 验证方式 | 阈值 | 证据落点 |
|------|----------|------|----------|
| Router 能正确解析 Impact 画像 | 用 5 个历史变更测试（V-04） | 成功率 ≥ 80% | `evidence/router-parse-stats.md` |
| 上下文检测规则覆盖常见场景 | 用 7 个边界场景测试（见 3.1） | 误判率 ≤ 20% | `evidence/context-detection-test.log` |
| MCP 检测超时不影响用户体验 | 测量 P95 延迟 | ≤ 2s | `evidence/mcp-latency.log` |
| 回滚命令可执行 | dry-run 测试（V-02） | 无报错 | `evidence/rollback-dry-run.log` |

### 验证方式

1. 用 3-5 个真实变更案例测试 Router 输出的完整性
2. 用 5-10 个场景测试 Skill 上下文检测的准确性
3. 收集用户反馈，迭代优化

### 开放问题

1. **Q**: 如果 Router 推导的流程用户不认可，如何覆盖？
   - **A**: Router 输出的是"建议"，用户可以跳过或增加步骤
2. **Q**: 如果 MCP 检测耗时过长怎么办？
   - **A**: 设置 2 秒超时，超时则降级
3. **Q**: 是否需要"快速模式"跳过 Router？
   - **A**: 保留 `/devbooks:quick`，适用于 ≤5 文件的小变更

---

## Decision Log

| 日期 | 决策者 | 状态 | 说明 |
|------|--------|------|------|
| 2026-01-12 | - | Draft | 初稿 |
| 2026-01-12 | Proposal Judge | **Revise** | 逻辑矛盾（21命令 vs Router唯一入口）；上下文感知规则不完整（无法仅凭存在性区分补漏/完整）；95%假设无依据；Router失败风险未评估；AC缺失context-detection-template；无回滚方案。**必须修改项**：P0-明确主要使用模式、补充完整性判断规则；P1-删除无依据假设、补充Router失败风险；P2-新增AC-011、补充回滚方案 |
| 2026-01-12 | Proposal Author | **Pending** (Revision 2) | **已修正**：1) 明确双入口模式（Router 主入口 + 直达命令备选）；2) 补充完整性判断规则（基于清单校验 + 不完整信号识别）；3) 删除无依据的"95%覆盖"假设，新增待验证假设表；4) 补充 Router 解析失败/推荐流程不完整两项风险及缓解措施；5) 新增 AC-011/012/013；6) 新增完整回滚方案（触发条件 + 4 步回滚 + 验证命令）|
| 2026-01-12 | Proposal Judge | **Revise** | **阻断项**：(B-01) 完整性判断 grep 计数无法保证 Req-Scenario 1:1 对应；(B-02) AC-013 "已验证"无证据；(B-03) 命令数量 21 vs 22 不一致，FT-009 用 -ge 非精确值。**必须修改**：(M-01) 重写完整性判断为按 Req 分组校验；(M-02) AC-013 改为"待验证"或补充 evidence；(M-03) 明确命令数量并用精确值。**验证要求**：V-01 提供 5+ 边界场景测试；V-02 回滚 dry-run 记录；V-03 同步 project-profile.md；V-04 Router 解析统计 |
| 2026-01-12 | Proposal Author | **Pending** (Revision 3) | **已修正**：(M-01) 重写完整性判断为按 Req 分组校验算法（bash 脚本，按块遍历）；(M-02) AC-013 改为"待验证"状态，明确 apply 阶段执行 dry-run；(M-03) 命令数量统一为 21 个，新增 18 个文件（非 15），FT-009 改为 `-eq 21`。**新增**：V-01 补充 7 个边界场景测试表（3.1）；V-02 回滚 dry-run 记录说明；V-03 新增 AC-014 同步 project-profile.md；V-04 待验证假设表增加 Router 解析统计证据落点 |
| 2026-01-12 | Proposal Judge | **Approved** | **裁决依据**：Challenger 报告中 3 个阻断项均已在 Revision 3 修复——(B-01) 完整性判断已重写为按 Req 分组校验（§3 第 316-362 行），含 7 个边界测试（§3.1）；(B-02) AC-013 已改为"待验证"，明确 apply 阶段执行 dry-run；(B-03) 命令数量统一为 21，FT-009 使用精确值 `-eq 21`。非阻断项 N-01~N-03 均为实现细节或可接受权衡。**验证要求**：(V-01) apply 阶段执行边界场景测试并记录；(V-02) 回滚 dry-run 记录到 `evidence/rollback-dry-run.log`；(V-03) 同步 project-profile.md；(V-04) Router 解析测试记录到 `evidence/router-parse-stats.md`。**放行条件**：Design 阶段可开始，apply 阶段必须完成 V-01~V-04 证据收集 |

---

## Acceptance Criteria

- [ ] AC-001: 21 个 Slash 命令模板存在于 `templates/claude-commands/devbooks/`
- [ ] AC-002: 每个命令与对应 Skill 1:1 对应
- [ ] AC-003: Router 能读取 Impact 画像并输出完整执行计划
- [ ] AC-004: `devbooks-spec-contract` 能自动检测"从零/补漏/同步"模式
- [ ] AC-005: `devbooks-c4-map` 能自动检测"新增 delta/更新真理"模式
- [ ] AC-006: MCP 检测机制在 Skill 执行时触发
- [ ] AC-007: 检测超时（2s）时自动降级到基础提示词
- [ ] AC-008: 现有 6 个命令的调用方式保持兼容
- [ ] AC-009: C4 架构文档更新（FT-009 改为 `-eq 21`）
- [ ] AC-010: 验证脚本 `verify-slash-commands.sh` 更新（AC-011 ~ AC-028）
- [ ] AC-011: `skills/_shared/context-detection-template.md` 存在并包含完整性判断规则
- [ ] AC-012: Router 解析失败时输出错误提示和降级方案
- [ ] AC-013: 回滚方案可执行（**待验证**：apply 阶段执行 dry-run 并记录到 `evidence/rollback-dry-run.log`）
- [ ] AC-014: `dev-playbooks/project-profile.md` 同步更新命令数量（V-03）

---

## References

- `docs/完全体提示词.md` - 现有角色和提示词定义
- `skills/devbooks-router/SKILL.md` - Router 现有实现
- `templates/claude-commands/devbooks/` - 现有命令模板
