#!/usr/bin/env node
/**
 * DevBooks MCP Server
 *
 * 功能：
 * 1. 拦截代码相关请求，自动注入 Augment 风格的上下文
 * 2. 自动检查/生成 SCIP 索引
 * 3. 注入热点信息、影响分析建议
 *
 * 架构：
 * Claude Code → DevBooks MCP → CKB MCP / 其他工具
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  ListPromptsRequestSchema,
  GetPromptRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { execSync, exec } from "child_process";
import { existsSync, statSync, readFileSync } from "fs";
import { join } from "path";

// 意图检测关键词
const CODE_INTENT_PATTERNS = [
  // 修改代码
  /修复|fix|bug|错误|问题/i,
  /重构|refactor|优化|改进/i,
  /添加|新增|实现|add|implement|feature/i,
  /删除|移除|remove|delete/i,
  /修改|更新|change|update|modify/i,
  // 代码分析
  /分析|analyze|影响|impact/i,
  /查找|搜索|find|search|引用|reference/i,
  /调用|call|依赖|depend/i,
  /这个函数|这个类|这个方法|this function|this class/i,
  // 文件操作
  /\.ts|\.tsx|\.js|\.jsx|\.py|\.go|\.rs|\.java/i,
  /src\/|lib\/|app\//i,
];

// 非代码意图（排除）
const NON_CODE_PATTERNS = [
  /天气|weather/i,
  /翻译|translate/i,
  /写邮件|write email/i,
  /聊天|chat|闲聊/i,
];

interface ProjectContext {
  projectRoot: string;
  hasScipIndex: boolean;
  indexAge: number | null; // hours
  language: string | null;
  hotspots: string[];
  truthRoot: string | null;
  changeRoot: string | null;
}

class DevBooksMcpServer {
  private server: Server;
  private projectRoot: string;

  constructor() {
    this.projectRoot = process.cwd();
    this.server = new Server(
      {
        name: "devbooks-mcp-server",
        version: "1.0.0",
      },
      {
        capabilities: {
          tools: {},
          prompts: {},
        },
      }
    );

    this.setupHandlers();
  }

  private setupHandlers() {
    // 列出可用工具
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: [
        {
          name: "devbooks_analyze_context",
          description: "分析当前项目上下文，返回 Augment 风格的代码分析信息（热点、索引状态、建议）",
          inputSchema: {
            type: "object",
            properties: {
              query: {
                type: "string",
                description: "用户的原始请求（用于意图检测）",
              },
              targetFiles: {
                type: "array",
                items: { type: "string" },
                description: "要分析的目标文件路径（可选）",
              },
            },
            required: ["query"],
          },
        },
        {
          name: "devbooks_ensure_index",
          description: "确保 SCIP 索引存在，如果不存在则自动生成",
          inputSchema: {
            type: "object",
            properties: {
              force: {
                type: "boolean",
                description: "强制重新生成索引",
              },
            },
          },
        },
        {
          name: "devbooks_get_hotspots",
          description: "获取项目热点文件（高频修改 + 高复杂度）",
          inputSchema: {
            type: "object",
            properties: {
              limit: {
                type: "number",
                description: "返回的热点数量（默认 10）",
              },
            },
          },
        },
        {
          name: "devbooks_smart_analyze",
          description: "智能分析请求，提取符号和文件，返回推荐的 CKB 工具调用",
          inputSchema: {
            type: "object",
            properties: {
              query: {
                type: "string",
                description: "用户的原始请求",
              },
              files: {
                type: "array",
                items: { type: "string" },
                description: "相关文件列表（可选）",
              },
            },
            required: ["query"],
          },
        },
      ],
    }));

    // 列出可用 prompts
    this.server.setRequestHandler(ListPromptsRequestSchema, async () => ({
      prompts: [
        {
          name: "devbooks_code_context",
          description: "获取代码相关请求的增强上下文",
          arguments: [
            {
              name: "query",
              description: "用户的原始请求",
              required: true,
            },
          ],
        },
      ],
    }));

    // 获取 prompt
    this.server.setRequestHandler(GetPromptRequestSchema, async (request) => {
      if (request.params.name === "devbooks_code_context") {
        const query = request.params.arguments?.query as string || "";
        const context = await this.getProjectContext();
        const isCodeRelated = this.detectCodeIntent(query);

        if (!isCodeRelated) {
          return {
            messages: [
              {
                role: "user",
                content: {
                  type: "text",
                  text: query,
                },
              },
            ],
          };
        }

        // 注入增强上下文
        const enhancedContext = this.buildEnhancedContext(context, query);

        return {
          messages: [
            {
              role: "user",
              content: {
                type: "text",
                text: `${enhancedContext}\n\n---\n\n${query}`,
              },
            },
          ],
        };
      }

      throw new Error(`Unknown prompt: ${request.params.name}`);
    });

    // 处理工具调用
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      switch (name) {
        case "devbooks_analyze_context":
          return this.handleAnalyzeContext(args as { query: string; targetFiles?: string[] });

        case "devbooks_ensure_index":
          return this.handleEnsureIndex(args as { force?: boolean });

        case "devbooks_get_hotspots":
          return this.handleGetHotspots(args as { limit?: number });

        case "devbooks_smart_analyze":
          return this.handleSmartAnalyze(args as { query: string; files?: string[] });

        default:
          throw new Error(`Unknown tool: ${name}`);
      }
    });
  }

  private detectCodeIntent(query: string): boolean {
    // 先检查是否明确非代码意图
    for (const pattern of NON_CODE_PATTERNS) {
      if (pattern.test(query)) {
        return false;
      }
    }

    // 再检查是否为代码意图
    for (const pattern of CODE_INTENT_PATTERNS) {
      if (pattern.test(query)) {
        return true;
      }
    }

    return false;
  }

  private async getProjectContext(): Promise<ProjectContext> {
    const indexPath = join(this.projectRoot, "index.scip");
    const hasScipIndex = existsSync(indexPath);

    let indexAge: number | null = null;
    if (hasScipIndex) {
      const stat = statSync(indexPath);
      indexAge = Math.floor((Date.now() - stat.mtimeMs) / (1000 * 60 * 60));
    }

    const language = this.detectLanguage();
    const hotspots = this.getHotspots(10);
    const { truthRoot, changeRoot } = this.detectRoots();

    return {
      projectRoot: this.projectRoot,
      hasScipIndex,
      indexAge,
      language,
      hotspots,
      truthRoot,
      changeRoot,
    };
  }

  private detectLanguage(): string | null {
    if (existsSync(join(this.projectRoot, "package.json")) ||
        existsSync(join(this.projectRoot, "tsconfig.json"))) {
      return "typescript";
    }
    if (existsSync(join(this.projectRoot, "pyproject.toml")) ||
        existsSync(join(this.projectRoot, "setup.py")) ||
        existsSync(join(this.projectRoot, "requirements.txt"))) {
      return "python";
    }
    if (existsSync(join(this.projectRoot, "go.mod"))) {
      return "go";
    }
    if (existsSync(join(this.projectRoot, "Cargo.toml"))) {
      return "rust";
    }
    return null;
  }

  private detectRoots(): { truthRoot: string | null; changeRoot: string | null } {
    // 检查 OpenSpec
    if (existsSync(join(this.projectRoot, "openspec/project.md"))) {
      return {
        truthRoot: "openspec/specs",
        changeRoot: "openspec/changes",
      };
    }

    // 检查 .devbooks/config.yaml
    const configPath = join(this.projectRoot, ".devbooks/config.yaml");
    if (existsSync(configPath)) {
      try {
        const content = readFileSync(configPath, "utf-8");
        const truthMatch = content.match(/truth_root:\s*["']?([^"'\n]+)/);
        const changeMatch = content.match(/change_root:\s*["']?([^"'\n]+)/);
        return {
          truthRoot: truthMatch?.[1] || "specs",
          changeRoot: changeMatch?.[1] || "changes",
        };
      } catch {
        // ignore
      }
    }

    // 默认
    if (existsSync(join(this.projectRoot, "specs"))) {
      return { truthRoot: "specs", changeRoot: "changes" };
    }

    return { truthRoot: null, changeRoot: null };
  }

  private getHotspots(limit: number): string[] {
    try {
      // 使用 git log 获取热点文件
      const result = execSync(
        `git log --since="30 days ago" --name-only --pretty=format: 2>/dev/null | grep -v '^$' | grep -v 'node_modules\\|dist\\|build\\|\\.lock' | sort | uniq -c | sort -rn | head -${limit}`,
        { cwd: this.projectRoot, encoding: "utf-8" }
      );

      return result
        .split("\n")
        .filter(Boolean)
        .map((line) => {
          const match = line.trim().match(/^\s*(\d+)\s+(.+)$/);
          if (match) {
            return `${match[2]} (${match[1]} changes)`;
          }
          return line.trim();
        });
    } catch {
      return [];
    }
  }

  private buildEnhancedContext(context: ProjectContext, query: string): string {
    const lines: string[] = ["[DevBooks 自动注入上下文]", ""];

    // 索引状态
    if (context.hasScipIndex) {
      if (context.indexAge && context.indexAge > 24) {
        lines.push(`⚠️ SCIP 索引已过期（${context.indexAge}h），建议更新`);
      } else {
        lines.push(`✅ SCIP 索引可用，图基分析已启用`);
      }
    } else {
      lines.push(`⚠️ SCIP 索引不存在，将自动生成或降级为文本搜索`);
      if (context.language) {
        lines.push(`   检测到 ${context.language} 项目`);
      }
    }

    // 热点文件
    if (context.hotspots.length > 0) {
      lines.push("");
      lines.push("🔥 热点文件（近30天高频修改）：");
      context.hotspots.slice(0, 5).forEach((h, i) => {
        const marker = i < 2 ? "🔴" : i < 5 ? "🟡" : "🟢";
        lines.push(`   ${marker} ${h}`);
      });
    }

    // DevBooks 配置
    if (context.truthRoot) {
      lines.push("");
      lines.push(`📁 DevBooks 配置：`);
      lines.push(`   truth-root: ${context.truthRoot}`);
      lines.push(`   change-root: ${context.changeRoot}`);
    }

    // 建议
    lines.push("");
    lines.push("💡 建议：");
    lines.push("   - 修改热点文件时请增加测试覆盖");
    lines.push("   - 使用 mcp__ckb__analyzeImpact 分析影响范围");
    lines.push("   - 使用 mcp__ckb__findReferences 查找引用");

    return lines.join("\n");
  }

  private async handleAnalyzeContext(args: { query: string; targetFiles?: string[] }) {
    const context = await this.getProjectContext();
    const isCodeRelated = this.detectCodeIntent(args.query);

    const result: Record<string, unknown> = {
      isCodeRelated,
      projectContext: {
        language: context.language,
        hasScipIndex: context.hasScipIndex,
        indexAge: context.indexAge,
        truthRoot: context.truthRoot,
        changeRoot: context.changeRoot,
      },
    };

    if (isCodeRelated) {
      result.hotspots = context.hotspots;
      result.enhancedContext = this.buildEnhancedContext(context, args.query);

      // 检查目标文件是否为热点
      if (args.targetFiles) {
        const hotspotFiles = context.hotspots.map(h => h.split(" ")[0]);
        result.targetFileRisks = args.targetFiles.map(f => ({
          file: f,
          isHotspot: hotspotFiles.some(hf => f.includes(hf)),
          risk: hotspotFiles.findIndex(hf => f.includes(hf)),
        }));
      }
    }

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(result, null, 2),
        },
      ],
    };
  }

  private async handleEnsureIndex(args: { force?: boolean }) {
    const indexPath = join(this.projectRoot, "index.scip");

    if (!args.force && existsSync(indexPath)) {
      const stat = statSync(indexPath);
      const ageHours = Math.floor((Date.now() - stat.mtimeMs) / (1000 * 60 * 60));

      if (ageHours < 24) {
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                status: "exists",
                message: `索引已存在且新鲜（${ageHours}h 前更新）`,
                indexPath,
              }),
            },
          ],
        };
      }
    }

    const language = this.detectLanguage();
    if (!language) {
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              status: "unsupported",
              message: "无法检测项目语言，不支持自动生成索引",
            }),
          },
        ],
      };
    }

    const indexCommands: Record<string, { check: string; cmd: string; install: string }> = {
      typescript: {
        check: "scip-typescript",
        cmd: "scip-typescript index --output index.scip",
        install: "npm install -g @sourcegraph/scip-typescript",
      },
      python: {
        check: "scip-python",
        cmd: "scip-python index . --output index.scip",
        install: "pip install scip-python",
      },
      go: {
        check: "scip-go",
        cmd: "scip-go --output index.scip",
        install: "go install github.com/sourcegraph/scip-go@latest",
      },
    };

    const config = indexCommands[language];
    if (!config) {
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              status: "unsupported",
              message: `暂不支持 ${language} 项目的自动索引`,
            }),
          },
        ],
      };
    }

    // 检查索引器是否安装
    try {
      execSync(`which ${config.check}`, { encoding: "utf-8" });
    } catch {
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              status: "indexer_missing",
              message: `索引器 ${config.check} 未安装`,
              installCommand: config.install,
            }),
          },
        ],
      };
    }

    // 生成索引
    try {
      execSync(config.cmd, { cwd: this.projectRoot, encoding: "utf-8" });

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              status: "generated",
              message: "索引生成成功",
              indexPath,
            }),
          },
        ],
      };
    } catch (error) {
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({
              status: "error",
              message: `索引生成失败: ${error}`,
            }),
          },
        ],
      };
    }
  }

  private async handleGetHotspots(args: { limit?: number }) {
    const limit = args.limit || 10;
    const hotspots = this.getHotspots(limit);

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify({
            count: hotspots.length,
            hotspots,
            risk: {
              critical: hotspots.slice(0, 2),
              high: hotspots.slice(2, 5),
              normal: hotspots.slice(5),
            },
          }, null, 2),
        },
      ],
    };
  }

  private async handleSmartAnalyze(args: { query: string; files?: string[] }) {
    const context = await this.getProjectContext();
    const query = args.query.toLowerCase();

    // 提取潜在的符号名（函数名、类名等）
    const symbolPatterns = [
      /(?:function|函数|方法|class|类)\s+[`"']?(\w+)[`"']?/gi,
      /(\w+)\s*\(\s*\)/g,  // function calls
      /(?:修改|修复|重构|删除|添加)\s*[`"']?(\w+)[`"']?/gi,
    ];

    const extractedSymbols: string[] = [];
    for (const pattern of symbolPatterns) {
      let match;
      while ((match = pattern.exec(args.query)) !== null) {
        if (match[1] && match[1].length > 2) {
          extractedSymbols.push(match[1]);
        }
      }
    }

    // 提取文件路径
    const filePatterns = [
      /[\w\-\/]+\.(ts|tsx|js|jsx|py|go|rs|java)/gi,
      /src\/[\w\-\/]+/gi,
      /lib\/[\w\-\/]+/gi,
    ];

    const extractedFiles: string[] = args.files || [];
    for (const pattern of filePatterns) {
      let match;
      while ((match = pattern.exec(args.query)) !== null) {
        extractedFiles.push(match[0]);
      }
    }

    // 检测意图类型
    const intentType = this.detectIntentType(query);

    // 构建推荐的 CKB 工具调用
    const recommendations: Array<{
      tool: string;
      reason: string;
      priority: "high" | "medium" | "low";
      suggestedParams?: Record<string, unknown>;
    }> = [];

    // 根据意图类型推荐工具
    if (intentType.includes("impact") || intentType.includes("refactor")) {
      recommendations.push({
        tool: "mcp__ckb__analyzeImpact",
        reason: "评估代码修改的影响范围",
        priority: "high",
        suggestedParams: extractedSymbols.length > 0
          ? { symbolId: `搜索 ${extractedSymbols[0]}` }
          : undefined,
      });
    }

    if (intentType.includes("reference") || intentType.includes("usage")) {
      recommendations.push({
        tool: "mcp__ckb__findReferences",
        reason: "查找符号的所有引用位置",
        priority: "high",
      });
    }

    if (intentType.includes("call") || intentType.includes("dependency")) {
      recommendations.push({
        tool: "mcp__ckb__getCallGraph",
        reason: "分析调用关系和依赖",
        priority: "medium",
      });
    }

    if (extractedSymbols.length > 0) {
      recommendations.push({
        tool: "mcp__ckb__searchSymbols",
        reason: `搜索符号: ${extractedSymbols.join(", ")}`,
        priority: "high",
        suggestedParams: { query: extractedSymbols[0] },
      });
    }

    // 检查热点重叠
    const hotspotFiles = context.hotspots.map(h => h.split(" ")[0]);
    const hotspotOverlap = extractedFiles.filter(f =>
      hotspotFiles.some(hf => f.includes(hf) || hf.includes(f))
    );

    // 构建结果
    const result = {
      analysis: {
        intentTypes: intentType,
        extractedSymbols,
        extractedFiles,
        isCodeRelated: this.detectCodeIntent(args.query),
      },
      context: {
        hasScipIndex: context.hasScipIndex,
        indexAge: context.indexAge,
        language: context.language,
      },
      hotspotWarning: hotspotOverlap.length > 0 ? {
        message: "部分文件为热点区域，请谨慎修改",
        files: hotspotOverlap,
      } : null,
      recommendations,
      nextSteps: this.buildNextSteps(recommendations, context),
    };

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(result, null, 2),
        },
      ],
    };
  }

  private detectIntentType(query: string): string[] {
    const intents: string[] = [];

    if (/影响|impact|范围|scope/i.test(query)) intents.push("impact");
    if (/重构|refactor|优化/i.test(query)) intents.push("refactor");
    if (/引用|reference|使用|usage|调用/i.test(query)) intents.push("reference");
    if (/调用图|call.*graph|依赖|depend/i.test(query)) intents.push("call");
    if (/修复|fix|bug|错误/i.test(query)) intents.push("bugfix");
    if (/添加|add|新增|implement/i.test(query)) intents.push("feature");
    if (/删除|remove|移除/i.test(query)) intents.push("remove");

    return intents.length > 0 ? intents : ["general"];
  }

  private buildNextSteps(
    recommendations: Array<{ tool: string; reason: string; priority: string }>,
    context: ProjectContext
  ): string[] {
    const steps: string[] = [];

    // 索引检查
    if (!context.hasScipIndex) {
      steps.push("1. 先运行 devbooks_ensure_index 生成 SCIP 索引以启用图分析");
    } else if (context.indexAge && context.indexAge > 24) {
      steps.push("1. 建议运行 devbooks_ensure_index --force 更新过期的索引");
    }

    // 根据推荐添加步骤
    const highPriority = recommendations.filter(r => r.priority === "high");
    highPriority.forEach((r, i) => {
      steps.push(`${steps.length + 1}. 调用 ${r.tool}: ${r.reason}`);
    });

    // 通用建议
    if (context.hotspots.length > 0) {
      steps.push(`${steps.length + 1}. 注意热点文件风险，考虑增加测试覆盖`);
    }

    return steps;
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error("DevBooks MCP Server running on stdio");
  }
}

const server = new DevBooksMcpServer();
server.run().catch(console.error);
