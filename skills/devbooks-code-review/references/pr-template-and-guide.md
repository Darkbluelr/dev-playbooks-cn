# Pull Request Template and Guide

Inspired by VS Code's `.github/pull_request_template.md`, this document defines the standard PR submission process.

---

## 1) PR Template

```markdown
## Summary

<!-- Describe what this PR does in 1-3 sentences -->

## Related Issues

<!-- Related issues, use Fixes #123 or Relates to #456 -->

## Changes

<!-- List the main changes -->

- [ ] Change 1
- [ ] Change 2
- [ ] Change 3

## Type of Change

<!-- Select one type -->

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Documentation update
- [ ] Refactoring (no functional changes)

## Test Plan

<!-- Describe how to test this change -->

1. Step 1
2. Step 2
3. Expected result

## Checklist

<!-- Confirm the following items -->

- [ ] Code follows project coding standards
- [ ] Added/updated relevant tests
- [ ] All tests pass (`npm test`)
- [ ] Updated relevant documentation
- [ ] Commit messages follow Conventional Commits specification
- [ ] Self-reviewed code, no debug statements remaining
- [ ] Screenshots (if applicable)

<!-- If UI changes are involved, please provide screenshots -->
```

---

## 2) PR Types and Size

### Type Definitions

| Type | Prefix | Description |
|------|--------|-------------|
| Bug fix | `fix:` | Fixes issues in existing functionality |
| New feature | `feat:` | Adds new functionality |
| Refactoring | `refactor:` | Code optimization without behavior change |
| Documentation | `docs:` | Documentation changes only |
| Testing | `test:` | Adding or modifying tests |
| Build | `build:` | Build system or dependency changes |
| Performance | `perf:` | Performance optimization |

### Size Control

| Size | Lines Changed | Review Time | Recommendation |
|------|---------------|-------------|----------------|
| XS | < 50 lines | 15 minutes | Can be quickly merged |
| S | 50-200 lines | 30 minutes | Standard review |
| M | 200-500 lines | 1 hour | Requires careful review |
| L | 500-1000 lines | 2+ hours | Consider splitting |
| XL | > 1000 lines | Half day+ | **Must be split** |

**Principle**: One PR does one thing, maintain atomicity.

---

## 3) Commit Specification

### Conventional Commits Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Examples

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

### Common Types

| Type | Description | Example |
|------|-------------|---------|
| `feat` | New feature | `feat(user): add profile edit` |
| `fix` | Bug fix | `fix(auth): correct token expiry` |
| `docs` | Documentation | `docs(readme): update install guide` |
| `style` | Formatting | `style: fix indentation` |
| `refactor` | Refactoring | `refactor(api): extract common logic` |
| `test` | Testing | `test(user): add unit tests` |
| `chore` | Miscellaneous | `chore(deps): update lodash` |

---

## 4) Review Checklist

### Submitter Self-Check

Before submitting a PR, confirm the following:

```bash
# 1. Code check
npm run lint
npm run compile

# 2. Tests pass
npm test

# 3. No debug code
rg 'console\.(log|debug)|debugger' src/ --type ts

# 4. No .only tests
rg '\.only\s*\(' tests/ --type ts

# 5. No sensitive information
rg '(password|secret|token|key)\s*[:=]' --type ts -i
```

### Reviewer Checks

When reviewing a PR, focus on the following aspects:

**Functionality**
- [ ] Does the code implement the functionality described in the PR?
- [ ] Are boundary conditions handled?
- [ ] Are error cases handled?

**Code Quality**
- [ ] Is naming clear?
- [ ] Are functions too long?
- [ ] Is there duplicate code?
- [ ] Are there obvious performance issues?

**Security**
- [ ] Is there SQL injection risk?
- [ ] Is there XSS risk?
- [ ] Is sensitive data protected?

**Testing**
- [ ] Are there corresponding tests?
- [ ] Do tests cover the main paths?
- [ ] Are tests independent and repeatable?

**Documentation**
- [ ] Are public APIs documented?
- [ ] Does the README need updating?
- [ ] Does the changelog need updating?

---

## 5) PR Workflow

### Standard Process

```
1. Create branch
   git checkout -b feat/feature-name

2. Develop and commit
   git add .
   git commit -m "feat(scope): description"

3. Push branch
   git push -u origin feat/feature-name

4. Create PR
   - Fill in PR template
   - Link issues
   - Request review

5. Handle review comments
   - Reply to comments
   - Push changes
   - Request re-review

6. Merge
   - Squash and merge (recommended)
   - Delete source branch
```

### Branch Naming

| Type | Format | Example |
|------|--------|---------|
| Feature | `feat/<name>` | `feat/user-auth` |
| Bug fix | `fix/<issue-id>` | `fix/123-login-error` |
| Documentation | `docs/<name>` | `docs/api-guide` |
| Refactoring | `refactor/<name>` | `refactor/auth-service` |
| Hotfix | `hotfix/<name>` | `hotfix/security-patch` |

---

## 6) Review Etiquette

### Submitter

- Provide sufficient context
- Respond to review comments promptly
- Thank reviewers for their time
- Avoid large PRs

### Reviewer

- Review promptly (within 24-48 hours)
- Provide constructive feedback
- Explain "why" not just "what"
- Distinguish between "must fix" and "suggestions"

### Comment Format

```markdown
# Must fix
🔴 **Required**: There's a security vulnerability here, input validation needed

# Suggested fix
🟡 **Suggestion**: Consider using `Array.from()` instead of spread operator

# Question
🔵 **Question**: What's the rationale for this timeout value?

# Praise
🟢 **Nice**: This abstraction is elegant!
```

---

## 7) Automated Checks

### CI Pipeline Configuration

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

### Required Checks

| Check | Description |
|-------|-------------|
| Lint | ESLint rules pass |
| TypeScript | Type checking passes |
| Tests | All tests pass |
| Coverage | Coverage not below baseline |
| Build | Build succeeds |
