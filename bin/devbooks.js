#!/usr/bin/env node

/**
 * DevBooks CLI
 *
 * AI-agnostic spec-driven development workflow
 *
 * 用法：
 *   dev-playbooks-cn init [path] [options]
 *   dev-playbooks-cn update [path]
 *   dev-playbooks-cn migrate --from <framework> [options]
 *
 * 选项：
 *   --tools <tools>    非交互式指定 AI 工具：all, none, 或逗号分隔的列表
 *   --from <framework> 迁移来源框架：openspec, speckit
 *   --dry-run          模拟运行，不实际修改文件
 *   --keep-old         迁移后保留原目录
 *   --help             显示帮助信息
 */

import fs from 'fs';
import path from 'path';
import os from 'os';
import { fileURLToPath } from 'url';
import { spawn } from 'child_process';
import { checkbox, confirm } from '@inquirer/prompts';
import chalk from 'chalk';
import ora from 'ora';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const CLI_COMMAND = 'dev-playbooks-cn';

// ============================================================================
// Skills 支持级别定义
// ============================================================================

const SKILLS_SUPPORT = {
  FULL: 'full',      // 完整 Skills 系统（可独立调用、有独立上下文）
  RULES: 'rules',    // Rules 类似系统（自动应用的规则）
  AGENTS: 'agents',  // Agents/自定义指令（项目级指令文件）
  BASIC: 'basic'     // 仅基础指令（无独立 Skills 概念）
};

// ============================================================================
// AI 工具配置
// ============================================================================

const AI_TOOLS = [
  // === 完整 Skills 支持 ===
  {
    id: 'claude',
    name: 'Claude Code',
    description: 'Anthropic Claude Code CLI',
    skillsSupport: SKILLS_SUPPORT.FULL,
    slashDir: '.claude/commands/devbooks',
    skillsDir: path.join(os.homedir(), '.claude', 'skills'),
    instructionFile: 'CLAUDE.md',
    available: true
  },
  {
    id: 'qoder',
    name: 'Qoder CLI',
    description: 'Qoder AI Coding Assistant',
    skillsSupport: SKILLS_SUPPORT.FULL,
    slashDir: '.qoder/commands/devbooks',
    agentsDir: 'agents',
    globalDir: path.join(os.homedir(), '.qoder'),
    instructionFile: 'AGENTS.md',
    available: true
  },

  // === Rules 类似系统 ===
  {
    id: 'cursor',
    name: 'Cursor',
    description: 'Cursor AI IDE',
    skillsSupport: SKILLS_SUPPORT.RULES,
    slashDir: '.cursor/commands/devbooks',
    rulesDir: '.cursor/rules',
    instructionFile: null,
    available: true
  },
  {
    id: 'windsurf',
    name: 'Windsurf',
    description: 'Codeium Windsurf IDE',
    skillsSupport: SKILLS_SUPPORT.RULES,
    slashDir: '.windsurf/commands/devbooks',
    rulesDir: '.windsurf/rules',
    instructionFile: null,
    available: true
  },
  {
    id: 'gemini',
    name: 'Gemini CLI',
    description: 'Google Gemini CLI',
    skillsSupport: SKILLS_SUPPORT.RULES,
    slashDir: '.gemini/commands/devbooks',
    rulesDir: '.gemini',
    globalDir: path.join(os.homedir(), '.gemini'),
    instructionFile: 'GEMINI.md',
    available: true
  },
  {
    id: 'antigravity',
    name: 'Antigravity',
    description: 'Google Antigravity (VS Code)',
    skillsSupport: SKILLS_SUPPORT.RULES,
    slashDir: '.agent/workflows/devbooks',
    rulesDir: '.agent/rules',
    globalDir: path.join(os.homedir(), '.gemini', 'antigravity'),
    instructionFile: 'GEMINI.md',
    available: true
  },
  {
    id: 'opencode',
    name: 'OpenCode',
    description: 'OpenCode AI CLI',
    skillsSupport: SKILLS_SUPPORT.RULES,
    slashDir: '.opencode/commands/devbooks',
    agentsDir: '.opencode/agent',
    globalDir: path.join(os.homedir(), '.config', 'opencode'),
    instructionFile: 'AGENTS.md',
    available: true
  },

  // === Agents/自定义指令 ===
  {
    id: 'github-copilot',
    name: 'GitHub Copilot',
    description: 'GitHub Copilot (VS Code / JetBrains)',
    skillsSupport: SKILLS_SUPPORT.AGENTS,
    instructionsDir: '.github/instructions',
    instructionFile: '.github/copilot-instructions.md',
    available: true
  },

  // === Continue（Rules/Prompts 系统）===
  {
    id: 'continue',
    name: 'Continue',
    description: 'Continue (VS Code / JetBrains)',
    skillsSupport: SKILLS_SUPPORT.RULES,
    slashDir: '.continue/prompts/devbooks',
    rulesDir: '.continue/rules',
    instructionFile: null,
    available: true
  },

  // === Codex CLI（完整 Skills 支持）===
  {
    id: 'codex',
    name: 'Codex CLI',
    description: 'OpenAI Codex CLI',
    skillsSupport: SKILLS_SUPPORT.FULL,
    slashDir: null,
    skillsDir: path.join(os.homedir(), '.codex', 'skills'),
    globalSlashDir: path.join(os.homedir(), '.codex', 'prompts'),
    instructionFile: 'AGENTS.md',
    available: true
  }
];

const DEVBOOKS_MARKERS = {
  start: '<!-- DEVBOOKS:START -->',
  end: '<!-- DEVBOOKS:END -->'
};

// ============================================================================
// 辅助函数
// ============================================================================

function expandPath(p) {
  if (p.startsWith('~')) {
    return path.join(os.homedir(), p.slice(1));
  }
  return p;
}

function copyDirSync(src, dest) {
  if (!fs.existsSync(src)) return 0;
  fs.mkdirSync(dest, { recursive: true });
  let count = 0;

  const entries = fs.readdirSync(src, { withFileTypes: true });
  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);

    if (entry.isDirectory()) {
      count += copyDirSync(srcPath, destPath);
    } else if (entry.isSymbolicLink()) {
      // Skip symlinks to avoid broken links
      continue;
    } else {
      fs.copyFileSync(srcPath, destPath);
      count++;
    }
  }
  return count;
}

function copyCodexPromptsSync(srcDir, destDir) {
  if (!fs.existsSync(srcDir)) return 0;
  fs.mkdirSync(destDir, { recursive: true });

  let count = 0;
  const entries = fs.readdirSync(srcDir, { withFileTypes: true });
  for (const entry of entries) {
    if (!entry.isFile()) continue;
    if (!entry.name.endsWith('.md')) continue;

    const srcPath = path.join(srcDir, entry.name);
    const destName = entry.name.startsWith('devbooks-') ? entry.name : `devbooks-${entry.name}`;
    const destPath = path.join(destDir, destName);
    fs.copyFileSync(srcPath, destPath);
    count++;
  }

  return count;
}

function getSkillsSupportLabel(level) {
  switch (level) {
    case SKILLS_SUPPORT.FULL:
      return chalk.green('★ 完整 Skills');
    case SKILLS_SUPPORT.RULES:
      return chalk.blue('◆ Rules 系统');
    case SKILLS_SUPPORT.AGENTS:
      return chalk.yellow('● 自定义指令');
    case SKILLS_SUPPORT.BASIC:
      return chalk.gray('○ 基础支持');
    default:
      return chalk.gray('○ 未知');
  }
}

function getSkillsSupportDescription(level) {
  switch (level) {
    case SKILLS_SUPPORT.FULL:
      return '支持独立 Skills/Agents，可按需调用';
    case SKILLS_SUPPORT.RULES:
      return '支持 Rules 规则系统，自动应用';
    case SKILLS_SUPPORT.AGENTS:
      return '支持项目级自定义指令';
    case SKILLS_SUPPORT.BASIC:
      return '仅支持全局提示词';
    default:
      return '';
  }
}

// ============================================================================
// Skills 支持说明
// ============================================================================

function printSkillsSupportInfo() {
  console.log();
  console.log(chalk.bold('📚 Skills 支持级别说明'));
  console.log(chalk.gray('─'.repeat(50)));
  console.log();

  console.log(chalk.green('★ 完整 Skills') + chalk.gray(' - Claude Code, Codex CLI, Qoder'));
  console.log(chalk.gray('   └ 独立的 Skills/Agents 系统，可按需调用，有独立上下文'));
  console.log();

  console.log(chalk.blue('◆ Rules 系统') + chalk.gray(' - Cursor, Windsurf, Gemini, Antigravity, OpenCode, Continue'));
  console.log(chalk.gray('   └ 规则自动应用于匹配的文件/场景，功能接近 Skills'));
  console.log();

  console.log(chalk.yellow('● 自定义指令') + chalk.gray(' - GitHub Copilot'));
  console.log(chalk.gray('   └ 项目级指令文件，AI 会参考但无法主动调用'));
  console.log();
  console.log(chalk.gray('─'.repeat(50)));
  console.log();
}

// ============================================================================
// 交互式选择（inquirer）
// ============================================================================

async function promptToolSelection(projectDir) {
  printSkillsSupportInfo();

  // 读取已保存的配置
  const config = loadConfig(projectDir);
  const savedTools = config.aiTools || [];
  const hasSavedConfig = savedTools.length > 0;

  const choices = AI_TOOLS.filter(t => t.available).map(tool => {
    const isSelected = hasSavedConfig
      ? savedTools.includes(tool.id)
      : tool.id === 'claude'; // 首次运行默认选中 Claude Code

    return {
      name: `${tool.name} ${chalk.gray(`(${tool.description})`)} ${getSkillsSupportLabel(tool.skillsSupport)}`,
      value: tool.id,
      checked: isSelected
    };
  });

  if (hasSavedConfig) {
    console.log(chalk.blue('ℹ') + ` 检测到已保存的配置: ${savedTools.join(', ')}`);
    console.log();
  }

  const selectedTools = await checkbox({
    message: '选择要配置的 AI 工具（空格选择，回车确认）',
    choices,
    pageSize: 12,
    instructions: false
  });

  if (selectedTools.length === 0) {
    const continueWithoutTools = await confirm({
      message: '未选择任何工具，是否继续（仅创建项目结构）？',
      default: false
    });
    if (!continueWithoutTools) {
      console.log(chalk.yellow('已取消初始化。'));
      process.exit(0);
    }
  }

  return selectedTools;
}

// ============================================================================
// 安装 Slash 命令
// ============================================================================

function installSlashCommands(toolIds, projectDir) {
  const slashSrcDir = path.join(__dirname, '..', 'templates', 'claude-commands', 'devbooks');

  if (!fs.existsSync(slashSrcDir)) {
    return { results: [], total: 0 };
  }

  const results = [];

  for (const toolId of toolIds) {
    const tool = AI_TOOLS.find(t => t.id === toolId);
    if (!tool) continue;

    let destDir;
    if (tool.slashDir) {
      destDir = path.join(projectDir, tool.slashDir);
    } else if (tool.globalSlashDir) {
      destDir = expandPath(tool.globalSlashDir);
    } else {
      continue;
    }

    const count = toolId === 'codex'
      ? copyCodexPromptsSync(slashSrcDir, destDir)
      : copyDirSync(slashSrcDir, destDir);
    results.push({ tool: tool.name, count, path: destDir });
  }

  return { results, total: results.length };
}

// ============================================================================
// 安装 Skills（Claude Code, Codex CLI, Qoder）
// ============================================================================

function installSkills(toolIds, update = false) {
  const results = [];

  for (const toolId of toolIds) {
    const tool = AI_TOOLS.find(t => t.id === toolId);
    if (!tool || tool.skillsSupport !== SKILLS_SUPPORT.FULL) continue;

    // Claude Code 和 Codex CLI 都支持相同格式的 Skills
    if ((toolId === 'claude' || toolId === 'codex') && tool.skillsDir) {
      const skillsSrcDir = path.join(__dirname, '..', 'skills');
      const skillsDestDir = tool.skillsDir;

      if (!fs.existsSync(skillsSrcDir)) continue;

      const skillDirs = fs.readdirSync(skillsSrcDir)
        .filter(name => name.startsWith('devbooks-'))
        .filter(name => fs.statSync(path.join(skillsSrcDir, name)).isDirectory());

      if (skillDirs.length === 0) continue;

      fs.mkdirSync(skillsDestDir, { recursive: true });

      let installedCount = 0;
      for (const skillName of skillDirs) {
        const srcPath = path.join(skillsSrcDir, skillName);
        const destPath = path.join(skillsDestDir, skillName);

        if (fs.existsSync(destPath) && !update) continue;
        if (fs.existsSync(destPath)) {
          fs.rmSync(destPath, { recursive: true, force: true });
        }

        copyDirSync(srcPath, destPath);
        installedCount++;
      }

      results.push({ tool: tool.name, type: 'skills', count: installedCount, total: skillDirs.length });
    }

    // Qoder: 创建 agents 目录结构（但不复制 Skills，因为格式不同）
    if (toolId === 'qoder') {
      results.push({ tool: 'Qoder', type: 'agents', count: 0, total: 0, note: '需要手动创建 agents/' });
    }
  }

  return results;
}

// ============================================================================
// 安装 Rules（Cursor, Windsurf, Gemini, Antigravity, OpenCode, Continue）
// ============================================================================

function installRules(toolIds, projectDir) {
  const results = [];

  for (const toolId of toolIds) {
    const tool = AI_TOOLS.find(t => t.id === toolId);
    if (!tool || tool.skillsSupport !== SKILLS_SUPPORT.RULES) continue;

    if (tool.rulesDir) {
      const rulesDestDir = path.join(projectDir, tool.rulesDir);
      fs.mkdirSync(rulesDestDir, { recursive: true });

      // 创建 devbooks.md 规则文件
      const ruleContent = generateRuleContent(toolId);
      const ruleFileName = toolId === 'gemini' ? 'GEMINI.md' : 'devbooks.md';
      const rulePath = path.join(rulesDestDir, ruleFileName);

      if (!fs.existsSync(rulePath)) {
        fs.writeFileSync(rulePath, ruleContent);
        results.push({ tool: tool.name, type: 'rules', path: rulePath });
      }
    }
  }

  return results;
}

function generateRuleContent(toolId) {
  const frontmatter = {
    cursor: `---
description: DevBooks 工作流规则
globs: ["**/*"]
---`,
    windsurf: `---
trigger: model_decision
description: DevBooks 工作流规则 - 在处理功能开发、架构变更时自动应用
---`,
    gemini: '',
    antigravity: `---
description: DevBooks 工作流规则
---`,
    opencode: '',
    continue: `---
name: DevBooks 工作流规则
description: DevBooks spec-driven development workflow
---`
  };

  return `${frontmatter[toolId] || ''}
${DEVBOOKS_MARKERS.start}
# DevBooks 工作流规则

## 协议发现

在回答任何问题或写任何代码前，按以下顺序查找配置：
1. \`.devbooks/config.yaml\`（如存在）→ 解析并使用其中的映射
2. \`dev-playbooks/project.md\`（如存在）→ DevBooks 协议

## 核心约束

- Test Owner 与 Coder 必须独立对话/独立实例
- Coder 禁止修改 tests/
- 任何新功能/破坏性变更/架构改动：必须先创建 \`dev-playbooks/changes/<id>/\`

## 工作流命令

| 命令 | 说明 |
|------|------|
| \`/devbooks:proposal\` | 创建变更提案 |
| \`/devbooks:design\` | 创建设计文档 |
| \`/devbooks:apply <role>\` | 执行实现 |
| \`/devbooks:archive\` | 归档变更包 |

${DEVBOOKS_MARKERS.end}
`;
}

// ============================================================================
// 安装自定义指令文件
// ============================================================================

function installInstructionFiles(toolIds, projectDir) {
  const results = [];

  for (const toolId of toolIds) {
    const tool = AI_TOOLS.find(t => t.id === toolId);
    if (!tool) continue;

    // GitHub Copilot 特殊处理
    if (toolId === 'github-copilot') {
      const instructionsDir = path.join(projectDir, '.github', 'instructions');
      fs.mkdirSync(instructionsDir, { recursive: true });

      const copilotInstructionPath = path.join(projectDir, '.github', 'copilot-instructions.md');
      if (!fs.existsSync(copilotInstructionPath)) {
        fs.writeFileSync(copilotInstructionPath, generateCopilotInstructions());
        results.push({ tool: 'GitHub Copilot', type: 'instructions', path: copilotInstructionPath });
      }

      // 创建 devbooks.instructions.md
      const devbooksInstructionPath = path.join(instructionsDir, 'devbooks.instructions.md');
      if (!fs.existsSync(devbooksInstructionPath)) {
        fs.writeFileSync(devbooksInstructionPath, generateCopilotDevbooksInstructions());
        results.push({ tool: 'GitHub Copilot', type: 'instructions', path: devbooksInstructionPath });
      }
    }

    // 创建 AGENTS.md / CLAUDE.md / GEMINI.md
    if (tool.instructionFile && !tool.instructionFile.includes('/')) {
      const instructionPath = path.join(projectDir, tool.instructionFile);
      if (!fs.existsSync(instructionPath)) {
        fs.writeFileSync(instructionPath, generateAgentsContent(tool.instructionFile));
        results.push({ tool: tool.name, type: 'instruction', path: instructionPath });
      }
    }
  }

  return results;
}

function generateCopilotInstructions() {
  return `${DEVBOOKS_MARKERS.start}
# GitHub Copilot 项目指令

## DevBooks 协议

本项目使用 DevBooks 工作流进行开发。

### 协议发现

在回答问题或写代码前，检查：
1. \`.devbooks/config.yaml\` - DevBooks 配置
2. \`dev-playbooks/project.md\` - 项目规范

### 核心约束

- 新功能/架构变更需先创建提案
- Test Owner 与 Coder 角色分离
- 禁止在 coder 角色时修改 tests/

${DEVBOOKS_MARKERS.end}
`;
}

function generateCopilotDevbooksInstructions() {
  return `---
applyTo: "dev-playbooks/**/*"
description: "DevBooks 工作流文件处理规则"
---
${DEVBOOKS_MARKERS.start}
# DevBooks 文件处理规则

当编辑 dev-playbooks/ 目录下的文件时：

1. **proposal.md**: 只写 Why/What/Impact，不写实现细节
2. **design.md**: 写 What/Constraints + AC-xxx，不写函数体代码
3. **tasks.md**: 可跟踪的任务项，绑定验收锚点
4. **verification.md**: 追溯矩阵，记录 Red/Green 证据

${DEVBOOKS_MARKERS.end}
`;
}

function generateAgentsContent(filename) {
  const toolHint = filename === 'CLAUDE.md' ? 'Claude Code'
    : filename === 'GEMINI.md' ? 'Gemini CLI / Antigravity'
    : '兼容 AGENTS.md 的 AI 工具';

  return `${DEVBOOKS_MARKERS.start}
# DevBooks 使用说明

这些说明适用于 ${toolHint}。

## DevBooks 协议发现与约束

- **配置发现**：在回答任何问题或写任何代码前，按以下顺序查找配置：
  1. \`.devbooks/config.yaml\`（如存在）→ 解析并使用其中的映射
  2. \`dev-playbooks/project.md\`（如存在）→ DevBooks 协议
- 找到配置后，先阅读 \`agents_doc\`（规则文档），再执行任何操作。
- Test Owner 与 Coder 必须独立对话/独立实例；Coder 禁止修改 tests/。
- 任何新功能/破坏性变更/架构改动：必须先创建 \`dev-playbooks/changes/<id>/\`。

## 工作流命令

| 命令 | 说明 |
|------|------|
| \`/devbooks:proposal\` | 创建变更提案 |
| \`/devbooks:design\` | 创建设计文档 |
| \`/devbooks:apply <role>\` | 执行实现（test-owner/coder/reviewer） |
| \`/devbooks:archive\` | 归档变更包 |

${DEVBOOKS_MARKERS.end}
`;
}

// ============================================================================
// 创建项目结构
// ============================================================================

function createProjectStructure(projectDir) {
  const templateDir = path.join(__dirname, '..', 'templates');

  const dirs = [
    'dev-playbooks/specs/_meta/anti-patterns',
    'dev-playbooks/specs/architecture',
    'dev-playbooks/changes',
    'dev-playbooks/scripts',
    'dev-playbooks/docs',
    '.devbooks'
  ];

  for (const dir of dirs) {
    fs.mkdirSync(path.join(projectDir, dir), { recursive: true });
  }

  const templateFiles = [
    { src: 'dev-playbooks/README.md', dest: 'dev-playbooks/README.md' },
    { src: 'dev-playbooks/constitution.md', dest: 'dev-playbooks/constitution.md' },
    { src: 'dev-playbooks/project.md', dest: 'dev-playbooks/project.md' },
    { src: 'dev-playbooks/specs/_meta/project-profile.md', dest: 'dev-playbooks/specs/_meta/project-profile.md' },
    { src: 'dev-playbooks/specs/_meta/glossary.md', dest: 'dev-playbooks/specs/_meta/glossary.md' },
    { src: 'dev-playbooks/specs/architecture/fitness-rules.md', dest: 'dev-playbooks/specs/architecture/fitness-rules.md' },
    { src: '.devbooks/config.yaml', dest: '.devbooks/config.yaml' }
  ];

  // 动态添加 docs 目录下的所有文件
  const docsDir = path.join(templateDir, 'dev-playbooks', 'docs');
  if (fs.existsSync(docsDir)) {
    const docFiles = fs.readdirSync(docsDir).filter(f => f.endsWith('.md'));
    for (const docFile of docFiles) {
      templateFiles.push({
        src: `dev-playbooks/docs/${docFile}`,
        dest: `dev-playbooks/docs/${docFile}`
      });
    }
  }

  let copiedCount = 0;
  for (const { src, dest } of templateFiles) {
    const srcPath = path.join(templateDir, src);
    const destPath = path.join(projectDir, dest);

    if (fs.existsSync(srcPath) && !fs.existsSync(destPath)) {
      fs.mkdirSync(path.dirname(destPath), { recursive: true });
      fs.copyFileSync(srcPath, destPath);
      copiedCount++;
    }
  }

  return copiedCount;
}

// ============================================================================
// 保存配置
// ============================================================================

function saveConfig(toolIds, projectDir) {
  const configPath = path.join(projectDir, '.devbooks', 'config.yaml');

  // 读取现有配置或创建新配置
  let configContent = '';
  if (fs.existsSync(configPath)) {
    configContent = fs.readFileSync(configPath, 'utf-8');
  }

  // 更新 ai_tools 部分
  const toolsYaml = `ai_tools:\n${toolIds.map(id => `  - ${id}`).join('\n')}`;

  if (configContent.includes('ai_tools:')) {
    // 替换现有的 ai_tools 部分
    configContent = configContent.replace(/ai_tools:[\s\S]*?(?=\n\w|\n$|$)/, toolsYaml + '\n');
  } else {
    // 追加 ai_tools 部分
    configContent = configContent.trimEnd() + '\n\n' + toolsYaml + '\n';
  }

  fs.writeFileSync(configPath, configContent);
}

function loadConfig(projectDir) {
  const configPath = path.join(projectDir, '.devbooks', 'config.yaml');

  if (!fs.existsSync(configPath)) {
    return { aiTools: [] };
  }

  const content = fs.readFileSync(configPath, 'utf-8');
  const match = content.match(/ai_tools:\s*([\s\S]*?)(?=\n\w|\n$|$)/);

  if (!match) {
    return { aiTools: [] };
  }

  const tools = match[1]
    .split('\n')
    .map(line => line.trim())
    .filter(line => line.startsWith('-'))
    .map(line => line.replace(/^-\s*/, '').trim());

  return { aiTools: tools };
}

// ============================================================================
// Init 命令
// ============================================================================

async function initCommand(projectDir, options) {
  console.log();
  console.log(chalk.cyan('╔══════════════════════════════════════╗'));
  console.log(chalk.cyan('║') + chalk.bold('         DevBooks 初始化向导         ') + chalk.cyan('║'));
  console.log(chalk.cyan('╚══════════════════════════════════════╝'));
  console.log();

  // 确定选择的工具
  let selectedTools;

  if (options.tools) {
    if (options.tools === 'all') {
      selectedTools = AI_TOOLS.filter(t => t.available).map(t => t.id);
    } else if (options.tools === 'none') {
      selectedTools = [];
    } else {
      selectedTools = options.tools.split(',').map(t => t.trim()).filter(t =>
        AI_TOOLS.some(tool => tool.id === t)
      );
    }
    console.log(chalk.blue('ℹ') + ` 非交互式模式：${selectedTools.length > 0 ? selectedTools.join(', ') : '无'}`);
  } else {
    selectedTools = await promptToolSelection(projectDir);
  }

  // 创建项目结构
  const spinner = ora('创建项目结构...').start();
  const templateCount = createProjectStructure(projectDir);
  spinner.succeed(`创建了 ${templateCount} 个模板文件`);

  // 保存配置
  saveConfig(selectedTools, projectDir);

  if (selectedTools.length === 0) {
    console.log();
    console.log(chalk.green('✓') + ' DevBooks 项目结构已创建！');
    console.log(chalk.gray(`  运行 \`${CLI_COMMAND} init\` 并选择 AI 工具来配置集成。`));
    return;
  }

  // 安装 Slash 命令
  const slashSpinner = ora('安装 Slash 命令...').start();
  const slashResults = installSlashCommands(selectedTools, projectDir);
  slashSpinner.succeed(`安装了 ${slashResults.results.length} 个工具的 Slash 命令`);

  for (const result of slashResults.results) {
    console.log(chalk.gray(`  └ ${result.tool}: ${result.count} 个命令`));
  }

  // 安装 Skills（仅完整支持的工具）
  const fullSupportTools = selectedTools.filter(id => {
    const tool = AI_TOOLS.find(t => t.id === id);
    return tool && tool.skillsSupport === SKILLS_SUPPORT.FULL;
  });

  if (fullSupportTools.length > 0) {
    const skillsSpinner = ora('安装 Skills...').start();
    const skillsResults = installSkills(fullSupportTools);
    skillsSpinner.succeed('Skills 安装完成');

    for (const result of skillsResults) {
      if (result.count > 0) {
        console.log(chalk.gray(`  └ ${result.tool}: ${result.count}/${result.total} 个 ${result.type}`));
      } else if (result.note) {
        console.log(chalk.gray(`  └ ${result.tool}: ${result.note}`));
      }
    }
  }

  // 安装 Rules（Rules 类似系统的工具）
  const rulesTools = selectedTools.filter(id => {
    const tool = AI_TOOLS.find(t => t.id === id);
    return tool && tool.skillsSupport === SKILLS_SUPPORT.RULES;
  });

  if (rulesTools.length > 0) {
    const rulesSpinner = ora('安装 Rules...').start();
    const rulesResults = installRules(rulesTools, projectDir);
    rulesSpinner.succeed(`创建了 ${rulesResults.length} 个规则文件`);

    for (const result of rulesResults) {
      console.log(chalk.gray(`  └ ${result.tool}: ${path.relative(projectDir, result.path)}`));
    }
  }

  // 安装指令文件
  const instructionSpinner = ora('创建指令文件...').start();
  const instructionResults = installInstructionFiles(selectedTools, projectDir);
  instructionSpinner.succeed(`创建了 ${instructionResults.length} 个指令文件`);

  for (const result of instructionResults) {
    console.log(chalk.gray(`  └ ${result.tool}: ${path.relative(projectDir, result.path)}`));
  }

  // 完成
  console.log();
  console.log(chalk.green('══════════════════════════════════════'));
  console.log(chalk.green('✓') + chalk.bold(' DevBooks 初始化完成！'));
  console.log(chalk.green('══════════════════════════════════════'));
  console.log();

  // 显示已配置的工具
  console.log(chalk.white('已配置的 AI 工具：'));
  for (const toolId of selectedTools) {
    const tool = AI_TOOLS.find(t => t.id === toolId);
    if (tool) {
      console.log(`  ${chalk.cyan('▸')} ${tool.name} ${getSkillsSupportLabel(tool.skillsSupport)}`);
    }
  }
  console.log();

  // 下一步提示
  console.log(chalk.bold('下一步：'));
  console.log(`  1. 编辑 ${chalk.cyan('dev-playbooks/project.md')} 添加项目信息`);
  console.log(`  2. 使用 ${chalk.cyan('/devbooks:proposal')} 创建第一个变更提案`);
  console.log();
  console.log(chalk.yellow('重要提示：'));
  console.log('  Slash 命令在 IDE 启动时加载，请重启你的 AI 工具以使命令生效。');
}

// ============================================================================
// Update 命令
// ============================================================================

async function updateCommand(projectDir) {
  console.log();
  console.log(chalk.bold('DevBooks 更新'));
  console.log();

  // 检查是否已初始化
  const configPath = path.join(projectDir, '.devbooks', 'config.yaml');
  if (!fs.existsSync(configPath)) {
    console.log(chalk.red('✗') + ` 未找到 DevBooks 配置。请先运行 \`${CLI_COMMAND} init\`。`);
    process.exit(1);
  }

  // 加载配置
  const config = loadConfig(projectDir);
  const configuredTools = config.aiTools;

  if (configuredTools.length === 0) {
    console.log(chalk.yellow('⚠') + ` 未配置任何 AI 工具。运行 \`${CLI_COMMAND} init\` 进行配置。`);
    return;
  }

  const toolNames = configuredTools.map(id => {
    const tool = AI_TOOLS.find(t => t.id === id);
    return tool ? tool.name : id;
  });
  console.log(chalk.blue('ℹ') + ` 检测到已配置的工具: ${toolNames.join(', ')}`);

  // 更新 Slash 命令
  const slashResults = installSlashCommands(configuredTools, projectDir);
  for (const result of slashResults.results) {
    console.log(chalk.green('✓') + ` ${result.tool}: 更新了 ${result.count} 个 slash 命令`);
  }

  // 更新 Skills
  const skillsResults = installSkills(configuredTools, true);
  for (const result of skillsResults) {
    if (result.count > 0) {
      console.log(chalk.green('✓') + ` ${result.tool} ${result.type}: 更新了 ${result.count}/${result.total} 个`);
    }
  }

  // 更新 Rules
  const rulesTools = configuredTools.filter(id => {
    const tool = AI_TOOLS.find(t => t.id === id);
    return tool && tool.skillsSupport === SKILLS_SUPPORT.RULES;
  });

  if (rulesTools.length > 0) {
    const rulesResults = installRules(rulesTools, projectDir);
    for (const result of rulesResults) {
      console.log(chalk.green('✓') + ` ${result.tool}: 更新了规则文件`);
    }
  }

  console.log();
  console.log(chalk.green('✓') + ' 更新完成！');
}

// ============================================================================
// Migrate 命令
// ============================================================================

async function migrateCommand(projectDir, options) {
  console.log();
  console.log(chalk.bold('DevBooks 迁移工具'));
  console.log();

  const { from, dryRun, keepOld, force } = options;

  if (!from) {
    console.log(chalk.red('✗') + ' 请指定迁移来源框架：--from openspec 或 --from speckit');
    console.log();
    console.log(chalk.cyan('示例:'));
    console.log(`  ${CLI_COMMAND} migrate --from openspec`);
    console.log(`  ${CLI_COMMAND} migrate --from speckit`);
    console.log(`  ${CLI_COMMAND} migrate --from openspec --dry-run`);
    process.exit(1);
  }

  const validFrameworks = ['openspec', 'speckit'];
  if (!validFrameworks.includes(from)) {
    console.log(chalk.red('✗') + ` 不支持的框架: ${from}`);
    console.log(chalk.gray(`  支持的框架: ${validFrameworks.join(', ')}`));
    process.exit(1);
  }

  // 确定脚本路径
  const scriptName = from === 'openspec' ? 'migrate-from-openspec.sh' : 'migrate-from-speckit.sh';
  const scriptPath = path.join(__dirname, '..', 'scripts', scriptName);

  if (!fs.existsSync(scriptPath)) {
    console.log(chalk.red('✗') + ` 迁移脚本不存在: ${scriptPath}`);
    process.exit(1);
  }

  // 构建参数
  const args = ['--project-root', projectDir];
  if (dryRun) args.push('--dry-run');
  if (keepOld) args.push('--keep-old');
  if (force) args.push('--force');

  console.log(chalk.blue('ℹ') + ` 迁移来源: ${from}`);
  console.log(chalk.blue('ℹ') + ` 项目目录: ${projectDir}`);
  if (dryRun) console.log(chalk.yellow('ℹ') + ' 模式: DRY-RUN（模拟运行）');
  console.log();

  // 执行脚本
  return new Promise((resolve, reject) => {
    const child = spawn('bash', [scriptPath, ...args], {
      stdio: 'inherit',
      cwd: projectDir
    });

    child.on('close', (code) => {
      if (code === 0) {
        console.log();
        if (!dryRun) {
          console.log(chalk.green('✓') + ' 迁移完成！');
          console.log();
          console.log(chalk.bold('下一步：'));
          console.log(`  运行 ${chalk.cyan(`${CLI_COMMAND} init`)} 安装 DevBooks Skills`);
        }
        resolve();
      } else {
        reject(new Error(`迁移脚本退出码: ${code}`));
      }
    });

    child.on('error', (err) => {
      reject(new Error(`执行迁移脚本失败: ${err.message}`));
    });
  });
}

// ============================================================================
// 帮助信息
// ============================================================================

function showHelp() {
  console.log();
  console.log(chalk.bold('DevBooks') + ' - AI-agnostic spec-driven development workflow');
  console.log();
  console.log(chalk.cyan('用法:'));
  console.log(`  ${CLI_COMMAND} init [path] [options]              初始化 DevBooks`);
  console.log(`  ${CLI_COMMAND} update [path]                      更新已配置的工具`);
  console.log(`  ${CLI_COMMAND} migrate --from <framework> [opts]  从其他框架迁移`);
  console.log();
  console.log(chalk.cyan('选项:'));
  console.log('  --tools <tools>    非交互式指定 AI 工具');
  console.log('                     可用值: all, none, 或逗号分隔的工具 ID');
  console.log('  --from <framework> 迁移来源框架 (openspec, speckit)');
  console.log('  --dry-run          模拟运行，不实际修改文件');
  console.log('  --keep-old         迁移后保留原目录');
  console.log('  --force            强制重新执行所有步骤');
  console.log('  -h, --help         显示此帮助信息');
  console.log();
  console.log(chalk.cyan('支持的 AI 工具:'));

  // 按 Skills 支持级别分组显示
  const groupedTools = {
    [SKILLS_SUPPORT.FULL]: [],
    [SKILLS_SUPPORT.RULES]: [],
    [SKILLS_SUPPORT.AGENTS]: [],
    [SKILLS_SUPPORT.BASIC]: []
  };

  for (const tool of AI_TOOLS.filter(t => t.available)) {
    groupedTools[tool.skillsSupport].push(tool);
  }

  console.log();
  console.log(chalk.green('  ★ 完整 Skills 支持:'));
  for (const tool of groupedTools[SKILLS_SUPPORT.FULL]) {
    console.log(`    ${tool.id.padEnd(15)} ${tool.name}`);
  }

  console.log();
  console.log(chalk.blue('  ◆ Rules 系统支持:'));
  for (const tool of groupedTools[SKILLS_SUPPORT.RULES]) {
    console.log(`    ${tool.id.padEnd(15)} ${tool.name}`);
  }

  console.log();
  console.log(chalk.yellow('  ● 自定义指令支持:'));
  for (const tool of groupedTools[SKILLS_SUPPORT.AGENTS]) {
    console.log(`    ${tool.id.padEnd(15)} ${tool.name}`);
  }

  console.log();
  console.log();
  console.log(chalk.cyan('示例:'));
  console.log(`  ${CLI_COMMAND} init                        # 交互式初始化`);
  console.log(`  ${CLI_COMMAND} init my-project             # 在 my-project 目录初始化`);
  console.log(`  ${CLI_COMMAND} init --tools claude,cursor  # 非交互式`);
  console.log(`  ${CLI_COMMAND} update                      # 更新已配置的工具`);
  console.log(`  ${CLI_COMMAND} migrate --from openspec     # 从 OpenSpec 迁移`);
  console.log(`  ${CLI_COMMAND} migrate --from speckit      # 从 spec-kit 迁移`);
  console.log(`  ${CLI_COMMAND} migrate --from openspec --dry-run  # 模拟迁移`);
}

// ============================================================================
// 主入口
// ============================================================================

async function main() {
  const args = process.argv.slice(2);

  // 解析参数
  let command = null;
  let projectPath = null;
  const options = {};

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];

    if (arg === '-h' || arg === '--help') {
      showHelp();
      process.exit(0);
    } else if (arg === '--tools') {
      options.tools = args[++i];
    } else if (arg === '--from') {
      options.from = args[++i];
    } else if (arg === '--dry-run') {
      options.dryRun = true;
    } else if (arg === '--keep-old') {
      options.keepOld = true;
    } else if (arg === '--force') {
      options.force = true;
    } else if (!arg.startsWith('-')) {
      if (!command) {
        command = arg;
      } else if (!projectPath) {
        projectPath = arg;
      }
    }
  }

  // 确定项目目录
  const projectDir = projectPath ? path.resolve(projectPath) : process.cwd();

  // 执行命令
  try {
    if (command === 'init' || !command) {
      await initCommand(projectDir, options);
    } else if (command === 'update') {
      await updateCommand(projectDir);
    } else if (command === 'migrate') {
      await migrateCommand(projectDir, options);
    } else {
      console.log(chalk.red(`未知命令: ${command}`));
      showHelp();
      process.exit(1);
    }
  } catch (error) {
    if (error.name === 'ExitPromptError') {
      console.log(chalk.yellow('\n已取消。'));
      process.exit(0);
    }
    throw error;
  }
}

main().catch(error => {
  console.error(chalk.red('✗'), error.message);
  process.exit(1);
});
