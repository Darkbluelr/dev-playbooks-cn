# 降级验证 / Fallback Test

> 状态：待填充
> 变更包：achieve-augment-parity (Phase 1)

---

## 降级场景

| 场景 | 触发条件 | 预期行为 | 测试状态 |
|------|----------|----------|----------|
| 无 Embedding 索引 | `.devbooks/embeddings/` 不存在 | 降级到关键词搜索 | ⏳ |
| 无 API Key | `OPENAI_API_KEY` 未设置 | 跳过 Embedding 构建，使用关键词 | ⏳ |
| CKB 索引不可用 | SCIP 索引缺失 | 降级到 Grep 搜索 | ⏳ |
| CKB MCP 超时 | 网络/服务问题 | 返回缓存或关键词结果 | ⏳ |
| 空项目 | 无代码文件 | 返回空上下文 + 提示 | ⏳ |

## 降级验证步骤

### 场景 1：无 Embedding 索引

```bash
# 1. 移除索引
rm -rf .devbooks/embeddings/

# 2. 触发查询
echo '{"prompt":"分析 UserService"}' | ./augment-context-global.sh

# 3. 验证输出
# 预期：包含 "💡 提示：可启用语义搜索" + 关键词搜索结果
```

**结果**: ⏳ 待测试

### 场景 2：无 API Key

```bash
# 1. 清除环境变量
unset OPENAI_API_KEY

# 2. 尝试构建索引
./devbooks-embedding.sh build

# 3. 验证行为
# 预期：提示 API Key 缺失，跳过构建
```

**结果**: ⏳ 待测试

### 场景 3：CKB 索引不可用

```bash
# 1. 移除 SCIP 索引
rm -f index.scip

# 2. 触发调用链查询
# 预期：降级到 Grep，输出警告
```

**结果**: ⏳ 待测试

## 汇总

| 降级场景 | 测试结果 | 用户体验评分 |
|----------|----------|--------------|
| 无 Embedding | ⏳ | - |
| 无 API Key | ⏳ | - |
| CKB 不可用 | ⏳ | - |
| MCP 超时 | ⏳ | - |
| 空项目 | ⏳ | - |

**总体降级覆盖率**: ⏳ 待计算

---

*证据由 Test Owner 在 Apply 阶段填充*
