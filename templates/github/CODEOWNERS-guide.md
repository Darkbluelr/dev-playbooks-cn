# CODEOWNERS 模式指南

借鉴 VS Code 的 `.github/CODEOWNERS` 结构，本文档定义了代码所有权的标准配置。

---

## 1) 什么是 CODEOWNERS

CODEOWNERS 文件定义了代码库中不同部分的负责人，GitHub 会自动请求这些人审查相关的 PR。

**位置**：`.github/CODEOWNERS`

**作用**：
- 自动分配 PR 审查者
- 明确代码所有权
- 确保关键变更被正确审查

---

## 2) 基本语法

```gitignore
# 格式：<pattern> <owners>
# owners 可以是 @username、@org/team、或 email

# 默认所有者（兜底规则）
* @default-reviewer

# 目录所有者
/src/auth/ @security-team
/docs/ @docs-team

# 文件类型所有者
*.sql @dba-team
*.yml @devops-team

# 特定文件
/package.json @lead-dev
/tsconfig.json @lead-dev
```

---

## 3) 推荐结构（按 VS Code 模式）

```gitignore
# ============================================
# CODEOWNERS - 代码所有权定义
# ============================================

# --------------------------------------------
# 默认所有者
# --------------------------------------------
* @project-maintainers

# --------------------------------------------
# 核心模块
# --------------------------------------------
/src/core/ @core-team
/src/core/security/ @security-team @core-team

# --------------------------------------------
# 平台层
# --------------------------------------------
/src/platform/ @platform-team
/src/platform/auth/ @security-team
/src/platform/storage/ @storage-team

# --------------------------------------------
# 功能模块
# --------------------------------------------
/src/features/user/ @user-team
/src/features/billing/ @billing-team @finance-team

# --------------------------------------------
# 测试
# --------------------------------------------
/tests/ @qa-team
/tests/e2e/ @qa-team @platform-team

# --------------------------------------------
# 工程配置（高敏感）
# --------------------------------------------
/.github/ @devops-team @lead-dev
/package.json @lead-dev
/package-lock.json @lead-dev
/tsconfig.json @lead-dev
/.eslintrc* @lead-dev

# --------------------------------------------
# 文档
# --------------------------------------------
/docs/ @docs-team
/README.md @docs-team @project-maintainers
/CHANGELOG.md @release-team

# --------------------------------------------
# 安全相关（需要安全团队审查）
# --------------------------------------------
**/security/** @security-team
**/auth/** @security-team
**/crypto/** @security-team
*.pem @security-team
*.key @security-team
```

---

## 4) DevBooks 角色映射

将 DevBooks 的角色映射到 CODEOWNERS：

| DevBooks 角色 | CODEOWNERS 团队 | 负责区域 |
|--------------|----------------|----------|
| Proposal Author | @architects | 设计文档、架构决策 |
| Test Owner | @qa-team | tests/、verification.md |
| Coder | @dev-team | src/（排除敏感文件） |
| Reviewer | @senior-devs | 所有代码审查 |

**示例配置**：

```gitignore
# DevBooks 角色映射
/openspec/ @architects
/openspec/**/proposal.md @architects
/openspec/**/design.md @architects @senior-devs

# Test Owner 负责区域
/tests/ @qa-team
/**/verification.md @qa-team
/**/test-plan.md @qa-team

# 禁止 Coder 直接修改的文件
/.devbooks/ @architects @lead-dev
/openspec/**/spec-*.md @architects
```

---

## 5) 最佳实践

### 分层所有权

```gitignore
# 更具体的规则优先级更高
/src/ @dev-team                    # 宽泛规则
/src/core/ @core-team              # 更具体
/src/core/security/ @security-team # 最具体（优先）
```

### 多团队审查

```gitignore
# 需要多个团队审查的关键变更
/src/api/public/ @api-team @security-team @docs-team
```

### 敏感文件保护

```gitignore
# 高敏感文件需要多人审查
/.env* @security-team @lead-dev
/secrets/ @security-team @lead-dev
```

### 排除模式

```gitignore
# 排除生成的文件
# 注意：CODEOWNERS 不支持 ! 排除语法
# 解决方案：不为生成的文件指定所有者
# dist/、build/、node_modules/ 等应在 .gitignore 中
```

---

## 6) 验证 CODEOWNERS

```bash
# 检查 CODEOWNERS 语法
# GitHub 会在 Settings > Branches 显示解析错误

# 本地验证（使用 codeowners-checker）
npm install -g codeowners-checker
codeowners-checker check

# 查看特定文件的所有者
codeowners-checker who src/auth/login.ts
```

---

## 7) 与分支保护集成

在 GitHub 仓库设置中：

1. **Settings → Branches → Branch protection rules**
2. 勾选 **Require review from Code Owners**
3. 设置最少审查人数

这样 PR 必须获得 CODEOWNERS 中定义的人员审查才能合并。

---

## 8) 常见问题

### Q: CODEOWNERS 规则冲突怎么办？

后面的规则优先级更高。

```gitignore
/src/ @team-a        # 先匹配
/src/special/ @team-b # 后匹配，优先级更高
```

### Q: 如何排除某些文件？

CODEOWNERS 不支持排除语法。解决方案：
- 将文件放入 .gitignore（如果不需要版本控制）
- 不为该文件指定所有者

### Q: 团队成员变动怎么处理？

使用 GitHub 团队而非个人用户名：

```gitignore
# 推荐：使用团队
/src/auth/ @org/security-team

# 不推荐：使用个人（人员变动需要修改）
/src/auth/ @john @jane
```
