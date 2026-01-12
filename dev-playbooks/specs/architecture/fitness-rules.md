# 架构适应度规则 (Architecture Fitness Rules)

> 本文档定义项目的架构适应度函数规则。
> 这些规则由 `fitness-check.sh` 自动检查。

---

## 概述

架构适应度函数是一种自动化的架构守护机制，确保代码变更不会违反既定的架构约束。

### 规则严重程度

| 级别 | 说明 | 处置 |
|------|------|------|
| **Critical** | 严重违规，必须阻断 | error 模式阻断 |
| **High** | 重要违规，建议阻断 | error 模式阻断 |
| **Medium** | 中等违规，需要警告 | warn 模式警告 |
| **Low** | 轻微违规，建议修复 | warn 模式警告 |

---

## FR-001: 分层架构检查

**规则 ID**: FR-001-layered-arch
**严重程度**: High
**检查方式**: 自动

### 规则描述

Controller 层不应直接访问 Repository 层，必须通过 Service 层中转。

### 正确分层

```
Controller → Service → Repository → Database
    ↓           ↓           ↓
  (HTTP)    (业务)     (数据)
```

### 违规模式

```typescript
// 错误：Controller 直接调用 Repository
class UserController {
  constructor(private userRepository: UserRepository) {}  // ❌

  async getUser(id: string) {
    return this.userRepository.findById(id);  // ❌
  }
}
```

### 正确模式

```typescript
// 正确：Controller 调用 Service
class UserController {
  constructor(private userService: UserService) {}  // ✅

  async getUser(id: string) {
    return this.userService.findById(id);  // ✅
  }
}
```

### 检测命令

```bash
grep -rn "Repository\." src/controllers/
```

---

## FR-002: 禁止循环依赖

**规则 ID**: FR-002-no-cycle
**严重程度**: Critical
**检查方式**: 自动（基础版）

### 规则描述

模块之间不应存在循环依赖关系。

### 违规模式

```
a.ts --import--> b.ts --import--> a.ts  // ❌ 循环依赖
```

### 解决方案

1. **依赖倒置**：引入接口层，打破循环
2. **事件驱动**：使用事件解耦
3. **模块合并**：如果两个模块强耦合，考虑合并

### 检测工具

- `madge --circular src/`（Node.js）
- `deptry src/`（Python）
- `go mod why -m`（Go）

---

## FR-003: 敏感文件守护

**规则 ID**: FR-003-sensitive-file
**严重程度**: Critical
**检查方式**: 自动

### 规则描述

敏感文件不应被 Git 跟踪或意外提交。

### 敏感文件模式

| 模式 | 说明 |
|------|------|
| `.env*` | 环境变量文件 |
| `credentials.json` | 凭证文件 |
| `secrets.yaml` | 密钥配置 |
| `*.pem` | 证书文件 |
| `*.key` | 私钥文件 |
| `id_rsa*` | SSH 密钥 |
| `id_ed25519*` | SSH 密钥 |

### 防护措施

1. 确保 `.gitignore` 包含敏感模式
2. 使用 `git-secrets` 或 `pre-commit` 钩子
3. 定期扫描仓库历史

### .gitignore 推荐内容

```gitignore
# 环境变量
.env
.env.*
!.env.example

# 密钥和凭证
*.pem
*.key
*.p12
*.pfx
credentials.json
secrets.yaml

# SSH
id_rsa*
id_ed25519*
```

---

## 自定义规则

### 添加新规则

1. 在本文件中定义规则（FR-xxx 格式）
2. 在 `fitness-check.sh` 中实现检查函数
3. 在检查流程中调用新函数

### 规则模板

```markdown
## FR-xxx: 规则名称

**规则 ID**: FR-xxx-rule-name
**严重程度**: Critical | High | Medium | Low
**检查方式**: 自动 | 手动

### 规则描述
[规则的详细说明]

### 违规模式
[展示违规代码示例]

### 正确模式
[展示正确代码示例]

### 检测命令
[用于检测违规的命令]
```

---

## 检查结果示例

```
==========================================
架构适应度检查 (fitness-check.sh)
模式: error
项目: /path/to/project
==========================================

[INFO] FR-001: 检查分层架构...
[PASS] FR-001: 分层架构检查通过

[INFO] FR-002: 检查循环依赖...
[WARN] FR-002: 可能的循环依赖: a.ts <-> b.ts

[INFO] FR-003: 检查敏感文件...
[PASS] FR-003: 敏感文件检查通过

==========================================
检查完成
  错误: 0
  警告: 1
==========================================
```

---

**规则版本**: v1.0.0
**最后更新**: 2026-01-11
