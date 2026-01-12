# 8 Core Code Smells Cheatsheet

> Source: "Refactoring: Improving the Design of Existing Code" Debate Revision Edition
> Refined from the original 22 code smells to 8 high-frequency, high-impact core code smells

---

## Quick Reference Index

| # | Code Smell | One-Line Description | Severity |
|---|------------|---------------------|----------|
| 1 | Duplicated Code | Same code appears in multiple places | Blocking |
| 2 | Long Method | Function too long to understand | Blocking |
| 3 | Large Class | Class has too many responsibilities | Warning |
| 4 | Long Parameter List | Too many parameters to call | Blocking |
| 5 | Divergent Change | One class changes for multiple reasons | Warning |
| 6 | Shotgun Surgery | One change requires modifying multiple classes | Blocking |
| 7 | Feature Envy | Function overly dependent on other classes | Warning |
| 8 | Primitive Obsession | Business concepts using primitive types | Warning |
| 9 | **Module Cycle (Circular Dependency)** | A→B→A prevents independent testing | **Blocking** |

---

## 1. Duplicated Code

**Recognition Signals**:
- Code blocks with >80% similarity appearing ≥2 places
- Copy-paste with only variable names changed
- Sibling subclasses contain identical code

**Why It's a Problem**:
- Easy to miss changes when modifying, causing inconsistent behavior
- Increases code volume, decreases readability
- Violates DRY principle

**Refactoring Techniques**:
1. **Duplication within same class** → Extract Method
2. **Duplication between sibling subclasses** → Extract Method → Pull Up Method
3. **Duplication between unrelated classes** → Extract Class (extract common class)

**Code Example**:
```python
# Code smell: duplicate validation logic
def create_user(email):
    if not email or '@' not in email:
        raise ValueError("Invalid email")
    # ...

def update_email(email):
    if not email or '@' not in email:  # Duplicate!
        raise ValueError("Invalid email")
    # ...

# After refactoring: extract method
def validate_email(email):
    if not email or '@' not in email:
        raise ValueError("Invalid email")

def create_user(email):
    validate_email(email)
    # ...
```

---

## 2. Long Method

**Recognition Signals**:
- **P95<50 lines** (exceeding triggers discussion)
- Need to scroll to see the entire function
- Large comment blocks explaining "what this part does"
- Cyclomatic complexity >10

**Why It's a Problem**:
- Difficult to understand overall function logic
- Difficult to test (need to cover too many branches)
- Difficult to reuse partial logic

**Refactoring Techniques**:
1. **Comments are signals** → Extract Method (function name from comment)
2. **Too many temporary variables** → Replace Temp with Query
3. **Complex conditional branches** → Decompose Conditional

**Code Example**:
```python
# Code smell: long method
def process_order(order):
    # Validate order
    if not order.items:
        raise ValueError("Empty order")
    if order.total < 0:
        raise ValueError("Invalid total")

    # Calculate discount
    discount = 0
    if order.customer.is_vip:
        discount = order.total * 0.1
    elif order.total > 1000:
        discount = order.total * 0.05

    # Update inventory
    for item in order.items:
        stock = get_stock(item.product_id)
        stock.quantity -= item.quantity
        save_stock(stock)

    # ... 50 more lines

# After refactoring: extract methods
def process_order(order):
    validate_order(order)
    discount = calculate_discount(order)
    update_inventory(order)
    # ...
```

---

## 3. Large Class

**Recognition Signals**:
- **P95<500 lines**
- Instance variables >10
- Methods >20
- Multiple groups of fields with same prefix (e.g., `billing_xxx`, `shipping_xxx`)

**Why It's a Problem**:
- Violates Single Responsibility Principle
- Difficult to test (too many dependencies)
- Uncontrollable impact scope when modifying

**Refactoring Techniques**:
1. **Responsibilities can be separated** → Extract Class
2. **Subtypes exist** → Extract Subclass
3. **Only partial interface needed** → Extract Interface

---

## 4. Long Parameter List

**Recognition Signals**:
- Parameter count >5
- Easy to confuse parameter order
- Multiple functions have same parameter combinations

**Why It's a Problem**:
- Easy to pass wrong parameters when calling
- Function signature hard to remember
- Parameter combination may be a hidden concept

**Refactoring Techniques**:
1. **Parameters obtainable from object** → Preserve Whole Object
2. **Parameters always appear together** → Introduce Parameter Object

**Code Example**:
```python
# Code smell: too many parameters
def create_address(street, city, state, zip_code, country, apt_number):
    pass

# After refactoring: introduce parameter object
@dataclass
class Address:
    street: str
    city: str
    state: str
    zip_code: str
    country: str
    apt_number: str = None

def create_address(address: Address):
    pass
```

---

## 5. Divergent Change

**Recognition Signals**:
- Modifying database requires changing this class
- Modifying UI also requires changing this class
- Modifying business rules still requires changing this class
- "Every requirement change requires changing this file"

**Why It's a Problem**:
- Class bears responsibilities for multiple change axes
- Changes from different reasons affect each other
- Difficult to test a single dimension

**Refactoring Techniques**:
- Extract Class (separate by change reason)

**Comparison with Shotgun Surgery**:
- Divergent Change: one class responds to multiple types of changes
- Shotgun Surgery: one type of change requires modifying multiple classes
- They are **dual problems**, solutions are opposite

---

## 6. Shotgun Surgery

**Recognition Signals**:
- One requirement requires modifying ≥3 classes
- "Changing one place requires changing many places"
- Easy to miss changes causing bugs

**Why It's a Problem**:
- Easy to miss modifications
- Scattered logic makes it hard to understand the whole
- Test coverage is difficult

**Refactoring Techniques**:
1. **Logic should be centralized** → Move Method / Move Field
2. **Too scattered** → Inline Class (merge first then re-split)

---

## 7. Feature Envy

**Recognition Signals**:
- Function calls to other classes > calls to own class
- Function heavily uses another class's fields
- "This method seems to be in the wrong place"

**Why It's a Problem**:
- Violates "data and operations should be together" principle
- Increases coupling between classes
- Unclear responsibility division

**Refactoring Techniques**:
- Move Method (move to the class where data resides)

**Exception Cases** (not Feature Envy):
- Strategy pattern (strategy class accesses context)
- Visitor pattern (visitor accesses elements)
- Need to annotate in code comments "this is a design pattern, not Feature Envy"

---

## 8. Primitive Obsession

**Recognition Signals**:
- Using String for phone numbers, emails, currency
- Using int for status codes, type codes
- Business rules scattered in multiple places (e.g., email format validation)

**Why It's a Problem**:
- Lack of type safety (String can accept any value)
- Business rules cannot be centralized
- Not aligned with glossary.md terminology

**Refactoring Techniques**:
- Replace Data Value with Object
- Replace Type Code with Class/Subclass

**Applicable Scope** (debate revision):
- **Must encapsulate**: business concepts (Money, Email, UserId, PhoneNumber)
- **Optional encapsulation**: technical types (coordinates, colors, simple configs)

**Code Example**:
```python
# Code smell: primitive types for business concepts
def transfer(from_account: str, to_account: str, amount: float):
    pass  # amount can be negative? what currency?

# After refactoring: encapsulate as value objects
@dataclass(frozen=True)
class Money:
    amount: Decimal
    currency: str

    def __post_init__(self):
        if self.amount < 0:
            raise ValueError("Amount cannot be negative")

def transfer(from_account: AccountId, to_account: AccountId, amount: Money):
    pass
```

---

## Removed Code Smells (Refined After Debate)

The following concepts were deleted after Advocate/Skeptic/Judge three-party debate:

| Original Code Smell | Reason for Removal |
|--------------------|-------------------|
| Parallel Inheritance Hierarchies | Deep inheritance rarely used in modern code |
| Lazy Class | Conflicts with SRP, small classes are good design |
| Speculative Generality | Judgment criteria too subjective |
| Temporary Field | Low occurrence rate |
| Message Chains | Functional chained calls are prevalent |
| Middle Man | Has anti-corruption value in layered architecture |
| Alternative Classes with Different Interfaces | Covered by terminology consistency check |
| Incomplete Library Class | Third-party libraries cannot be refactored |
| Data Class | Modern architecture (DDD) allows anemic DTO layer |
| Refused Bequest | Inheritance use has greatly reduced |
| Comments | "Why" type comments have value |

---

## Quick Decision Flowchart

```
Found suspicious code
    │
    ├─ Duplicate? ────────────────→ Extract Method
    │
    ├─ Function >50 lines? ───────→ Extract Method + Decompose Conditional
    │
    ├─ Class >500 lines? ─────────→ Extract Class
    │
    ├─ Parameters >5? ────────────→ Introduce Parameter Object
    │
    ├─ Change one place requires  → Move Method/Field (centralize logic)
    │  changing many places?
    │
    ├─ One class responds to      → Extract Class (separate change axes)
    │  multiple types of changes?
    │
    ├─ Function always accesses   → Move Method
    │  other classes?
    │
    └─ Business concept using     → Replace Data Value with Object
       String?
```

---

## 9. Module Cycle (Circular Dependency)

> Source: "Clean Architecture" Debate Revision Edition - Core rule retained by consensus

**Recognition Signals**:
- Module A depends on B, B depends back on A (direct cycle)
- A→B→C→A indirect cycle
- Cannot compile/test a module independently
- "Changing one module requires changing another at the same time"

**Why It's a Problem**:
- Modules cannot be tested independently (must mock multiple sides simultaneously)
- Cannot be deployed/released independently
- Strong signal of architecture decay
- Refactoring cost grows exponentially

**Detection Tools**:
```bash
# JavaScript/TypeScript
npx madge --circular src/

# Java
jdeps -R -summary target/classes | grep cycle

# Go
go mod graph | tsort 2>&1 | grep -i cycle

# Python
pydeps --show-cycles src/
```

**Refactoring Techniques**:
1. **Dependency Inversion** → Extract interface to independent module, both sides depend on interface
2. **Callback/Event** → When A calls B, B notifies A via callback/event instead of direct dependency
3. **Extract Common Module** → Extract parts commonly depended on by A/B into C

**Code Example**:
```python
# Code smell: circular dependency
# order.py
from payment import PaymentService  # Order → Payment

# payment.py
from order import Order  # Payment → Order (cycle!)

# After refactoring: dependency inversion
# interfaces.py (independent module)
class OrderInterface(ABC):
    @abstractmethod
    def get_total(self) -> Money: pass

# order.py
class Order(OrderInterface):  # Implements interface
    pass

# payment.py
from interfaces import OrderInterface  # Only depends on interface
class PaymentService:
    def charge(self, order: OrderInterface): pass
```

**CI Integration Recommendation**:
```yaml
# .github/workflows/ci.yml
- name: Check circular dependencies
  run: |
    npx madge --circular src/ && echo "No cycles found" || exit 1
```

---

## References

- "Refactoring: Improving the Design of Existing Code" (2nd Edition) - Martin Fowler
- "Clean Architecture" - Robert C. Martin (Chapter 14 Component Coupling)
- dev-playbooks Debate Revision Assessment Report
- devbooks-code-review Checklist

---

## 10. VS Code Style Code Hygiene Checks

> Borrowed from VS Code ESLint custom rules, as automated check items for code review

### Patterns Forbidden to Commit (Blocking Level)

| Pattern | Detection Command | Reason |
|---------|-------------------|--------|
| `test.only` / `describe.only` | `rg '\.only\s*\(' tests/` | Skips other tests |
| `console.log` / `console.debug` | `rg 'console\.(log\|debug)' src/` | Debug code residue |
| `debugger` | `rg 'debugger' src/` | Breakpoint residue |
| `@ts-ignore` | `rg '@ts-ignore' src/` | Hides type errors |
| `as any` | `rg 'as any' src/` | Type safety bypass |
| `TODO` without issue | `rg 'TODO(?!.*#\d+)' src/` | Untraceable todos |

### Resource Management Checks (Warning Level)

| Pattern | Detection Method | Correct Approach |
|---------|-----------------|------------------|
| Non-readonly DisposableStore | `rg 'private\s+(?!readonly)\s*_?\w*[Dd]isposable'` | Use `readonly` |
| dispose() not calling super | Manual check override dispose | Must call `super.dispose()` |
| setInterval without cleanup | Search setInterval without corresponding clearInterval | Clean up in dispose |
| Event listeners not removed | Search addEventListener without removeEventListener | Use AbortController |

### Layer Constraint Checks

```bash
# Check forbidden cross-layer dependencies
# base layer cannot depend on platform/editor/workbench
rg "from ['\"](vs/(platform|editor|workbench))" src/vs/base/

# platform layer cannot depend on editor/workbench
rg "from ['\"](vs/(editor|workbench))" src/vs/platform/

# common layer cannot depend on browser/node
rg "from ['\"].*(browser|node)" src/**/common/
```

### Type Safety Checks

```typescript
// Forbidden: empty object assertion
const config = {} as Config;  // ❌

// Forbidden: non-null assertion
const name = user!.name;  // ❌

// Forbidden: any type
function process(data: any) { }  // ❌

// Correct: use unknown or specific types
function process(data: unknown) { }  // ✓
```

### Automated Check Script

```bash
#!/bin/bash
# hygiene-check.sh

set -e

echo "=== Code Hygiene Check ==="

# 1. Debug code
if rg -l 'console\.(log|debug)|debugger' src/ --type ts 2>/dev/null; then
  echo "❌ Found debug code"
  exit 1
fi

# 2. test.only
if rg -l '\.only\s*\(' tests/ --type ts 2>/dev/null; then
  echo "❌ Found test.only"
  exit 1
fi

# 3. @ts-ignore
count=$(rg -c '@ts-ignore' src/ --type ts 2>/dev/null | wc -l)
if [ "$count" -gt 0 ]; then
  echo "⚠️  Found $count instances of @ts-ignore"
fi

# 4. any type
count=$(rg -c ': any[^a-z]' src/ --type ts 2>/dev/null | wc -l)
if [ "$count" -gt 0 ]; then
  echo "⚠️  Found $count instances of any type"
fi

echo "✅ Hygiene check passed"
```
