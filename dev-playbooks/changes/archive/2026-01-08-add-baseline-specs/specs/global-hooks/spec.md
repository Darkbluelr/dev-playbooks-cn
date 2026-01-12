# global-hooks

## 修改需求

### 需求：提供全局 Hook 安装脚本

系统必须提供全局 Hook 安装脚本，用于配置 Claude Code 的上下文注入。

#### 场景：安装 Hook 到 Claude Code
- **当** 执行 `./setup/global-hooks/install.sh`
- **那么** `setup/global-hooks/augment-context-global.sh` 被复制到 `~/.claude/hooks/` 并设置可执行权限
- **并且** `~/.claude/settings.json` 包含 `augment-context-global.sh` 的 hook 配置
- **证据**：`setup/global-hooks/install.sh`

### 需求：Hook 自动识别代码项目并跳过非代码项目

系统必须在非代码项目目录中跳过上下文注入，避免产生无效输出。

#### 场景：在非代码目录执行 Hook
- **当** Hook 运行且目录中缺少常见项目标识文件
- **那么** Hook 输出空的 `additionalContext`
- **证据**：`setup/global-hooks/augment-context-global.sh`

### 需求：Hook 支持 @file 与 @folder 引用

系统必须支持在用户提问中通过 @file 与 @folder 引用读取文件或目录内容。

#### 场景：用户在提问中使用 @file 引用
- **当** 提问包含 `@file:path` 或 `@folder:path`
- **那么** Hook 会读取对应文件或目录并注入上下文片段
- **证据**：`setup/global-hooks/augment-context-global.sh`
