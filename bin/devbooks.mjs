#!/usr/bin/env node

/**
 * DevBooks CLI
 *
 * AI-agnostic spec-driven development workflow
 *
 * 用法：
 *   dev-playbooks-cn init [path] [options]
 *   dev-playbooks-cn update [path]           # 更新 CLI 和已配置的工具
 *   dev-playbooks-cn migrate --from <framework> [options]
 *   dev-playbooks-cn delivery [options]      # 唯一入口指引（不执行 AI）
 *
 * 选项：
 *   --tools <tools>      非交互式指定 AI 工具：all, none, 或逗号分隔的列表
 *   --scope <scope>      Skills 安装位置：project（默认）或 global
 *   --from <framework>   迁移来源（对应 scripts/legacy/migrate-from-<framework>.sh）
 *   --dry-run            模拟运行，不实际修改文件
 *   --keep-old           迁移后保留原目录
 *   --force              强制覆盖已有文件（谨慎使用）
 *   --help               显示帮助信息
 *   --version            显示版本号
 */

import fs from 'fs';
import path from 'path';
import os from 'os';
import { fileURLToPath } from 'url';
import { spawn } from 'child_process';
import { checkbox, confirm, select } from '@inquirer/prompts';
import chalk from 'chalk';
import ora from 'ora';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const CLI_COMMAND = 'dev-playbooks-cn';
const ENTRY_DOC = 'docs/使用指南.md';
const ENTRY_TEMPLATES = {
  delivery: 'templates/claude-commands/devbooks/delivery.md',
  index: 'templates/claude-commands/devbooks/index.md'
};
const XDG_CONFIG_HOME = process.env.XDG_CONFIG_HOME || path.join(os.homedir(), '.config');

// 版本检查缓存配置
const VERSION_CACHE_FILE = path.join(os.tmpdir(), `${CLI_COMMAND}-version-cache.json`);
const VERSION_CACHE_TTL = 10 * 60 * 1000; // 10 分钟缓存

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
// Skills 安装范围
// ============================================================================

const INSTALL_SCOPE = {
  GLOBAL: 'global',   // 全局安装（~/.claude/skills 等）
  PROJECT: 'project'  // 项目级安装（.claude/skills 等）
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
  {
    id: 'opencode',
    name: 'OpenCode',
    description: 'OpenCode AI CLI（兼容 oh-my-opencode）',
    skillsSupport: SKILLS_SUPPORT.FULL,
    slashDir: '.opencode/command',
    agentsDir: '.opencode/agent',
    skillsDir: path.join(XDG_CONFIG_HOME, 'opencode', 'skill'),
    globalDir: path.join(XDG_CONFIG_HOME, 'opencode'),
    instructionFile: 'AGENTS.md',
    available: true
  },

  // === Factory（原生 Skills 支持）===
  {
    id: 'factory',
    name: 'Factory',
    description: 'Factory Droid',
    skillsSupport: SKILLS_SUPPORT.FULL,
    slashDir: null,
    skillsDir: '.factory/skills',  // 项目级
    instructionFile: null,
    available: true
  },

  // === Cursor（原生 Skills 支持）===
  {
    id: 'cursor',
    name: 'Cursor',
    description: 'Cursor AI IDE',
    skillsSupport: SKILLS_SUPPORT.FULL,
    slashDir: '.cursor/commands/devbooks',
    skillsDir: '.cursor/skills',  // 项目级
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
  },

  // === Every Code / just-every/code（完整 Skills 支持）===
  {
    id: 'code',
    name: 'Every Code',
    description: 'Every Code CLI (@just-every/code)',
    skillsSupport: SKILLS_SUPPORT.FULL,
    slashDir: null,
    skillsDir: path.join(os.homedir(), '.code', 'skills'),
    globalSlashDir: null,
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

/**
 * 更新文件中 DEVBOOKS:START/END 标记之间的内容
 * 保留标记外的用户自定义内容
 */
function updateManagedContent(filePath, newManagedContent) {
  if (!fs.existsSync(filePath)) {
    return false;
  }

  const content = fs.readFileSync(filePath, 'utf-8');
  const startMarker = DEVBOOKS_MARKERS.start;
  const endMarker = DEVBOOKS_MARKERS.end;

  const startIdx = content.indexOf(startMarker);
  const endIdx = content.indexOf(endMarker);

  if (startIdx === -1 || endIdx === -1 || startIdx >= endIdx) {
    // 没有找到有效的标记，无法更新
    return false;
  }

  // 提取新内容中标记之间的部分
  const newStartIdx = newManagedContent.indexOf(startMarker);
  const newEndIdx = newManagedContent.indexOf(endMarker);

  if (newStartIdx === -1 || newEndIdx === -1) {
    return false;
  }

  const newManagedBlock = newManagedContent.slice(newStartIdx, newEndIdx + endMarker.length);

  // 替换旧内容中标记之间的部分
  const before = content.slice(0, startIdx);
  const after = content.slice(endIdx + endMarker.length);
  const updatedContent = before + newManagedBlock + after;

  if (updatedContent !== content) {
    fs.writeFileSync(filePath, updatedContent);
    return true;
  }

  return false;
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

function pruneRemovedSkills(skillsDestDir, allowedSkillNames) {
  if (!fs.existsSync(skillsDestDir)) return 0;
  let removedCount = 0;
  const entries = fs.readdirSync(skillsDestDir, { withFileTypes: true });

  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    if (!entry.name.startsWith('devbooks-')) continue;
    if (allowedSkillNames.has(entry.name)) continue;

    fs.rmSync(path.join(skillsDestDir, entry.name), { recursive: true, force: true });
    removedCount++;
  }

  return removedCount;
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

function getCliVersion() {
  const packagePath = path.join(__dirname, '..', 'package.json');
  try {
    const raw = fs.readFileSync(packagePath, 'utf-8');
    const pkg = JSON.parse(raw);
    return pkg.version || 'unknown';
  } catch {
    return 'unknown';
  }
}

/**
 * 检查 npm 上是否有新版本（带缓存）
 * @returns {Promise<{hasUpdate: boolean, latestVersion: string|null, currentVersion: string}>}
 */
async function checkNpmUpdate() {
  const currentVersion = getCliVersion();

  // 检查缓存
  try {
    if (fs.existsSync(VERSION_CACHE_FILE)) {
      const cache = JSON.parse(fs.readFileSync(VERSION_CACHE_FILE, 'utf-8'));
      const cacheAge = Date.now() - cache.timestamp;

      // 如果缓存未过期且当前版本匹配缓存的最新版本，跳过网络请求
      if (cacheAge < VERSION_CACHE_TTL && cache.currentVersion === currentVersion) {
        // 如果缓存显示已是最新版本，直接返回
        if (!cache.hasUpdate) {
          return { hasUpdate: false, latestVersion: cache.latestVersion, currentVersion };
        }
        // 如果缓存显示有更新，仍返回缓存结果
        return { hasUpdate: cache.hasUpdate, latestVersion: cache.latestVersion, currentVersion };
      }
    }
  } catch {
    // 缓存读取失败，继续网络请求
  }

  try {
    const { execSync } = await import('child_process');
    const latestVersion = execSync(`npm view ${CLI_COMMAND} version`, {
      encoding: 'utf-8',
      timeout: 10000,
      stdio: ['pipe', 'pipe', 'pipe']
    }).trim();

    let hasUpdate = false;
    if (latestVersion && latestVersion !== currentVersion) {
      // 简单版本比较（假设语义化版本）
      const current = currentVersion.split('.').map(Number);
      const latest = latestVersion.split('.').map(Number);
      hasUpdate = latest[0] > current[0] ||
        (latest[0] === current[0] && latest[1] > current[1]) ||
        (latest[0] === current[0] && latest[1] === current[1] && latest[2] > current[2]);
    }

    // 保存缓存
    try {
      fs.writeFileSync(VERSION_CACHE_FILE, JSON.stringify({
        timestamp: Date.now(),
        currentVersion,
        latestVersion,
        hasUpdate
      }));
    } catch {
      // 缓存写入失败，忽略
    }

    return { hasUpdate, latestVersion, currentVersion };
  } catch {
    // 网络错误或超时，静默忽略
    return { hasUpdate: false, latestVersion: null, currentVersion };
  }
}

/**
 * 执行 npm 全局更新
 * @returns {Promise<boolean>} 更新是否成功
 */
async function performNpmUpdate() {
  return new Promise((resolve) => {
    const spinner = ora(`正在更新 ${CLI_COMMAND}...`).start();
    const child = spawn('npm', ['install', '-g', CLI_COMMAND], {
      stdio: ['pipe', 'pipe', 'pipe'],
      shell: true
    });

    let stderr = '';
    child.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    child.on('close', (code) => {
      if (code === 0) {
        spinner.succeed(`${CLI_COMMAND} 已更新到最新版本`);
        resolve(true);
      } else {
        spinner.fail(`更新失败: ${stderr || '未知错误'}`);
        resolve(false);
      }
    });

    child.on('error', (err) => {
      spinner.fail(`更新失败: ${err.message}`);
      resolve(false);
    });
  });
}

/**
 * 显示版本变更摘要
 * @param {string} fromVersion - 当前版本
 * @param {string} toVersion - 目标版本
 */
async function displayVersionChangelog(fromVersion, toVersion) {
  try {
    // 尝试从 npm 获取 CHANGELOG
    const { execSync } = await import('child_process');
    const changelogUrl = `https://raw.githubusercontent.com/Darkbluelr/dev-playbooks-cn/master/CHANGELOG.md`;

    // 使用 curl 获取 CHANGELOG（如果可用）
    let changelog = '';
    try {
      changelog = execSync(`curl -s -m 5 "${changelogUrl}"`, {
        encoding: 'utf-8',
        stdio: ['pipe', 'pipe', 'pipe']
      });
    } catch {
      // 如果获取失败，显示简化信息
      console.log(chalk.cyan('📋 版本变更摘要'));
      console.log(chalk.gray('─'.repeat(60)));
      console.log(chalk.yellow('⚠ 无法获取详细变更日志，请访问：'));
      console.log(chalk.blue(`   https://github.com/Darkbluelr/dev-playbooks-cn/releases/tag/v${toVersion}`));
      return;
    }

    // 解析 CHANGELOG，提取相关版本的变更
    const changes = parseChangelog(changelog, fromVersion, toVersion);

    if (changes.length === 0) {
      console.log(chalk.cyan('📋 版本变更摘要'));
      console.log(chalk.gray('─'.repeat(60)));
      console.log(chalk.yellow('⚠ 未找到详细变更信息，请访问：'));
      console.log(chalk.blue(`   https://github.com/Darkbluelr/dev-playbooks-cn/releases/tag/v${toVersion}`));
      return;
    }

    // 显示变更摘要
    console.log(chalk.cyan('📋 版本变更摘要'));
    console.log(chalk.gray('─'.repeat(60)));

    for (const change of changes) {
      console.log();
      console.log(chalk.bold.green(`## ${change.version}`));
      if (change.date) {
        console.log(chalk.gray(`   发布日期: ${change.date}`));
      }
      console.log();

      // 显示主要变更（限制显示前10条）
      const highlights = change.content.split('\n')
        .filter(line => line.trim().length > 0)
        .slice(0, 10);

      for (const line of highlights) {
        if (line.startsWith('###')) {
          console.log(chalk.bold.yellow(line));
        } else if (line.startsWith('####')) {
          console.log(chalk.bold(line));
        } else if (line.startsWith('- ✅') || line.startsWith('- ✓')) {
          console.log(chalk.green(line));
        } else if (line.startsWith('- ⚠️') || line.startsWith('- ❌')) {
          console.log(chalk.yellow(line));
        } else if (line.startsWith('- ')) {
          console.log(chalk.white(line));
        } else {
          console.log(chalk.gray(line));
        }
      }

      if (change.content.split('\n').length > 10) {
        console.log(chalk.gray('   ... (更多变更请查看完整日志)'));
      }
    }

    console.log();
    console.log(chalk.gray('─'.repeat(60)));
    console.log(chalk.blue('📖 完整变更日志: ') + chalk.underline(`https://github.com/Darkbluelr/dev-playbooks-cn/blob/master/CHANGELOG.md`));

  } catch (error) {
    // 静默失败，不影响更新流程
    console.log(chalk.gray('提示: 无法显示变更摘要'));
  }
}

/**
 * 解析 CHANGELOG 内容，提取指定版本范围的变更
 * @param {string} changelog - CHANGELOG 内容
 * @param {string} fromVersion - 起始版本
 * @param {string} toVersion - 目标版本
 * @returns {Array} - 变更列表
 */
function parseChangelog(changelog, fromVersion, toVersion) {
  const changes = [];
  const lines = changelog.split('\n');

  let currentVersion = null;
  let currentDate = null;
  let currentContent = [];
  let inVersionBlock = false;
  let shouldCapture = false;

  // 解析版本号（移除 'v' 前缀）
  const from = fromVersion.replace(/^v/, '');
  const to = toVersion.replace(/^v/, '');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    // 匹配版本标题：## [2.0.0] - 2026-01-19
    const versionMatch = line.match(/^##\s+\[?(\d+\.\d+\.\d+)\]?\s*(?:-\s*(\d{4}-\d{2}-\d{2}))?/);

    if (versionMatch) {
      // 保存上一个版本的内容
      if (inVersionBlock && shouldCapture && currentVersion) {
        changes.push({
          version: currentVersion,
          date: currentDate,
          content: currentContent.join('\n').trim()
        });
      }

      // 开始新版本
      currentVersion = versionMatch[1];
      currentDate = versionMatch[2] || null;
      currentContent = [];
      inVersionBlock = true;

      // 判断是否应该捕获这个版本
      // 捕获从 fromVersion 到 toVersion 之间的所有版本
      const versionNum = currentVersion.split('.').map(Number);
      const fromNum = from.split('.').map(Number);
      const toNum = to.split('.').map(Number);

      const isAfterFrom = compareVersions(versionNum, fromNum) > 0;
      const isBeforeOrEqualTo = compareVersions(versionNum, toNum) <= 0;

      shouldCapture = isAfterFrom && isBeforeOrEqualTo;

      continue;
    }

    // 如果遇到下一个版本标题或分隔线，结束当前版本
    if (line.startsWith('---') && inVersionBlock) {
      if (shouldCapture && currentVersion) {
        changes.push({
          version: currentVersion,
          date: currentDate,
          content: currentContent.join('\n').trim()
        });
      }
      inVersionBlock = false;
      shouldCapture = false;
      continue;
    }

    // 收集内容
    if (inVersionBlock && shouldCapture) {
      currentContent.push(line);
    }
  }

  // 保存最后一个版本
  if (inVersionBlock && shouldCapture && currentVersion) {
    changes.push({
      version: currentVersion,
      date: currentDate,
      content: currentContent.join('\n').trim()
    });
  }

  return changes;
}

/**
 * 比较两个版本号
 * @param {number[]} v1 - 版本1 [major, minor, patch]
 * @param {number[]} v2 - 版本2 [major, minor, patch]
 * @returns {number} - 1 if v1 > v2, -1 if v1 < v2, 0 if equal
 */
function compareVersions(v1, v2) {
  for (let i = 0; i < 3; i++) {
    if (v1[i] > v2[i]) return 1;
    if (v1[i] < v2[i]) return -1;
  }
  return 0;
}

// ============================================================================
// 自动更新 .gitignore 和 .npmignore
// ============================================================================

const IGNORE_MARKERS = {
  start: '# DevBooks managed - DO NOT EDIT',
  end: '# End DevBooks managed'
};

/**
 * 获取需要添加到 .gitignore 的条目
 * @param {string[]} toolIds - 选择的 AI 工具 ID
 * @returns {string[]} - 需要忽略的条目
 */
function getGitIgnoreEntries(toolIds) {
  const entries = [
    '# DevBooks 本地配置（包含用户偏好，不应提交）',
    '.devbooks/',
    '',
    '# DevBooks 工作目录（运行时产生的内容）',
    '/dev-playbooks/',
    '',
    '# DevBooks 工作流产生的临时文件',
    'evidence/',
    '*.tmp',
    '*.bak'
  ];

  // 根据选择的工具添加对应的 AI 工具目录
  for (const toolId of toolIds) {
    const tool = AI_TOOLS.find(t => t.id === toolId);
    if (!tool) continue;

    // 添加 slash 命令目录
    if (tool.slashDir) {
      const topDir = tool.slashDir.split('/')[0];
      if (!entries.includes(topDir + '/')) {
        entries.push(`${topDir}/`);
      }
    }

    // 添加 skills 目录（项目级）
    if (tool.skillsDir && !path.isAbsolute(tool.skillsDir)) {
      const topDir = tool.skillsDir.split('/')[0];
      if (!entries.includes(topDir + '/')) {
        entries.push(`${topDir}/`);
      }
    }

    // 添加 rules 目录
    if (tool.rulesDir) {
      const topDir = tool.rulesDir.split('/')[0];
      if (!entries.includes(topDir + '/')) {
        entries.push(`${topDir}/`);
      }
    }

    // 添加 agents 目录（如 .github/instructions 等）
    if (tool.instructionsDir) {
      const topDir = tool.instructionsDir.split('/')[0];
      if (topDir !== '.github') { // .github 目录通常需要保留
        if (!entries.includes(topDir + '/')) {
          entries.push(`${topDir}/`);
        }
      }
    }
  }

  return entries;
}

/**
 * 获取需要添加到 .npmignore 的条目
 * @returns {string[]} - 需要忽略的条目
 */
function getNpmIgnoreEntries() {
  return [
    '# DevBooks 开发文档（运行时不需要）',
    '/dev-playbooks/',
    '.devbooks/',
    '',
    '# AI 工具配置目录',
    '.claude/',
    '.cursor/',
    '.factory/',
    '.windsurf/',
    '.gemini/',
    '.agent/',
    '.opencode/',
    '.continue/',
    '.qoder/',
    '.code/',
    '.codex/',
    '.github/instructions/',
    '.github/copilot-instructions.md',
    '',
    '# DevBooks 指令文件',
    'CLAUDE.md',
    'AGENTS.md',
    'GEMINI.md',
    '',
    '# DevBooks 工作流临时文件',
    'evidence/',
    '*.tmp',
    '*.bak'
  ];
}

/**
 * 更新 ignore 文件，保留用户自定义内容
 * @param {string} filePath - ignore 文件路径
 * @param {string[]} entries - 需要添加的条目
 * @returns {object} - { updated: boolean, action: 'created' | 'updated' | 'unchanged' }
 */
function updateIgnoreFile(filePath, entries) {
  const managedBlock = [
    IGNORE_MARKERS.start,
    ...entries,
    IGNORE_MARKERS.end
  ].join('\n');

  if (!fs.existsSync(filePath)) {
    // 文件不存在，创建新文件
    fs.writeFileSync(filePath, managedBlock + '\n');
    return { updated: true, action: 'created' };
  }

  const content = fs.readFileSync(filePath, 'utf-8');
  const startIdx = content.indexOf(IGNORE_MARKERS.start);
  const endIdx = content.indexOf(IGNORE_MARKERS.end);

  if (startIdx !== -1 && endIdx !== -1 && startIdx < endIdx) {
    // 已有托管块，更新它
    const before = content.slice(0, startIdx);
    const after = content.slice(endIdx + IGNORE_MARKERS.end.length);
    const newContent = before + managedBlock + after;

    if (newContent !== content) {
      fs.writeFileSync(filePath, newContent);
      return { updated: true, action: 'updated' };
    }
    return { updated: false, action: 'unchanged' };
  }

  // 没有托管块，追加到文件末尾
  const newContent = content.trimEnd() + '\n\n' + managedBlock + '\n';
  fs.writeFileSync(filePath, newContent);
  return { updated: true, action: 'updated' };
}

/**
 * 设置项目的 ignore 文件
 * @param {string[]} toolIds - 选择的 AI 工具 ID
 * @param {string} projectDir - 项目目录
 * @returns {object[]} - 结果数组
 */
function setupIgnoreFiles(toolIds, projectDir) {
  const results = [];

  // 更新 .gitignore
  const gitIgnorePath = path.join(projectDir, '.gitignore');
  const gitIgnoreEntries = getGitIgnoreEntries(toolIds);
  const gitResult = updateIgnoreFile(gitIgnorePath, gitIgnoreEntries);
  if (gitResult.updated) {
    results.push({ file: '.gitignore', action: gitResult.action });
  }

  // 更新 .npmignore
  const npmIgnorePath = path.join(projectDir, '.npmignore');
  const npmIgnoreEntries = getNpmIgnoreEntries();
  const npmResult = updateIgnoreFile(npmIgnorePath, npmIgnoreEntries);
  if (npmResult.updated) {
    results.push({ file: '.npmignore', action: npmResult.action });
  }

  return results;
}

function showVersion() {
  console.log(`${CLI_COMMAND} v${getCliVersion()}`);
}

// ============================================================================
// Skills 支持说明
// ============================================================================

function printSkillsSupportInfo() {
  console.log();
  console.log(chalk.bold('📚 Skills 支持级别说明'));
  console.log(chalk.gray('─'.repeat(50)));
  console.log();

  console.log(chalk.green('★ 完整 Skills') + chalk.gray(' - Claude Code, Codex CLI, OpenCode, Qoder, Every Code'));
  console.log(chalk.gray('   └ 独立的 Skills/Agents 系统，可按需调用，有独立上下文'));
  console.log();

  console.log(chalk.blue('◆ Rules 系统') + chalk.gray(' - Cursor, Windsurf, Gemini, Antigravity, Continue'));
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

async function promptInstallScope(projectDir, selectedTools) {
  // 检查是否有需要安装 Skills 的工具
  const fullSupportTools = selectedTools.filter(id => {
    const tool = AI_TOOLS.find(t => t.id === id);
    return tool && tool.skillsSupport === SKILLS_SUPPORT.FULL;
  });

  if (fullSupportTools.length === 0) {
    return INSTALL_SCOPE.PROJECT; // 没有完整 Skills 支持的工具，默认项目级
  }

  // 读取已保存的配置
  const config = loadConfig(projectDir);
  const savedScope = config.installScope;

  console.log();
  console.log(chalk.bold('📦 Skills 安装位置'));
  console.log(chalk.gray('─'.repeat(50)));
  console.log();

  const scope = await select({
    message: 'Skills 安装到哪里？',
    choices: [
      {
        name: `项目级 ${chalk.gray('(.claude/skills 等，仅当前项目可用)')}`,
        value: INSTALL_SCOPE.PROJECT,
        description: '推荐：Skills 随项目走，不影响其他项目'
      },
      {
        name: `全局 ${chalk.gray('(~/.claude/skills 等，所有项目共享)')}`,
        value: INSTALL_SCOPE.GLOBAL,
        description: '所有项目共享同一套 Skills'
      }
    ],
    default: savedScope || INSTALL_SCOPE.PROJECT
  });

  return scope;
}


// ============================================================================
// 安装 Skills（Claude Code, Codex CLI, Qoder）
// ============================================================================

function getSkillsDestDir(tool, scope, projectDir) {
  // 根据安装范围确定目标目录
  if (scope === INSTALL_SCOPE.PROJECT) {
    // 项目级安装：如果 skillsDir 是相对路径，使用项目目录
    if (tool.skillsDir && !path.isAbsolute(tool.skillsDir)) {
      return path.join(projectDir, tool.skillsDir);
    }
    // 兼容旧的硬编码逻辑
    if (tool.id === 'claude') {
      return path.join(projectDir, '.claude', 'skills');
    } else if (tool.id === 'codex') {
      return path.join(projectDir, '.codex', 'skills');
    } else if (tool.id === 'opencode') {
      return path.join(projectDir, '.opencode', 'skill');
    } else if (tool.id === 'code') {
      return path.join(projectDir, '.code', 'skills');
    }
  }
  // 全局安装：使用工具定义的全局目录
  return tool.skillsDir;
}

function installSkills(toolIds, projectDir, scope = INSTALL_SCOPE.GLOBAL, update = false) {
  const results = [];

  for (const toolId of toolIds) {
    const tool = AI_TOOLS.find(t => t.id === toolId);
    if (!tool || tool.skillsSupport !== SKILLS_SUPPORT.FULL) continue;

    // 所有支持完整 Skills 的工具
    if (tool.skillsDir) {
      const skillsSrcDir = path.join(__dirname, '..', 'skills');
      const skillsDestDir = getSkillsDestDir(tool, scope, projectDir);

      if (!fs.existsSync(skillsSrcDir)) continue;

      const skillDirs = fs.readdirSync(skillsSrcDir)
        .filter(name => name.startsWith('devbooks-'))
        .filter(name => fs.statSync(path.join(skillsSrcDir, name)).isDirectory());

      if (skillDirs.length === 0) continue;
      const skillNames = new Set(skillDirs);

      fs.mkdirSync(skillsDestDir, { recursive: true });

      // 先安装共享目录 _shared（如果存在）
      const sharedSrcDir = path.join(skillsSrcDir, '_shared');
      if (fs.existsSync(sharedSrcDir)) {
        const sharedDestDir = path.join(skillsDestDir, '_shared');
        if (update || !fs.existsSync(sharedDestDir)) {
          if (fs.existsSync(sharedDestDir)) {
            fs.rmSync(sharedDestDir, { recursive: true, force: true });
          }
          copyDirSync(sharedSrcDir, sharedDestDir);
        }
      }

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

      const removedCount = update ? pruneRemovedSkills(skillsDestDir, skillNames) : 0;

      results.push({
        tool: tool.name,
        type: 'skills',
        count: installedCount,
        total: skillDirs.length,
        removed: removedCount,
        scope: scope,
        path: skillsDestDir
      });
    }

    // Qoder: 创建 agents 目录结构（但不复制 Skills，因为格式不同）
    if (toolId === 'qoder') {
      results.push({ tool: 'Qoder', type: 'agents', count: 0, total: 0, note: '需要手动创建 agents/' });
    }
  }

  return results;
}

// ============================================================================
// OpenCode：安装项目级命令入口（.opencode/command/devbooks.md）
// ============================================================================

function generateOpenCodeDevbooksCommand() {
  return `---
description: DevBooks 工作流入口(OpenCode)
---

${DEVBOOKS_MARKERS.start}
# DevBooks(OpenCode)

本项目使用 DevBooks 工作流进行规格驱动开发。

## 快速开始

唯一入口：在对话中输入：\`/devbooks:delivery\`

> 说明：在 OpenCode 中，Skills 会作为可用的 Slash Commands 被加载，因此可以直接用 \`/<skill-name>\` 调用。

## 常用命令（直接用 /<skill-name>）

- \`/devbooks:delivery\`：唯一入口（自动路由到最小充分闭环）
- \`/devbooks-impact-analysis\`：影响分析（跨模块/对外契约）
- \`/devbooks-proposal-author\`：创建提案（禁止编码）
- \`/devbooks-design-doc\`：设计文档（What/Constraints + AC）
- \`/devbooks-implementation-plan\`：编码计划（tasks.md）
- \`/devbooks-test-owner\`：验收测试与追溯（独立对话）
- \`/devbooks-coder\`：按 tasks 实现（禁止改 tests/）
- \`/devbooks-archiver\`：归档前规格修剪

## 核心约束（必须遵守）

- 在回答任何问题或写任何代码前：先做配置发现并阅读规则文档（\`.devbooks/config.yaml\` → \`dev-playbooks/project.md\` → \`project.md\`）
- 新功能/破坏性变更/架构改动：必须先创建 \`dev-playbooks/changes/<id>/\` 并产出 proposal/design/tasks/verification
- Test Owner 与 Coder 必须在独立对话/独立实例中执行；Coder 禁止修改 \`tests/**\`

${DEVBOOKS_MARKERS.end}
`;
}

function installOpenCodeCommands(toolIds, projectDir, update = false) {
  const results = [];

  if (!toolIds.includes('opencode')) return results;

  const destDir = path.join(projectDir, '.opencode', 'command');
  fs.mkdirSync(destDir, { recursive: true });

  const destPath = path.join(destDir, 'devbooks.md');
  const content = generateOpenCodeDevbooksCommand();

  if (!fs.existsSync(destPath)) {
    fs.writeFileSync(destPath, content);
    results.push({ tool: 'OpenCode', type: 'command', path: destPath, action: 'created' });
  } else if (update) {
    const updated = updateManagedContent(destPath, content);
    if (updated) {
      results.push({ tool: 'OpenCode', type: 'command', path: destPath, action: 'updated' });
    }
  }

  return results;
}

// ============================================================================
// 安装 Claude Code 自定义子代理（解决内置子代理无法访问 Skills 的问题）
// ============================================================================

function installClaudeAgents(toolIds, projectDir, update = false) {
  const results = [];

  // 只有 Claude Code 需要安装自定义子代理
  if (!toolIds.includes('claude')) return results;

  const agentsSrcDir = path.join(__dirname, '..', 'templates', 'claude-agents');
  const agentsDestDir = path.join(projectDir, '.claude', 'agents');

  if (!fs.existsSync(agentsSrcDir)) return results;

  const agentFiles = fs.readdirSync(agentsSrcDir)
    .filter(name => name.endsWith('.md'));

  if (agentFiles.length === 0) return results;

  fs.mkdirSync(agentsDestDir, { recursive: true });

  let installedCount = 0;
  for (const agentFile of agentFiles) {
    const srcPath = path.join(agentsSrcDir, agentFile);
    const destPath = path.join(agentsDestDir, agentFile);

    if (fs.existsSync(destPath) && !update) continue;

    fs.copyFileSync(srcPath, destPath);
    installedCount++;
  }

  if (installedCount > 0) {
    results.push({
      tool: 'Claude Code',
      type: 'agents',
      count: installedCount,
      total: agentFiles.length,
      path: agentsDestDir
    });
  }

  return results;
}

// ============================================================================
// 安装 Rules（Cursor, Windsurf, Gemini, Antigravity, OpenCode, Continue）
// ============================================================================

function installRules(toolIds, projectDir, update = false) {
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
        results.push({ tool: tool.name, type: 'rules', path: rulePath, action: 'created' });
      } else if (update) {
        // 更新已存在的文件中 DEVBOOKS:START/END 之间的内容
        const updated = updateManagedContent(rulePath, ruleContent);
        if (updated) {
          results.push({ tool: tool.name, type: 'rules', path: rulePath, action: 'updated' });
        }
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

## 工作流 Skills

| Skill | 说明 |
|------|------|
| \`devbooks-proposal-author\` | 创建变更提案 |
| \`devbooks-design-doc\` | 创建设计文档 |
| \`devbooks-test-owner / devbooks-coder\` | 执行实现 |
| \`devbooks-archiver\` | 归档变更包 |

${DEVBOOKS_MARKERS.end}
`;
}

// ============================================================================
// 安装自定义指令文件
// ============================================================================

function installInstructionFiles(toolIds, projectDir, update = false) {
  const results = [];

  for (const toolId of toolIds) {
    const tool = AI_TOOLS.find(t => t.id === toolId);
    if (!tool) continue;

    // GitHub Copilot 特殊处理
    if (toolId === 'github-copilot') {
      const instructionsDir = path.join(projectDir, '.github', 'instructions');
      fs.mkdirSync(instructionsDir, { recursive: true });

      const copilotInstructionPath = path.join(projectDir, '.github', 'copilot-instructions.md');
      const copilotContent = generateCopilotInstructions();
      if (!fs.existsSync(copilotInstructionPath)) {
        fs.writeFileSync(copilotInstructionPath, copilotContent);
        results.push({ tool: 'GitHub Copilot', type: 'instructions', path: copilotInstructionPath, action: 'created' });
      } else if (update) {
        const updated = updateManagedContent(copilotInstructionPath, copilotContent);
        if (updated) {
          results.push({ tool: 'GitHub Copilot', type: 'instructions', path: copilotInstructionPath, action: 'updated' });
        }
      }

      // 创建 devbooks.instructions.md
      const devbooksInstructionPath = path.join(instructionsDir, 'devbooks.instructions.md');
      const devbooksContent = generateCopilotDevbooksInstructions();
      if (!fs.existsSync(devbooksInstructionPath)) {
        fs.writeFileSync(devbooksInstructionPath, devbooksContent);
        results.push({ tool: 'GitHub Copilot', type: 'instructions', path: devbooksInstructionPath, action: 'created' });
      } else if (update) {
        const updated = updateManagedContent(devbooksInstructionPath, devbooksContent);
        if (updated) {
          results.push({ tool: 'GitHub Copilot', type: 'instructions', path: devbooksInstructionPath, action: 'updated' });
        }
      }
    }

    // 创建 AGENTS.md / CLAUDE.md / GEMINI.md
    if (tool.instructionFile && !tool.instructionFile.includes('/')) {
      const instructionPath = path.join(projectDir, tool.instructionFile);
      const instructionContent = generateAgentsContent(tool.instructionFile);
      if (!fs.existsSync(instructionPath)) {
        fs.writeFileSync(instructionPath, instructionContent);
        results.push({ tool: tool.name, type: 'instruction', path: instructionPath, action: 'created' });
      } else if (update) {
        const updated = updateManagedContent(instructionPath, instructionContent);
        if (updated) {
          results.push({ tool: tool.name, type: 'instruction', path: instructionPath, action: 'updated' });
        }
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

## 语言偏好

**默认使用中文**：除非明确要求使用其他语言，否则所有输出都应使用中文，包括：
- 文档内容
- 代码注释
- 提交信息
- 规格说明

## 工作流

当请求满足以下条件时，始终打开 \`@/AGENTS.md\`：
- 提及规划或提案（如 proposal、spec、change、plan 等词语）
- 引入新功能、破坏性变更、架构变更或重大性能/安全工作
- 请求不明确，需要在编码前了解权威规格

使用 \`@/AGENTS.md\` 了解：
- 如何创建和应用变更提案
- 规格格式和约定
- 项目结构和指南

保持此托管块，以便 'devbooks update' 可以刷新说明。

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

function saveConfig(toolIds, projectDir, installScope = INSTALL_SCOPE.PROJECT) {
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

  // 更新 install_scope 部分
  const scopeYaml = `install_scope: ${installScope}`;

  if (configContent.includes('install_scope:')) {
    // 替换现有的 install_scope 部分
    configContent = configContent.replace(/install_scope:.*/, scopeYaml);
  } else {
    // 追加 install_scope 部分
    configContent = configContent.trimEnd() + '\n\n' + scopeYaml + '\n';
  }

  fs.writeFileSync(configPath, configContent);
}

function loadConfig(projectDir) {
  const configPath = path.join(projectDir, '.devbooks', 'config.yaml');

  if (!fs.existsSync(configPath)) {
    return { aiTools: [], installScope: null };
  }

  const content = fs.readFileSync(configPath, 'utf-8');

  // 解析 ai_tools
  // 修复：使用更健壮的正则，匹配到下一个顶级 key（非缩进的行）或文件结尾
  const toolsMatch = content.match(/ai_tools:\s*\n((?:[ \t]+-[ \t]+.+\n?)*)/);
  const tools = toolsMatch
    ? toolsMatch[1]
        .split('\n')
        .map(line => line.trim())
        .filter(line => line.startsWith('-'))
        .map(line => line.replace(/^-\s*/, '').trim())
        .filter(line => line.length > 0)
    : [];

  // 解析 install_scope
  const scopeMatch = content.match(/install_scope:\s*(\w+)/);
  const installScope = scopeMatch ? scopeMatch[1] : null;

  return { aiTools: tools, installScope };
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
  let installScope = INSTALL_SCOPE.PROJECT; // 默认项目级安装

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

    // 非交互式模式下，检查 --scope 选项
    if (options.scope) {
      installScope = options.scope === 'global' ? INSTALL_SCOPE.GLOBAL : INSTALL_SCOPE.PROJECT;
    }
  } else {
    selectedTools = await promptToolSelection(projectDir);

    // 交互式选择安装范围
    installScope = await promptInstallScope(projectDir, selectedTools);
  }

  // 创建项目结构
  const spinner = ora('创建项目结构...').start();
  const templateCount = createProjectStructure(projectDir);
  spinner.succeed(`创建了 ${templateCount} 个模板文件`);

  // 保存配置（包含安装范围）
  saveConfig(selectedTools, projectDir, installScope);

  if (selectedTools.length === 0) {
    console.log();
    console.log(chalk.green('✓') + ' DevBooks 项目结构已创建！');
    console.log(chalk.gray(`  运行 \`${CLI_COMMAND} init\` 并选择 AI 工具来配置集成。`));
    return;
  }

  // 安装 Skills（仅完整支持的工具）
  const fullSupportTools = selectedTools.filter(id => {
    const tool = AI_TOOLS.find(t => t.id === id);
    return tool && tool.skillsSupport === SKILLS_SUPPORT.FULL;
  });

  if (fullSupportTools.length > 0) {
    const skillsSpinner = ora('安装 Skills...').start();
    const skillsResults = installSkills(fullSupportTools, projectDir, installScope);
    skillsSpinner.succeed('Skills 安装完成');

    for (const result of skillsResults) {
      if (result.count > 0) {
        const scopeLabel = result.scope === INSTALL_SCOPE.PROJECT ? '项目级' : '全局';
        console.log(chalk.gray(`  └ ${result.tool}: ${result.count}/${result.total} 个 ${result.type} (${scopeLabel})`));
        if (result.path) {
          console.log(chalk.gray(`    → ${result.path}`));
        }
      } else if (result.note) {
        console.log(chalk.gray(`  └ ${result.tool}: ${result.note}`));
      }
    }

    // 安装 Claude Code 自定义子代理（解决内置子代理无法访问 Skills 的问题）
    const agentsResults = installClaudeAgents(fullSupportTools, projectDir);
    for (const result of agentsResults) {
      if (result.count > 0) {
        console.log(chalk.gray(`  └ ${result.tool}: ${result.count} 个自定义子代理 → ${result.path}`));
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

  // OpenCode：安装项目级命令入口（.opencode/command/devbooks.md）
  const openCodeCmdResults = installOpenCodeCommands(selectedTools, projectDir);
  for (const result of openCodeCmdResults) {
    console.log(chalk.gray(`  └ ${result.tool}: ${path.relative(projectDir, result.path)}`));
  }

  // 设置 ignore 文件
  const ignoreSpinner = ora('配置 ignore 文件...').start();
  const ignoreResults = setupIgnoreFiles(selectedTools, projectDir);
  if (ignoreResults.length > 0) {
    ignoreSpinner.succeed('ignore 文件已配置');
    for (const result of ignoreResults) {
      console.log(chalk.gray(`  └ ${result.file}: ${result.action === 'created' ? '已创建' : '已更新'}`));
    }
  } else {
    ignoreSpinner.succeed('ignore 文件无需更新');
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
  console.log(`  2. 使用 ${chalk.cyan('devbooks-proposal-author')} Skill 创建第一个变更提案`);
  console.log();
}

// ============================================================================
// Update 命令
// ============================================================================

async function updateCommand(projectDir) {
  console.log();
  console.log(chalk.bold('DevBooks 更新'));
  console.log();

  // 1. 检查 CLI 自身是否有新版本
  const spinner = ora('检查 CLI 更新...').start();
  const { hasUpdate, latestVersion, currentVersion } = await checkNpmUpdate();

  if (hasUpdate) {
    spinner.info(`发现新版本: ${currentVersion} → ${latestVersion}`);

    // 显示版本变更摘要
    console.log();
    await displayVersionChangelog(currentVersion, latestVersion);
    console.log();

    const shouldUpdate = await confirm({
      message: `是否更新 ${CLI_COMMAND} 到 ${latestVersion}?`,
      default: true
    });

    if (shouldUpdate) {
      const success = await performNpmUpdate();
      if (success) {
        console.log(chalk.blue('ℹ') + ` 请重新运行 \`${CLI_COMMAND} update\` 以更新项目文件。`);
        return;
      }
      // 更新失败，继续更新本地文件
    }
  } else {
    spinner.succeed(`CLI 已是最新版本 (v${currentVersion})`);
  }

  console.log();

  // 2. 检查是否已初始化（更新项目文件）
  const configPath = path.join(projectDir, '.devbooks', 'config.yaml');
  if (!fs.existsSync(configPath)) {
    console.log(chalk.red('✗') + ` 未找到 DevBooks 配置。请先运行 \`${CLI_COMMAND} init\`。`);
    process.exit(1);
  }

  // 加载配置
  const config = loadConfig(projectDir);
  const configuredTools = config.aiTools;
  const installScope = config.installScope || INSTALL_SCOPE.PROJECT;

  if (configuredTools.length === 0) {
    console.log(chalk.yellow('⚠') + ` 未配置任何 AI 工具。运行 \`${CLI_COMMAND} init\` 进行配置。`);
    return;
  }

  const toolNames = configuredTools.map(id => {
    const tool = AI_TOOLS.find(t => t.id === id);
    return tool ? tool.name : id;
  });
  const scopeLabel = installScope === INSTALL_SCOPE.PROJECT ? '项目级' : '全局';
  console.log(chalk.blue('ℹ') + ` 检测到已配置的工具: ${toolNames.join(', ')} (${scopeLabel}安装)`);

  // 更新 Skills（使用配置中保存的安装范围）
  const skillsResults = installSkills(configuredTools, projectDir, installScope, true);
  for (const result of skillsResults) {
    if (result.count > 0) {
      console.log(chalk.green('✓') + ` ${result.tool} ${result.type}: 更新了 ${result.count}/${result.total} 个`);
      if (result.path) {
        console.log(chalk.gray(`    → ${result.path}`));
      }
    }
    if (result.removed && result.removed > 0) {
      console.log(chalk.green('✓') + ` ${result.tool} ${result.type}: 清理了 ${result.removed} 个已删除的技能`);
    }
  }

  // 更新 Claude Code 自定义子代理（项目目录）
  const agentsResults = installClaudeAgents(configuredTools, projectDir, true);
  for (const result of agentsResults) {
    if (result.count > 0) {
      console.log(chalk.green('✓') + ` ${result.tool}: 更新了 ${result.count} 个自定义子代理`);
    }
  }

  // 更新 Rules（项目目录）
  const rulesTools = configuredTools.filter(id => {
    const tool = AI_TOOLS.find(t => t.id === id);
    return tool && tool.skillsSupport === SKILLS_SUPPORT.RULES;
  });

  if (rulesTools.length > 0) {
    const rulesResults = installRules(rulesTools, projectDir, true);
    for (const result of rulesResults) {
      if (result.action === 'updated') {
        console.log(chalk.green('✓') + ` ${result.tool}: 更新了规则文件`);
      }
    }
  }

  // 更新指令文件（项目目录）
  const instructionResults = installInstructionFiles(configuredTools, projectDir, true);
  for (const result of instructionResults) {
    if (result.action === 'updated') {
      console.log(chalk.green('✓') + ` ${result.tool}: 更新了指令文件 ${path.relative(projectDir, result.path)}`);
    }
  }

  // OpenCode：更新项目级命令入口（.opencode/command/devbooks.md）
  const openCodeCmdResults = installOpenCodeCommands(configuredTools, projectDir, true);
  for (const result of openCodeCmdResults) {
    if (result.action === 'updated') {
      console.log(chalk.green('✓') + ` ${result.tool}: 更新了命令入口 ${path.relative(projectDir, result.path)}`);
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
    console.log(chalk.red('✗') + ' 请指定迁移来源：--from <legacy-id>');
    console.log();
    console.log(chalk.cyan('示例:'));
    console.log(`  ${CLI_COMMAND} migrate --from legacy --dry-run`);
    console.log(`  ${CLI_COMMAND} migrate --from <legacy-id> --dry-run`);
    process.exit(1);
  }

  // legacy-id must be a simple identifier; actual scripts are resolved under scripts/legacy/
  if (!/^[a-z0-9][a-z0-9_-]*$/.test(from)) {
    console.log(chalk.red('✗') + ` 非法 legacy-id: ${from}`);
    console.log(chalk.gray('  允许字符: a-z, 0-9, "_" , "-" (且必须以字母/数字开头)'));
    process.exit(1);
  }

  // 确定脚本路径
  const scriptName = `migrate-from-${from}.sh`;
  const scriptPath = path.join(__dirname, '..', 'scripts', 'legacy', scriptName);

  if (!fs.existsSync(scriptPath)) {
    console.log(chalk.red('✗') + ` 迁移脚本不存在: ${scriptPath}`);
    const legacyDir = path.join(__dirname, '..', 'scripts', 'legacy');
    console.log(chalk.gray(`  可用迁移脚本位于: ${legacyDir}`));
    console.log(chalk.gray('  下一步: 在该目录下查找 migrate-from-<legacy-id>.sh，并将 <legacy-id> 传给 --from'));
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

function showStartHelp() {
  console.log();
  console.log(chalk.bold('DevBooks Delivery') + ' - 唯一入口与路由指引');
  console.log();
  console.log(chalk.cyan('用法:'));
  console.log(`  ${CLI_COMMAND} delivery [options]`);
  console.log();
  console.log(chalk.cyan('说明:'));
  console.log('  本命令仅提供入口指引，不执行 AI 或调用 Skills。');
  console.log('  所有任务都从 Delivery 进入，由它负责路由到最小充分闭环。');
  console.log();
  console.log(chalk.cyan('入口模板:'));
  console.log(`  ${ENTRY_TEMPLATES.delivery}`);
  console.log();
  console.log(chalk.cyan('入口文档:'));
  console.log(`  ${ENTRY_DOC}`);
}

function showHelp() {
  console.log();
  console.log(chalk.bold('DevBooks') + ' - AI-agnostic spec-driven development workflow');
  console.log();
  console.log(chalk.cyan('用法:'));
  console.log(`  ${CLI_COMMAND} init [path] [options]              初始化 DevBooks`);
  console.log(`  ${CLI_COMMAND} update [path]                      更新 CLI 和已配置的工具`);
  console.log(`  ${CLI_COMMAND} migrate --from <legacy-id> [options] 从其他工作流迁移`);
  console.log(`  ${CLI_COMMAND} delivery [options]                唯一入口指引（不执行 AI）`);
  console.log();
  console.log(chalk.cyan('选项:'));
  console.log('  --tools <tools>    非交互式指定 AI 工具');
  console.log('                     可用值: all, none, 或逗号分隔的工具 ID');
  console.log('  --scope <scope>    Skills 安装位置 (非交互式模式)');
  console.log('                     可用值: project (默认), global');
  console.log('  --from <legacy-id> 迁移来源');
  console.log('                     可用值: legacy-id（查看 scripts/legacy/）');
  console.log('  --dry-run          只打印动作，不实际修改文件');
  console.log('  --keep-old         迁移后保留原目录');
  console.log('  --force            强制覆盖已有文件（谨慎使用）');
  console.log('  -h, --help         显示此帮助信息');
  console.log('  -v, --version      显示版本号');
  console.log();
  console.log(chalk.cyan('入口模板与文档:'));
  console.log(`  Delivery 模板: ${ENTRY_TEMPLATES.delivery}`);
  console.log(`  Index 模板:  ${ENTRY_TEMPLATES.index}`);
  console.log(`  入口文档:    ${ENTRY_DOC}`);
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
  console.log(`  ${CLI_COMMAND} init --tools claude,cursor  # 非交互式（默认项目级安装）`);
  console.log(`  ${CLI_COMMAND} init --tools claude --scope global  # 非交互式（全局安装）`);
  console.log(`  ${CLI_COMMAND} update                      # 更新 CLI 和 Skills`);
  console.log(`  ${CLI_COMMAND} migrate --from legacy       # 通用 legacy 迁移（如可用）`);
  console.log(`  ${CLI_COMMAND} migrate --from <legacy-id>  # 指定迁移来源（对应 scripts/legacy/ 下脚本）`);
  console.log(`  ${CLI_COMMAND} migrate --from <legacy-id> --dry-run  # 先预览变更`);
  console.log(`  ${CLI_COMMAND} delivery                    # 查看唯一入口指引`);
}

// ============================================================================
// 主入口
// ============================================================================

async function startCommand() {
  showStartHelp();
}

async function main() {
  const args = process.argv.slice(2);

  // 解析参数
  let command = null;
  let projectPath = null;
  const options = { help: false };

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];

    if (arg === '-h' || arg === '--help') {
      options.help = true;
    } else if (arg === '-v' || arg === '--version') {
      showVersion();
      process.exit(0);
    } else if (arg === '--tools') {
      options.tools = args[++i];
    } else if (arg === '--scope') {
      options.scope = args[++i];
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
    if (options.help) {
      if (command === 'delivery') {
        showStartHelp();
        return;
      }
      showHelp();
      return;
    }
    if (command === 'init' || !command) {
      await initCommand(projectDir, options);
    } else if (command === 'update') {
      await updateCommand(projectDir);
    } else if (command === 'migrate') {
      await migrateCommand(projectDir, options);
    } else if (command === 'delivery') {
      await startCommand();
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
