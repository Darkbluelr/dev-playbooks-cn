# Test Layering Strategy

Borrowing from VS Code's test organization patterns, this document defines best practices for test layering.

---

## 1) Test Pyramid Principles

### Ideal Ratios

| Layer | Ratio | Characteristics | Execution Frequency |
|-------|-------|-----------------|---------------------|
| Unit Tests | 70% | Fast, isolated, focused | Every commit |
| Integration Tests | 20% | Module boundaries, real dependencies | Every PR |
| E2E Tests | 10% | End-to-end, user perspective | Every merge |

### Layer Responsibilities

**Unit Tests**:
- Test behavior of individual functions/classes
- Completely isolated, no external dependencies
- Execution speed < 5s/file
- Cover all boundary conditions

**Integration Tests**:
- Test interactions between modules
- May use test database/cache
- Execution speed < 30s/file
- Cover API contracts

**E2E Tests**:
- Test complete user flows
- Use real environment
- Execution speed < 60s/scenario
- Only cover critical paths

---

## 2) Test Naming Conventions

### File Naming

```
src/
|-- user/
|   |-- user.service.ts
|   |-- test/
|       |-- user.service.test.ts    # Unit test (adjacent to source)

tests/
|-- unit/                           # Alternative: centralized unit tests
|   |-- user.service.test.ts
|-- integration/
|   |-- user.api.integrationTest.ts # Integration test
|-- e2e/
|   |-- user-flow.e2e.ts            # E2E test
|-- contract/
|   |-- user.api.contract.ts        # Contract test
|-- smoke/
    |-- health.smoke.ts             # Smoke test
```

### Test Case Naming

```typescript
// Good: Describe behavior and expected result
describe('UserService', () => {
  describe('createUser', () => {
    it('should create a new user with valid data', () => {});
    it('should throw ValidationError when email is invalid', () => {});
    it('should return existing user when email already exists', () => {});
  });
});

// Bad: Vague descriptions
describe('UserService', () => {
  it('test1', () => {});
  it('works', () => {});
});
```

---

## 3) Test Isolation Strategy

### Unit Test Isolation

```typescript
// Use mock to isolate external dependencies
import { mock, MockProxy } from 'jest-mock-extended';

describe('UserService', () => {
  let userRepo: MockProxy<UserRepository>;
  let service: UserService;

  beforeEach(() => {
    userRepo = mock<UserRepository>();
    service = new UserService(userRepo);
  });

  it('should call repository save', async () => {
    userRepo.save.mockResolvedValue({ id: '1', name: 'test' });
    await service.createUser({ name: 'test' });
    expect(userRepo.save).toHaveBeenCalledWith({ name: 'test' });
  });
});
```

### Integration Test Isolation

```typescript
// Use beforeEach/afterEach for cleanup
describe('User API Integration', () => {
  let testDb: TestDatabase;

  beforeAll(async () => {
    testDb = await TestDatabase.create();
  });

  beforeEach(async () => {
    await testDb.clean(); // Clean before each test
  });

  afterAll(async () => {
    await testDb.destroy();
  });

  it('should create user via API', async () => {
    const response = await request(app)
      .post('/users')
      .send({ name: 'test' });
    expect(response.status).toBe(201);
  });
});
```

### E2E Test Isolation

```typescript
// Use independent test environment
describe('User Registration Flow', () => {
  let browser: Browser;
  let page: Page;

  beforeAll(async () => {
    browser = await chromium.launch();
  });

  beforeEach(async () => {
    page = await browser.newPage();
    await seedTestData(); // Prepare test data
  });

  afterEach(async () => {
    await page.close();
    await cleanupTestData(); // Clean up test data
  });

  afterAll(async () => {
    await browser.close();
  });
});
```

---

## 4) Test Stability Assurance

### Forbidden Patterns to Commit

```bash
# pre-commit hook check
check_test_only() {
  if rg -l '\.(only|skip)\(' tests/ src/**/test/; then
    echo "error: found .only() or .skip() in tests" >&2
    exit 1
  fi
}
```

### Flaky Test Handling

```typescript
// Temporarily mark flaky test (must include issue link)
describe.skip('Flaky test - see #123', () => {
  // TODO: Fix flaky test by 2024-01-15
});

// Or use retry (not recommended, should fix root cause)
it('sometimes fails', async () => {
  // jest-retries or mocha-retry
}, { retries: 2 });
```

### Timeout Settings

```typescript
// Reasonable timeout settings
jest.setTimeout(5000); // Unit test default 5s

describe('Integration Tests', () => {
  beforeAll(() => {
    jest.setTimeout(30000); // Integration test 30s
  });
});
```

---

## 5) Test Coverage Strategy

### Coverage Targets

| Metric | Minimum Requirement | Recommended Target |
|--------|--------------------|--------------------|
| Line Coverage | 70% | 80%+ |
| Branch Coverage | 60% | 70%+ |
| Function Coverage | 80% | 90%+ |

### Coverage Exceptions

```typescript
// Explicitly mark code that doesn't need coverage
/* istanbul ignore next */
function debugOnly() {
  // Debug only, no testing needed
}

/* istanbul ignore if */
if (process.env.NODE_ENV === 'development') {
  // Development environment specific code
}
```

---

## 6) Test Anti-Fragility Strategy (Borrowed from VS Code Audit.md)

### Avoid Fragile Selectors

```typescript
// Bad: Depends on CSS class name (easily fails from style refactoring)
await page.click('.btn-primary');

// Bad: Depends on text content (easily fails from i18n)
await page.click('text=Submit');

// Good: Use data-testid
await page.click('[data-testid="submit-button"]');

// Good: Use role
await page.click('role=button[name="Submit"]');
```

### Avoid Fragile Assertions

```typescript
// Bad: Exact match (easily fails from format changes)
expect(result.createdAt).toBe('2024-01-01T00:00:00.000Z');

// Good: Type assertion
expect(result.createdAt).toBeInstanceOf(Date);

// Good: Fuzzy match
expect(result.message).toContain('success');
```

---

## 7) Test Review Checklist

Check during Code Review:

- [ ] Do tests follow naming conventions?
- [ ] Are unit tests completely isolated?
- [ ] Do integration tests have cleanup logic?
- [ ] Are there leftover `.only()` or `.skip()`?
- [ ] Are timeout settings reasonable?
- [ ] Are fragile selectors avoided?
- [ ] Does new code have corresponding tests?
- [ ] Do tests cover boundary conditions?
