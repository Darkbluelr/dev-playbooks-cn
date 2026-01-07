---
name: devbooks-federation
description: devbooks-federation：跨仓库联邦分析与契约同步。当变更涉及对外 API/契约、或需要分析跨仓库影响时使用。用户说"跨仓库影响/联邦分析/契约同步/上下游依赖/多仓库"等时使用。
tools:
  - Glob
  - Read
  - Bash
  - mcp__ckb__analyzeImpact
  - mcp__ckb__findReferences
  - mcp__github__search_code
  - mcp__github__create_issue
---

# DevBooks：跨仓库联邦分析（Federation Analysis）

## 触发条件

以下任一条件满足时自动执行：
1. 用户说"跨仓库影响/联邦分析/契约同步/上下游依赖/多仓库"
2. `devbooks-impact-analysis` 检测到变更涉及 `federation.yaml` 中定义的契约文件
3. 用户在 `proposal.md` 中标记了 `Impact: Cross-Repo`

## 前置条件

- 项目根目录存在 `.devbooks/federation.yaml` 或 `openspec/federation.yaml`
- 如需跨仓库搜索，需要 GitHub MCP 已配置

## 执行流程

### Step 1: 加载联邦配置

```bash
# 检测联邦配置文件
if [ -f ".devbooks/federation.yaml" ]; then
  FEDERATION_CONFIG=".devbooks/federation.yaml"
elif [ -f "openspec/federation.yaml" ]; then
  FEDERATION_CONFIG="openspec/federation.yaml"
else
  echo "未找到联邦配置，请先创建 federation.yaml"
  exit 1
fi
```

读取配置后提取：
- 上游依赖列表（我依赖谁）
- 下游消费者列表（谁依赖我）
- 契约文件列表

### Step 2: 识别契约变更

检查本次变更是否涉及契约文件：

```
变更文件 ∩ 契约文件 = 契约变更集
```

契约变更分类：
- **Breaking**：删除/重命名导出、修改必填参数、改变返回类型
- **Deprecation**：新增 `@deprecated` 注解
- **Enhancement**：新增可选参数、新增导出
- **Patch**：内部实现变更，不影响签名

### Step 3: 跨仓库影响分析

对于涉及契约变更的情况：

1. **本地分析**（使用 CKB）
   ```
   mcp__ckb__findReferences(symbolId=<契约符号>)
   mcp__ckb__analyzeImpact(symbolId=<契约符号>)
   ```

2. **远程搜索**（使用 GitHub MCP）
   ```
   mcp__github__search_code(query="<契约名> org:<org>")
   ```

3. **整合结果**
   - 本仓库内引用
   - 下游仓库引用（来自 GitHub 搜索）
   - 潜在影响范围估算

### Step 4: 生成联邦影响报告

输出格式：

```markdown
# 跨仓库影响分析报告

## 变更概要

| 契约文件 | 变更类型 | 影响级别 |
|---------|---------|---------|
| `src/api/v1/user.ts` | Breaking | 🔴 Critical |
| `src/types/order.ts` | Enhancement | 🟢 Safe |

## 本仓库影响

- 内部引用数：15
- 受影响模块：`services/`, `handlers/`

## 跨仓库影响

### 下游消费者

| 仓库 | 引用数 | 状态 |
|-----|-------|------|
| org/web-app | 8 | ⚠️ 需要同步 |
| org/mobile-app | 3 | ⚠️ 需要同步 |

### 建议动作

1. [ ] 在 org/web-app 创建适配 Issue
2. [ ] 在 org/mobile-app 创建适配 Issue
3. [ ] 更新 CHANGELOG
4. [ ] 发送 Slack 通知

## 兼容性策略

- [ ] 保持旧 API 可用（双写期）
- [ ] 添加 `@deprecated` 注解
- [ ] 设置移除日期：YYYY-MM-DD
```

### Step 5: 自动通知（可选）

如果配置了 `notify_on_change: true`：

1. 在下游仓库创建 Issue（使用 GitHub MCP）
2. 发送 Slack 通知（需配置 webhook）

Issue 模板：
```markdown
## 上游契约变更通知

**来源仓库**：org/my-service
**变更类型**：Breaking Change
**预计移除日期**：YYYY-MM-DD

### 受影响的契约

- `UserService.getUser()` - 参数签名变更

### 建议动作

请在 [deadline] 前完成以下适配：
1. 更新调用处以适配新签名
2. 运行测试确保兼容

### 相关链接

- 变更 PR：org/my-service#123
- 迁移指南：[链接]
```

## 脚本支持

### 联邦检查脚本

```bash
# 检查联邦约束
bash skills/devbooks-federation/scripts/federation-check.sh \
  --project-root "$(pwd)" \
  --change-files "src/api/v1/user.ts,src/types/order.ts"
```

### 契约同步脚本

```bash
# 生成下游通知
bash skills/devbooks-federation/scripts/federation-notify.sh \
  --project-root "$(pwd)" \
  --change-type breaking \
  --dry-run
```

## 与其他 Skills 的协作

- `devbooks-impact-analysis`：检测到跨仓库影响时自动调用本 Skill
- `devbooks-spec-contract`：契约定义变更时同步触发（合并了原 spec-delta + contract-data）
- `devbooks-proposal-author`：在 proposal.md 中自动标记 Cross-Repo Impact

## 注意事项

1. 跨仓库搜索依赖 GitHub MCP，需要适当的访问权限
2. 大型组织的搜索可能耗时较长，建议缩小搜索范围
3. 联邦配置应与团队同步，确保上下游信息准确
4. Breaking 变更建议使用语义版本控制（SemVer）

## 参考

- [Augment Code Federation](https://docs.augmentcode.com/federation) - 灵感来源
- [API Versioning Best Practices](https://swagger.io/resources/articles/best-practices-in-api-versioning/)
