# Pull Request 模板与指南

借鉴 VS Code 的 `.github/pull_request_template.md`，本文档定义了 PR 提交的标准流程。

---

## 1) PR 模板

```markdown
## Summary

<!-- 用 1-3 句话描述这个 PR 做了什么 -->

## Related Issues

<!-- 关联的 Issue，使用 Fixes #123 或 Relates to #456 -->

## Changes

<!-- 列出主要变更点 -->

- [ ] 变更点 1
- [ ] 变更点 2
- [ ] 变更点 3

## Type of Change

<!-- 选择一个类型 -->

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Documentation update
- [ ] Refactoring (no functional changes)

## Test Plan

<!-- 描述如何测试这个变更 -->

1. 步骤 1
2. 步骤 2
3. 预期结果

## Checklist

<!-- 确认以下项目 -->

- [ ] 代码遵循项目编码规范
- [ ] 已添加/更新相关测试
- [ ] 所有测试通过（`npm test`）
- [ ] 已更新相关文档
- [ ] 提交信息遵循 Conventional Commits 规范
- [ ] 已自查代码，无调试语句残留

## Screenshots (if applicable)

<!-- 如果涉及 UI 变更，请提供截图 -->
```

---

## 2) PR 类型与规模

### 类型定义

| 类型 | 前缀 | 说明 |
|------|------|------|
| Bug 修复 | `fix:` | 修复现有功能的问题 |
| 新功能 | `feat:` | 添加新功能 |
| 重构 | `refactor:` | 不改变行为的代码优化 |
| 文档 | `docs:` | 仅文档变更 |
| 测试 | `test:` | 添加或修改测试 |
| 构建 | `build:` | 构建系统或依赖变更 |
| 性能 | `perf:` | 性能优化 |

### 规模控制

| 规模 | 变更行数 | 审查时间 | 建议 |
|------|----------|----------|------|
| XS | < 50 行 | 15 分钟 | 可快速合并 |
| S | 50-200 行 | 30 分钟 | 标准审查 |
| M | 200-500 行 | 1 小时 | 需要仔细审查 |
| L | 500-1000 行 | 2+ 小时 | 建议拆分 |
| XL | > 1000 行 | 半天+ | **必须拆分** |

**原则**：一个 PR 只做一件事，保持原子性。

---

## 3) Commit 规范

### Conventional Commits 格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### 示例

```
feat(auth): add OAuth2 login support

- Add OAuth2 provider configuration
- Implement token refresh mechanism
- Add logout cleanup logic

Closes #123
```

```
fix(api): handle null response from external service

The external API sometimes returns null instead of an empty array.
Added defensive check to prevent runtime errors.

Fixes #456
```

### 常见类型

| 类型 | 说明 | 示例 |
|------|------|------|
| `feat` | 新功能 | `feat(user): add profile edit` |
| `fix` | Bug 修复 | `fix(auth): correct token expiry` |
| `docs` | 文档 | `docs(readme): update install guide` |
| `style` | 格式调整 | `style: fix indentation` |
| `refactor` | 重构 | `refactor(api): extract common logic` |
| `test` | 测试 | `test(user): add unit tests` |
| `chore` | 杂项 | `chore(deps): update lodash` |

---

## 4) 审查清单

### 提交者自查

提交 PR 前，确认以下内容：

```bash
# 1. 代码检查
npm run lint
npm run compile

# 2. 测试通过
npm test

# 3. 无调试代码
rg 'console\.(log|debug)|debugger' src/ --type ts

# 4. 无 .only 测试
rg '\.only\s*\(' tests/ --type ts

# 5. 无敏感信息
rg '(password|secret|token|key)\s*[:=]' --type ts -i
```

### 审查者检查

审查 PR 时，关注以下方面：

**功能性**
- [ ] 代码是否实现了 PR 描述的功能？
- [ ] 边界条件是否处理？
- [ ] 错误情况是否处理？

**代码质量**
- [ ] 命名是否清晰？
- [ ] 函数是否过长？
- [ ] 是否有重复代码？
- [ ] 是否有明显的性能问题？

**安全性**
- [ ] 是否有 SQL 注入风险？
- [ ] 是否有 XSS 风险？
- [ ] 敏感数据是否保护？

**测试**
- [ ] 是否有对应的测试？
- [ ] 测试是否覆盖主要路径？
- [ ] 测试是否独立、可重复？

**文档**
- [ ] 公共 API 是否有文档？
- [ ] README 是否需要更新？
- [ ] 变更日志是否需要更新？

---

## 5) PR 工作流

### 标准流程

```
1. 创建分支
   git checkout -b feat/feature-name

2. 开发并提交
   git add .
   git commit -m "feat(scope): description"

3. 推送分支
   git push -u origin feat/feature-name

4. 创建 PR
   - 填写 PR 模板
   - 关联 Issue
   - 请求审查

5. 处理审查意见
   - 回复评论
   - 推送修改
   - 请求重新审查

6. 合并
   - Squash and merge（推荐）
   - 删除源分支
```

### 分支命名

| 类型 | 格式 | 示例 |
|------|------|------|
| 功能 | `feat/<name>` | `feat/user-auth` |
| 修复 | `fix/<issue-id>` | `fix/123-login-error` |
| 文档 | `docs/<name>` | `docs/api-guide` |
| 重构 | `refactor/<name>` | `refactor/auth-service` |
| 紧急 | `hotfix/<name>` | `hotfix/security-patch` |

---

## 6) 审查礼仪

### 提交者

- 提供足够的上下文
- 及时回复审查意见
- 感谢审查者的时间
- 避免大型 PR

### 审查者

- 及时审查（24-48 小时内）
- 提供建设性意见
- 解释"为什么"而不只是"什么"
- 区分"必须修改"和"建议"

### 评论格式

```markdown
# 必须修改
🔴 **必须**：这里有安全漏洞，需要添加输入验证

# 建议修改
🟡 **建议**：考虑使用 `Array.from()` 替代 spread 操作

# 疑问
🔵 **问题**：这个超时时间的选择依据是什么？

# 赞扬
🟢 **赞**：这个抽象很优雅！
```

---

## 7) 自动化检查

### CI 流程配置

```yaml
# .github/workflows/pr-check.yml
name: PR Check

on:
  pull_request:
    branches: [main, develop]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Type Check
        run: npm run compile

      - name: Test
        run: npm test

      - name: Check for debug statements
        run: |
          if rg 'console\.(log|debug)|debugger' src/ --type ts; then
            echo "::error::Found debug statements"
            exit 1
          fi
```

### 必须通过的检查

| 检查项 | 说明 |
|--------|------|
| Lint | ESLint 规则通过 |
| TypeScript | 类型检查通过 |
| Tests | 所有测试通过 |
| Coverage | 覆盖率不低于基线 |
| Build | 构建成功 |
