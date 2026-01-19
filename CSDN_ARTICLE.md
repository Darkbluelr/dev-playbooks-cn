# [AI编程神器] 别让 Claude/Copilot 瞎写了！DevBooks：给 AI 戴上“紧箍咒”的开发工作流

大家现在写代码肯定离不开 AI 了吧？Claude Code、Cursor、GitHub Copilot 确实强。
但是！你有没有遇到过这种情况：
*   AI 信誓旦旦说“修复了”，结果运行报错，甚至连编译都过不去。
*   让它加个功能，它“贴心”地把别的功能改坏了。
*   只有代码没有测试，或者测试全是 Mock 骗自己。
*   写新 Demo 神勇无敌，一到几十万行的老项目就“智商掉线”。

今天给大家推荐一个开源神器：**DevBooks (`dev-playbooks-cn`)**。

> **[图片预留位 1：DevBooks 的 Logo 或者 GitHub/NPM 页面 Banner]**
> *图片描述：一张醒目的 Banner 图，包含 DevBooks 的名字和 "Agentic Workflow for Claude Code / Codex" 字样，背景可以是代码风格的深色背景。*

它不是另一个 AI 模型，而是一套**专门管 AI 的“交通规则”**。它能让你的 AI 编程助手（特别是 Claude Code 和 Codex CLI）从“由着性子胡来”变成“按规矩办事”。

开源地址：[https://www.npmjs.com/package/dev-playbooks-cn](https://www.npmjs.com/package/dev-playbooks-cn)

---

## 1. 专治“自欺欺人”：强制角色隔离

AI 最喜欢干的事就是：既当裁判又当运动员。在一个对话框里，它刚写完代码，马上又写个测试说“通过了”，实际上那个测试可能根本没跑，或者逻辑就是错的。

DevBooks 引入了**“双轨制开发”**，强制要求：**写测试的 AI** 和 **写代码的 AI** 必须分开！

> **[图片预留位 2：左右分屏的终端截图]**
> *图片描述：左边终端窗口显示正在运行 `devbooks-test-owner`，正在编写 `verification.md` 和测试用例；右边终端窗口显示正在运行 `devbooks-coder`，正在读取测试并编写实现代码。文字标注：左侧“测试官”，右侧“开发”。*

*   **Test Owner**：只管理解需求，写红灯测试（Red Test）。
*   **Coder**：只管实现功能，让测试变绿（Green）。**Coder 根本没权限改测试代码**，想通过修改测试来“偷懒”？没门！

## 2. 拒绝“口头支票”：基于证据的完成

你问 AI：“改完了吗？”
AI：“改完了！所有测试都通过了。”
DevBooks：“我不信，证据呢？”

> **[图片预留位 3：项目文件结构截图，高亮 `evidence/` 目录]**
> *图片描述：展示 `dev-playbooks/changes/xxx/evidence/` 目录结构，里面包含 `run.log`, `screenshot.png` 等文件。*

DevBooks 要求 AI 必须提交运行日志、构建报告、截图等实打实的“证据”文件。而且，系统里有自动化的**质量闸门（Quality Gates）**，检测不到合格的证据，任务就无法 Close。

## 3. 拯救“屎山”：存量项目也能用

很多 AI 工具只能从头生成项目（Greenfield），面对复杂的存量项目（Brownfield）往往无从下手，因为上下文太多了。

DevBooks 专门有一个 `brownfield-bootstrap` 技能。

> **[图片预留位 4：`devbooks-brownfield-bootstrap` 运行结果示意图]**
> *图片描述：展示命令行运行该 Skill 后，生成的 `project-profile.md`（项目画像）或者依赖关系图。体现 AI 自动分析了老项目的结构。*

它可以帮你分析现有的老项目，生成项目画像、依赖图和基线规格。这就好比给 AI 戴上了“夜视仪”，让它能快速看懂你那陈年老代码。

## 4. 拒绝“写诗”也拒绝“谜语”：恰到好处的计划颗粒度

很多 AI 生成的计划，要么太简略（“实现功能 X”一句话带过），AI 执行时容易迷失方向；要么太啰嗦（连变量名都规定死了），不仅浪费 Token，还限制了 AI 的编码能力。

DevBooks 生成的 `tasks.md` 能够保持**刚刚好的颗粒度**。它关注**接口契约**、**数据流向**和**关键边界**，既给出了明确的导航，又保留了实现的灵活性。

> **[图片预留位 5：`tasks.md` 任务列表内容截图]**
> *图片描述：展示一个 Markdown 格式的任务列表，内容清晰地拆解了步骤（如“定义接口”、“实现服务层”、“添加单元测试”），但没有罗列具体的代码行，体现出结构化和概括性。*

## 5. 18般武艺：Skills 全家桶

它不仅仅是写代码，而是内置了 18 个 Skills，覆盖软件开发全流程：

*   **想清楚再做** (`proposal-author`)：AI 先帮你写提案、设计文档，对齐需求。
*   **不仅看语法** (`reviewer`)：AI Reviewer 帮你检查代码可读性和一致性。
*   **防腐化** (`entropy-monitor`)：监控代码是不是越来越乱（熵值），提醒你该重构了。

> **[图片预留位 6：DevBooks 完整工作流图]**
> *图片描述：可以使用项目中 `docs/workflow-diagram.svg` 的图片。展示 Proposal -> Design -> Specs -> Plan -> Test/Code -> Review -> Archive 的全流程。*

---

## 🚀 快速上手，好玩又硬核

### 安装

前提是你得有 Node.js。

```bash
npm install -g dev-playbooks-cn
```

### 初始化

在你的项目根目录下：

```bash
dev-playbooks-cn init
```
它会自动配置好环境，支持 Claude Code、Cursor、Windsurf 等多种主流 AI 工具。

### 开始你的指挥官生涯

使用 **Router** 模式，直接用自然语言下令：

> "请运行 devbooks-router skill，分析需求：给现有的登录模块增加 OAuth2 支持，并确保兼容旧的 Session 验证。"

> **[图片预留位 7：Router Skill 生成的任务列表截图]**
> *图片描述：展示 CLI 界面中 AI 回复的执行计划，列出了 `tasks.md` 中的 Todo List，清晰明了。*

AI 会帮你拆解任务、写文档、生成测试、编写代码，你只需要像一个架构师一样进行 Review 和决策。

---

## 🔗 赶紧试试

别再让 AI 像抽卡一样写代码了，用 DevBooks 给它立个规矩，把 AI 变成真正的“数字员工”！

**开源地址**：[https://www.npmjs.com/package/dev-playbooks-cn](https://www.npmjs.com/package/dev-playbooks-cn)
**GitHub**：也可以去 GitHub 上搜 `dev-playbooks-cn` 点个 Star 哦！
