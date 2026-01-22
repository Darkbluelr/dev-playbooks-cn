# AP-001: Controller Direct Database Access

> Anti-Pattern ID: AP-001-direct-db-in-controller
> Severity: High
> Related Rule: FR-001

---

## Problem Description

Controller directly calls Repository or database operations, bypassing the Service layer.

## Symptoms

- `Repository.find()` calls appearing in Controller
- Direct SQL queries in Controller
- Controller injecting Repository instead of Service

## Bad Example

```typescript
// ❌ Wrong: Controller directly accesses Repository
@Controller('/users')
class UserController {
  constructor(private userRepository: UserRepository) {}

  @Get('/:id')
  async getUser(@Param('id') id: string) {
    return this.userRepository.findById(id);  // Direct database access
  }

  @Post('/')
  async createUser(@Body() data: CreateUserDto) {
    return this.userRepository.save(data);  // Bypassing business logic
  }
}
```

## Why This is an Anti-Pattern

1. **Violates Layered Architecture**: Controller should only handle HTTP request/response
2. **Scattered Business Logic**: Same logic may be duplicated in multiple Controllers
3. **Hard to Test**: Requires mocking database instead of Service
4. **Hard to Maintain**: Database structure changes affect Controller

## Correct Approach

```typescript
// ✅ Correct: Controller calls Service
@Controller('/users')
class UserController {
  constructor(private userService: UserService) {}

  @Get('/:id')
  async getUser(@Param('id') id: string) {
    return this.userService.findById(id);  // Through Service
  }

  @Post('/')
  async createUser(@Body() data: CreateUserDto) {
    return this.userService.create(data);  // Business logic in Service
  }
}

// Service layer encapsulates business logic
@Injectable()
class UserService {
  constructor(private userRepository: UserRepository) {}

  async findById(id: string) {
    const user = await this.userRepository.findById(id);
    if (!user) throw new NotFoundException();
    return user;
  }

  async create(data: CreateUserDto) {
    // Business validation, transformation, event publishing, etc.
    const user = this.userRepository.save(data);
    this.eventBus.publish(new UserCreatedEvent(user));
    return user;
  }
}
```

## Detection Methods

```bash
# Detect Repository calls in Controller
grep -rn "Repository\.\(find\|save\|delete\|update\|create\)" src/controllers/

# Detect Controller injecting Repository
grep -rn "private.*Repository" src/controllers/
```

## Refactoring Steps

1. Create corresponding Service class
2. Move Repository operations to Service
3. Change Controller to inject Service
4. Add necessary business logic to Service
5. Update tests

## Related Resources

- [Layered Architecture Pattern](https://martinfowler.com/bliki/PresentationDomainDataLayering.html)
- [Dependency Inversion Principle](https://en.wikipedia.org/wiki/Dependency_inversion_principle)
