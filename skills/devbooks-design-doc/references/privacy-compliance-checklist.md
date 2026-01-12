# Telemetry Privacy Compliance Checklist

Drawing from VS Code's `telemetry.instructions.md`, this document defines privacy compliance requirements for instrumentation/telemetry data.

---

## 1) GDPR Classification Requirements

When design.md or spec-delta involves instrumentation, the following fields **must** be filled:

```markdown
## Telemetry / Instrumentation Design

### GDPR Classification

| Field | Value | Description |
|-------|-------|-------------|
| **owner** | @username | Data owner (must be a team member) |
| **isMeasurement** | true/false | Whether it is measurement data (non-PII) |
| **purpose** | PerformanceAndHealth / BusinessInsight / FeatureInsight | Collection purpose |
| **classification** | SystemMetaData / CallstackOrException / EndUserPseudonymizedInformation | Data type |
| **retention** | 90d / 1y / permanent | Data retention period |
| **gdprRequired** | true/false | Whether user consent is required |

### Instrumentation Event Definition

| Event Name | Trigger Timing | Data Fields | Classification |
|------------|----------------|-------------|----------------|
| feature.used | When user uses feature X | `{ featureId, duration }` | SystemMetaData |
| error.occurred | When exception occurs | `{ errorCode, stack }` | CallstackOrException |
```

---

## 2) Data Classification Description

### SystemMetaData

**Definition**: System information not involving user identity

**Allowed to collect**:
- Operating system version
- Application version
- Feature flag status
- Performance metrics (latency, memory)
- Anonymous usage frequency

**Example**:
```typescript
// Compliant: System metadata
telemetry.log('app.startup', {
  version: '1.0.0',
  os: 'darwin',
  memoryUsage: process.memoryUsage().heapUsed,
});
```

### CallstackOrException

**Definition**: Error information and call stacks

**Allowed to collect**:
- Error codes
- Error messages (must be sanitized)
- Call stacks (must sanitize file paths)

**Sanitization Requirements**:
- Remove usernames: `/Users/john/` -> `/Users/<username>/`
- Remove project paths: `/project/secret/` -> `<project>/`
- Remove sensitive filenames: `credentials.json` -> `<sensitive>`

**Example**:
```typescript
// Compliant: Sanitized exception
telemetry.logError('app.error', {
  errorCode: 'E001',
  message: sanitizeMessage(error.message),
  stack: sanitizeStack(error.stack),
});
```

### EndUserPseudonymizedInformation

**Definition**: Pseudonymized user information

**Requirements**:
- Must use one-way hash
- Cannot be reversed
- Requires user consent

**Example**:
```typescript
// Compliant: Pseudonymized user ID
telemetry.log('user.action', {
  hashedUserId: sha256(userId + salt), // One-way hash
  action: 'click',
});
```

### PublicNonPersonalData

**Definition**: Completely public data not involving any personal information

**Allowed to collect**:
- Public configuration options
- Public API versions
- Public feature lists

---

## 3) Prohibited Data Collection

| Type | Example | Reason |
|------|---------|--------|
| Plaintext PII | Name, email, phone | Directly identifies user |
| Location information | GPS, IP address | Indirectly identifies user |
| File contents | User documents, code | Sensitive data |
| Passwords/tokens | API keys, passwords | Security risk |
| Health information | Medical data | Sensitive data |
| Financial information | Bank card numbers | Sensitive data |

**Detection Rules**:
```bash
# Detect potential PII collection
rg "email|phone|name|address|ip" --type ts -g "*telemetry*"
rg "password|token|secret|key" --type ts -g "*telemetry*"
```

---

## 4) Event Naming Conventions

### Regular Events (publicLog2)

For normal feature usage and performance measurements:

```typescript
// Naming format: <domain>.<action>
publicLog2<{ duration: number }>('editor.opened', { duration: 123 });
publicLog2<{ count: number }>('search.performed', { count: 10 });
```

### Exception Events (publicLogError2)

For errors and exceptional situations:

```typescript
// Naming format: <domain>.error or <domain>.failed
publicLogError2<{ code: string }>('editor.error', { code: 'E001' });
publicLogError2<{ reason: string }>('save.failed', { reason: 'disk_full' });
```

---

## 5) Code Review Checklist

When reviewing code involving instrumentation:

### Must Check

- [ ] **Is GDPR classification complete?**
  - Is owner specified?
  - Is classification correct?
  - Is purpose clear?

- [ ] **Is data sanitized?**
  - Are usernames removed from file paths?
  - Are sensitive information filtered from error messages?
  - Is there plaintext PII?

- [ ] **Is naming standard?**
  - Does event name follow `<domain>.<action>` format?
  - Do error events use `publicLogError2`?

- [ ] **Is user consent handled?**
  - Is `telemetryLevel` checked for data requiring consent?
  - Are user privacy settings respected?

### Automated Checks

```bash
# Check for unclassified instrumentation
rg "publicLog2|telemetry\.log" --type ts | xargs -I {} grep -L "classification" {}

# Check for sensitive data collection
rg "(email|phone|password|token)" --type ts -g "*telemetry*"
```

---

## 6) design.md Template

When design.md involves instrumentation, add the following section:

```markdown
## Telemetry Impact

### New Instrumentation Events

| Event | owner | classification | purpose | isMeasurement |
|-------|-------|----------------|---------|---------------|
| feature.x.used | @alice | SystemMetaData | FeatureInsight | true |
| feature.x.error | @alice | CallstackOrException | PerformanceAndHealth | false |

### Data Field Definition

```typescript
interface FeatureXUsedEvent {
  duration: number;        // Usage duration (ms)
  success: boolean;        // Whether successful
  // Prohibited to add: userId, filePath, etc.
}
```

### Privacy Impact Assessment

- [ ] No PII collected
- [ ] Sensitive paths sanitized
- [ ] telemetryLevel settings checked
- [ ] Privacy Review obtained (if needed)
```

---

## 7) Compliance Approval Process

| Data Type | Approval Requirement |
|-----------|---------------------|
| SystemMetaData | No approval needed |
| CallstackOrException | No approval needed (must sanitize) |
| EndUserPseudonymizedInformation | Privacy Review required |
| Any new PII | Legal Review required |

---

## References

- [GDPR Data Classification Guide](https://gdpr.eu/data-protection/)
- [VS Code Telemetry Documentation](https://code.visualstudio.com/docs/getstarted/telemetry)
- [Microsoft Privacy Statement](https://privacy.microsoft.com/)
