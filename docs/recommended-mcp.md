# Configured MCP Servers

> Detailed configuration and usage guide for MCP servers recommended by this project
>
> Date: 2025-12-30
> Configuration Level: User Scope (available for all projects)

---

## Table of Contents

1. [Overview](#overview)
2. [TaskMaster AI](#taskmaster-ai)
3. [CKB (Code Knowledge Backend)](#ckb-code-knowledge-backend)
4. [tree-sitter-mcp](#tree-sitter-mcp)
5. [Context7](#context7)
6. [GitHub MCP Server](#github-mcp-server)
7. [Playwright MCP](#playwright-mcp)
8. [Configuration Location](#configuration-location)

---

## Overview

### Currently Configured MCP Servers

| Server | Type | Scope | Primary Function |
|--------|------|-------|------------------|
| **task-master** | Task Management | User Scope | AI-driven task management system |
| **ckb** | Code Analysis | User Scope | Code symbol search, reference finding |
| **tree-sitter-mcp** | Code Search | User Scope | Semantic code search and analysis |
| **context7** | Code Documentation | User Scope | Real-time retrieval of latest library documentation and code examples |
| **github** | GitHub Integration | User Scope | GitHub repository, Issues, PR management and automation |
| **playwright** | Browser Automation | User Scope | Web automation testing, scraping and interaction |

**Configuration File**: `~/.claude.json` (top-level `mcpServers` field)

**Scope**: All projects

---

## TaskMaster AI

### Basic Information

- **npm package**: `task-master-ai`
- **Type**: AI-driven task management system
- **Installation**: npx (automatic download)
- **Official Documentation**: [https://docs.task-master.dev](https://docs.task-master.dev)
- **GitHub**: [eyaltoledano/claude-task-master](https://github.com/eyaltoledano/claude-task-master)

### Features

- **Task Management**: Create, update, delete, search tasks
- **Priority Management**: Set task priorities (high, medium, low)
- **Status Tracking**: To-do, in progress, completed
- **Smart Analysis**: AI-driven task analysis and suggestions
- **Natural Language Interaction**: Manage tasks through conversation
- **Multi-model Support**: Supports Claude, GPT, and other AI models

### Configuration

```json
{
  "mcpServers": {
    "task-master": {
      "command": "npx",
      "args": ["-y", "task-master-ai"],
      "env": {
        "ANTHROPIC_API_KEY": "sk-...",
        "ANTHROPIC_BASE_URL": "https://anyrouter.top",
        "OPENAI_API_KEY": "sk-...",
        "OPENAI_BASE_URL": "https://anyrouter.top/v1",
        "TASK_MASTER_TOOLS": "core"
      }
    }
  }
}
```

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | Yes | API Key for Claude model |
| `ANTHROPIC_BASE_URL` | No | Custom Anthropic API endpoint |
| `OPENAI_API_KEY` | No | API Key for OpenAI GPT model |
| `OPENAI_BASE_URL` | No | Custom OpenAI API endpoint |
| `TASK_MASTER_TOOLS` | No | Enabled toolset: `core`/`standard`/`all`/custom comma-separated list |

### Toolsets (TASK_MASTER_TOOLS)

> Note: `task-master-ai` reads `TASK_MASTER_TOOLS` (not `TASK_MASTER_TOOL_MODE`).

Common values:

- `core`: Minimal toolset (default/recommended)
- `standard`: Standard toolset
- `all`: Enable all tools
- `tool_a,tool_b,...`: Custom tool whitelist (comma-separated)

**Currently using**: `core` mode

### Usage Examples

**Create task**:
```
Use task-master to create a task: Complete MCP configuration documentation
```

**List tasks**:
```
Use task-master to list all pending tasks
```

**Update task status**:
```
Use task-master to mark the task as completed
```

**Search tasks**:
```
Use task-master to search for tasks about "documentation"
```

### Model Configuration (Optional)

To specify the AI model to use, you can create a configuration file:

```bash
# Interactive configuration
npx task-master-ai models --setup

# Or set directly
npx task-master-ai models --set-main=gpt-4o
npx task-master-ai models --set-research=claude-3-5-sonnet-20241022
npx task-master-ai models --set-fallback=gpt-3.5-turbo
```

Configuration file location: `~/.taskmaster/config.json`

### Supported API Providers

- Anthropic (Claude)
- OpenAI (GPT-4, GPT-3.5)
- Perplexity
- Google (Gemini)
- Mistral
- Groq
- OpenRouter
- xAI (Grok)
- Azure OpenAI
- Ollama (Local)

---

## CKB (Code Knowledge Backend)

### Basic Information

- **Version**: 7.5.0
- **Type**: Language-agnostic code understanding layer
- **Installation Location**: `/usr/local/bin/ckb`
- **GitHub**: [simplyliz/codemcp](https://github.com/simplyliz/codemcp)

### Features

- **Symbol Search**: Quickly find functions, classes, variables
- **Find References**: Locate all usage locations of a symbol
- **Impact Analysis**: Assess the impact scope of code modifications
- **Architecture View**: Project structure and dependency relationships
- **Git Integration**: Blame information and history tracking

### Backend Support

- **LSP** (Language Server Protocol): Supports Python, TypeScript, Go, etc.
- **SCIP**: Pre-computed index (for Go/Java/TypeScript)
- **Git**: Repository history and blame information

### Configuration

```json
{
  "mcpServers": {
    "ckb": {
      "command": "/usr/local/bin/ckb",
      "args": ["mcp"]
    }
  }
}
```

### Installation Steps

#### 1. Install CKB Binary

```bash
# Clone the repository
cd ~/Projects/mcps
git clone https://github.com/simplyliz/codemcp.git
cd codemcp

# Set Go proxy (for users in China)
export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.google.cn

# Build
go build -o ckb ./cmd/ckb

# Install to system path
sudo cp ckb /usr/local/bin/ckb
sudo chmod +x /usr/local/bin/ckb

# Verify installation
ckb --version
```

#### 2. Install Python LSP Support

```bash
pip3 install python-lsp-server

# Verify installation
python3 -m pylsp --version
```

#### 3. Initialize CKB for Project

```bash
cd /path/to/your/project
ckb init
```

This creates the `.ckb/config.json` configuration file.

### Project Configuration File

Location: `project/.ckb/config.json`

```json
{
  "backends": {
    "lsp": {
      "enabled": true,
      "servers": {
        "python": {
          "command": "python3",
          "args": ["-m", "pylsp"]
        }
      }
    },
    "git": {
      "enabled": true
    }
  }
}
```

### Usage Examples

**Search symbols**:
```
Use CKB to search for FastAPI symbols in the project
```

**Find references**:
```
Use CKB to find all references to the get_user function
```

**Impact analysis**:
```
Use CKB to analyze the impact of modifying the User class
```

### Common Commands

```bash
# View system status
ckb status

# Search symbols
ckb search <symbol_name>

# Find references
ckb refs <symbol_name>

# Get architecture overview
ckb arch

# Run diagnostics
ckb doctor
```

### Supported Languages

- Python (via LSP)
- TypeScript/JavaScript (via LSP)
- Go (via SCIP + LSP)
- Java (via SCIP)
- Any project with Git history

### Notes

**Important**: Each project needs separate initialization. Although the CKB MCP server is User Scope (globally available), each project needs to run `ckb init` to create project-specific configuration.

---

## tree-sitter-mcp

### Basic Information

- **npm package**: `@nendo/tree-sitter-mcp`
- **Type**: Semantic code search
- **Installation**: npx (automatic download)
- **GitHub**: [nendo/tree-sitter-mcp](https://github.com/nendo/tree-sitter-mcp)

### Features

- **Real-time Code Parsing**: No pre-generated index required
- **Semantic Search**: Search that understands code structure
- **AST Queries**: Abstract syntax tree level analysis
- **Multi-language Support**: Supports mainstream programming languages
- **Lightweight**: No complex configuration required

### Configuration

```json
{
  "mcpServers": {
    "tree-sitter-mcp": {
      "command": "npx",
      "args": ["-y", "@nendo/tree-sitter-mcp", "--mcp"]
    }
  }
}
```

### Characteristics

- Auto-installs on first use
- Automatically updates to latest version
- No local installation maintenance required
- Works with any project (no initialization needed)
- Zero configuration

### Usage Examples

**Analyze file structure**:
```
Use tree-sitter to analyze the structure of backend/main.py
```

**Find function definitions**:
```
Use tree-sitter to find all async function definitions
```

**Code pattern search**:
```
Use tree-sitter to search for all try-except blocks
```

### Supported Languages

- Python
- JavaScript/TypeScript
- Go
- Rust
- C/C++
- Java
- Ruby
- And more...

### Feature Comparison

| Feature | tree-sitter-mcp | CKB |
|---------|----------------|-----|
| Installation Complexity | Simple (automatic) | Medium (requires compilation) |
| Project Initialization | Not required | Required |
| Semantic Understanding | Medium | High |
| Reference Finding | Basic | Complete |
| Use Case | Quick search | Deep analysis |

---

## Context7

### Basic Information

- **npm package**: `@upstash/context7-mcp`
- **Version**: 2.0.0+
- **Type**: Real-time code documentation service
- **Installation**: npx (automatic download)
- **Official Website**: [context7.com](https://context7.com)
- **GitHub**: [upstash/context7](https://github.com/upstash/context7)

### Features

- **Real-time Documentation**: Get latest, version-specific library documentation
- **Code Examples**: Directly retrieve latest code examples and API usage
- **Library Matching**: Smart identification and matching of libraries used in project
- **Seamless Integration**: No need to switch tabs to check documentation
- **Avoid Hallucinations**: Eliminate outdated code suggestions and non-existent APIs
- **Broad Support**: Supports mainstream libraries and frameworks

### Configuration

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    }
  }
}
```

**Configuration with API Key** (optional, for higher rate limits and private repositories):

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"],
      "env": {
        "CONTEXT7_API_KEY": "your-api-key"
      }
    }
  }
}
```

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `CONTEXT7_API_KEY` | No | Context7 API Key (optional, for higher rate limits and private repository access) |

**Get API Key**: Visit [context7.com/dashboard](https://context7.com/dashboard) to create an account and get your key.

### Available Tools

Context7 provides the following tools for LLM use:

1. **resolve-library-id**: Resolve library name to Context7-compatible library ID
   - `query` (required): User's question or task
   - `libraryName` (required): Library name to search for

2. **query-docs**: Retrieve documentation using library ID
   - `libraryId` (required): Context7 library ID (e.g., `/mongodb/docs`)
   - `query` (required): Question or task to get relevant documentation for

### Usage Examples

#### Basic Usage (Recommended Rule)

Add a rule in CLAUDE.md or settings to automatically call Context7:

```markdown
Always use context7 when I need code generation, setup or configuration steps, or
library/API documentation. This means you should automatically use the Context7 MCP
tools to resolve library id and get library docs without me having to explicitly ask.
```

After adding this rule, just ask directly:

```
Create a Next.js middleware that checks for valid JWT in cookies,
and redirects unauthenticated users to /login
```

#### Manual Trigger

If no rule is set, add `use context7` to your prompt:

```
Configure Cloudflare Worker script to cache JSON API responses for 5 minutes. use context7
```

#### Specifying Library ID (Advanced)

If you know the exact library ID, you can specify it directly:

```
Implement basic authentication using Supabase.
use library /supabase/supabase for API and docs.
```

### Supported Libraries and Frameworks

Context7 supports thousands of libraries, including but not limited to:

**Web Frameworks**:
- Next.js, React, Vue, Angular, Svelte
- Express, Fastify, Koa, NestJS

**Cloud Services**:
- AWS SDK, Google Cloud, Azure
- Cloudflare Workers, Vercel, Netlify

**Databases**:
- MongoDB, PostgreSQL, MySQL
- Supabase, Firebase, PlanetScale

**Utility Libraries**:
- Lodash, Axios, Prisma
- TailwindCSS, shadcn/ui

**Find more**: Visit [context7.com](https://context7.com) to search for available libraries.

### Characteristics

- **Zero Configuration**: Auto-installs on first use
- **Auto Update**: npx automatically uses latest version
- **Version Aware**: Get version-specific documentation
- **Community Driven**: Libraries contributed and maintained by community
- **Lightweight**: No local indexing or preprocessing required

### Proxy Configuration

Context7 supports standard HTTPS proxy environment variables:

```bash
export https_proxy=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080
```

### Feature Comparison

| Feature | Context7 | CKB | tree-sitter-mcp |
|---------|----------|-----|-----------------|
| Installation Complexity | Simple (automatic) | Medium (requires compilation) | Simple (automatic) |
| Documentation Source | Online latest | Local code | Local code |
| Version Specific | Yes | No | No |
| Code Examples | Yes - Latest | No | No |
| Offline Use | No | Yes | Yes |
| Use Case | Library docs | Analyze local code | Search local code |

### Troubleshooting

#### Context7 Connection Failure

**Common causes**:
- Network connection issues
- Proxy configuration errors
- Rate limiting (without API Key)

**Solutions**:
```bash
# Test connection
curl -I https://api.context7.com

# Check proxy settings
echo $https_proxy

# Get API Key to increase rate limits
# Visit context7.com/dashboard
```

#### Library Not Found

**Solutions**:
1. Check library name spelling
2. Visit [context7.com](https://context7.com) to search for available libraries
3. If library doesn't exist, you can submit an addition request

#### Slow First Run

**Reason**: npx needs to download the package (normal behavior)

**Solution**: Wait for download to complete, subsequent runs will be fast

---

## GitHub MCP Server

### Basic Information

- **Docker Image**: `ghcr.io/github/github-mcp-server`
- **Version**: 0.26.3+
- **Type**: GitHub platform integration
- **Installation**: Docker (recommended) or source build
- **Official Repository**: [github/github-mcp-server](https://github.com/github/github-mcp-server)
- **Maintainer**: GitHub Official

### Features

- **Repository Management**: Browse code, search files, analyze commits, understand project structure
- **Issue & PR Automation**: Create, update, manage Issues and Pull Requests
- **CI/CD Intelligence**: Monitor GitHub Actions workflows, analyze build failures, manage releases
- **Code Analysis**: Check security findings, review Dependabot alerts, code pattern analysis
- **Team Collaboration**: Access discussions, manage notifications, analyze team activity
- **Multi-function Toolset**: Supports Gists, Labels, Projects, Stargazers, etc.

### Configuration

#### Basic Configuration (Docker)

```json
{
  "mcpServers": {
    "github": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-e",
        "GITHUB_PERSONAL_ACCESS_TOKEN",
        "ghcr.io/github/github-mcp-server"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "YOUR_GITHUB_PAT_HERE"
      }
    }
  }
}
```

#### Configuration with Toolsets

```json
{
  "mcpServers": {
    "github": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-e",
        "GITHUB_PERSONAL_ACCESS_TOKEN",
        "-e",
        "GITHUB_TOOLSETS",
        "ghcr.io/github/github-mcp-server"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "YOUR_GITHUB_PAT_HERE",
        "GITHUB_TOOLSETS": "repos,issues,pull_requests,actions"
      }
    }
  }
}
```

#### GitHub Enterprise Configuration

For GitHub Enterprise Server or Enterprise Cloud with data residency (ghe.com):

```json
{
  "mcpServers": {
    "github": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-e",
        "GITHUB_PERSONAL_ACCESS_TOKEN",
        "-e",
        "GITHUB_HOST",
        "ghcr.io/github/github-mcp-server"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "YOUR_GITHUB_PAT_HERE",
        "GITHUB_HOST": "https://your-ghes-domain.com"
      }
    }
  }
}
```

### Getting a GitHub Personal Access Token (PAT)

#### Step 1: Create PAT

1. Visit [GitHub Settings > Developer settings > Personal access tokens > Tokens (classic)](https://github.com/settings/tokens)
2. Click **Generate new token** > **Generate new token (classic)**
3. Fill in Token description (e.g., "Claude Code MCP")
4. Select expiration time (90 days recommended)
5. Select required permissions (Scopes)

#### Step 2: Recommended Permission Scopes

**Basic permissions** (read-only access):
- `repo` - Full repository access (including private repos)
- `read:org` - Read organization info
- `read:user` - Read user info

**Full functionality** (read-write access):
- `repo` - Full repository access
- `workflow` - Update GitHub Actions workflows
- `admin:org` - Manage organization (if needed)
- `gist` - Create and manage Gists
- `notifications` - Access notifications
- `user` - User info
- `read:discussion` - Read discussions
- `write:discussion` - Write discussions

#### Step 3: Save Token

**Important**: Copy the generated Token and save it to a secure location. You won't be able to view it again after leaving the page!

#### Step 4: Configure in Claude Code

Add the Token to the `~/.claude.json` configuration file:

```json
{
  "mcpServers": {
    "github": {
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxxxxxxxxxxxxxxxxxxx"
      }
    }
  }
}
```

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `GITHUB_PERSONAL_ACCESS_TOKEN` | Yes | GitHub Personal Access Token |
| `GITHUB_TOOLSETS` | No | Enabled toolsets (comma-separated) |
| `GITHUB_TOOLS` | No | Enabled specific tools (comma-separated) |
| `GITHUB_HOST` | No | GitHub Enterprise hostname |
| `GITHUB_READ_ONLY` | No | Read-only mode (set to `1` to enable) |
| `GITHUB_LOCKDOWN_MODE` | No | Lockdown mode (set to `1` to enable) |
| `GITHUB_DYNAMIC_TOOLSETS` | No | Dynamic toolset discovery (set to `1` to enable) |

### Available Toolsets

GitHub MCP Server supports controlling available features through toolsets:

#### Default Toolsets (when not configured)

- `context` - User and GitHub context information
- `repos` - Repository management
- `issues` - Issue management
- `pull_requests` - PR management
- `users` - User information

#### All Available Toolsets

| Toolset | Description |
|---------|-------------|
| `context` | Current user and GitHub context (strongly recommended) |
| `actions` | GitHub Actions workflows and CI/CD |
| `code_security` | Code security scanning |
| `dependabot` | Dependabot tools |
| `discussions` | GitHub Discussions |
| `gists` | GitHub Gist |
| `git` | Git API low-level operations |
| `issues` | Issue management |
| `labels` | Label management |
| `notifications` | Notification management |
| `orgs` | Organization management |
| `projects` | GitHub Projects |
| `pull_requests` | Pull Request management |
| `repos` | Repository management |
| `secret_protection` | Secret scanning |
| `security_advisories` | Security advisories |
| `stargazers` | Star management |
| `users` | User information |

#### Special Toolsets

- `all` - Enable all available toolsets
- `default` - Default configuration (context, repos, issues, pull_requests, users)

### Usage Examples

#### Repository Management

```
Use GitHub MCP to list all my repositories
```

```
Get file content from owner/repo repository: src/main.py
```

```
Search for files containing "authentication" in owner/repo
```

#### Issue Management

```
Create a new Issue in owner/repo: title "Fix Login Bug", description "Users cannot login"
```

```
List all open Issues in owner/repo
```

```
Add comment to Issue #123: "Fixed, please test"
```

#### Pull Request Management

```
Create PR in owner/repo: from feature-branch to main
```

```
List all pending review PRs in owner/repo
```

```
Get review comments for PR #456
```

#### CI/CD Monitoring

```
View recent GitHub Actions run status in owner/repo
```

```
Get logs for workflow run ID 123456
```

### Toolset Configuration Examples

#### Read-Only Mode (Recommended for Beginners)

```json
{
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxx",
    "GITHUB_READ_ONLY": "1"
  }
}
```

#### Specify Toolsets

```json
{
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxx",
    "GITHUB_TOOLSETS": "repos,issues,pull_requests,actions"
  }
}
```

#### Enable All Tools

```json
{
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxx",
    "GITHUB_TOOLSETS": "all"
  }
}
```

#### Dynamic Toolset Discovery

```json
{
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxx",
    "GITHUB_DYNAMIC_TOOLSETS": "1"
  }
}
```

### Characteristics

- **Official Support**: Maintained by GitHub
- **Complete Features**: Covers most GitHub platform APIs
- **Flexible Configuration**: Supports toolsets, read-only mode, lockdown mode
- **Enterprise Support**: Supports GitHub Enterprise Server and Cloud
- **Containerized**: Runs with Docker, environment isolation
- **Auto Update**: Docker image automatically fetches latest version

### Prerequisites

#### 1. Docker Installation

Ensure Docker is installed:

```bash
# Check if Docker is installed
docker --version

# If not installed, visit https://docs.docker.com/get-docker/
```

#### 2. Docker Running Status

```bash
# Ensure Docker is running
docker ps

# If error, start Docker Desktop or Docker service
```

#### 3. Pull Image (Optional)

Will auto-pull on first use, or pull in advance:

```bash
docker pull ghcr.io/github/github-mcp-server
```

### Feature Comparison

| Feature | GitHub MCP | CKB | tree-sitter-mcp |
|---------|-----------|-----|-----------------|
| Installation Complexity | Medium (requires Docker) | Medium (requires compilation) | Simple (automatic) |
| GitHub Integration | Complete | No | No |
| Local Code Analysis | No | Yes | Yes |
| Issue/PR Management | Yes | No | No |
| CI/CD Monitoring | Yes | No | No |
| Requires Network | Yes | No | No |
| Requires Authentication | Yes PAT | No | No |

### Troubleshooting

#### Docker Related Issues

**Issue: Docker image pull failure**

```bash
# Check Docker login status
docker logout ghcr.io

# Re-pull image
docker pull ghcr.io/github/github-mcp-server
```

**Issue: Docker not running**

```bash
# macOS: Start Docker Desktop
open -a Docker

# Linux: Start Docker service
sudo systemctl start docker
```

#### Permission Issues

**Issue: PAT insufficient permissions**

Check Token permissions:
1. Visit [GitHub Settings > Tokens](https://github.com/settings/tokens)
2. Click Token name
3. Check and add missing permissions
4. Regenerate Token (if needed)

**Issue: API rate limiting**

GitHub API has rate limits:
- Unauthenticated: 60 requests/hour
- Authenticated: 5000 requests/hour

Using PAT significantly increases the limit.

#### Connection Issues

**Issue: Cannot connect to GitHub**

```bash
# Test network connection
curl -I https://api.github.com

# If using proxy, configure Docker proxy
# Edit ~/.docker/config.json
```

**Issue: GitHub Enterprise connection failure**

Ensure `GITHUB_HOST` is configured correctly:
- GitHub Enterprise Server: `https://your-ghes.com`
- GitHub Enterprise Cloud (ghe.com): `https://yourorg.ghe.com`

#### Tool Related Issues

**Issue: Tools not showing**

Check toolset configuration:
```bash
# View current configuration
cat ~/.claude.json | grep -A 20 '"github"'

# Try enabling all tools
# Add "GITHUB_TOOLSETS": "all" in configuration
```

**Issue: Read-only operation failure**

If only read permissions are needed, use read-only mode:
```json
{
  "env": {
    "GITHUB_READ_ONLY": "1"
  }
}
```

### Security Best Practices

#### 1. Token Management

- **Don't commit**: Never commit PAT to Git repository
- **Regular rotation**: Rotate Token every 90 days recommended
- **Least privilege**: Only grant necessary permissions
- **Timely revocation**: Revoke Token immediately when no longer needed

#### 2. Permission Control

- Use read-only mode (`GITHUB_READ_ONLY=1`) for exploration
- Use toolsets to limit available features
- Use lockdown mode (`GITHUB_LOCKDOWN_MODE=1`) for production environment

#### 3. Audit

- Regularly check [GitHub Security Log](https://github.com/settings/security-log)
- Monitor Token usage
- Detect anomalous activity promptly

---

## Playwright MCP

### Basic Information

- **npm package**: `@playwright/mcp@latest`
- **Version**: 0.0.54+
- **Type**: Browser automation
- **Installation**: npx (automatic download)
- **Official Repository**: [microsoft/playwright-mcp](https://github.com/microsoft/playwright-mcp)
- **Official Website**: [playwright.dev](https://playwright.dev)
- **Maintainer**: Microsoft Official

### Features

- **Browser Automation**: Automate browser operations using Playwright
- **No Vision Model Required**: Based on Accessibility Tree instead of screenshots, fast and lightweight
- **Deterministic Tools**: Avoid ambiguity of screenshot-based approaches
- **Multi-browser Support**: Chrome, Firefox, WebKit (Safari), Microsoft Edge
- **Page Interaction**: Click, input, navigation, form submission, etc.
- **Content Extraction**: Get page text, element information
- **Test Assertions**: Optional testing functionality support
- **PDF Generation**: Optional PDF export functionality
- **Visual Features**: Optional coordinate clicking (requires vision capability)

### Configuration

#### Basic Configuration (Recommended)

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest"
      ]
    }
  }
}
```

#### Configuration with Parameters

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--browser=chrome",
        "--viewport-size=1280x720",
        "--timeout-action=10000"
      ]
    }
  }
}
```

#### Headless Mode Configuration

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--headless"
      ]
    }
  }
}
```

### Common Configuration Parameters

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| `--browser` | Browser type | chrome | chrome, firefox, webkit, msedge |
| `--headless` | Run in headless mode | false (show browser) | --headless |
| `--viewport-size` | Browser window size | default size | --viewport-size=1280x720 |
| `--device` | Emulate device | none | --device="iPhone 15" |
| `--timeout-action` | Action timeout (ms) | 5000 | --timeout-action=10000 |
| `--timeout-navigation` | Navigation timeout (ms) | 60000 | --timeout-navigation=30000 |
| `--user-agent` | Custom UA | default UA | --user-agent="Custom UA" |
| `--ignore-https-errors` | Ignore HTTPS errors | false | --ignore-https-errors |
| `--caps` | Extra capabilities | none | --caps=vision,pdf,testing |

### Advanced Configuration Options

#### Proxy Configuration

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--proxy-server=http://myproxy:3128",
        "--proxy-bypass=.com,chromium.org"
      ]
    }
  }
}
```

#### Persistent User Data

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--user-data-dir=/path/to/profile"
      ]
    }
  }
}
```

#### Isolated Session

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--isolated",
        "--storage-state=/path/to/state.json"
      ]
    }
  }
}
```

#### Enable Extra Capabilities

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--caps=vision,pdf,testing"
      ]
    }
  }
}
```

### User Profile Locations

Playwright MCP uses persistent profiles by default to store login state:

**macOS**:
```
~/Library/Caches/ms-playwright/mcp-{channel}-profile
```

**Linux**:
```
~/.cache/ms-playwright/mcp-{channel}-profile
```

**Windows**:
```
%USERPROFILE%\AppData\Local\ms-playwright\mcp-{channel}-profile
```

Use `--user-data-dir` parameter to customize location.

### Core Tools

Playwright MCP provides the following core automation tools:

#### 1. Browser Management
- **Open browser**: Launch new browser instance
- **Close browser**: Close current browser
- **New tab**: Create new tab
- **Switch tab**: Switch between tabs
- **Close tab**: Close specified tab

#### 2. Page Operations
- **Navigate**: Visit URL
- **Click**: Click page element
- **Type text**: Enter content in input field
- **Select**: Dropdown menu selection
- **Submit form**: Submit form data
- **Scroll**: Page scroll operations

#### 3. Content Extraction
- **Get page snapshot**: Get structured page content (Accessibility Tree)
- **Extract text**: Get element text content
- **Get attributes**: Read element attributes
- **Screenshot**: Save page screenshot (requires vision)

#### 4. Wait Operations
- **Wait for element**: Wait for element to appear
- **Wait for navigation**: Wait for page load completion
- **Wait for condition**: Wait for custom condition to be met

### Optional Features (enabled via --caps)

#### Vision Feature
Enable coordinate-based clicking:
```bash
--caps=vision
```

Features:
- Click elements based on coordinates
- Requires vision model support
- Suitable for complex page layouts

#### PDF Feature
Enable PDF generation:
```bash
--caps=pdf
```

Features:
- Generate page PDF
- Custom PDF options
- Save to specified path

#### Testing Feature
Enable test assertions:
```bash
--caps=testing
```

Features:
- expect() assertions
- Element visibility checks
- Content match validation

#### Tracing Feature
Enable debug tracing:
```bash
--caps=tracing
```

Features:
- Record operation traces
- Performance analysis
- Debug assistance

### Usage Examples

#### Basic Browsing

```
Use Playwright to open browser and visit https://example.com
```

#### Form Filling

```
Use Playwright:
1. Visit https://forms.example.com
2. Enter "testuser" in #username
3. Enter "password123" in #password
4. Click #submit button
```

#### Content Extraction

```
Use Playwright to visit https://news.example.com and extract all article titles
```

#### Web Testing

```
Use Playwright to test login flow:
1. Visit login page
2. Enter credentials
3. Submit form
4. Verify redirect to dashboard
```

#### Save Screenshot

```
Use Playwright to visit https://example.com and save screenshot
```

### Use Cases

#### Suitable for:

- **Web Testing**: Automated UI testing, E2E testing
- **Data Scraping**: Extract data from dynamic web pages
- **Form Automation**: Automatically fill and submit forms
- **Page Screenshots**: Batch generate web page screenshots
- **PDF Generation**: Convert web pages to PDF
- **Web Monitoring**: Periodically check web page changes
- **SPA Interaction**: Interact with React, Vue, and other single-page apps
- **E-commerce Operations**: Automated shopping flow testing

#### Not suitable for:

- **Large-scale Crawling**: Not suitable for high-frequency large-scale scraping (performance overhead)
- **Real-time Monitoring**: High browser resource usage
- **Simple API Calls**: HTTP clients are more efficient

### Characteristics

- **Zero Configuration**: Auto-installs on first use
- **Auto Update**: npx automatically uses latest version
- **Cross-browser**: Supports Chrome, Firefox, WebKit, Edge
- **Fast and Reliable**: Based on Accessibility Tree, faster than visual methods
- **Mobile Emulation**: Supports mobile device emulation
- **Network Control**: Can intercept and modify network requests
- **File Upload/Download**: Supports file operations
- **Multiple Tabs**: Parallel operations on multiple tabs

### Prerequisites

#### 1. Node.js

```bash
# Check Node.js version (requires 18+)
node --version

# If version is too low, please upgrade Node.js
```

#### 2. Browsers (auto-installs on first run)

Playwright will automatically download required browsers on first run:
- Chromium (for Chrome)
- Firefox
- WebKit (for Safari)

Manual installation:
```bash
npx playwright install
```

### Browser Extension Mode (Advanced)

Connect to existing browser using Chrome extension:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--extension"
      ]
    }
  }
}
```

**Prerequisites**:
1. Install "Playwright MCP Bridge" Chrome extension
2. Only supports Edge/Chrome
3. Can use existing logged-in browser sessions

**Use cases**:
- Leverage existing browser state and login sessions
- No need to re-login
- Suitable for operations requiring authenticated state

### Feature Comparison

| Feature | Playwright MCP | Selenium | Puppeteer |
|---------|---------------|----------|-----------|
| Installation Complexity | Simple (automatic) | Complex (requires driver) | Simple |
| Multi-browser Support | Complete | Complete | Chrome only |
| Speed | Fast | Slow | Fast |
| API Design | Modern | Traditional | Modern |
| Mobile Emulation | Yes | Partial | Yes |
| Claude Code Integration | Native | No | No |
| LLM Friendly | Structured | No | No |

### Security and Limitations

#### Website Access Control

Limit allowed websites:

```bash
--allowed-origins="https://example.com;https://trusted.com"
```

Or block specific websites:

```bash
--blocked-origins="https://malicious.com"
```

**Important**: This is not a security boundary, only serves as a guardrail.

#### Service Workers

Block Service Workers:

```bash
--block-service-workers
```

#### Sandbox Mode

Browser sandbox is enabled by default. May need to disable in certain environments (like Docker):

```bash
--no-sandbox
```

**Warning**: Disabling sandbox reduces security, use only when necessary.

### Troubleshooting

#### Browser Not Installed

**Issue**: Missing browser prompt on first run

**Solution**:
```bash
# Manually install all browsers
npx playwright install

# Or install specific browser
npx playwright install chromium
```

#### Slow First Run

**Reason**: npx needs to download package and browsers (normal behavior)

**Solution**: Wait for download to complete, subsequent runs will be fast

#### Debugging Difficulty in Headless Mode

**Solution**:
1. Remove `--headless` parameter to see browser
2. Enable tracing: `--caps=tracing`
3. Save screenshots for debugging

#### Timeout Errors

**Issue**: Operation timeout

**Solution**:
```bash
# Increase timeout
--timeout-action=30000
--timeout-navigation=90000
```

#### Permission Errors

**Issue**: Certain permissions required (like geolocation, notifications)

**Solution**:
```bash
--grant-permissions=geolocation,clipboard-read,clipboard-write
```

#### Docker Environment Issues

**Issue**: Running fails in Docker

**Solution**:
```dockerfile
# Dockerfile example
FROM mcr.microsoft.com/playwright:v1.48.0-noble

WORKDIR /app

# Install dependencies
RUN npm install -g playwright

# Use --no-sandbox at runtime
CMD ["npx", "@playwright/mcp@latest", "--headless", "--no-sandbox"]
```

### Standalone Server Mode (Advanced)

Run standalone HTTP server on systems without display or when remote access is needed:

```bash
# Start server
npx @playwright/mcp@latest --port 8931

# In MCP client configuration
{
  "mcpServers": {
    "playwright": {
      "url": "http://localhost:8931/mcp"
    }
  }
}
```

**Characteristics**:
- HTTP transport
- Suitable for remote access
- Suitable for headless environments

### Configuration File

Use configuration file to manage complex settings:

```json
// playwright-mcp-config.json
{
  "browser": "chrome",
  "headless": true,
  "viewport": { "width": 1280, "height": 720 },
  "ignoreHTTPSErrors": true,
  "timeout": {
    "action": 10000,
    "navigation": 60000
  },
  "proxy": {
    "server": "http://myproxy:3128",
    "bypass": ".com,chromium.org"
  }
}
```

Use configuration file:
```bash
--config=/path/to/config.json
```

### Comparison with GitHub MCP Server

| Feature | Playwright MCP | GitHub MCP |
|---------|---------------|-----------|
| Installation Complexity | Simple (npx) | Medium (Docker) |
| Primary Use | Browser automation | GitHub integration |
| Requires Authentication | No (some sites need it) | Yes PAT |
| Network Dependency | Yes | Yes |
| Resource Usage | High (browser) | Low |
| Use Case | Web testing/scraping | Code repository management |

### Collaboration with Other MCP Servers

Playwright can work collaboratively with other MCP servers:

#### + Context7
- Playwright visits documentation websites
- Context7 gets latest API documentation
- Combined use for dynamically generated documentation

#### + GitHub MCP
- Playwright tests GitHub Pages websites
- GitHub MCP manages source code
- Automated post-deployment testing flow

#### + tree-sitter-mcp
- tree-sitter analyzes local test files
- Playwright runs browser tests
- Full-stack test coverage

### Best Practices

#### 1. Choose Appropriate Mode

```bash
# Development debugging: show browser
--browser=chrome

# Production environment: headless mode
--headless

# CI/CD: headless + sandbox disabled
--headless --no-sandbox
```

#### 2. Optimize Performance

```bash
# Reduce timeout
--timeout-action=3000

# Use persistent session to avoid repeated login
--user-data-dir=~/.playwright-profile

# Reuse browser context
--shared-browser-context
```

#### 3. Save Debug Information

```bash
# Save session
--save-session

# Save trace
--save-trace

# Save video
--save-video=1280x720
```

#### 4. Permission Management

```bash
# Grant necessary permissions
--grant-permissions=geolocation,notifications

# Limit access domains
--allowed-origins="https://trusted.com"
```

### Update Playwright MCP

```bash
# npx automatically uses latest version
# No manual update needed

# Clear cache if needed
npx clear-npx-cache

# Reinstall browsers
npx playwright install
```

---

## Configuration Location

### User Scope Configuration

**File**: `~/.claude.json`

**Structure**:
```json
{
  "mcpServers": {
    "task-master": { ... },
    "ckb": { ... },
    "tree-sitter-mcp": { ... },
    "context7": { ... },
    "github": { ... },
    "playwright": { ... }
  },
  "projects": {
    ...
  }
}
```

### Codex CLI Configuration (Sync with Claude Code)

If you're also using Codex CLI and want to reuse the same MCP:

- **Codex Configuration File**: `~/.codex/config.toml`
- **Field**: `mcp_servers`
- **Important**: Some versions require enabling `features.rmcp_client = true` to load MCP tools in Codex
- **Recommended**: Use this repository's script to sync from Claude config to Codex: `scripts/sync_mcp_from_claude_to_codex.py`
- **Tutorial**: `mcp_codex.md`

### Project-Specific Configuration

**CKB Configuration**: `project/.ckb/config.json`

**TaskMaster Configuration**: `~/.taskmaster/config.json` (optional)

---

## Use Cases

### TaskMaster AI is suitable for

- Project task management and tracking
- Development to-do item recording
- Code refactoring task planning
- Bug fix task tracking
- Project progress management

### CKB is suitable for

- Understanding architecture of large codebases
- Finding symbol references
- Impact analysis (assessing impact before modifying code)
- Git blame and history analysis
- Dependency tracking

### tree-sitter-mcp is suitable for

- Quick code search
- Semantic analysis
- Temporary projects (no initialization needed)
- Lightweight code understanding
- Code pattern matching

### Context7 is suitable for

- Querying latest library documentation and APIs
- Getting real-time code examples
- Learning how to use new libraries or frameworks
- Avoiding outdated code suggestions
- Quickly understanding library configuration and best practices

### GitHub MCP Server is suitable for

- Browsing and searching GitHub repositories
- Creating and managing Issues
- Creating and reviewing Pull Requests
- Monitoring CI/CD workflows
- Team collaboration and project management
- Security scanning and Dependabot management

### Playwright MCP is suitable for

- Web automation testing and E2E testing
- Scraping data from dynamic web pages
- Automated form filling and submission
- Batch generating web page screenshots
- Converting web pages to PDF
- Periodically monitoring web page changes
- Interacting with single-page apps (React, Vue, etc.)
- E-commerce flow automation testing

---

## Troubleshooting

### TaskMaster Won't Start

**Common causes**:
- Missing API Key
- API endpoint unreachable
- npx download failure

**Solutions**:
```bash
# Check environment variables
cat ~/.claude.json | python3 -c "
import sys, json
data = json.load(sys.stdin)
env = data['mcpServers']['task-master']['env']
print('Environment variables:', list(env.keys()))
"

# Test API connection
curl -I https://anyrouter.top
```

### CKB Shows "LSP not ready"

**Solutions**:
```bash
# Verify pylsp installation
python3 -m pylsp --version

# Check project configuration
cat .ckb/config.json

# Reinitialize
ckb init
```

### tree-sitter-mcp Slow First Run

**Reason**: npx needs to download package (normal behavior)

**Solution**: Wait for download to complete, subsequent runs will be fast

### Context7 Related Issues

Please refer to the troubleshooting section in the [Context7 section](#context7).

### GitHub MCP Server Related Issues

Please refer to the troubleshooting section in the [GitHub MCP Server section](#github-mcp-server).

### Playwright MCP Related Issues

Please refer to the troubleshooting section in the [Playwright MCP section](#playwright-mcp).

---

## Maintenance and Updates

### Update TaskMaster

```bash
# Using npx automatically uses latest version
# No manual update needed
```

### Update CKB

```bash
cd ~/Projects/mcps/codemcp
git pull
go build -o ckb ./cmd/ckb
sudo cp ckb /usr/local/bin/ckb
```

### Update tree-sitter-mcp

```bash
# Using npx -y automatically downloads latest version
# No manual update needed
```

### Update Context7

```bash
# Using npx -y automatically downloads latest version
# No manual update needed
```

### Update GitHub MCP Server

```bash
# Docker image automatically pulls latest version
# Or manual update:
docker pull ghcr.io/github/github-mcp-server
```

### Update Playwright MCP

```bash
# npx automatically uses latest version
# No manual update needed

# Clear cache if needed
npx clear-npx-cache

# Reinstall browsers
npx playwright install
```

---

## Reference Resources

### TaskMaster AI
- [Official Documentation](https://docs.task-master.dev)
- [GitHub Repository](https://github.com/eyaltoledano/claude-task-master)
- [npm Package](https://www.npmjs.com/package/task-master-ai)

### CKB
- [GitHub Repository](https://github.com/simplyliz/codemcp)
- [MCP Server List](https://mcp.lobehub.com/)

### tree-sitter-mcp
- [GitHub Repository](https://github.com/nendo/tree-sitter-mcp)
- [npm Package](https://www.npmjs.com/package/@nendo/tree-sitter-mcp)

### Context7
- [Official Website](https://context7.com)
- [GitHub Repository](https://github.com/upstash/context7)
- [npm Package](https://www.npmjs.com/package/@upstash/context7-mcp)
- [Get API Key](https://context7.com/dashboard)
- [Add Projects to Context7](https://github.com/upstash/context7#-adding-projects)

### GitHub MCP Server
- [GitHub Repository](https://github.com/github/github-mcp-server)
- [Docker Image](https://github.com/github/github-mcp-server/pkgs/container/github-mcp-server)
- [Official Documentation](https://github.com/github/github-mcp-server#readme)
- [Installation Guide](https://github.com/github/github-mcp-server/tree/main/docs)
- [Create PAT](https://github.com/settings/tokens)

### Playwright MCP
- [Official Repository](https://github.com/microsoft/playwright-mcp)
- [Official Website](https://playwright.dev)
- [npm Package](https://www.npmjs.com/package/@playwright/mcp)
- [Chrome Extension](https://github.com/microsoft/playwright-mcp/tree/main/extension)
- [Docker Usage](https://github.com/microsoft/playwright-mcp#docker)

### General Resources
- [MCP Protocol Specification](https://modelcontextprotocol.io/)
- [Claude Code MCP Documentation](https://docs.claude.com/en/docs/claude-code/mcp)
- [MCP Server Marketplace](https://mcp.lobehub.com/)

---

**Document Update Date**: 2025-12-30
**Author**: Claude Code
**Maintenance**: Regular updates to configuration and usage instructions
