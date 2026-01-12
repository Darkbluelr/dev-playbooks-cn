# Prototype-Production Dual Track

> Source: "The Mythical Man-Month" Chapter 11 "Plan to Throw One Away" - "The first system built is not going to be usable... Plan to throw one away; you will, anyhow."

## Core Philosophy

**Prototype track** is for rapid validation of technical feasibility, producing a "disposable first version".
**Production track** is for delivering high-quality code, with tests/gates as completion criteria.

The two tracks are **physically isolated**, connected through an explicit "promotion" process.

---

## When to Use Prototype Track

| Scenario | Signal | Recommendation |
|----------|--------|----------------|
| Technical uncertainty | "Don't know if this library will work" / "Uncertain if performance is sufficient" | Use prototype |
| First time doing it | "First time building this type of feature" / "Expect to rewrite" | Use prototype |
| Exploratory behavior | "Need to observe actual API return values" | Use prototype |
| Clear requirements | Design confirmed, ACs defined | Skip to production track |
| Minor fixes | Bug fixes, configuration adjustments | Skip to production track |

---

## Dual Track Process Diagram

```
+------------------------------------------------------------------+
|                        Proposal Phase                              |
|  proposal.md (shared)                                              |
+------------------------------------------------------------------+
                              |
                              v
              +---------------+---------------+
              |                               |
              v                               v
    +------------------+             +------------------+
    |   Prototype      |             |   Production     |
    |   Track          |             |   Track          |
    +------------------+             +------------------+
    | prototype/src/   |             | design.md        |
    | prototype/       |             | tasks.md         |
    |   characterization/|           | verification.md  |
    | PROTOTYPE.md     |             | tests/**         |
    +------------------+             +------------------+
    | Characterization |             | Acceptance       |
    | tests            |             | tests            |
    | (record actual   |             | (verify design   |
    | behavior)        |             | intent)          |
    | No Red baseline  |             | Red baseline     |
    | required         |             | required         |
    +--------+---------+             +--------+---------+
             |                                |
             |                                |
             v                                |
    +------------------+                      |
    | Learn & Decide   |                      |
    | Promote or       |                      |
    | Discard?         |                      |
    +--------+---------+                      |
             |                                |
     +-------+-------+                        |
     v               v                        |
  [Promote]       [Discard]                   |
     |               |                        |
     v               v                        |
prototype-promote.sh  Delete prototype/       |
     |               +------------------------+
     |                                        |
     +----------------------------------------+
                              |
                              v
                    +------------------+
                    |   Archive Phase  |
                    +------------------+
```

---

## Characterization Tests vs Acceptance Tests

| Dimension | Acceptance Test | Characterization Test |
|-----------|-----------------|----------------------|
| **Purpose** | Assert "what should be" | Assert "what actually is" |
| **Source** | Design document / AC-xxx | Runtime observation |
| **Baseline** | Must be Red first | Initially Green |
| **Track** | Production track | Prototype track |
| **Use** | Verify design intent | Record behavior snapshot |
| **CI** | Enters main pipeline | Marked skip / isolated |

### Characterization Test Naming Convention

```
# Python
test_characterize_<behavior>.py
@pytest.mark.characterization

# TypeScript/JavaScript
*.characterization.test.ts
describe.skip('characterization: <behavior>')
```

---

## Role Isolation (Unchanged)

Under prototype mode, role isolation principles are **exactly the same** as production track:

| Role | Responsibility | Prohibited |
|------|----------------|------------|
| Test Owner | Produce characterization tests | Must not share context with Coder |
| Coder | Produce prototype code | Prohibited from modifying characterization/ |

---

## Prototype Promotion Checklist

Before running `prototype-promote.sh <change-id>`, must complete:

- [ ] Create production-grade `design.md` (extract What/Constraints/AC-xxx from prototype learnings)
- [ ] Test Owner produces acceptance tests `verification.md` (replacing characterization tests)
- [ ] Complete promotion checklist in `prototype/PROTOTYPE.md`
- [ ] Document technical discoveries in "Learning Record" section of `prototype/PROTOTYPE.md`

---

## Prototype Discard Checklist

If deciding to discard prototype:

- [ ] Record key insights learned to `proposal.md` Decision Log
- [ ] Delete `prototype/` directory
- [ ] Optional: preserve some insights to `<truth-root>/_meta/lessons-learned/`

---

## Script Reference

| Script | Purpose | Example |
|--------|---------|---------|
| `change-scaffold.sh --prototype` | Create prototype skeleton | `change-scaffold.sh feat-001 --prototype` |
| `prototype-promote.sh` | Promote prototype to production track | `prototype-promote.sh feat-001` |

---

## FAQ

### Q: Can prototype code be used directly in production?

**No**. Prototype code is physically isolated in `prototype/src/`, prohibited from directly landing in repository `src/`. Must go through `prototype-promote.sh` for explicit promotion.

### Q: Do characterization tests enter CI?

**No**. Characterization tests use `@characterization` marker, skipped by default. Upon promotion, they are archived to `tests/archived-characterization/`.

### Q: Do I need to write design.md in prototype mode?

**Not during prototype phase**. After prototype ends, if deciding to promote, extract production-grade `design.md` from prototype learnings.

### Q: Can I skip prototype and go directly to production?

**Yes**. If requirements are clear and technical solution is confirmed, go directly to production track (A/B/C/D phases).

---

## References

- "The Mythical Man-Month" Chapter 11 "Plan to Throw One Away"
- Michael Feathers, "Working Effectively with Legacy Code" - Characterization Tests
- Martin Fowler, "Is High Quality Software Worth the Cost?"
