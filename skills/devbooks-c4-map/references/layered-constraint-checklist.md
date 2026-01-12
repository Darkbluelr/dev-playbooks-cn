# Layered Constraint Checklist

Inspired by VS Code's `code-layering.ts` and `layersChecker.ts`, this document defines checking rules for layered architecture.

---

## 1) Layered Dependency Checking Rules

### 1.1 Unidirectional Dependency Violation Detection

**Checking Method**: Scan import/require statements to verify dependency directions

```typescript
// Violation example: base layer referencing platform layer
// src/base/utils.ts
import { ConfigService } from '../platform/config';  // Violation!

// Correct example: platform layer referencing base layer
// src/platform/config.ts
import { deepClone } from '../base/utils';  // Legal
```

**Example Check Commands** (using grep/rg):

```bash
# Check if base layer violates by referencing platform
rg "from ['\"].*platform" src/base/ --type ts

# Check if common layer violates by referencing browser/node
rg "from ['\"].*(browser|node)" src/common/ --type ts
```

### 1.2 Environment Isolation Violation Detection

| Environment | Forbidden APIs | Detection Regex |
|-------------|----------------|-----------------|
| common | DOM API | `document\.|window\.|navigator\.` |
| common | Node API | `require\(['"]fs['"]\)|process\.|__dirname` |
| browser | Node API | `require\(['"]fs['"]\)|child_process` |
| node | DOM API | `document\.|window\.|DOM\.` |

### 1.3 Contrib Reverse Dependency Detection

```bash
# Check if core violates by referencing contrib
rg "from ['\"].*contrib" src/core/ --type ts
rg "from ['\"].*contrib" src/workbench/services/ --type ts
```

---

## 2) Layered Constraint Definition Template

Add to `<truth-root>/architecture/c4.md`:

```markdown
## Architecture Guardrails

### Layering Constraints

This project adopts N-layer architecture with dependency direction: base <- platform <- domain <- application <- ui

| Layer | Directory | Responsibility | Can Depend On | Cannot Depend On |
|-------|-----------|----------------|---------------|------------------|
| base | src/base/ | Basic utilities, cross-platform abstractions | (none) | All other layers |
| platform | src/platform/ | Platform services, dependency injection | base | domain, app, ui |
| domain | src/domain/ | Business logic, domain models | base, platform | app, ui |
| application | src/app/ | Application services, use case orchestration | base, platform, domain | ui |
| ui | src/ui/ | User interface, interaction logic | All layers | (none) |

### Environment Constraints

| Environment Directory | Can Reference | Cannot Reference |
|-----------------------|---------------|------------------|
| */common/ | Platform-agnostic libraries | */browser/*, */node/* |
| */browser/ | */common/* | */node/* |
| */node/ | */common/* | */browser/* |

### Validation Commands

```bash
# Layer violation check
npm run valid-layers-check

# Or manual check
rg "from ['\"].*platform" src/base/ --type ts && echo "FAIL: base->platform" || echo "OK"
```
```

---

## 3) Severity Levels of Layer Violations

| Violation Type | Severity | Handling |
|----------------|----------|----------|
| Lower layer referencing upper layer | **Critical** | Must fix immediately, block merge |
| common referencing browser/node | **Critical** | Must fix immediately |
| Deep importing Internal modules across layers | **High** | Should use public API |
| contrib referenced by core | **High** | Violates extension point design |
| Circular dependencies | **High** | Requires refactoring to decouple |

---

## 4) Layer Check Integration

### 4.1 Configure in ESLint (Recommended)

```javascript
// eslint.config.js
module.exports = {
  rules: {
    'import/no-restricted-paths': ['error', {
      zones: [
        // base cannot import platform
        { target: './src/base', from: './src/platform', message: 'base cannot import platform' },
        // platform cannot import domain
        { target: './src/platform', from: './src/domain', message: 'platform cannot import domain' },
        // common cannot import browser/node
        { target: './src/**/common', from: './src/**/browser', message: 'common cannot import browser' },
        { target: './src/**/common', from: './src/**/node', message: 'common cannot import node' },
      ]
    }]
  }
};
```

### 4.2 Configure in TypeScript

Create separate tsconfig for each layer:

```json
// tsconfig.base.json
{
  "compilerOptions": {
    "paths": {
      // base layer can only see itself
    }
  },
  "include": ["src/base/**/*"],
  "exclude": ["src/platform/**/*", "src/domain/**/*"]
}
```

### 4.3 Configure in CI

```yaml
# .github/workflows/pr.yml
- name: Check layer constraints
  run: |
    # Check layer violations
    ./scripts/valid-layers-check.sh || exit 1
```

---

## 5) Layer Refactoring Guide

When layer violations are found:

1. **Identify the Cause of Violation**
   - Is it a reasonable dependency? (may need to adjust layer definition)
   - Can it be decoupled through interface abstraction?
   - Should the code be moved to the correct layer?

2. **Decoupling Strategies**
   - **Dependency Injection**: Upper layer injects through interface, lower layer doesn't directly depend on implementation
   - **Event Mechanism**: Lower layer publishes events, upper layer subscribes
   - **Callback Passing**: Lower layer receives callback functions, doesn't care about the caller

3. **Code Movement**
   - If code truly belongs to lower layer, move to correct location
   - Update all reference paths
   - Run layer check to confirm fix

---

## 6) Review Checklist

During Code Review, check the following items:

- [ ] Do new imports comply with layer constraints?
- [ ] Are there deep imports of Internal modules?
- [ ] Does code in common directory use platform-specific APIs?
- [ ] Are contrib modules referenced by core modules?
- [ ] Are there circular dependencies?
