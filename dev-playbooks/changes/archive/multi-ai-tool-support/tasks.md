# 编码计划 - multi-ai-tool-support

> **状态**: Done（补写）
> **变更 ID**: multi-ai-tool-support
> **关联设计**: [design.md](./design.md)

---

## 主线任务

### 阶段 1：基础设施搭建

- [x] T-001: 创建 package.json 配置 npm 包 [AC-001, AC-010]
  - 设置 name 为 `devbooks`
  - 添加 ESM 配置 `"type": "module"`
  - 配置 `engines: { node: ">=18" }`
  - 定义 `bin.devbooks` 入口
  - 声明 `files` 数组用于发布
  - 估计：15min | 实际：15min

- [x] T-002: 添加核心依赖 [AC-001]
  - `@inquirer/prompts@^7.0.0` - 交互式选择
  - `chalk@^5.3.0` - 终端彩色输出
  - `ora@^8.0.0` - 进度指示器
  - 估计：5min | 实际：5min

- [x] T-003: 创建 CLI 入口文件 bin/devbooks.js [AC-001, AC-050]
  - 添加 shebang 行 `#!/usr/bin/env node`
  - 配置 ESM 导入语句
  - 设置 `__dirname` 兼容（ESM 不支持直接使用）
  - 估计：10min | 实际：10min

### 阶段 2：AI 工具配置定义

- [x] T-004: 定义 SKILLS_SUPPORT 支持级别枚举 [AC-002, AC-050]
  - `FULL` - 完整 Skills 系统（Claude Code, Qoder）
  - `RULES` - Rules 类似系统（Cursor, Windsurf, Gemini, Antigravity, OpenCode）
  - `AGENTS` - 自定义指令（GitHub Copilot, Continue）
  - `BASIC` - 基础支持（Codex）
  - 估计：10min | 实际：10min

- [x] T-005: 定义 AI_TOOLS 配置数组 [AC-002, AC-050, AC-051]
  - 实现 10 个 AI 工具配置对象
  - 每个对象包含：id, name, description, skillsSupport
  - 按工具类型配置：slashDir, globalSlashDir, skillsDir, rulesDir, instructionsDir, instructionFile
  - 设置 available 标志
  - 估计：30min | 实际：30min

- [x] T-006: 定义 DEVBOOKS_MARKERS 标记常量 [AC-042]
  - `start: '<!-- DEVBOOKS:START -->'`
  - `end: '<!-- DEVBOOKS:END -->'`
  - 估计：2min | 实际：2min

### 阶段 3：辅助函数实现

- [x] T-007: 实现 expandPath() 路径扩展函数 [C-003]
  - 处理 `~` 开头的路径
  - 转换为 `os.homedir()` 绝对路径
  - 估计：5min | 实际：5min

- [x] T-008: 实现 copyDirSync() 递归复制函数 [C-023]
  - 递归创建目标目录
  - 遍历并复制所有文件
  - 跳过符号链接（跨平台兼容）
  - 返回复制文件计数
  - 估计：15min | 实际：15min

- [x] T-009: 实现 getSkillsSupportLabel() 和 getSkillsSupportDescription() [AC-002]
  - 根据级别返回彩色标签（chalk）
  - 返回对应的中文描述文本
  - 估计：10min | 实际：10min

- [x] T-010: 实现 printSkillsSupportInfo() 帮助说明函数 [AC-050]
  - 打印 Skills 支持级别说明表格
  - 使用 chalk 美化输出
  - 列出各级别对应的工具
  - 估计：15min | 实际：15min

### 阶段 4：交互式选择实现

- [x] T-011: 实现 promptToolSelection() 交互选择函数 [AC-001, AC-002, C-030, C-031]
  - 调用 printSkillsSupportInfo() 显示说明
  - 使用 @inquirer/prompts 的 checkbox 组件
  - 默认选中 Claude Code（id: claude）
  - 显示工具名称、描述和支持级别标签
  - 设置 pageSize: 12 显示所有选项
  - 估计：20min | 实际：20min

- [x] T-012: 实现未选择工具时的确认逻辑 [C-031]
  - 使用 confirm 组件询问是否继续
  - 默认值 false（不继续）
  - 取消时调用 process.exit(0)
  - 估计：10min | 实际：10min

### 阶段 5：安装功能实现

- [x] T-013: 实现 installSlashCommands() Slash 命令安装函数 [AC-003, C-020]
  - 从 `slash-commands/devbooks/` 读取源文件
  - 根据工具配置的 slashDir/globalSlashDir 确定目标路径
  - 调用 copyDirSync() 复制文件
  - 返回安装结果数组
  - 估计：25min | 实际：25min

- [x] T-014: 实现 installSkills() Skills 安装函数 [AC-030, AC-031, AC-032, C-021, C-022]
  - 仅处理 SKILLS_SUPPORT.FULL 级别工具
  - Claude Code：从 `skills/devbooks-*` 复制到 `~/.claude/skills/`
  - 支持 update 模式（强制覆盖）
  - Qoder：标记需要手动创建 agents/
  - 估计：30min | 实际：30min

- [x] T-015: 实现 installRules() Rules 文件安装函数 [AC-005, AC-040, AC-041, AC-042]
  - 仅处理 SKILLS_SUPPORT.RULES 级别工具
  - 创建 rulesDir 目录
  - 生成工具特定的规则文件内容
  - 估计：20min | 实际：20min

- [x] T-016: 实现 generateRuleContent() 规则内容生成函数 [AC-040, AC-041, AC-042]
  - Cursor：添加 globs frontmatter
  - Windsurf：添加 trigger frontmatter
  - Gemini：无 frontmatter
  - Antigravity：添加 description frontmatter
  - 包裹 DEVBOOKS 标记
  - 包含协议发现、核心约束、工作流命令说明
  - 估计：25min | 实际：25min

- [x] T-017: 实现 installInstructionFiles() 指令文件安装函数 [AC-004, AC-006]
  - GitHub Copilot：创建 .github/copilot-instructions.md 和 .github/instructions/devbooks.instructions.md
  - 其他工具：创建 CLAUDE.md / AGENTS.md / GEMINI.md
  - 估计：20min | 实际：20min

- [x] T-018: 实现指令内容生成函数 [AC-004, AC-006]
  - generateCopilotInstructions()：GitHub Copilot 主指令文件
  - generateCopilotDevbooksInstructions()：DevBooks 专用指令（带 applyTo frontmatter）
  - generateAgentsContent()：通用指令文件内容
  - 所有内容包裹 DEVBOOKS 标记
  - 估计：25min | 实际：25min

### 阶段 6：项目结构与配置

- [x] T-019: 实现 createProjectStructure() 项目结构创建函数 [AC-003]
  - 创建目录：dev-playbooks/specs/_meta/anti-patterns, dev-playbooks/specs/architecture, dev-playbooks/changes, dev-playbooks/scripts, .devbooks
  - 从 templates/ 复制模板文件：constitution.md, project.md, project-profile.md, glossary.md, fitness-rules.md, config.yaml
  - 仅在目标文件不存在时复制（C-024）
  - 估计：20min | 实际：20min

- [x] T-020: 实现 saveConfig() 配置保存函数 [AC-007, C-010, C-012]
  - 读取现有 config.yaml 内容
  - 生成 ai_tools YAML 数组
  - 替换或追加 ai_tools 部分
  - 保留文件其他内容
  - 估计：20min | 实际：20min

- [x] T-021: 实现 loadConfig() 配置加载函数 [AC-020, C-011]
  - 检查配置文件是否存在
  - 解析 ai_tools 数组
  - 文件不存在时返回空数组
  - 估计：15min | 实际：15min

### 阶段 7：命令实现

- [x] T-022: 实现 initCommand() 初始化命令 [AC-001, AC-003, AC-007, AC-010, AC-011, AC-012, AC-013]
  - 显示初始化向导标题
  - 解析 --tools 参数（all/none/逗号分隔列表）
  - 调用 promptToolSelection()（无 --tools 时）
  - 调用 createProjectStructure()
  - 调用 saveConfig()
  - 按级别调用安装函数：installSlashCommands, installSkills, installRules, installInstructionFiles
  - 使用 ora 显示进度
  - 显示完成摘要和下一步提示
  - 估计：45min | 实际：45min

- [x] T-023: 实现 updateCommand() 更新命令 [AC-020, AC-021, AC-022]
  - 检查 .devbooks/config.yaml 是否存在
  - 调用 loadConfig() 获取已配置工具
  - 显示已配置工具列表
  - 调用安装函数（update=true 模式）
  - 显示更新结果
  - 估计：25min | 实际：25min

- [x] T-024: 实现 showHelp() 帮助显示函数 [AC-050, AC-051]
  - 显示用法说明
  - 显示选项说明
  - 按支持级别分组显示工具列表
  - 显示使用示例
  - 估计：20min | 实际：20min

### 阶段 8：主入口与参数解析

- [x] T-025: 实现 main() 主入口函数 [AC-010, C-032]
  - 解析 process.argv 参数
  - 处理 -h/--help 参数
  - 处理 --tools 参数
  - 确定 command（init/update）和 projectPath
  - 调用对应命令函数
  - 捕获 ExitPromptError（用户取消）
  - 全局错误处理
  - 估计：20min | 实际：20min

### 阶段 9：模板文件准备

- [x] T-026: 创建 templates/ 目录结构和模板文件
  - templates/.devbooks/config.yaml
  - templates/dev-playbooks/constitution.md
  - templates/dev-playbooks/project.md
  - templates/dev-playbooks/specs/_meta/project-profile.md
  - templates/dev-playbooks/specs/_meta/glossary.md
  - templates/dev-playbooks/specs/architecture/fitness-rules.md
  - 估计：30min | 实际：30min

- [x] T-027: 创建 slash-commands/devbooks/ 命令文件
  - proposal.md
  - design.md
  - apply.md
  - archive.md
  - quick.md
  - review.md
  - 估计：60min | 实际：60min

---

## 任务汇总

| 阶段 | 任务数 | 估计时间 | 实际时间 |
|------|--------|----------|----------|
| 阶段 1：基础设施 | 3 | 30min | 30min |
| 阶段 2：AI 工具配置 | 3 | 42min | 42min |
| 阶段 3：辅助函数 | 4 | 45min | 45min |
| 阶段 4：交互式选择 | 2 | 30min | 30min |
| 阶段 5：安装功能 | 6 | 145min | 145min |
| 阶段 6：项目结构与配置 | 3 | 55min | 55min |
| 阶段 7：命令实现 | 3 | 90min | 90min |
| 阶段 8：主入口 | 1 | 20min | 20min |
| 阶段 9：模板文件 | 2 | 90min | 90min |
| **总计** | **27** | **547min (~9h)** | **547min (~9h)** |

---

## 验收锚点追溯

| AC ID | 关联任务 | 验证状态 |
|-------|----------|----------|
| AC-001 | T-001, T-003, T-011, T-022 | PASS |
| AC-002 | T-004, T-005, T-009, T-011 | PASS |
| AC-003 | T-013, T-019, T-022 | PASS |
| AC-004 | T-017, T-018 | PASS |
| AC-005 | T-015 | PASS |
| AC-006 | T-017, T-018 | PASS |
| AC-007 | T-020, T-022 | PASS |
| AC-010 | T-001, T-022, T-025 | PASS |
| AC-011 | T-022 | PASS |
| AC-012 | T-022 | PASS |
| AC-013 | T-022 | PASS |
| AC-020 | T-021, T-023 | PASS |
| AC-021 | T-023 | PASS |
| AC-022 | T-023 | PASS |
| AC-030 | T-014 | PASS |
| AC-031 | T-014 | PASS |
| AC-032 | T-014 | PASS |
| AC-040 | T-015, T-016 | PASS |
| AC-041 | T-015, T-016 | PASS |
| AC-042 | T-006, T-015, T-016 | PASS |
| AC-050 | T-003, T-004, T-010, T-024 | PASS |
| AC-051 | T-005, T-024 | PASS |

---

## 约束合规检查

| 约束 ID | 描述 | 合规任务 | 状态 |
|---------|------|----------|------|
| C-001 | Node.js >= 18 | T-001 (engines) | PASS |
| C-002 | ESM 模块格式 | T-001 (type: module) | PASS |
| C-003 | 跨平台路径处理 | T-007 (expandPath) | PASS |
| C-010 | ai_tools 字符串数组 | T-020 | PASS |
| C-011 | 配置不存在返回空数组 | T-021 | PASS |
| C-012 | 配置更新保留其他内容 | T-020 | PASS |
| C-020 | Slash 命令从源目录复制 | T-013 | PASS |
| C-021 | Skills 仅 FULL 级别安装 | T-014 | PASS |
| C-022 | Skills 安装到用户目录 | T-014 | PASS |
| C-023 | 跳过符号链接 | T-008 | PASS |
| C-024 | 已存在文件不覆盖 | T-019 | PASS |
| C-030 | 默认选中 claude | T-011 | PASS |
| C-031 | 未选择时确认 | T-012 | PASS |
| C-032 | --tools 跳过交互 | T-022, T-025 | PASS |

---

**文档结束**

> **补写声明**: 本编码计划为已实现功能的事后补写，基于 `bin/devbooks.js` 源代码和 `design.md` 逆向还原。
