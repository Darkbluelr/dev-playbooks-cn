# API 设计指南

借鉴 VS Code Extension API 设计原则，本文档定义了 API 设计的最佳实践。

---

## 1) 核心原则

### 1.1 最小惊讶原则

API 的行为应符合用户的直觉预期。

```typescript
// 违规：方法名暗示查询，但实际修改了状态
function getUser(id: string): User {
  this.lastAccessedUser = id;  // 副作用！
  return this.users[id];
}

// 正确：查询方法无副作用
function getUser(id: string): User {
  return this.users[id];
}
```

### 1.2 一致性原则

相似的操作应有相似的 API。

```typescript
// 违规：不一致的命名
interface UserService {
  getUser(id: string): User;
  fetchOrder(id: string): Order;  // 应该用 getOrder
  loadProduct(id: string): Product;  // 应该用 getProduct
}

// 正确：一致的命名模式
interface UserService {
  getUser(id: string): User;
  getOrder(id: string): Order;
  getProduct(id: string): Product;
}
```

### 1.3 显式优于隐式

避免魔法行为，让 API 的效果清晰可见。

```typescript
// 违规：隐式行为
function saveUser(user: User): void {
  // 隐式地发送通知
  this.notificationService.send('User saved');
  // 隐式地更新缓存
  this.cache.update(user);
}

// 正确：显式控制
interface SaveOptions {
  sendNotification?: boolean;
  updateCache?: boolean;
}

function saveUser(user: User, options?: SaveOptions): void {
  // 根据选项显式执行
}
```

---

## 2) 命名规范

### 2.1 方法命名

| 操作类型 | 前缀 | 示例 |
|---------|------|------|
| 获取单个 | `get` | `getUser()`, `getConfig()` |
| 获取列表 | `list` / `getAll` | `listUsers()`, `getAllConfigs()` |
| 查找/搜索 | `find` / `search` | `findByEmail()`, `searchUsers()` |
| 创建 | `create` | `createUser()`, `createOrder()` |
| 更新 | `update` | `updateUser()`, `updateConfig()` |
| 删除 | `delete` / `remove` | `deleteUser()`, `removeItem()` |
| 检查存在 | `has` / `exists` | `hasUser()`, `exists()` |
| 检查状态 | `is` / `can` | `isActive()`, `canEdit()` |
| 转换 | `to` | `toJSON()`, `toString()` |
| 从...创建 | `from` | `fromJSON()`, `fromString()` |

### 2.2 参数命名

```typescript
// 布尔参数：使用肯定形式
function setVisible(visible: boolean): void;  // ✓
function setHidden(hidden: boolean): void;    // ✗ 双重否定难理解

// 回调参数：描述触发时机
function onUserCreated(callback: Function): void;  // ✓
function userCallback(callback: Function): void;   // ✗ 不清晰

// ID 参数：明确类型
function getUser(userId: string): User;  // ✓
function getUser(id: string): User;      // 可接受，但不如上面清晰
```

---

## 3) 参数设计

### 3.1 参数数量控制

```typescript
// 违规：参数过多
function createUser(
  name: string,
  email: string,
  age: number,
  role: string,
  department: string,
  manager: string,
  startDate: Date
): User;

// 正确：使用选项对象
interface CreateUserOptions {
  name: string;
  email: string;
  age?: number;
  role?: string;
  department?: string;
  manager?: string;
  startDate?: Date;
}

function createUser(options: CreateUserOptions): User;
```

### 3.2 可选参数

```typescript
// 使用默认值
function paginate<T>(
  items: T[],
  page: number = 1,
  pageSize: number = 20
): T[];

// 使用选项对象（参数 > 3 个时）
interface PaginationOptions {
  page?: number;
  pageSize?: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

function paginate<T>(items: T[], options?: PaginationOptions): T[];
```

### 3.3 避免布尔陷阱

```typescript
// 违规：调用时不清楚 true 的含义
user.save(true);  // true 是什么意思？

// 正确：使用命名参数或枚举
user.save({ validate: true });
// 或
user.save({ mode: SaveMode.Validated });
```

---

## 4) 返回值设计

### 4.1 空值处理

```typescript
// 方案 1：返回 null/undefined
function findUser(id: string): User | null;

// 方案 2：返回 Optional（需要工具库）
function findUser(id: string): Optional<User>;

// 方案 3：抛出异常（仅用于真正的错误情况）
function getUser(id: string): User;  // 不存在时抛出 NotFoundError
```

**选择指南**：

| 场景 | 推荐方案 |
|------|---------|
| 查询可能不存在的记录 | 返回 `null` |
| 必须存在的记录 | 抛出异常 |
| 链式调用场景 | 返回 `Optional` |

### 4.2 集合返回

```typescript
// 始终返回数组，不返回 null
function listUsers(): User[];  // 无结果时返回 []

// 带元数据的分页结果
interface PagedResult<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}

function listUsers(options: PaginationOptions): PagedResult<User>;
```

### 4.3 异步返回

```typescript
// 始终使用 Promise
async function getUser(id: string): Promise<User>;

// 可取消的异步操作
function fetchData(
  url: string,
  signal?: AbortSignal
): Promise<Response>;
```

---

## 5) 错误处理

### 5.1 错误类型

```typescript
// 定义明确的错误类型
class ApiError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number,
    public readonly details?: Record<string, unknown>
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

class NotFoundError extends ApiError {
  constructor(resource: string, id: string) {
    super(
      `${resource} with id ${id} not found`,
      'NOT_FOUND',
      404,
      { resource, id }
    );
  }
}

class ValidationError extends ApiError {
  constructor(field: string, message: string) {
    super(
      message,
      'VALIDATION_ERROR',
      400,
      { field }
    );
  }
}
```

### 5.2 错误文档

```typescript
/**
 * 获取用户信息
 *
 * @param id - 用户 ID
 * @returns 用户对象
 * @throws {NotFoundError} 用户不存在时
 * @throws {ValidationError} ID 格式无效时
 */
async function getUser(id: string): Promise<User>;
```

---

## 6) 版本演进

### 6.1 向后兼容

```typescript
// 添加可选参数（兼容）
// 旧版本
function search(query: string): Result[];
// 新版本
function search(query: string, options?: SearchOptions): Result[];

// 添加新方法（兼容）
interface UserService {
  getUser(id: string): User;
  // 新增
  getUserWithDetails(id: string): UserWithDetails;
}
```

### 6.2 废弃策略

```typescript
/**
 * @deprecated 使用 `getUserById` 代替，将在 v3.0 移除
 */
function getUser(id: string): User {
  console.warn('getUser is deprecated, use getUserById instead');
  return getUserById(id);
}

function getUserById(id: string): User {
  // 新实现
}
```

### 6.3 Breaking Changes

需要 Breaking Change 时：

1. 在 CHANGELOG 中明确标注
2. 提供迁移指南
3. 考虑提供 codemod

```typescript
// v2 → v3 迁移示例
// 旧 API
userService.save(user, true);  // true = validate

// 新 API
userService.save(user, { validate: true });
```

---

## 7) API 审查清单

设计新 API 时，确认以下内容：

- [ ] 命名是否清晰、一致？
- [ ] 参数数量是否 ≤ 3？（否则使用对象）
- [ ] 返回值是否明确？（避免 any）
- [ ] 错误情况是否处理？
- [ ] 是否有 JSDoc 文档？
- [ ] 是否向后兼容？
- [ ] 是否符合最小惊讶原则？
