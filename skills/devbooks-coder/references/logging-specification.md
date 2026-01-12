# Logging Specification

Based on VS Code logging practices, this document defines the standard specification for application logging.

---

## 1) Log Levels

### Level Definitions

| Level | Purpose | Example |
|------|------|------|
| `ERROR` | Errors requiring immediate attention | Database connection failure, external API error |
| `WARN` | Potential issues that don't affect main flow | Missing config using default value, retry succeeded |
| `INFO` | Key business process milestones | User login, order creation, service startup |
| `DEBUG` | Development debugging information | Function parameters, intermediate state |
| `TRACE` | Detailed tracing information | Each row data processing, loop iteration |

### Level Selection Guide

```typescript
// ERROR: System cannot work properly
logger.error('Database connection failed', { error, retries: 3 });

// WARN: Recoverable issue
logger.warn('Cache miss, falling back to database', { key });

// INFO: Business milestone
logger.info('User registered', { userId, email });

// DEBUG: Information useful during development
logger.debug('Processing request', { params, headers });

// TRACE: Very detailed tracing
logger.trace('Row processed', { rowIndex, data });
```

---

## 2) Log Format

### Structured Logging

```typescript
// Recommended: Structured logging
logger.info('Order created', {
  orderId: '12345',
  userId: 'user-789',
  amount: 99.99,
  currency: 'USD',
  items: 3
});

// Output JSON (easy to parse)
{
  "timestamp": "2024-01-15T10:30:00.000Z",
  "level": "INFO",
  "message": "Order created",
  "orderId": "12345",
  "userId": "user-789",
  "amount": 99.99,
  "currency": "USD",
  "items": 3,
  "service": "order-service",
  "traceId": "abc-123-xyz"
}
```

### Required Fields

| Field | Description | Example |
|------|------|------|
| `timestamp` | ISO 8601 format timestamp | `2024-01-15T10:30:00.000Z` |
| `level` | Log level | `INFO`, `ERROR` |
| `message` | Human-readable message | `User logged in` |
| `service` | Service name | `user-service` |
| `traceId` | Request trace ID | `abc-123-xyz` |

### Optional Fields

| Field | Description | When to Use |
|------|------|---------|
| `userId` | User identifier | When user context exists |
| `requestId` | Request ID | HTTP request handling |
| `duration` | Duration (milliseconds) | Performance-related logs |
| `error` | Error details | ERROR level logs |

---

## 3) Log Content Guidelines

### Message Format

```typescript
// Recommended: Start with verb, describe what happened
logger.info('User logged in', { userId });
logger.info('Order created', { orderId });
logger.info('Payment processed', { paymentId, amount });

// Avoid: Vague messages
logger.info('Done');  // What done?
logger.info('Error');  // What error?
logger.info('Processing...');  // Processing what?
```

### Context Data

```typescript
// Recommended: Include sufficient context
logger.error('Failed to process payment', {
  orderId: '12345',
  paymentMethod: 'credit_card',
  error: {
    code: 'DECLINED',
    message: 'Card declined by issuer'
  },
  retryCount: 2
});

// Avoid: Missing context
logger.error('Payment failed');  // Which order? What reason?
```

### Sensitive Data Handling

```typescript
// Prohibited: Logging sensitive data
logger.info('User login', {
  email: 'user@example.com',
  password: '123456'  // Absolutely prohibited!
});

// Correct: Mask sensitive data
logger.info('User login', {
  email: maskEmail('user@example.com'),  // u***@example.com
  passwordProvided: true
});

// Masking utility functions
function maskEmail(email: string): string {
  const [local, domain] = email.split('@');
  return `${local[0]}***@${domain}`;
}

function maskCreditCard(card: string): string {
  return `****-****-****-${card.slice(-4)}`;
}
```

**Data Prohibited from Logging**:

| Type | Example |
|------|------|
| Passwords | password, secret, token |
| Credentials | API key, access token |
| Personal Information | ID number, bank card number |
| Sensitive Business Data | Full credit card number, CVV |

---

## 4) Error Logging Guidelines

### Error Information Structure

```typescript
logger.error('Operation failed', {
  operation: 'createOrder',
  error: {
    name: error.name,
    message: error.message,
    code: error.code,
    stack: error.stack  // Only in non-production environment
  },
  context: {
    userId: '12345',
    input: sanitize(input)  // Sanitized input
  },
  recovery: 'Will retry in 5 seconds'
});
```

### Error Classification

```typescript
// Recoverable error (WARN)
logger.warn('Temporary failure, retrying', {
  operation: 'fetchData',
  attempt: 2,
  maxAttempts: 3
});

// Unrecoverable error (ERROR)
logger.error('Critical failure', {
  operation: 'saveData',
  error: error.message,
  action: 'Manual intervention required'
});
```

---

## 5) Performance Logging

### Duration Recording

```typescript
// Record operation duration
const start = performance.now();
await processOrder(order);
const duration = performance.now() - start;

logger.info('Order processed', {
  orderId: order.id,
  duration: Math.round(duration),  // milliseconds
  durationUnit: 'ms'
});

// Timeout warning
if (duration > 1000) {
  logger.warn('Slow operation detected', {
    operation: 'processOrder',
    duration,
    threshold: 1000
  });
}
```

### Batch Operations

```typescript
logger.info('Batch processing completed', {
  operation: 'importUsers',
  total: 1000,
  success: 985,
  failed: 15,
  duration: 5230,
  avgPerItem: 5.23
});
```

---

## 6) Log Configuration

### Environment Configuration

| Environment | Default Level | Output Format | Stack Trace |
|------|---------|---------|---------|
| Development | DEBUG | Human-readable | Full |
| Staging | INFO | JSON | ERROR only |
| Production | INFO | JSON | ERROR only |

### Configuration Example

```typescript
// logger.config.ts
interface LoggerConfig {
  level: 'error' | 'warn' | 'info' | 'debug' | 'trace';
  format: 'json' | 'pretty';
  includeStack: boolean;
  service: string;
}

const config: LoggerConfig = {
  level: process.env.LOG_LEVEL || 'info',
  format: process.env.NODE_ENV === 'production' ? 'json' : 'pretty',
  includeStack: process.env.NODE_ENV !== 'production',
  service: process.env.SERVICE_NAME || 'app'
};
```

---

## 7) Recommended Logging Libraries

### Node.js

```typescript
// Recommended: pino (high performance)
import pino from 'pino';

const logger = pino({
  level: 'info',
  formatters: {
    level: (label) => ({ level: label.toUpperCase() })
  },
  timestamp: () => `,"timestamp":"${new Date().toISOString()}"`
});

// Or: winston (feature-rich)
import winston from 'winston';

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.Console()
  ]
});
```

### Browser

```typescript
// Simple wrapper
const logger = {
  error: (msg: string, data?: object) =>
    console.error(JSON.stringify({ level: 'ERROR', message: msg, ...data })),
  warn: (msg: string, data?: object) =>
    console.warn(JSON.stringify({ level: 'WARN', message: msg, ...data })),
  info: (msg: string, data?: object) =>
    console.info(JSON.stringify({ level: 'INFO', message: msg, ...data })),
  debug: (msg: string, data?: object) =>
    console.debug(JSON.stringify({ level: 'DEBUG', message: msg, ...data }))
};
```

---

## 8) Checklist

Confirm when writing logs:

- [ ] Is the level correct? (ERROR/WARN/INFO/DEBUG)
- [ ] Is the message clear? (Starts with verb, describes event)
- [ ] Is context sufficient? (Can locate the problem)
- [ ] Is sensitive data masked?
- [ ] Does error log include stack trace?
- [ ] Does performance log include duration?
