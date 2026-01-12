# Resource Management Review Checklist

Inspired by VS Code's `code-no-potentially-unsafe-disposables` and `code-must-use-super-dispose` rules.

---

## 1) Common Resource Leak Patterns

### Subscription/Listener Leaks

```typescript
// Violation: subscription not cancelled
class MyComponent {
  private handler = (e: Event) => { /* ... */ };

  initialize() {
    document.addEventListener('click', this.handler);
    // Missing corresponding removeEventListener
  }
}

// Correct: use AbortController
class MyComponent {
  private abortController = new AbortController();

  initialize() {
    document.addEventListener('click', this.handler, {
      signal: this.abortController.signal
    });
  }

  dispose() {
    this.abortController.abort();
  }
}
```

### Timer Leaks

```typescript
// Violation: timer not cleaned up
class Poller {
  start() {
    setInterval(() => this.poll(), 1000);
    // Missing cleanup logic
  }
}

// Correct: save reference and clean up in dispose
class Poller {
  private intervalId?: NodeJS.Timeout;

  start() {
    this.intervalId = setInterval(() => this.poll(), 1000);
  }

  dispose() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = undefined;
    }
  }
}
```

### Stream/Connection Leaks

```typescript
// Violation: stream not closed
async function readFile(path: string) {
  const stream = fs.createReadStream(path);
  const data = await streamToString(stream);
  // If streamToString throws, stream won't close
  return data;
}

// Correct: use try-finally
async function readFile(path: string) {
  const stream = fs.createReadStream(path);
  try {
    return await streamToString(stream);
  } finally {
    stream.destroy();
  }
}

// Better: use using (TypeScript 5.2+)
async function readFile(path: string) {
  using stream = fs.createReadStream(path);
  return await streamToString(stream);
}
```

---

## 2) DisposableStore Pattern

### Basic Usage

```typescript
import { Disposable, DisposableStore } from 'vs/base/common/lifecycle';

class MyService extends Disposable {
  // Must be readonly
  private readonly _disposables = new DisposableStore();

  constructor() {
    super();

    // Register subscription to store
    this._disposables.add(
      eventEmitter.on('change', () => this.handleChange())
    );

    // Register timer to store
    this._disposables.add(
      new IntervalTimer(() => this.poll(), 1000)
    );
  }

  override dispose() {
    this._disposables.dispose();
    super.dispose(); // Must call
  }
}
```

### Check Rules

| Rule | Detection Pattern | Severity |
|------|-------------------|----------|
| DisposableStore must be readonly | `private\s+(?!readonly)\s*_?\w*[Dd]isposable` | Error |
| dispose() must call super | `override\s+dispose\(\).*\{(?![\s\S]*super\.dispose)` | Error |
| Subscriptions must register to store | `.on\(.*\)` without following `.add(` | Warning |
| Tests must check for leaks | Test file without `ensureNoDisposablesAreLeakedInTestSuite` | Warning |

---

## 3) Resource Leak Detection in Tests

### Using ensureNoDisposablesAreLeakedInTestSuite

```typescript
import { ensureNoDisposablesAreLeakedInTestSuite } from 'vs/base/test/common/utils';

suite('MyService', () => {
  // Enable leak detection at suite start
  ensureNoDisposablesAreLeakedInTestSuite();

  let service: MyService;

  setup(() => {
    service = new MyService();
  });

  teardown(() => {
    service.dispose(); // Must clean up
  });

  test('should do something', () => {
    // Test code
  });
});
```

### Common Test Leaks

```typescript
// Violation: resources created in test not cleaned up
test('creates disposable', () => {
  const disposable = new MyDisposable();
  // Test ends, disposable not cleaned up → leak
});

// Correct: use teardown for cleanup
let disposable: MyDisposable;

setup(() => {
  disposable = new MyDisposable();
});

teardown(() => {
  disposable.dispose();
});
```

---

## 4) Review Checklist

### Must Check During Code Review

- [ ] **DisposableStore Declaration**
  - Is it using `readonly` modifier?
  - Is it using `private`?

- [ ] **dispose() Method**
  - Does it call `super.dispose()`?
  - Does it clean up all known resources?
  - Is it defined in base class?

- [ ] **Subscriptions/Listeners**
  - Are they registered to DisposableStore?
  - Is there corresponding cancellation logic?
  - Is AbortController being used?

- [ ] **Timers**
  - Does setInterval have corresponding clearInterval?
  - Is setTimeout cancelled when component is destroyed?

- [ ] **Streams/Connections**
  - Are they closed in finally block?
  - Is using syntax being used?

- [ ] **Tests**
  - Is there `ensureNoDisposablesAreLeakedInTestSuite()`?
  - Does teardown clean up all created resources?

---

## 5) Automated Detection

### ESLint Rule Configuration

```javascript
// eslint.config.js
module.exports = {
  rules: {
    // Custom rule: DisposableStore must be readonly
    'local/code-no-potentially-unsafe-disposables': 'error',

    // Custom rule: dispose must call super
    'local/code-must-use-super-dispose': 'error',
  }
};
```

### grep Detection Commands

```bash
# Detect non-readonly DisposableStore
rg 'private\s+(?!readonly)\s*_?\w*[Dd]isposable' --type ts

# Detect dispose method not calling super.dispose
rg -U 'override\s+dispose\(\).*?\{[^}]*\}' --type ts | grep -v 'super.dispose'

# Detect uncleaned setInterval
rg 'setInterval\(' --type ts -l | xargs -I {} sh -c 'rg -c "clearInterval" {} || echo "Missing clearInterval: {}"'
```

---

## 6) Fix Guide

### Adding DisposableStore

```typescript
// Before
class MyClass {
  private subscription: Subscription;

  constructor() {
    this.subscription = eventEmitter.on('change', () => {});
  }
}

// After
class MyClass extends Disposable {
  private readonly _disposables = new DisposableStore();

  constructor() {
    super();
    this._disposables.add(
      eventEmitter.on('change', () => {})
    );
  }

  override dispose() {
    this._disposables.dispose();
    super.dispose();
  }
}
```

### Adding Test Leak Detection

```typescript
// Before
suite('MyTest', () => {
  test('does something', () => {
    const obj = new MyDisposable();
    // Not cleaned up
  });
});

// After
suite('MyTest', () => {
  ensureNoDisposablesAreLeakedInTestSuite();

  const disposables = new DisposableStore();

  teardown(() => {
    disposables.clear();
  });

  test('does something', () => {
    const obj = disposables.add(new MyDisposable());
    // Will be automatically cleaned up in teardown
  });
});
```
