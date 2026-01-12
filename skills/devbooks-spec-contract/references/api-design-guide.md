# API Design Guide

Drawing from VS Code Extension API design principles, this document defines best practices for API design.

---

## 1) Core Principles

### 1.1 Principle of Least Astonishment

API behavior should match users' intuitive expectations.

```typescript
// Violation: Method name suggests query, but actually modifies state
function getUser(id: string): User {
  this.lastAccessedUser = id;  // Side effect!
  return this.users[id];
}

// Correct: Query method without side effects
function getUser(id: string): User {
  return this.users[id];
}
```

### 1.2 Consistency Principle

Similar operations should have similar APIs.

```typescript
// Violation: Inconsistent naming
interface UserService {
  getUser(id: string): User;
  fetchOrder(id: string): Order;  // Should use getOrder
  loadProduct(id: string): Product;  // Should use getProduct
}

// Correct: Consistent naming pattern
interface UserService {
  getUser(id: string): User;
  getOrder(id: string): Order;
  getProduct(id: string): Product;
}
```

### 1.3 Explicit Over Implicit

Avoid magic behavior; make API effects clearly visible.

```typescript
// Violation: Implicit behavior
function saveUser(user: User): void {
  // Implicitly sends notification
  this.notificationService.send('User saved');
  // Implicitly updates cache
  this.cache.update(user);
}

// Correct: Explicit control
interface SaveOptions {
  sendNotification?: boolean;
  updateCache?: boolean;
}

function saveUser(user: User, options?: SaveOptions): void {
  // Execute based on options explicitly
}
```

---

## 2) Naming Conventions

### 2.1 Method Naming

| Operation Type | Prefix | Examples |
|---------------|--------|----------|
| Get single | `get` | `getUser()`, `getConfig()` |
| Get list | `list` / `getAll` | `listUsers()`, `getAllConfigs()` |
| Find/Search | `find` / `search` | `findByEmail()`, `searchUsers()` |
| Create | `create` | `createUser()`, `createOrder()` |
| Update | `update` | `updateUser()`, `updateConfig()` |
| Delete | `delete` / `remove` | `deleteUser()`, `removeItem()` |
| Check existence | `has` / `exists` | `hasUser()`, `exists()` |
| Check state | `is` / `can` | `isActive()`, `canEdit()` |
| Convert | `to` | `toJSON()`, `toString()` |
| Create from | `from` | `fromJSON()`, `fromString()` |

### 2.2 Parameter Naming

```typescript
// Boolean parameters: Use positive form
function setVisible(visible: boolean): void;  // ✓
function setHidden(hidden: boolean): void;    // ✗ Double negation is confusing

// Callback parameters: Describe trigger timing
function onUserCreated(callback: Function): void;  // ✓
function userCallback(callback: Function): void;   // ✗ Unclear

// ID parameters: Specify type clearly
function getUser(userId: string): User;  // ✓
function getUser(id: string): User;      // Acceptable, but less clear
```

---

## 3) Parameter Design

### 3.1 Parameter Count Control

```typescript
// Violation: Too many parameters
function createUser(
  name: string,
  email: string,
  age: number,
  role: string,
  department: string,
  manager: string,
  startDate: Date
): User;

// Correct: Use options object
interface CreateUserOptions {
  name: string;
  email: string;
  age?: number;
  role?: string;
  department?: string;
  manager?: string;
  startDate?: Date;
}

function createUser(options: CreateUserOptions): User;
```

### 3.2 Optional Parameters

```typescript
// Use default values
function paginate<T>(
  items: T[],
  page: number = 1,
  pageSize: number = 20
): T[];

// Use options object (when parameters > 3)
interface PaginationOptions {
  page?: number;
  pageSize?: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

function paginate<T>(items: T[], options?: PaginationOptions): T[];
```

### 3.3 Avoid Boolean Traps

```typescript
// Violation: Unclear what true means at call site
user.save(true);  // What does true mean?

// Correct: Use named parameters or enums
user.save({ validate: true });
// Or
user.save({ mode: SaveMode.Validated });
```

---

## 4) Return Value Design

### 4.1 Null Handling

```typescript
// Option 1: Return null/undefined
function findUser(id: string): User | null;

// Option 2: Return Optional (requires utility library)
function findUser(id: string): Optional<User>;

// Option 3: Throw exception (only for true error conditions)
function getUser(id: string): User;  // Throws NotFoundError if not exists
```

**Selection Guide**:

| Scenario | Recommended Approach |
|----------|---------------------|
| Query for potentially non-existent record | Return `null` |
| Record must exist | Throw exception |
| Chaining scenarios | Return `Optional` |

### 4.2 Collection Returns

```typescript
// Always return array, never null
function listUsers(): User[];  // Returns [] when no results

// Paginated results with metadata
interface PagedResult<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}

function listUsers(options: PaginationOptions): PagedResult<User>;
```

### 4.3 Async Returns

```typescript
// Always use Promise
async function getUser(id: string): Promise<User>;

// Cancellable async operations
function fetchData(
  url: string,
  signal?: AbortSignal
): Promise<Response>;
```

---

## 5) Error Handling

### 5.1 Error Types

```typescript
// Define explicit error types
class ApiError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number,
    public readonly details?: Record<string, unknown>
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

class NotFoundError extends ApiError {
  constructor(resource: string, id: string) {
    super(
      `${resource} with id ${id} not found`,
      'NOT_FOUND',
      404,
      { resource, id }
    );
  }
}

class ValidationError extends ApiError {
  constructor(field: string, message: string) {
    super(
      message,
      'VALIDATION_ERROR',
      400,
      { field }
    );
  }
}
```

### 5.2 Error Documentation

```typescript
/**
 * Get user information
 *
 * @param id - User ID
 * @returns User object
 * @throws {NotFoundError} When user does not exist
 * @throws {ValidationError} When ID format is invalid
 */
async function getUser(id: string): Promise<User>;
```

---

## 6) Version Evolution

### 6.1 Backward Compatibility

```typescript
// Add optional parameters (compatible)
// Old version
function search(query: string): Result[];
// New version
function search(query: string, options?: SearchOptions): Result[];

// Add new methods (compatible)
interface UserService {
  getUser(id: string): User;
  // New addition
  getUserWithDetails(id: string): UserWithDetails;
}
```

### 6.2 Deprecation Strategy

```typescript
/**
 * @deprecated Use `getUserById` instead, will be removed in v3.0
 */
function getUser(id: string): User {
  console.warn('getUser is deprecated, use getUserById instead');
  return getUserById(id);
}

function getUserById(id: string): User {
  // New implementation
}
```

### 6.3 Breaking Changes

When breaking changes are needed:

1. Clearly mark in CHANGELOG
2. Provide migration guide
3. Consider providing a codemod

```typescript
// v2 → v3 migration example
// Old API
userService.save(user, true);  // true = validate

// New API
userService.save(user, { validate: true });
```

---

## 7) API Review Checklist

When designing new APIs, verify the following:

- [ ] Is naming clear and consistent?
- [ ] Is parameter count ≤ 3? (Otherwise use object)
- [ ] Is return value explicit? (Avoid any)
- [ ] Are error cases handled?
- [ ] Is there JSDoc documentation?
- [ ] Is it backward compatible?
- [ ] Does it follow the principle of least astonishment?
