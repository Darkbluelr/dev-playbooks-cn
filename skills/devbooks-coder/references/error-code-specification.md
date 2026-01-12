# Error Code Specification

Based on VS Code error handling patterns, this document defines the standard specification for application error codes.

---

## 1) Error Code Design Principles

### 1.1 Readability

Error codes should be human-readable for easy understanding and memorization.

```typescript
// Recommended: Semantic error codes
'USER_NOT_FOUND'
'INVALID_EMAIL_FORMAT'
'PAYMENT_DECLINED'

// Avoid: Pure numbers or meaningless codes
'E10001'
'ERR_X7B2'
```

### 1.2 Uniqueness

Each error code should be unique across the entire system.

```typescript
// Use prefixes to distinguish modules
'AUTH_INVALID_TOKEN'
'AUTH_SESSION_EXPIRED'
'ORDER_NOT_FOUND'
'ORDER_ALREADY_PAID'
```

### 1.3 Stability

Once published, error codes should not change their meaning.

---

## 2) Error Code Format

### Standard Format

```
<MODULE>_<CATEGORY>_<DESCRIPTION>
```

| Part | Description | Example |
|------|------|------|
| MODULE | Module/Service name | `AUTH`, `ORDER`, `USER` |
| CATEGORY | Error category | `INVALID`, `NOT_FOUND`, `FAILED` |
| DESCRIPTION | Specific description | `TOKEN`, `EMAIL`, `PAYMENT` |

### Examples

```typescript
// Authentication module
'AUTH_INVALID_CREDENTIALS'
'AUTH_TOKEN_EXPIRED'
'AUTH_PERMISSION_DENIED'

// User module
'USER_NOT_FOUND'
'USER_ALREADY_EXISTS'
'USER_INVALID_EMAIL'

// Order module
'ORDER_NOT_FOUND'
'ORDER_INVALID_STATUS'
'ORDER_PAYMENT_FAILED'
```

---

## 3) Error Categories

### Standard Categories

| Category | HTTP Status Code | Description |
|------|------------|------|
| `INVALID` | 400 | Input validation failed |
| `UNAUTHORIZED` | 401 | Not authenticated |
| `FORBIDDEN` | 403 | No permission |
| `NOT_FOUND` | 404 | Resource does not exist |
| `CONFLICT` | 409 | Resource conflict |
| `RATE_LIMITED` | 429 | Rate limited |
| `INTERNAL` | 500 | Internal error |
| `UNAVAILABLE` | 503 | Service unavailable |
| `TIMEOUT` | 504 | Timeout |

### Mapping Table

```typescript
const ERROR_STATUS_MAP: Record<string, number> = {
  // 400 Bad Request
  'INVALID': 400,
  'VALIDATION': 400,
  'MALFORMED': 400,

  // 401 Unauthorized
  'UNAUTHORIZED': 401,
  'UNAUTHENTICATED': 401,

  // 403 Forbidden
  'FORBIDDEN': 403,
  'PERMISSION': 403,

  // 404 Not Found
  'NOT_FOUND': 404,
  'MISSING': 404,

  // 409 Conflict
  'CONFLICT': 409,
  'DUPLICATE': 409,
  'ALREADY_EXISTS': 409,

  // 429 Too Many Requests
  'RATE_LIMITED': 429,
  'THROTTLED': 429,

  // 500 Internal Server Error
  'INTERNAL': 500,
  'UNEXPECTED': 500,

  // 503 Service Unavailable
  'UNAVAILABLE': 503,
  'MAINTENANCE': 503,

  // 504 Gateway Timeout
  'TIMEOUT': 504,
};
```

---

## 4) Error Class Implementation

### Base Error Class

```typescript
interface ErrorDetails {
  [key: string]: unknown;
}

class AppError extends Error {
  public readonly code: string;
  public readonly statusCode: number;
  public readonly details?: ErrorDetails;
  public readonly timestamp: string;
  public readonly isOperational: boolean;

  constructor(
    code: string,
    message: string,
    statusCode: number = 500,
    details?: ErrorDetails
  ) {
    super(message);
    this.name = this.constructor.name;
    this.code = code;
    this.statusCode = statusCode;
    this.details = details;
    this.timestamp = new Date().toISOString();
    this.isOperational = true;  // Distinguish business errors from system errors

    Error.captureStackTrace(this, this.constructor);
  }

  toJSON() {
    return {
      code: this.code,
      message: this.message,
      statusCode: this.statusCode,
      details: this.details,
      timestamp: this.timestamp,
    };
  }
}
```

### Specific Error Classes

```typescript
// Validation error
class ValidationError extends AppError {
  constructor(field: string, message: string) {
    super(
      `VALIDATION_${field.toUpperCase()}_INVALID`,
      message,
      400,
      { field }
    );
  }
}

// Not found error
class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(
      `${resource.toUpperCase()}_NOT_FOUND`,
      `${resource} with id '${id}' not found`,
      404,
      { resource, id }
    );
  }
}

// Authentication error
class AuthenticationError extends AppError {
  constructor(reason: string) {
    super(
      `AUTH_${reason.toUpperCase()}`,
      `Authentication failed: ${reason}`,
      401
    );
  }
}

// Permission error
class ForbiddenError extends AppError {
  constructor(action: string, resource: string) {
    super(
      'AUTH_PERMISSION_DENIED',
      `You don't have permission to ${action} ${resource}`,
      403,
      { action, resource }
    );
  }
}

// Conflict error
class ConflictError extends AppError {
  constructor(resource: string, conflict: string) {
    super(
      `${resource.toUpperCase()}_CONFLICT`,
      `${resource} conflict: ${conflict}`,
      409,
      { resource, conflict }
    );
  }
}
```

---

## 5) Error Code Registry

### Central Registry

```typescript
// errors/registry.ts
export const ERROR_REGISTRY = {
  // ===== Authentication Module (AUTH_*) =====
  AUTH_INVALID_CREDENTIALS: {
    message: 'Invalid username or password',
    statusCode: 401,
    recoverable: true,
  },
  AUTH_TOKEN_EXPIRED: {
    message: 'Authentication token has expired',
    statusCode: 401,
    recoverable: true,
  },
  AUTH_TOKEN_INVALID: {
    message: 'Invalid authentication token',
    statusCode: 401,
    recoverable: false,
  },
  AUTH_PERMISSION_DENIED: {
    message: 'You do not have permission to perform this action',
    statusCode: 403,
    recoverable: false,
  },

  // ===== User Module (USER_*) =====
  USER_NOT_FOUND: {
    message: 'User not found',
    statusCode: 404,
    recoverable: false,
  },
  USER_ALREADY_EXISTS: {
    message: 'User already exists',
    statusCode: 409,
    recoverable: false,
  },
  USER_INVALID_EMAIL: {
    message: 'Invalid email format',
    statusCode: 400,
    recoverable: true,
  },

  // ===== Order Module (ORDER_*) =====
  ORDER_NOT_FOUND: {
    message: 'Order not found',
    statusCode: 404,
    recoverable: false,
  },
  ORDER_INVALID_STATUS: {
    message: 'Invalid order status transition',
    statusCode: 400,
    recoverable: false,
  },
  ORDER_PAYMENT_FAILED: {
    message: 'Payment processing failed',
    statusCode: 402,
    recoverable: true,
  },

  // ===== System Errors (SYSTEM_*) =====
  SYSTEM_INTERNAL_ERROR: {
    message: 'An internal error occurred',
    statusCode: 500,
    recoverable: false,
  },
  SYSTEM_SERVICE_UNAVAILABLE: {
    message: 'Service temporarily unavailable',
    statusCode: 503,
    recoverable: true,
  },
  SYSTEM_RATE_LIMITED: {
    message: 'Too many requests, please try again later',
    statusCode: 429,
    recoverable: true,
  },
} as const;

export type ErrorCode = keyof typeof ERROR_REGISTRY;
```

### Using the Registry

```typescript
function createError(code: ErrorCode, details?: ErrorDetails): AppError {
  const config = ERROR_REGISTRY[code];
  return new AppError(
    code,
    config.message,
    config.statusCode,
    details
  );
}

// Usage
throw createError('USER_NOT_FOUND', { userId: '12345' });
```

---

## 6) Error Response Format

### API Error Response

```typescript
interface ErrorResponse {
  error: {
    code: string;
    message: string;
    details?: ErrorDetails;
    timestamp: string;
    requestId?: string;
    documentation?: string;
  };
}

// Example response
{
  "error": {
    "code": "USER_NOT_FOUND",
    "message": "User with id '12345' not found",
    "details": {
      "userId": "12345"
    },
    "timestamp": "2024-01-15T10:30:00.000Z",
    "requestId": "req-abc-123",
    "documentation": "https://docs.example.com/errors/USER_NOT_FOUND"
  }
}
```

### Express Error Handling Middleware

```typescript
function errorHandler(
  err: Error,
  req: Request,
  res: Response,
  next: NextFunction
) {
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      error: {
        code: err.code,
        message: err.message,
        details: err.details,
        timestamp: err.timestamp,
        requestId: req.id,
      }
    });
  }

  // Unknown error
  console.error('Unexpected error:', err);
  return res.status(500).json({
    error: {
      code: 'SYSTEM_INTERNAL_ERROR',
      message: 'An unexpected error occurred',
      timestamp: new Date().toISOString(),
      requestId: req.id,
    }
  });
}
```

---

## 7) Error Documentation

### Documentation Template

```markdown
## USER_NOT_FOUND

**HTTP Status Code**: 404

**Description**: The requested user does not exist

**Possible Causes**:
- User ID is incorrect
- User has been deleted
- No permission to access this user

**Solutions**:
1. Verify the user ID is correct
2. Confirm the user has not been deleted
3. Confirm you have sufficient access permissions

**Example Response**:
```json
{
  "error": {
    "code": "USER_NOT_FOUND",
    "message": "User with id '12345' not found"
  }
}
```
```

---

## 8) Checklist

Confirm when designing error codes:

- [ ] Is the error code semantic? (Human-readable)
- [ ] Is the error code unique? (Globally non-duplicate)
- [ ] Does the error code include a module prefix?
- [ ] Is the HTTP status code correctly mapped?
- [ ] Is the error message user-friendly?
- [ ] Is sensitive information masked?
- [ ] Is it recorded in the error registry?
- [ ] Is there documentation?
