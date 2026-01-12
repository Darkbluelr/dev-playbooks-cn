# Fitness Rules

> This document defines the project's architectural fitness functions.
> These rules are used to automatically verify compliance with architectural constraints.

---

## What are Fitness Functions?

Fitness functions are executable architectural constraint checks. They help teams:
- Automate validation of architectural decisions
- Continuously check architectural health in CI/CD
- Prevent architectural decay

---

## Rule Definition Format

```markdown
### FT-XXX: Rule Name

> Source: <rule source, such as design document or architectural decision>

**Rule**: <rule description>

**Check Command**:
\`\`\`bash
<check command>
\`\`\`

**Severity**: Critical | High | Medium | Low
```

---

## Rule List

### FT-001: Layered Dependency Direction

> Source: Architecture Design

**Rule**: Upper layers can depend on lower layers; lower layers are prohibited from depending on upper layers.

**Check Command**:
```bash
# Example: Check if domain layer depends on ui layer
grep -r "import.*from.*ui" src/domain/ && echo "FAIL" || echo "OK"
```

**Severity**: Critical

---

### FT-002: Circular Dependencies Prohibited

> Source: Architecture Design

**Rule**: Circular dependencies between modules are prohibited.

**Check Command**:
```bash
# Use madge or similar tool to check
npx madge --circular src/
```

**Severity**: High

---

### FT-003: Test Coverage

> Source: Quality Requirements

**Rule**: Unit test coverage must not be lower than 80%.

**Check Command**:
```bash
npm run test:coverage -- --coverage-threshold='{"global":{"lines":80}}'
```

**Severity**: High

---

## Process for Adding New Rules

1. Propose new rules in the change package's `design.md`
2. Go through Challenger questioning and Judge adjudication
3. Add rules to this document upon archival
4. Add corresponding check scripts in CI

---

**Rule Set Version**: v1.0.0
**Last Updated**: {{DATE}}
