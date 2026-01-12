# AP-002: God Class（上帝类）

> 反模式 ID: AP-002-god-class
> 严重程度: High
> 相关规则: 单一职责原则

---

## 问题描述

一个类承担了过多的职责，知道太多、做太多事情。

## 识别标准

| 指标 | 阈值 | 说明 |
|------|------|------|
| 方法数量 | > 20 | 方法过多 |
| 代码行数 | > 500 | 文件过大 |
| 依赖数量 | > 10 | 依赖过多 |
| 圈复杂度 | > 50 | 复杂度过高 |

## 症状

- 文件超过 500 行
- 类名包含 "Manager"、"Handler"、"Processor" 等模糊词
- 修改任何功能都要改这个类
- 难以为这个类写单元测试

## 错误示例

```typescript
// ❌ 错误：一个类做太多事情
class UserManager {
  // 用户 CRUD
  createUser() { ... }
  updateUser() { ... }
  deleteUser() { ... }
  findUser() { ... }

  // 认证
  login() { ... }
  logout() { ... }
  resetPassword() { ... }
  verifyEmail() { ... }

  // 权限
  checkPermission() { ... }
  assignRole() { ... }
  revokeRole() { ... }

  // 通知
  sendWelcomeEmail() { ... }
  sendPasswordResetEmail() { ... }
  sendNotification() { ... }

  // 报表
  getUserStats() { ... }
  generateReport() { ... }

  // 还有更多...
}
```

## 为什么是反模式

1. **违反单一职责**：一个类应只有一个改变的理由
2. **难以理解**：需要理解整个类才能修改一小部分
3. **难以测试**：测试需要大量 mock
4. **难以复用**：只需要部分功能时无法单独使用
5. **并发开发冲突**：多人修改同一文件

## 正确做法

```typescript
// ✅ 正确：职责分离

// 用户 CRUD
class UserRepository {
  create(data: CreateUserDto) { ... }
  update(id: string, data: UpdateUserDto) { ... }
  delete(id: string) { ... }
  findById(id: string) { ... }
}

// 认证
class AuthService {
  login(credentials: LoginDto) { ... }
  logout(userId: string) { ... }
  resetPassword(email: string) { ... }
}

// 权限
class PermissionService {
  check(userId: string, permission: string) { ... }
  assignRole(userId: string, role: string) { ... }
}

// 通知
class NotificationService {
  sendEmail(to: string, template: string, data: any) { ... }
}

// 报表
class UserReportService {
  getStats(filter: StatsFilter) { ... }
  generate(options: ReportOptions) { ... }
}
```

## 检测方法

```bash
# 检测大文件
find src/ -name "*.ts" -exec wc -l {} \; | awk '$1 > 500'

# 检测方法数量过多的类
grep -c "^\s*\(async \)\?\(public \|private \|protected \)\?\w\+(" src/**/*.ts

# 使用复杂度工具
npx ts-complexity src/
```

## 重构步骤

1. 识别类中的不同职责
2. 为每个职责创建独立的类
3. 使用依赖注入组合这些类
4. 逐步迁移方法到新类
5. 更新所有调用点
6. 删除原来的 God Class

## 相关资源

- [单一职责原则](https://en.wikipedia.org/wiki/Single-responsibility_principle)
- [重构：改善既有代码的设计](https://refactoring.com/)
- [Extract Class 重构手法](https://refactoring.guru/extract-class)
