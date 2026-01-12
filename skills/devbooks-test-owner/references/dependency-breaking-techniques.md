# Dependency Breaking Techniques Quick Reference (8 High-Frequency Techniques)

> Source: "Working Effectively with Legacy Code" Chapter 25 (selected from 24)
> Applicable Roles: Test Owner / Coder

---

## Quick Reference Index

| # | Technique | One-Liner Description | Frequency | Applicable Scenario |
|---|-----------|----------------------|-----------|---------------------|
| 1 | Extract Interface | Extract interface to isolate external dependencies | *** | External services/databases/third-party APIs |
| 2 | Parameterize Constructor | Inject dependencies through constructor | *** | Hardcoded dependencies, new operations in constructor |
| 3 | Subclass and Override | Subclass and override method | *** | Need to replace partial behavior, cannot modify original class |
| 4 | Introduce Static Setter | Provide setter for static dependencies | ** | Singletons, global objects, static factories |
| 5 | Extract and Override Getter | Extract getter and override | ** | Field dependencies, lazy initialization |
| 6 | Break Out Method Object | Extract method as object | ** | Long methods, complex algorithms |
| 7 | Adapt Parameter | Create adapter for parameter | * | Hard-to-mock parameter types |
| 8 | Encapsulate Global References | Encapsulate global variables | * | Global state, environment variables |

---

## 1. Extract Interface

### Problem Scenario
```python
class OrderService:
    def __init__(self):
        self._payment = PaymentGateway()  # Hardcoded dependency on real payment gateway
        self._inventory = InventoryDB()    # Hardcoded dependency on real database

    def process(self, order):
        self._payment.charge(order.total)  # Cannot test: will actually charge
        self._inventory.deduct(order.items)
```

### Solution
```python
# 1. Extract interface
class PaymentGatewayInterface(Protocol):
    def charge(self, amount: Decimal) -> bool: ...

class InventoryInterface(Protocol):
    def deduct(self, items: list[Item]) -> None: ...

# 2. Original class implements interface (optional)
class PaymentGateway(PaymentGatewayInterface):
    def charge(self, amount): ...

# 3. Inject through constructor
class OrderService:
    def __init__(self, payment: PaymentGatewayInterface, inventory: InventoryInterface):
        self._payment = payment
        self._inventory = inventory

# 4. Inject Mock in tests
def test_order_service():
    mock_payment = Mock(spec=PaymentGatewayInterface)
    mock_inventory = Mock(spec=InventoryInterface)
    service = OrderService(mock_payment, mock_inventory)
    service.process(order)
    mock_payment.charge.assert_called_once_with(order.total)
```

### Key Points
- Interface defines "contract", implementation is replaceable
- Use Mock to implement interface in tests
- Use real implementation in production

---

## 2. Parameterize Constructor

### Problem Scenario
```python
class ReportGenerator:
    def __init__(self):
        self._db = DatabaseConnection()  # new dependency in constructor
        self._logger = FileLogger("/var/log/app.log")
```

### Solution
```python
class ReportGenerator:
    def __init__(self, db=None, logger=None):
        self._db = db or DatabaseConnection()  # Default value maintains backward compatibility
        self._logger = logger or FileLogger("/var/log/app.log")

# In tests
def test_report_generator():
    mock_db = Mock()
    mock_logger = Mock()
    generator = ReportGenerator(db=mock_db, logger=mock_logger)
```

### Key Points
- Keep default values, don't break existing callers
- Production code needs no modification
- Test code can inject Mock

---

## 3. Subclass and Override

### Problem Scenario
```python
class PaymentProcessor:
    def process(self, payment):
        gateway = self._get_gateway()  # Protected method gets real gateway
        return gateway.charge(payment)

    def _get_gateway(self):
        return RealPaymentGateway()  # Cannot replace in tests
```

### Solution
```python
# Create subclass in tests
class TestablePaymentProcessor(PaymentProcessor):
    def __init__(self, mock_gateway):
        self._mock_gateway = mock_gateway

    def _get_gateway(self):  # Override protected method
        return self._mock_gateway

# Test
def test_payment_processor():
    mock_gateway = Mock()
    processor = TestablePaymentProcessor(mock_gateway)
    processor.process(payment)
    mock_gateway.charge.assert_called_once()
```

### Key Points
- Don't modify original class, only extend in tests
- Suitable when cannot modify source code
- Overridden methods should be as small as possible

---

## 4. Introduce Static Setter

### Problem Scenario
```python
class ConfigManager:
    _instance = None

    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            cls._instance = cls._create_real_config()  # Singleton, cannot replace
        return cls._instance

class MyService:
    def do_work(self):
        config = ConfigManager.get_instance()  # Depends on singleton
        return config.get("api_key")
```

### Solution
```python
class ConfigManager:
    _instance = None

    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            cls._instance = cls._create_real_config()
        return cls._instance

    @classmethod
    def set_instance_for_testing(cls, instance):  # Add testing setter
        cls._instance = instance

    @classmethod
    def reset_instance(cls):  # Test cleanup
        cls._instance = None

# Test
def test_my_service():
    mock_config = Mock()
    mock_config.get.return_value = "test_api_key"
    ConfigManager.set_instance_for_testing(mock_config)
    try:
        service = MyService()
        result = service.do_work()
        assert result == "test_api_key"
    finally:
        ConfigManager.reset_instance()  # Cleanup
```

### Key Points
- Only for testing, production code should not call setter
- Must reset in teardown
- Consider using pytest fixture for automatic cleanup

---

## 5. Extract and Override Getter

### Problem Scenario
```python
class OrderValidator:
    def validate(self, order):
        current_time = datetime.now()  # Direct call, cannot control time
        if order.expires_at < current_time:
            raise OrderExpiredError()
```

### Solution
```python
class OrderValidator:
    def validate(self, order):
        current_time = self._get_current_time()  # Extract to method
        if order.expires_at < current_time:
            raise OrderExpiredError()

    def _get_current_time(self):  # Can be overridden
        return datetime.now()

# Test
class TestableOrderValidator(OrderValidator):
    def __init__(self, fixed_time):
        self._fixed_time = fixed_time

    def _get_current_time(self):
        return self._fixed_time

def test_order_expired():
    validator = TestableOrderValidator(datetime(2024, 1, 15))
    expired_order = Order(expires_at=datetime(2024, 1, 10))
    with pytest.raises(OrderExpiredError):
        validator.validate(expired_order)
```

### Key Points
- Extract uncontrollable dependencies (time, random numbers, environment) to methods
- Control return values through subclass override in tests
- Keep original behavior unchanged

---

## 6. Break Out Method Object

### Problem Scenario
```python
class ReportEngine:
    def generate_complex_report(self, data, config, filters, formatters):
        # 200 lines of complex logic, using many local variables
        temp1 = ...
        temp2 = ...
        # Hard to test: method too long, too many dependencies
```

### Solution
```python
# Extract method to independent class
class ComplexReportGenerator:
    def __init__(self, data, config, filters, formatters):
        self._data = data
        self._config = config
        self._filters = filters
        self._formatters = formatters
        # Former local variables become instance variables
        self._temp1 = None
        self._temp2 = None

    def generate(self):
        self._step1()
        self._step2()
        return self._finalize()

    def _step1(self):  # Can be tested individually
        self._temp1 = ...

    def _step2(self):  # Can be tested individually
        self._temp2 = ...

# Original class delegates to new class
class ReportEngine:
    def generate_complex_report(self, data, config, filters, formatters):
        generator = ComplexReportGenerator(data, config, filters, formatters)
        return generator.generate()
```

### Key Points
- Long method split into multiple testable small methods
- Local variables become instance variables, can inspect intermediate state in tests
- Original class maintains interface unchanged

---

## 7. Adapt Parameter

### Problem Scenario
```python
class DataProcessor:
    def process(self, http_request: HttpRequest):  # HttpRequest hard to mock
        data = http_request.get_json()
        headers = http_request.headers
        # ...
```

### Solution
```python
# Create adapter interface
class RequestData(Protocol):
    def get_json(self) -> dict: ...
    def get_headers(self) -> dict: ...

# Adapter wraps real object
class HttpRequestAdapter:
    def __init__(self, request: HttpRequest):
        self._request = request

    def get_json(self):
        return self._request.get_json()

    def get_headers(self):
        return dict(self._request.headers)

# Modify method signature
class DataProcessor:
    def process(self, request: RequestData):  # Depend on interface not concrete class
        data = request.get_json()
        headers = request.get_headers()

# In tests
def test_data_processor():
    mock_request = Mock(spec=RequestData)
    mock_request.get_json.return_value = {"key": "value"}
    mock_request.get_headers.return_value = {"Content-Type": "application/json"}
    processor = DataProcessor()
    processor.process(mock_request)
```

### Key Points
- Create simplified interface for hard-to-mock parameters
- Production code uses adapter to wrap real objects
- Test code directly mocks interface

---

## 8. Encapsulate Global References

### Problem Scenario
```python
# Global variables
DATABASE_URL = os.environ.get("DATABASE_URL")
API_KEY = os.environ.get("API_KEY")

class MyService:
    def connect(self):
        return Database(DATABASE_URL)  # Depends on global variable
```

### Solution
```python
# Encapsulate as config class
class AppConfig:
    def __init__(self):
        self._db_url = os.environ.get("DATABASE_URL")
        self._api_key = os.environ.get("API_KEY")

    @property
    def database_url(self):
        return self._db_url

    @property
    def api_key(self):
        return self._api_key

# Inject config
class MyService:
    def __init__(self, config: AppConfig):
        self._config = config

    def connect(self):
        return Database(self._config.database_url)

# Test
def test_my_service():
    mock_config = Mock(spec=AppConfig)
    mock_config.database_url = "sqlite:///:memory:"
    service = MyService(mock_config)
```

### Key Points
- Global variables encapsulated as injectable config object
- Config values controllable in tests
- Eliminates implicit environment dependencies

---

## Decision Flowchart

```
Code untestable?
      |
      v
+-----------------------------+
| What type is the dependency? |
+----------+------------------+
     +-----+-----+-----+------+
     v     v     v     v      v
  External  new in  Singleton  Field  Global
  Service  Constructor Static  Dep   Variable
     |     |     |     |      |
     v     v     v     v      v
 Extract  Para-  Static Extract Encap-
 Inter-   meter- Setter Override sulate
 face     ize           Getter Global
          Constr-
          uctor
```

---

## Relationship with Other Documents

| Scenario | Reference Document |
|----------|-------------------|
| Need to safely add features to legacy code | `low-risk-modification-techniques.md` |
| Need to find optimal test point | `test-driven-development.md` S 7.2 Pinch Point |
| Need to assess change impact | `06-impact-analysis-prompt.md` |

---

## References

- "Working Effectively with Legacy Code" Chapter 25 - Dependency-Breaking Techniques
- dev-playbooks `devbooks-test-owner/SKILL.md`
