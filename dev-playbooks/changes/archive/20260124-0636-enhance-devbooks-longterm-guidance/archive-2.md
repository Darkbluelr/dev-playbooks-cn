# 归档报告：20260124-0636-enhance-devbooks-longterm-guidance（archive-2）

truth-root=dev-playbooks/specs; change-root=dev-playbooks/changes

## 变更包信息

- Change ID：`20260124-0636-enhance-devbooks-longterm-guidance`
- 归档批次：2
- 归档时间：2026-01-24

## 配置发现

- 配置文件：`.devbooks/config.yaml`
- truth-root：`dev-playbooks/specs`
- change-root：`dev-playbooks/changes`
- change-dir（归档前）：`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance`
- change-dir（归档后）：`dev-playbooks/changes/archive/20260124-0636-enhance-devbooks-longterm-guidance`

## 关键证据

- Green 证据：`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/evidence/green-final/bats-2026-01-24-165458.log`
- 追溯更新说明：`dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance/evidence/green-final/verification-update-note.md`

## 执行记录

### Step 0：严格闸门（MANDATORY）

命令：
```bash
./skills/devbooks-delivery-workflow/scripts/change-check.sh 20260124-0636-enhance-devbooks-longterm-guidance --mode strict --project-root . --change-root dev-playbooks/changes --truth-root dev-playbooks/specs
```

结果：通过（无警告）。

### Step 1：前置检查（二次确认）

- `verification.md`：AC 覆盖矩阵与追溯矩阵均已 `[x]`，Status 已切到 `Archived`
- `evidence/green-final/`：存在且非空
- `tasks.md`：主线任务均为 `[x]`

### Step 2：自动回写（Design Backport）

- `deviation-log.md`：未发现（本次无需回写）

### Step 3：规格合并（stage → promote）

命令：
```bash
./skills/devbooks-delivery-workflow/scripts/spec-stage.sh 20260124-0636-enhance-devbooks-longterm-guidance --project-root . --change-root dev-playbooks/changes --truth-root dev-playbooks/specs
./skills/devbooks-delivery-workflow/scripts/spec-promote.sh 20260124-0636-enhance-devbooks-longterm-guidance --project-root . --truth-root dev-playbooks/specs
```

结果：
- promoted：5 个文件（包含 `specs/README.md` 与 4 份规格文件）

### Step 4：文档/技能一致性检查（证据）

命令（已在 Green 证据中落盘）：
```bash
bats tests/20260124-0636-enhance-devbooks-longterm-guidance/*.bats
```

结果：全绿（见上方 Green 证据路径）。

### Step 5：归档移动

目标路径：
- `dev-playbooks/changes/archive/20260124-0636-enhance-devbooks-longterm-guidance`

执行：
```bash
mv dev-playbooks/changes/20260124-0636-enhance-devbooks-longterm-guidance dev-playbooks/changes/archive/20260124-0636-enhance-devbooks-longterm-guidance
```

## 归档结果

- 归档状态：已归档（已移动至 archive/）
