# AP-002: God Class

> Anti-Pattern ID: AP-002-god-class
> Severity: High
> Related Rule: Single Responsibility Principle

---

## Problem Description

A class takes on too many responsibilities, knowing too much and doing too many things.

## Identification Criteria

| Metric | Threshold | Description |
|--------|-----------|-------------|
| Method Count | > 20 | Too many methods |
| Lines of Code | > 500 | File too large |
| Dependency Count | > 10 | Too many dependencies |
| Cyclomatic Complexity | > 50 | Complexity too high |

## Symptoms

- File exceeds 500 lines
- Class name contains vague words like "Manager", "Handler", "Processor"
- Modifying any feature requires changing this class
- Difficult to write unit tests for this class

## Bad Example

```typescript
// ❌ Wrong: One class doing too many things
class UserManager {
  // User CRUD
  createUser() { ... }
  updateUser() { ... }
  deleteUser() { ... }
  findUser() { ... }

  // Authentication
  login() { ... }
  logout() { ... }
  resetPassword() { ... }
  verifyEmail() { ... }

  // Authorization
  checkPermission() { ... }
  assignRole() { ... }
  revokeRole() { ... }

  // Notifications
  sendWelcomeEmail() { ... }
  sendPasswordResetEmail() { ... }
  sendNotification() { ... }

  // Reports
  getUserStats() { ... }
  generateReport() { ... }

  // And more...
}
```

## Why This is an Anti-Pattern

1. **Violates Single Responsibility**: A class should have only one reason to change
2. **Hard to Understand**: Need to understand entire class to modify a small part
3. **Hard to Test**: Testing requires many mocks
4. **Hard to Reuse**: Cannot use only partial functionality separately
5. **Concurrent Development Conflicts**: Multiple people modifying same file

## Correct Approach

```typescript
// ✅ Correct: Separation of concerns

// User CRUD
class UserRepository {
  create(data: CreateUserDto) { ... }
  update(id: string, data: UpdateUserDto) { ... }
  delete(id: string) { ... }
  findById(id: string) { ... }
}

// Authentication
class AuthService {
  login(credentials: LoginDto) { ... }
  logout(userId: string) { ... }
  resetPassword(email: string) { ... }
}

// Authorization
class PermissionService {
  check(userId: string, permission: string) { ... }
  assignRole(userId: string, role: string) { ... }
}

// Notifications
class NotificationService {
  sendEmail(to: string, template: string, data: any) { ... }
}

// Reports
class UserReportService {
  getStats(filter: StatsFilter) { ... }
  generate(options: ReportOptions) { ... }
}
```

## Detection Methods

```bash
# Detect large files
find src/ -name "*.ts" -exec wc -l {} \; | awk '$1 > 500'

# Detect classes with too many methods
grep -c "^\s*\(async \)\?\(public \|private \|protected \)\?\w\+(" src/**/*.ts

# Use complexity tools
npx ts-complexity src/
```

## Refactoring Steps

1. Identify different responsibilities in the class
2. Create separate classes for each responsibility
3. Use dependency injection to compose these classes
4. Gradually migrate methods to new classes
5. Update all call sites
6. Delete the original God Class

## Related Resources

- [Single Responsibility Principle](https://en.wikipedia.org/wiki/Single-responsibility_principle)
- [Refactoring: Improving the Design of Existing Code](https://refactoring.com/)
- [Extract Class Refactoring](https://refactoring.guru/extract-class)
