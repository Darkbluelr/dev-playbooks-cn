Test Owner Review（<truth-root>=dev-playbooks/specs, <change-root>=dev-playbooks/changes）
角色：Test Engineer

## 评审范围
- 目标文件：`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/verification.md`
- 参照设计：`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/design.md`
- 测试映射核对：`tests/20260124-0636-enhance-devbooks-longterm-guidance/*.bats`
- 证据目录：`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/evidence/`
- 环境命令存在性：`command -v bats`，`command -v rg`

## 结论
当前 `verification.md` 在 AC 覆盖与命令可执行性方面具备基础条件，但存在 4 项必须修订项（状态一致性、证据链完整性、测试计划 AC 对齐、人工抽查证据落点）。完成修订后再进入 Verified 或 Done。

## 已满足
- AC 覆盖：AC-101 至 AC-106 均有 Test ID 映射，测试总数 11，与测试类型分布一致。
- 测试命令可执行性：`bats` 与 `rg` 在本机可用，测试路径与文档路径存在。
- 实现细节边界：验证计划未包含实现步骤，只描述可检查的文档与规格要求。

## 需修订项（必须）
1. 状态不一致：`verification.md` 标记为 `Status: Done`，但 AC 覆盖矩阵未勾选，追溯矩阵状态为“待验证”。
   - 建议修订：将 Status 回退为 `Ready` 或 `Implementation Done`，待 Green 证据审计后由 Test Owner 设置 `Verified`，Reviewer 再设置 `Done`。
   - 验证方法：核对 `verification.md` 的 Status、AC 覆盖矩阵勾选状态、追溯矩阵状态是否一致。

2. 证据链不完整：追溯矩阵仅引用 Red 基线日志，未引用 Green 证据，且未记录提交版本。
   - 建议修订：在追溯矩阵的 Evidence 列补充 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/evidence/green-final/bats-2026-01-24-125942.log`，如流程要求提交版本，新增 commit hash 记录。
   - 验证方法：确认 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/evidence/green-final/` 存在通过日志并被引用。

3. 测试计划 AC 对齐偏差：TP1.3 的 Acceptance Criteria 未包含 AC-105，但候选 Test IDs 包含 `TEST-AC105-03` 与 `TEST-AC105-04`。
   - 建议修订：将上述 Test IDs 移至 TP1.2，或在 TP1.3 的 Acceptance Criteria 中补充 AC-105。
   - 验证方法：逐项核对每个 TP 条目的 AC 列表与 Test IDs 的 AC 归属一致。

4. 手工抽查命令与 MANUAL 清单不一致：验证命令清单标注“人工抽查”，但 MANUAL 清单为“无”，且未定义证据落点。
   - 建议修订：若需要人工抽查，新增 MANUAL-* 条目，写明步骤、Pass/Fail 判据与证据路径（建议 `dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/evidence/manual-acceptance/`）；若不需要，删除“人工抽查”表述并保持自动化验收单一入口。
   - 验证方法：检查 MANUAL 清单与验证命令清单一致，且证据路径明确。

## 可选改进
- AC 覆盖矩阵增加覆盖摘要（AC 总数、覆盖率），便于审计。
  - 验证方法：核对摘要数值与矩阵行数一致。

## 说明
- 未执行 `bats` 测试，仅验证命令可用性与文件存在性。
