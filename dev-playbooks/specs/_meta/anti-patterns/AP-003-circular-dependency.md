# AP-003: Circular Dependency

> Anti-Pattern ID: AP-003-circular-dependency
> Severity: Critical
> Related Rule: FR-002

---

## Problem Description

Two or more modules depend on each other, forming circular references.

## Symptoms

- `import` statements form a cycle
- Runtime `undefined` errors
- Module loading order issues
- Difficult to understand dependency relationships

## Bad Example

```typescript
// ❌ Wrong: Circular dependency

// a.ts
import { B } from './b';
export class A {
  constructor(private b: B) {}
  doSomething() { this.b.help(); }
}

// b.ts
import { A } from './a';  // Circular reference!
export class B {
  constructor(private a: A) {}
  help() { this.a.doSomething(); }  // May cause infinite recursion
}
```

## Why This is an Anti-Pattern

1. **Runtime Errors**: Module loading order causes undefined
2. **Hard to Understand**: Cannot establish clear dependency hierarchy
3. **Hard to Test**: Cannot test either module independently
4. **Hard to Refactor**: Modifying one affects the other

## Solutions

### Solution 1: Dependency Inversion (Recommended)

```typescript
// ✅ Correct: Introduce interface layer

// interfaces.ts (no dependencies)
export interface IHelper {
  help(): void;
}

// a.ts
import { IHelper } from './interfaces';
export class A {
  constructor(private helper: IHelper) {}
  doSomething() { this.helper.help(); }
}

// b.ts (no longer depends on A)
import { IHelper } from './interfaces';
export class B implements IHelper {
  help() { console.log('helping'); }
}
```

### Solution 2: Event-Driven

```typescript
// ✅ Correct: Use events for decoupling

// event-bus.ts
export const eventBus = new EventEmitter();

// a.ts
import { eventBus } from './event-bus';
export class A {
  doSomething() {
    eventBus.emit('need-help', { from: this });
  }
}

// b.ts
import { eventBus } from './event-bus';
export class B {
  constructor() {
    eventBus.on('need-help', (data) => this.help(data));
  }
  help(data: any) { ... }
}
```

### Solution 3: Module Merge

```typescript
// ✅ If two classes are tightly coupled, consider merging

// ab.ts
export class AB {
  doSomething() { ... }
  help() { ... }
}
```

## Detection Methods

```bash
# Node.js projects
npx madge --circular src/

# Manual detection
grep -r "from '\.\/" src/ | awk -F: '{print $1, $2}' | sort | uniq

# Go projects
go mod why -m

# Python projects
pydeps --show-cycles src/
```

## Prevention Measures

1. **Layered Architecture**: Strict dependency direction (upper layer → lower layer)
2. **Dependency Injection**: Decouple through interfaces
3. **CI Check**: Run circular detection in CI
4. **Code Review**: Focus on new import statements

## Related Resources

- [Dependency Inversion Principle](https://en.wikipedia.org/wiki/Dependency_inversion_principle)
- [madge - Circular Dependency Detection Tool](https://github.com/pahen/madge)
- [Breaking Circular Dependencies](https://www.baeldung.com/circular-dependencies-in-spring)
