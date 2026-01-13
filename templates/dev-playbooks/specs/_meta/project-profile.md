# 项目画像 (Project Profile)

> 本文档描述项目的技术画像，用于 AI 助手快速理解项目上下文。

---

## 技术栈

| 类别 | 技术 | 版本 |
|------|------|------|
| 语言 | <!-- TypeScript/Python/Go --> | <!-- 版本 --> |
| 框架 | <!-- React/Django/Gin --> | <!-- 版本 --> |
| 数据库 | <!-- PostgreSQL/MongoDB --> | <!-- 版本 --> |
| 测试框架 | <!-- Jest/pytest/go test --> | <!-- 版本 --> |
| 构建工具 | <!-- webpack/vite/make --> | <!-- 版本 --> |

---

## 常用命令

| 命令 | 用途 |
|------|------|
| `npm run dev` | 启动开发服务器 |
| `npm run build` | 构建生产版本 |
| `npm run test` | 运行测试 |
| `npm run lint` | 运行代码检查 |

---

## 项目约定

### 命名约定

- **文件名**：kebab-case（如 `user-service.ts`）
- **组件名**：PascalCase（如 `UserProfile`）
- **函数名**：camelCase（如 `getUserById`）
- **常量名**：UPPER_SNAKE_CASE（如 `MAX_RETRY_COUNT`）

### 目录结构约定

```
src/
├── components/     # UI 组件
├── services/       # 业务逻辑
├── models/         # 数据模型
├── utils/          # 工具函数
└── tests/          # 测试文件
```

---

## 质量闸门

| 闸门 | 阈值 | 命令 |
|------|------|------|
| 单元测试覆盖率 | >= 80% | `npm run test:coverage` |
| 类型检查 | 0 错误 | `npm run typecheck` |
| Lint 检查 | 0 错误 | `npm run lint` |
| 构建 | 成功 | `npm run build` |

---

## 外部服务

| 服务 | 用途 | 环境变量 |
|------|------|----------|
| <!-- 如 PostgreSQL --> | <!-- 数据存储 --> | `DATABASE_URL` |
| <!-- 如 Redis --> | <!-- 缓存 --> | `REDIS_URL` |

---

## 特殊约束

<!-- 项目特有的约束或规则 -->

---

**画像版本**：v1.0.0
**最后更新**：{{DATE}}
