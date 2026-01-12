# AP-003: 循环依赖

> 反模式 ID: AP-003-circular-dependency
> 严重程度: Critical
> 相关规则: FR-002

---

## 问题描述

两个或多个模块相互依赖，形成循环引用。

## 症状

- `import` 语句形成闭环
- 运行时出现 `undefined` 错误
- 模块加载顺序问题
- 难以理解依赖关系

## 错误示例

```typescript
// ❌ 错误：循环依赖

// a.ts
import { B } from './b';
export class A {
  constructor(private b: B) {}
  doSomething() { this.b.help(); }
}

// b.ts
import { A } from './a';  // 循环引用！
export class B {
  constructor(private a: A) {}
  help() { this.a.doSomething(); }  // 可能导致无限递归
}
```

## 为什么是反模式

1. **运行时错误**：模块加载顺序导致 undefined
2. **难以理解**：无法建立清晰的依赖层次
3. **难以测试**：无法单独测试任一模块
4. **难以重构**：修改一个影响另一个

## 解决方案

### 方案一：依赖倒置（推荐）

```typescript
// ✅ 正确：引入接口层

// interfaces.ts（无依赖）
export interface IHelper {
  help(): void;
}

// a.ts
import { IHelper } from './interfaces';
export class A {
  constructor(private helper: IHelper) {}
  doSomething() { this.helper.help(); }
}

// b.ts（不再依赖 A）
import { IHelper } from './interfaces';
export class B implements IHelper {
  help() { console.log('helping'); }
}
```

### 方案二：事件驱动

```typescript
// ✅ 正确：使用事件解耦

// event-bus.ts
export const eventBus = new EventEmitter();

// a.ts
import { eventBus } from './event-bus';
export class A {
  doSomething() {
    eventBus.emit('need-help', { from: this });
  }
}

// b.ts
import { eventBus } from './event-bus';
export class B {
  constructor() {
    eventBus.on('need-help', (data) => this.help(data));
  }
  help(data: any) { ... }
}
```

### 方案三：模块合并

```typescript
// ✅ 如果两个类强耦合，考虑合并

// ab.ts
export class AB {
  doSomething() { ... }
  help() { ... }
}
```

## 检测方法

```bash
# Node.js 项目
npx madge --circular src/

# 手动检测
grep -r "from '\.\/" src/ | awk -F: '{print $1, $2}' | sort | uniq

# Go 项目
go mod why -m

# Python 项目
pydeps --show-cycles src/
```

## 预防措施

1. **分层架构**：严格的依赖方向（上层 → 下层）
2. **依赖注入**：通过接口解耦
3. **CI 检查**：在 CI 中运行循环检测
4. **代码审查**：关注新增的 import 语句

## 相关资源

- [依赖倒置原则](https://en.wikipedia.org/wiki/Dependency_inversion_principle)
- [madge - 循环依赖检测工具](https://github.com/pahen/madge)
- [Breaking Circular Dependencies](https://www.baeldung.com/circular-dependencies-in-spring)
