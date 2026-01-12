# AP-001: Controller 直接访问数据库

> 反模式 ID: AP-001-direct-db-in-controller
> 严重程度: High
> 相关规则: FR-001

---

## 问题描述

Controller 直接调用 Repository 或数据库操作，绕过 Service 层。

## 症状

- Controller 中出现 `Repository.find()` 调用
- Controller 中有直接的 SQL 查询
- Controller 注入了 Repository 而非 Service

## 错误示例

```typescript
// ❌ 错误：Controller 直接访问 Repository
@Controller('/users')
class UserController {
  constructor(private userRepository: UserRepository) {}

  @Get('/:id')
  async getUser(@Param('id') id: string) {
    return this.userRepository.findById(id);  // 直接访问数据库
  }

  @Post('/')
  async createUser(@Body() data: CreateUserDto) {
    return this.userRepository.save(data);  // 绕过业务逻辑
  }
}
```

## 为什么是反模式

1. **违反分层架构**：Controller 应只处理 HTTP 请求/响应
2. **业务逻辑分散**：相同逻辑可能在多个 Controller 重复
3. **难以测试**：需要 mock 数据库而非 Service
4. **难以维护**：修改数据库结构影响 Controller

## 正确做法

```typescript
// ✅ 正确：Controller 调用 Service
@Controller('/users')
class UserController {
  constructor(private userService: UserService) {}

  @Get('/:id')
  async getUser(@Param('id') id: string) {
    return this.userService.findById(id);  // 通过 Service
  }

  @Post('/')
  async createUser(@Body() data: CreateUserDto) {
    return this.userService.create(data);  // 业务逻辑在 Service
  }
}

// Service 层封装业务逻辑
@Injectable()
class UserService {
  constructor(private userRepository: UserRepository) {}

  async findById(id: string) {
    const user = await this.userRepository.findById(id);
    if (!user) throw new NotFoundException();
    return user;
  }

  async create(data: CreateUserDto) {
    // 业务验证、转换、事件发布等
    const user = this.userRepository.save(data);
    this.eventBus.publish(new UserCreatedEvent(user));
    return user;
  }
}
```

## 检测方法

```bash
# 检测 Controller 中的 Repository 调用
grep -rn "Repository\.\(find\|save\|delete\|update\|create\)" src/controllers/

# 检测 Controller 注入 Repository
grep -rn "private.*Repository" src/controllers/
```

## 重构步骤

1. 创建对应的 Service 类
2. 将 Repository 操作移到 Service
3. Controller 改为注入 Service
4. 添加必要的业务逻辑到 Service
5. 更新测试

## 相关资源

- [分层架构模式](https://martinfowler.com/bliki/PresentationDomainDataLayering.html)
- [依赖倒置原则](https://en.wikipedia.org/wiki/Dependency_inversion_principle)
