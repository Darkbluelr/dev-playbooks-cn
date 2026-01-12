# Low-Risk Modification Techniques Quick Reference

> Source: "Working Effectively with Legacy Code" - Michael Feathers
> Applicable Role: Coder (Implementation Lead)

---

## Applicable Scenarios

When a Coder needs to add features or fix bugs in legacy code but faces these constraints:
- High time pressure, unable to refactor at large scale
- Insufficient test coverage, high modification risk
- Need to ensure "behavior preservation"

---

## Core Principles

| Principle | Description |
|------|------|
| **Behavior Preservation** | Any modification must ensure original functionality remains unchanged |
| **Minimal Invasion** | Try not to modify original code, but add/wrap around it |
| **Testability First** | New code must be testable, even if old code is not |
| **Rely on Compiler** | After changing signature, let compiler errors reveal all call sites |

---

## I. Sprout Method

### Definition
When new functionality needs to be added, don't modify the original method, but **create a new method** and call it from the original method.

### Applicable Scenarios
- Need to add logic in the middle of a method
- Original method is too long or hard to test
- New logic is relatively independent

### Steps
1. Identify where to add code
2. Extract new code as independent method
3. Write tests for the new method
4. Call new method at original location

### Example

```python
# Original code (hard to test)
class OrderProcessor:
    def process(self, order):
        # 100 lines of legacy code...
        total = self._calculate_total(order)
        # Need to add discount calculation logic here
        self._save_order(order, total)
        # 50 lines of legacy code...

# After Sprout Method refactoring
class OrderProcessor:
    def process(self, order):
        # 100 lines of legacy code... (unchanged)
        total = self._calculate_total(order)
        discounted_total = self._apply_discount(order, total)  # New call
        self._save_order(order, discounted_total)  # Modified parameter
        # 50 lines of legacy code... (unchanged)

    def _apply_discount(self, order, total):  # New method, independently testable
        if order.customer.is_vip:
            return total * 0.9
        return total
```

### Advantages
- New code 100% testable
- Minimal change to original code (only adds one line of call)
- Risk isolation: bugs in new logic won't affect original logic

---

## II. Sprout Class

### Definition
When new functionality requires multiple methods or state, **create a new class** to handle it, then instantiate and use it in the original code.

### Applicable Scenarios
- New functionality is complex, requires multiple methods
- New functionality needs to maintain state
- Original class is already too large (>500 lines)

### Steps
1. Create new class, implement new functionality
2. Write complete tests for new class
3. Create new class instance in original code
4. Call new class methods

### Example

```python
# Create independent class (fully testable)
class DiscountCalculator:
    def __init__(self, discount_rules: list[DiscountRule]):
        self._rules = discount_rules

    def calculate(self, order, original_total):
        discount = 0
        for rule in self._rules:
            discount += rule.apply(order, original_total)
        return original_total - discount

# Use in original code
class OrderProcessor:
    def __init__(self):
        self._discount_calc = DiscountCalculator(self._load_rules())

    def process(self, order):
        # Legacy code...
        total = self._calculate_total(order)
        discounted = self._discount_calc.calculate(order, total)  # Use new class
        self._save_order(order, discounted)
```

### Advantages
- New class completely independent, can be tested separately
- Clear responsibilities, avoids original class bloating
- Extensible for future (e.g., adding more discount rules)

---

## III. Wrap Method

### Definition
Don't modify original method implementation, but **create a new method to wrap the original method**, adding pre/post logic in the wrapper.

### Applicable Scenarios
- Need to add logic before/after method execution (e.g., logging, validation, caching)
- Original method signature unchanged, transparent to callers
- Follows Open/Closed Principle

### Steps
1. Rename original method (e.g., `pay` -> `_pay_impl`)
2. Create new method with same name
3. Call original method in new method, add pre/post logic

### Example

```python
# Original code
class PaymentService:
    def pay(self, order, amount):
        # Payment logic...
        return result

# After Wrap Method refactoring
class PaymentService:
    def pay(self, order, amount):  # External calls unchanged
        self._log_payment_start(order, amount)  # Pre logic
        result = self._pay_impl(order, amount)  # Original logic
        self._log_payment_end(order, result)    # Post logic
        return result

    def _pay_impl(self, order, amount):  # Original method renamed
        # Original payment logic (completely unchanged)
        return result
```

### Advantages
- Original logic completely unchanged
- Callers unaware of change
- Pre/post logic can be tested independently

---

## IV. Wrap Class (Decorator)

### Definition
Create a new class that **wraps the original class**, adding logic before/after calling original class methods (Decorator pattern).

### Applicable Scenarios
- Original class cannot be modified (e.g., third-party library)
- Need to add cross-cutting concerns to entire class (logging, caching, permissions)
- Want to keep original class unchanged

### Steps
1. Create wrapper class, hold original class instance
2. Implement same interface
3. Add logic in methods then delegate to original class

### Example

```python
# Original class (possibly third-party library, cannot modify)
class LegacyPaymentGateway:
    def process(self, payment):
        # Complex legacy logic...
        return result

# Wrap Class
class AuditedPaymentGateway:
    def __init__(self, gateway: LegacyPaymentGateway, audit_log: AuditLog):
        self._gateway = gateway
        self._audit = audit_log

    def process(self, payment):  # Same interface
        self._audit.log_start(payment)
        try:
            result = self._gateway.process(payment)  # Delegate to original class
            self._audit.log_success(payment, result)
            return result
        except Exception as e:
            self._audit.log_failure(payment, e)
            raise
```

### Advantages
- Original class completely unchanged
- Can compose multiple wrappers (e.g., cache + logging + retry)
- Follows Open/Closed Principle

---

## V. Decision Flowchart

```
Need to add/modify functionality
      |
      v
+-------------------------+
| Is new functionality    |
| an independent block?   |
+-----------+-------------+
       +----+----+
       v         v
      Yes        No
       |         |
       v         v
 +----------+  +------------------+
 | Need     |  | Add before/after |
 | state?   |  | method?          |
 +----+-----+  +--------+---------+
   +--+--+          +---+---+
   v     v          v       v
  Yes   No         Yes      No
   |     |          |       |
   v     v          v       v
Sprout  Sprout    Wrap    Add in middle
Class   Method   Method   of method
                  or       |
                 Wrap      v
                 Class   Sprout
                         Method
```

---

## VI. Collaboration with Test Owner

| Coder Behavior | Test Owner Collaboration Needed |
|-----------|---------------------|
| Using Sprout Method/Class | Test Owner writes tests for new method/class |
| Using Wrap Method/Class | Test Owner verifies wrapped behavior unchanged |
| Need to break dependencies for testing | Refer to "Dependency Breaking Techniques Quick Reference" |
| Change affects multiple callers | Refer to Impact Analysis Pinch Point |

---

## VII. Prohibited Behaviors

- **Prohibited**: Directly modifying core logic of legacy code (unless sufficient test coverage exists)
- **Prohibited**: Modifying unrelated code for "incidental refactoring"
- **Prohibited**: Deleting seemingly unused code (may have hidden dependencies)
- **Prohibited**: Modifying `tests/**` directory (needs to be handed back to Test Owner)

---

## References

- "Working Effectively with Legacy Code" Chapters 6-8
- "Dependency Breaking Techniques Quick Reference"
- dev-playbooks `devbooks-coder/SKILL.md`
