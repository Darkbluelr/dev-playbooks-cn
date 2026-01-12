# Microservice Design Checklist

> Applicable Scenario: Use this checklist to verify design completeness when designing microservices/distributed architectures.
>
> This document is **optional reference**, only use when the project involves microservices/distributed systems.

---

## 1) RPC Location Transparency Trap (Must Check)

**Core Principle**: Remote calls are not equal to local function calls, do not hide complexity.

### 1.1 Design Document Must Declare

- [ ] **Timeout Strategy**: Timeout duration for each RPC call (recommended 1-5 seconds)
- [ ] **Retry Strategy**: Maximum retry count, retry interval, exponential backoff
- [ ] **Degradation Plan**: Behavior when dependent service is unavailable (return default value/cache/error code)
- [ ] **Circuit Breaker Threshold**: Failure rate that triggers circuit breaker (recommended 50%)

### 1.2 Anti-pattern Check

| Anti-pattern | Problem | Correct Approach |
|--------------|---------|------------------|
| RPC without timeout | One slow service drags down entire chain | Explicitly set timeout, recommended 1-5 seconds |
| Infinite retry | Retry storm overwhelms downstream | Maximum 3 times, use exponential backoff |
| Synchronous chained calls | A->B->C->D latency accumulates | Asynchronize or parallelize calls |
| Hidden remote calls | Caller doesn't know this is network IO | Interface name/return type reflects "can fail" |

### 1.3 Test Owner Checklist

- [ ] Test covers "dependent service timeout" scenario (mock timeout)
- [ ] Test covers "dependent service returns error" scenario
- [ ] Test covers "degradation behavior after circuit breaker"
- [ ] Test covers "retry logic" (verify maximum retry count)

---

## 2) Distributed Failure Impact Assessment

### 2.1 Failure Mode Checklist

| Failure Type | Impact Scope | Detection Method | Recovery Strategy |
|--------------|--------------|------------------|-------------------|
| Network partition | Service A cannot access Service B | Health check timeout | Circuit breaker + degradation |
| Node crash | Single node service interruption | Heartbeat detection failure | Load balancer switch |
| Response slowdown | Chain latency increase | p99 latency alert | Rate limiting + queuing |
| Data inconsistency | Multi-replica data out of sync | Reconciliation task | Retry + compensation |

### 2.2 Design Document Must Declare

- [ ] What inter-service dependencies does this change involve?
- [ ] What is the failure impact scope for each dependency?
- [ ] What is the user-visible behavior during failure?
- [ ] Is chaos engineering drill needed?

---

## 3) Distributed Tracing

### 3.1 Design Requirements

- [ ] All RPC calls must pass `trace_id`
- [ ] Logs must include `trace_id` field
- [ ] Events/messages must include `trace_id` field

### 3.2 Implementation Check

```
Request header passing: X-Trace-Id / X-Request-Id
Log format: {"trace_id": "xxx", "message": "...", "timestamp": "..."}
Message contains: {"trace_id": "xxx", "event_type": "...", "payload": {...}}
```

### 3.3 Test Owner Checklist

- [ ] Test verifies "trace_id is correctly passed across service calls"
- [ ] Test verifies "logs contain trace_id field"
- [ ] Test verifies "exception logs can trace back to original request via trace_id"

---

## 4) Service Contract Management

### 4.1 Contract Definition Requirements

- [ ] Use OpenAPI/Proto/AsyncAPI to define service contracts
- [ ] Contract files under version control
- [ ] Contract changes require compatibility check

### 4.2 Contract Testing Requirements

- [ ] Provider side has contract tests (verify implementation matches contract)
- [ ] Consumer side has contract tests (verify consumer assumptions are correct)
- [ ] Both sides' tests run when contract changes

### 4.3 Breaking Change Handling

- [ ] Prohibit direct deletion of published APIs
- [ ] New version runs parallel with old version for at least 2 release cycles
- [ ] Provide migration guide and deprecation timeline

---

## 5) Exactly-once and Idempotency

### 5.1 Message Processing Semantics Selection

| Semantics | Applicable Scenario | Implementation Complexity |
|-----------|---------------------|---------------------------|
| at-most-once | Logs, monitoring (loss allowed) | Low |
| at-least-once | Notifications, statistics (duplicates allowed) | Medium |
| exactly-once | Payments, orders (no loss or duplicates allowed) | High |

### 5.2 Exactly-once Implementation Checklist

- [ ] Message contains unique `message_id`
- [ ] Consumer records processed `message_id` (database/Redis)
- [ ] Duplicate messages return success directly (idempotent handling)
- [ ] Test covers "same message consumed 3 times, executed only once"

### 5.3 Test Owner Checklist

- [ ] Test verifies "no duplicate side effects when message is duplicated"
- [ ] Test verifies "retry succeeds when message is lost"
- [ ] Test verifies "correct compensation when partial failure"

---

## 6) Design Document Template Supplement

In the Target Architecture section of `design.md`, add the following subsections:

```markdown
### Microservice Design Constraints (if applicable)

#### Service Dependency Graph
- This service -> Dependent Service A (timeout 3s, retry 2 times, degrade to empty list)
- This service -> Dependent Service B (timeout 5s, retry 0 times, degrade to cache)

#### Failure Modes and Degradation
| Failure Scenario | User-visible Behavior | Recovery Strategy |
|------------------|----------------------|-------------------|
| Service A unavailable | Display "No data available" | Circuit breaker 60 seconds then retry |
| Service B slow response | Use cached data | Trigger rate limiting when p99 > 1s |

#### Distributed Tracing Requirements
- All APIs must pass `X-Trace-Id`
- Log format: JSON, must contain `trace_id`
```
