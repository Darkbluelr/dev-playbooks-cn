# 变更：DevBooks 存量初始化基线

## 为什么

- `openspec/specs/` 当前为空，缺少可追溯的规格基线
- 需要建立项目画像、术语表与最小验证锚点，避免在无真理源的情况下演进

## 变更内容

- 创建项目画像与元信息：`openspec/specs/_meta/`
- 生成架构基线文件：`openspec/specs/architecture/`
- 产出 7 个能力的基线规格增量（仅新增需求）
- 提供最小验证锚点与追溯矩阵

## 基线范围

### In

- Skills 安装与分发
- 全局上下文 Hook 注入
- OpenSpec 协议集成
- 协议发现与配置解析
- MCP 服务器与配置管理
- Embedding 语义检索
- 自动化守门与 CI 模板

### Out

- 业务逻辑代码变更
- 新功能开发或行为调整
- 测试覆盖扩展与重构
- CI 工作流实际接入

### 非目标

- 不改变现有脚本与文档行为
- 不引入新依赖或运行时
- 不补齐所有规格能力，仅建立基线

## 影响

- 新增规格与元信息文件，作为当前真理源
- 增加一个基线变更包用于后续归档合并
- 不修改现有代码与脚本行为

## 风险与已知未知

1. 现有测试与质量闸门入口未确认
   - 验证：见 `openspec/changes/add-baseline-specs/verification.md`
2. MCP 与索引器的实际运行环境未确认
   - 验证：见 `openspec/changes/add-baseline-specs/verification.md`
3. Embedding API Key 与配置的实际使用情况未确认
   - 验证：见 `openspec/changes/add-baseline-specs/verification.md`
4. 分层约束是否需要落盘未确认
   - 验证：见 `openspec/changes/add-baseline-specs/verification.md`
