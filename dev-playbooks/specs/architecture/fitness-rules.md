# Architecture Fitness Rules

> This document defines the project's architecture fitness function rules.
> These rules are automatically checked by `fitness-check.sh`.

---

## Overview

Architecture fitness functions are automated architecture guard mechanisms that ensure code changes do not violate established architectural constraints.

### Rule Severity Levels

| Level | Description | Handling |
|-------|-------------|----------|
| **Critical** | Severe violation, must block | Block in error mode |
| **High** | Important violation, recommend blocking | Block in error mode |
| **Medium** | Moderate violation, needs warning | Warn in warn mode |
| **Low** | Minor violation, recommend fix | Warn in warn mode |

---

## FR-001: Layered Architecture Check

**Rule ID**: FR-001-layered-arch
**Severity**: High
**Check Method**: Automatic

### Rule Description

Controller layer should not directly access Repository layer; must go through Service layer.

### Correct Layering

```
Controller → Service → Repository → Database
    ↓           ↓           ↓
  (HTTP)    (Business)   (Data)
```

### Violation Pattern

```typescript
// Wrong: Controller directly calls Repository
class UserController {
  constructor(private userRepository: UserRepository) {}  // ❌

  async getUser(id: string) {
    return this.userRepository.findById(id);  // ❌
  }
}
```

### Correct Pattern

```typescript
// Correct: Controller calls Service
class UserController {
  constructor(private userService: UserService) {}  // ✅

  async getUser(id: string) {
    return this.userService.findById(id);  // ✅
  }
}
```

### Detection Command

```bash
grep -rn "Repository\." src/controllers/
```

---

## FR-002: No Circular Dependencies

**Rule ID**: FR-002-no-cycle
**Severity**: Critical
**Check Method**: Automatic (basic version)

### Rule Description

Modules should not have circular dependency relationships.

### Violation Pattern

```
a.ts --import--> b.ts --import--> a.ts  // ❌ Circular dependency
```

### Solutions

1. **Dependency Inversion**: Introduce interface layer to break cycle
2. **Event-Driven**: Use events for decoupling
3. **Module Merge**: If two modules are tightly coupled, consider merging

### Detection Tools

- `madge --circular src/` (Node.js)
- `deptry src/` (Python)
- `go mod why -m` (Go)

---

## FR-003: Sensitive File Protection

**Rule ID**: FR-003-sensitive-file
**Severity**: Critical
**Check Method**: Automatic

### Rule Description

Sensitive files should not be tracked by Git or accidentally committed.

### Sensitive File Patterns

| Pattern | Description |
|---------|-------------|
| `.env*` | Environment variable files |
| `credentials.json` | Credential files |
| `secrets.yaml` | Secret configuration |
| `*.pem` | Certificate files |
| `*.key` | Private key files |
| `id_rsa*` | SSH keys |
| `id_ed25519*` | SSH keys |

### Protection Measures

1. Ensure `.gitignore` includes sensitive patterns
2. Use `git-secrets` or `pre-commit` hooks
3. Periodically scan repository history

### Recommended .gitignore Content

```gitignore
# Environment variables
.env
.env.*
!.env.example

# Keys and credentials
*.pem
*.key
*.p12
*.pfx
credentials.json
secrets.yaml

# SSH
id_rsa*
id_ed25519*
```

---

## Custom Rules

### Adding New Rules

1. Define rule in this file (FR-xxx format)
2. Implement check function in `fitness-check.sh`
3. Call new function in check flow

### Rule Template

```markdown
## FR-xxx: Rule Name

**Rule ID**: FR-xxx-rule-name
**Severity**: Critical | High | Medium | Low
**Check Method**: Automatic | Manual

### Rule Description
[Detailed description of the rule]

### Violation Pattern
[Show violation code examples]

### Correct Pattern
[Show correct code examples]

### Detection Command
[Command to detect violations]
```

---

## Check Result Example

```
==========================================
Architecture Fitness Check (fitness-check.sh)
Mode: error
Project: /path/to/project
==========================================

[INFO] FR-001: Checking layered architecture...
[PASS] FR-001: Layered architecture check passed

[INFO] FR-002: Checking circular dependencies...
[WARN] FR-002: Possible circular dependency: a.ts <-> b.ts

[INFO] FR-003: Checking sensitive files...
[PASS] FR-003: Sensitive file check passed

==========================================
Check Complete
  Errors: 0
  Warnings: 1
==========================================
```

---

**Rule Version**: v1.0.0
**Last Updated**: 2026-01-11
