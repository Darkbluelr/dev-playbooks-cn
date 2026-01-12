# glossary.md Template (Truth Source Meta Information)

> Recommended path: `<truth-root>/_meta/glossary.md`
>
> Goal: Unify business language to avoid specification and code drift caused by different names for the same concept.

---
owner: `<role/agent>`
last_verified: `YYYY-MM-DD`
status: `Active | Deprecated | Draft`
freshness_check: `3 Months`
---

## Glossary (Ubiquitous Language)

| Term (Chinese) | Term (English) | Code Name/Entity | Definition (Business Meaning) | Synonyms (Allowed) | Forbidden Words (Avoid) | Notes/Examples |
|---|---|---|---|---|---|---|
| Order | Order | Order | Transaction record generated after user completes payment | Purchase order | Deal/Trade | Examples: Order ID, Order Status |
| Customer | Customer | Customer | Natural person/enterprise that transacts with the platform | User | Account | Examples: Customer level, Customer profile |

## Domain Modeling Terms

> The following terms are used in the domain model section of `design.md` to help distinguish different types of objects.

| Term | Definition | Identification Criteria | Examples |
|------|------|----------|------|
| **Entity** | Object with unique identity, mutable state, and lifecycle tracking | 1. Has business-meaningful ID 2. State is mutable 3. Requires persistence | Order, Customer, Product |
| **Value Object** | Object without unique identity, immutable, descriptive | 1. No ID 2. Immutable 3. Can be freely copied/shared | Address, Money, DateRange, Email |
| **Invariant** | Business constraint that must always hold; no operation can violate it | 1. Cross-attribute constraint 2. Violation means data error | `Order total = SUM(line item amounts)`, `Inventory >= 0` |
| **Business Rule** | Configurable/changeable business policy with clear handling logic when violated | 1. May change with business 2. Violation has handling path | `Member discount rate`, `Auto-cancel on timeout` |
| **ACL (Anti-Corruption Layer)** | Adapter layer that isolates external system models from internal models | 1. External API call entry 2. Model transformation logic | Payment gateway adapter, Third-party logistics interface |
| **Bounded Context** | Autonomous business domain boundary with unified terminology inside | 1. Independent deployment/evolution 2. Clear terminology boundary | Order context, Product context, User context |

## Usage Rules

- Design/specification/test/code must use terms from this table; creating new terms is prohibited
- If a new term is needed, update this file first, then produce design/spec/tests
- **Entity vs Value Object Decision**:
  - Ask "Does this object need a unique identity?" -> Yes means Entity, No means Value Object
  - Ask "Will this object's state change?" -> Yes means Entity, No means Value Object
  - Ask "Are two objects with identical attributes equivalent?" -> Yes means Value Object, No means Entity
- **Invariant Annotation**: Mark with `[Invariant]` prefix in `design.md`; corresponding assertions should exist in code
