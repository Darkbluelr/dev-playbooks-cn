# Ethics and Compliance Checklist

> Applicable scenarios: Use this checklist for ethics review when the project involves personal data, AI decision-making, or social impact.
>
> This document is **optional reference**, use only when the project involves:
> - Personal data collection/processing/storage
> - Algorithmic decision-making (recommendations, moderation, scoring)
> - User behavior tracking
> - Automated decisions affecting user rights

---

## 1) Data Privacy (GDPR/CCPA Compliance)

### 1.1 Data Collection Check

- [ ] **Necessity principle**: Only collect data necessary for functionality
- [ ] **Informed consent**: Users explicitly know and consent before collection
- [ ] **Purpose limitation**: Data used only for stated purposes, no secondary use
- [ ] **Minimization principle**: Collect minimum necessary data fields

### 1.2 Data Storage Check

- [ ] **Retention period**: Clear how long data is retained and how it's deleted after expiry
- [ ] **Encrypted storage**: Is sensitive data encrypted at rest
- [ ] **Access control**: Who can access the data, are there audit logs
- [ ] **Cross-border transfer**: Is data transferred to other countries/regions

### 1.3 User Rights Check

- [ ] **Right to access**: Can users view their own data
- [ ] **Right to rectification**: Can users correct erroneous data
- [ ] **Right to erasure**: Can users request data deletion ("right to be forgotten")
- [ ] **Right to portability**: Can users export their own data

### 1.4 Required Declaration in design.md

```markdown
### Data Privacy Statement
- Data types collected: <list fields>
- Data purpose: <describe purpose>
- Retention period: <xx days/months/years>
- User rights implementation: <access/rectification/deletion entry points>
```

---

## 2) Algorithmic Bias (AI/ML Systems)

### 2.1 Bias Risk Check

| Bias Type | Manifestation | Detection Method |
|-----------|---------------|------------------|
| Historical bias | Training data reflects historical inequality | Data audit |
| Representation bias | Certain groups underrepresented in data | Group distribution statistics |
| Measurement bias | Feature selection unfair to certain groups | Fairness metrics comparison |
| Evaluation bias | Evaluation metrics unfair to certain groups | Segmented evaluation |

### 2.2 Fairness Checklist

- [ ] Has model performance difference across different populations been analyzed?
- [ ] Is there a mechanism to detect and correct bias?
- [ ] Are fairness metrics defined (e.g., accuracy difference across groups < 5%)?
- [ ] Is there a human review mechanism for edge cases?

### 2.3 Explainability Checklist

- [ ] Can users understand "why I got this result"?
- [ ] Is an appeal/feedback channel provided?
- [ ] Is there human intervention opportunity for important decisions?

---

## 3) Social Impact Assessment

### 3.1 Negative Impact Check

- [ ] Could this feature be abused? How to prevent?
- [ ] Could it create filter bubbles/polarization?
- [ ] Could it widen the digital divide?
- [ ] Could it affect user mental health?

### 3.2 Vulnerable Group Protection

- [ ] Are there special protections for minors?
- [ ] Can elderly/disabled users access without barriers?
- [ ] Are low-income groups excluded from the service?

### 3.3 Required Declaration in design.md

```markdown
### Social Impact Assessment
- Potential negative impacts: <describe risks>
- Mitigation measures: <describe how to reduce risks>
- Vulnerable group protection: <describe special measures>
```

---

## 4) Security and Abuse Prevention

### 4.1 Abuse Scenario Check

- [ ] Have malicious user abuse scenarios been considered?
- [ ] Are there rate limits to prevent flooding/attacks?
- [ ] Is there content moderation (e.g., UGC content)?
- [ ] Is there anomaly detection mechanism?

### 4.2 Data Leak Prevention

- [ ] Is sensitive data desensitized?
- [ ] Does API have authentication and authorization?
- [ ] Could logs leak sensitive information?

---

## 5) Proposal Phase Ethics Check

When challenging with `devbooks-proposal-challenger`, add the following checkpoints:

### 5.1 Mandatory Check (when involving personal data)

- [ ] **Data necessity**: Is only data necessary for functionality collected?
- [ ] **User awareness**: Does user clearly know how data is used?
- [ ] **Opt-out mechanism**: Can user choose not to participate or delete data?

### 5.2 Optional Check (when involving algorithmic decisions)

- [ ] **Explainability**: Can user understand decision rationale?
- [ ] **Appeal mechanism**: Can user contest decisions?
- [ ] **Fairness**: Is it fair to different groups?

### 5.3 Proposal Template Supplement

```markdown
### Ethics and Compliance (optional, but required when involving personal data)

#### Data Privacy
- Data collected: <none / list fields>
- User consent mechanism: <none / describe method>
- Deletion/export capability: <none / describe entry point>

#### Algorithmic Decision (if applicable)
- Decision type: <none / recommendation / moderation / scoring / other>
- Explainability: <none / describe method>
- Appeal mechanism: <none / describe entry point>

#### Social Impact
- Potential negative impacts: <none / describe risks>
- Mitigation measures: <none / describe method>
```

---

## 6) Compliance Regulations Quick Reference

| Regulation | Applicable Region | Core Requirements |
|------------|-------------------|-------------------|
| GDPR | European Union | Informed consent, data minimization, right to be forgotten, data portability |
| CCPA | California | Right to know, deletion right, non-discrimination right, opt-out right |
| PIPL | China | Separate consent, local storage, cross-border assessment |
| COPPA | USA | Protection of children under 13 data |

---

## 7) Decision Record Template

When ethical disputes exist, record in `proposal.md` Decision Log:

```markdown
### Ethics Decision Record

| Date | Dispute Point | Various Views | Final Decision | Rationale |
|------|---------------|---------------|----------------|-----------|
| YYYY-MM-DD | Whether to collect user location | Product: need precise recommendations / Security: privacy risk | Only collect city-level | Balance recommendation effectiveness with privacy |
```
