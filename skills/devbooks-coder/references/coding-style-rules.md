# Coding Style Rules

Based on VS Code's `guidelines/CODING_GUIDELINES.md`, this document defines specific code style conventions.

---

## 1) Naming Conventions

### TypeScript/JavaScript

| Type | Convention | Example |
|------|------|------|
| Class Name | PascalCase | `UserService`, `HttpClient` |
| Interface Name | PascalCase (no I prefix) | `User`, `Config` |
| Function Name | camelCase | `getUserById`, `parseConfig` |
| Variable Name | camelCase | `userName`, `isActive` |
| Constants | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT`, `API_URL` |
| Private Members | Underscore prefix | `_cache`, `_disposed` |
| Boolean Variables | is/has/can/should prefix | `isValid`, `hasPermission` |

### File Naming

| Type | Convention | Example |
|------|------|------|
| Component Files | PascalCase | `UserProfile.tsx` |
| Utility Files | camelCase | `stringUtils.ts` |
| Test Files | Source filename + `.test` | `userService.test.ts` |
| Type Files | Source filename + `.types` | `api.types.ts` |

---

## 2) Code Organization

### Import Order

```typescript
// 1. Node.js built-in modules
import * as fs from 'fs';
import * as path from 'path';

// 2. Third-party libraries (sorted alphabetically)
import { Observable } from 'rxjs';
import * as vscode from 'vscode';

// 3. Internal modules (sorted by layer: base → platform → business)
import { Disposable } from '@/base/common/lifecycle';
import { IConfigService } from '@/platform/config/common/config';

// 4. Relative imports (sorted by distance: far → near)
import { UserModel } from '../models/user';
import { formatDate } from './utils';

// 5. Type imports (separate group)
import type { User, Config } from '../types';
```

### Export Order

```typescript
// 1. Type exports
export type { User, Config };
export interface IService { ... }

// 2. Constant exports
export const DEFAULT_CONFIG = { ... };

// 3. Function exports
export function createUser() { ... }

// 4. Class exports
export class UserService { ... }

// 5. Default export (only for module entry points)
export default UserService;
```

---

## 3) Function Guidelines

### Function Length

- **Recommended**: <= 30 lines
- **Warning**: 30-50 lines
- **Prohibited**: > 50 lines (must be split)

### Parameter Count

- **Recommended**: <= 3 parameters
- **Warning**: 4-5 parameters
- **Prohibited**: > 5 parameters (use object parameter)

```typescript
// Violation: Too many parameters
function createUser(name: string, email: string, age: number,
                    role: string, department: string, manager: string) { ... }

// Correct: Use object parameter
interface CreateUserOptions {
  name: string;
  email: string;
  age: number;
  role: string;
  department: string;
  manager: string;
}

function createUser(options: CreateUserOptions) { ... }
```

### Return Values

```typescript
// Violation: Multiple returns, hard to track
function process(data: Data): Result {
  if (!data) return null;
  if (data.type === 'A') return processA(data);
  if (data.type === 'B') return processB(data);
  return processDefault(data);
}

// Correct: Single exit point, clear control flow
function process(data: Data): Result {
  let result: Result;

  if (!data) {
    result = null;
  } else if (data.type === 'A') {
    result = processA(data);
  } else if (data.type === 'B') {
    result = processB(data);
  } else {
    result = processDefault(data);
  }

  return result;
}
```

---

## 4) Type Safety

### Prohibited Patterns

```typescript
// Prohibited: any type
function process(data: any) { ... }  // ❌

// Correct: Use unknown or specific type
function process(data: unknown) { ... }  // ✓
function process(data: Record<string, unknown>) { ... }  // ✓

// Prohibited: Type assertion to bypass checks
const user = {} as User;  // ❌

// Correct: Construct complete object
const user: User = {
  id: '1',
  name: 'John',
  email: 'john@example.com'
};  // ✓

// Prohibited: Non-null assertion
const name = user!.name;  // ❌

// Correct: Explicit check
const name = user?.name ?? 'default';  // ✓
```

### Recommended Patterns

```typescript
// Use type guards
function isUser(obj: unknown): obj is User {
  return typeof obj === 'object' && obj !== null && 'id' in obj;
}

// Use satisfies operator (TypeScript 4.9+)
const config = {
  host: 'localhost',
  port: 3000
} satisfies Config;

// Use const assertion
const ROLES = ['admin', 'user', 'guest'] as const;
type Role = typeof ROLES[number];
```

---

## 5) Error Handling

### Exception Guidelines

```typescript
// Prohibited: Swallowing exceptions
try {
  await riskyOperation();
} catch (e) {
  // Do nothing ❌
}

// Correct: Log and rethrow or handle
try {
  await riskyOperation();
} catch (e) {
  logger.error('Operation failed', e);
  throw new OperationError('Failed to complete operation', { cause: e });
}

// Correct: Explicit handling
try {
  await riskyOperation();
} catch (e) {
  if (e instanceof NetworkError) {
    return fallbackValue;
  }
  throw e;
}
```

### Error Class Definition

```typescript
// Create custom error class
class ApplicationError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly details?: Record<string, unknown>
  ) {
    super(message);
    this.name = this.constructor.name;
  }
}

class ValidationError extends ApplicationError {
  constructor(message: string, details?: Record<string, unknown>) {
    super(message, 'VALIDATION_ERROR', details);
  }
}
```

---

## 6) Comment Guidelines

### When to Add Comments

| Scenario | Comment Needed |
|------|--------------|
| What the code does | ❌ Code should be self-explanatory |
| Why the code does it | ✓ Needs comment |
| Complex algorithms | ✓ Needs comment |
| Temporary workarounds | ✓ Needs comment + TODO |
| Public APIs | ✓ Needs JSDoc |

### JSDoc Format

```typescript
/**
 * Get user information by user ID
 *
 * @param id - The unique identifier of the user
 * @returns The user object, or undefined if not found
 * @throws {ValidationError} When the id format is invalid
 *
 * @example
 * ```typescript
 * const user = await getUserById('123');
 * if (user) {
 *   console.log(user.name);
 * }
 * ```
 */
async function getUserById(id: string): Promise<User | undefined> {
  // ...
}
```

### TODO Format

```typescript
// TODO(#123): Optimize query performance, current implementation is slow with large datasets
// FIXME(#456): Fix boundary condition handling
// HACK: Temporary workaround, remove after upstream library fix
// NOTE: Uses non-standard API, requires Node 18+ environment
```

---

## 7) Async Code

### Promise vs async/await

```typescript
// Recommended: Use async/await
async function fetchUserData(id: string): Promise<UserData> {
  const user = await getUser(id);
  const profile = await getProfile(user.profileId);
  return { user, profile };
}

// Parallel execution
async function fetchAllData(ids: string[]): Promise<UserData[]> {
  return Promise.all(ids.map(id => fetchUserData(id)));
}

// Avoid: Mixing then and await
async function badExample() {
  const user = await getUser(id);
  return getProfile(user.profileId).then(p => ({ user, profile: p })); // ❌
}
```

### Cancellation Support

```typescript
// Use AbortController
async function fetchWithTimeout(
  url: string,
  timeoutMs: number
): Promise<Response> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

  try {
    return await fetch(url, { signal: controller.signal });
  } finally {
    clearTimeout(timeoutId);
  }
}
```

---

## 8) Checklist

Confirm before code submission:

- [ ] Naming follows conventions (PascalCase/camelCase)
- [ ] Import order is correct
- [ ] Function length <= 30 lines
- [ ] Parameter count <= 3
- [ ] No `any` type
- [ ] No `@ts-ignore`
- [ ] Exceptions are properly handled
- [ ] Complex logic has comments
- [ ] Public APIs have JSDoc
- [ ] TODOs are linked to issue numbers
