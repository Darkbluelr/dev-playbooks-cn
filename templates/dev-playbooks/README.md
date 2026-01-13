# DevBooks

**An agentic AI development workflow for Claude Code / Codex CLI**

> Turn large changes into a controlled, traceable, verifiable loop: Skills + quality gates + role isolation.

[![npm](https://img.shields.io/npm/v/dev-playbooks-cn)](https://www.npmjs.com/package/dev-playbooks-cn)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](../LICENSE)

---

## Why DevBooks?

AI coding assistants are powerful, but often **unpredictable**:

| Pain point | Outcome |
|------|------|
| **AI self-declares "done"** | Tests fail, edge cases are missed |
| **Writing tests and code in the same chat** | Tests turn into “pass tests” instead of spec verification |
| **No verification gates** | False completion silently ships |
| **Only works for greenfield (0→1)** | Brownfield repos have no on-ramp |
| **Too few commands** | Complex changes are not just "spec/apply/archive" |

**DevBooks provides**:
- **Evidence-based done**: completion is defined by tests/build/evidence, not AI self-evaluation
- **Enforced role isolation**: Test Owner and Coder must work in separate conversations
- **Multiple quality gates**: green evidence checks, task completion, role boundary checks
- **21 Skills**: proposal, design, debate, review, entropy metrics, federation, and more

---

## DevBooks At a Glance (Comparison)

| Dimension | DevBooks | OpenSpec | spec-kit | No spec |
|------|----------|----------|----------|--------|
| Spec-driven workflow | Yes | Yes | Yes | No |
| Artifact traceability | Change package (proposal/design/spec/tasks/verification/evidence) | Mostly folder/file organization | Docs + tasks orchestration | None |
| Role & responsibility boundaries | **Enforced** (Test Owner / Coder) | Convention-based (not enforced) | Convention-based (not enforced) | None |
| Definition of Done (DoD) | **Evidence + gates** (tests/build/audit) | Manual definition/checks | Manual definition/checks | Often subjective |
| Code quality assurance | Gates + metrics (entropy/hotspots) + review roles | External tools / manual review | External tools / manual review | Unstable |
| Impact analysis | CKB graph capability (falls back to grep) | Text search / manual reasoning | Text search / manual reasoning | Easy to miss |
| Brownfield onboarding | Baseline specs/glossary/minimal verification anchors | Manual | Limited | - |
| Automation coverage | 21 Skills (proposal→implementation→archive loop) | 3 core commands | Toolkit (greenfield-leaning) | - |

---

## How It Works

```
                           DevBooks Workflow

    PROPOSAL stage                 APPLY stage                      ARCHIVE stage
    (no coding)                    (role isolation enforced)         (quality gates)

    ┌─────────────────┐            ┌─────────────────┐              ┌─────────────────┐
    │  /devbooks:     │            │   Chat A        │              │  /devbooks:     │
    │   proposal      │            │  ┌───────────┐  │              │   gardener      │
    │   impact        │────────────│  │Test Owner │  │──────────────│   delivery      │
    │   design        │            │  │(Red first)│  │              │                 │
    │   spec          │            │  └───────────┘  │              │  Gates:         │
    │   plan          │            │                 │              │  ✓ Green evidence│
    └─────────────────┘            │   Chat B        │              │  ✓ Tasks done   │
           │                       │  ┌───────────┐  │              │  ✓ Role boundary│
           ▼                       │  │  Coder    │  │              │  ✓ No failures  │
    ┌─────────────────┐            │  │(no tests!)│  │              └─────────────────┘
    │ Triangle debate │            │  └───────────┘  │
    │ Author/Challenger│            └─────────────────┘
    │ /Judge          │
    └─────────────────┘
```

**Hard constraint**: Test Owner and Coder **must work in separate conversations**. This is not a suggestion. Coder cannot modify `tests/**`. “Done” is defined by tests/build verification, not AI self-evaluation.

---

## Quick Start

### Supported AI tools

| Tool | Support Level | Slash Commands | Config File |
|------|---------------|----------------|-------------|
| **Claude Code** | Full Skills | `/devbooks:*` | `CLAUDE.md` |
| **Codex CLI** | Full Skills | `/devbooks:*` | `AGENTS.md` |
| **Qoder** | Full Skills | `/devbooks:*` | `AGENTS.md` |
| **Cursor** | Rules | - | `.cursor/rules/` |
| **Windsurf** | Rules | - | `.windsurf/rules/` |
| **Gemini CLI** | Rules | - | `GEMINI.md` |
| **Continue** | Rules | - | `.continue/rules/` |
| **GitHub Copilot** | Instructions | - | `.github/copilot-instructions.md` |

> **Tip**: For tools without Slash command support, use natural language, e.g., "Run DevBooks proposal skill..."

### Install & init

**Install via npm (recommended):**

```bash
# global install
npm install -g dev-playbooks-cn

# init inside your project
dev-playbooks-cn init
```

**One-off usage:**

```bash
npx dev-playbooks-cn@latest init
```

**From source (contributors):**

```bash
../scripts/install-skills.sh
```

### Install targets

After initialization:
- Claude Code: `~/.claude/skills/devbooks-*`
- Codex CLI: `~/.codex/skills/devbooks-*`
- Qoder: `~/.qoder/` (manual setup required)

### Quick integration

DevBooks uses two directory roots:

| Directory | Purpose | Default |
|------|------|--------|
| `<truth-root>` | Current specs (read-only truth) | `dev-playbooks/specs/` |
| `<change-root>` | Change packages (workspace) | `dev-playbooks/changes/` |

See `../docs/DevBooks集成模板（协议无关）.md` (currently in Chinese), or use `../docs/DevBooks安装提示词.md` to let your assistant configure it automatically.

---

## Day-to-Day Change Workflow

### Use Router (recommended)

```
/devbooks:router <your request>
```

Router analyzes your request and outputs an execution plan (which command to run next).

### Direct commands

Once you know the flow, call the Skills directly:

**1) Proposal stage (no coding)**

```
/devbooks:proposal Add OAuth2 user authentication
```

Artifacts: `proposal.md` (required), `design.md`, `tasks.md`

**2) Apply stage (role isolation enforced)**

You must use **two separate conversations**:

```
# Chat A - Test Owner
/devbooks:test add-oauth2

# Chat B - Coder
/devbooks:code add-oauth2
```

- Test Owner: writes `verification.md` + tests, runs **Red** first
- Coder: implements per `tasks.md`, makes gates **Green** (cannot modify tests)

**3) Review stage**

```
/devbooks:review add-oauth2
```

**4) Archive stage**

```
/devbooks:gardener add-oauth2
```

---

## Command Reference

### Proposal stage

| Command | Skill | Description |
|------|-------|------|
| `/devbooks:router` | devbooks-router | Route to the right Skill |
| `/devbooks:proposal` | devbooks-proposal-author | Create a change proposal |
| `/devbooks:impact` | devbooks-impact-analysis | Cross-module impact analysis |
| `/devbooks:challenger` | devbooks-proposal-challenger | Challenge a proposal |
| `/devbooks:judge` | devbooks-proposal-judge | Adjudicate a proposal |
| `/devbooks:debate` | devbooks-proposal-debate-workflow | Triangle debate (Author/Challenger/Judge) |
| `/devbooks:design` | devbooks-design-doc | Create a design doc |
| `/devbooks:spec` | devbooks-spec-contract | Define specs & contracts |
| `/devbooks:c4` | devbooks-c4-map | Generate a C4 map |
| `/devbooks:plan` | devbooks-implementation-plan | Create an implementation plan |

### Apply stage

| Command | Skill | Description |
|------|-------|------|
| `/devbooks:test` | devbooks-test-owner | Test Owner role (separate chat required) |
| `/devbooks:code` | devbooks-coder | Coder role (separate chat required) |
| `/devbooks:backport` | devbooks-design-backport | Backport discoveries to design |

### Review stage

| Command | Skill | Description |
|------|-------|------|
| `/devbooks:review` | devbooks-code-review | Code review (readability/consistency) |
| `/devbooks:test-review` | devbooks-test-reviewer | Test quality & coverage review |

### Archive stage

| Command | Skill | Description |
|------|-------|------|
| `/devbooks:gardener` | devbooks-spec-gardener | Maintain/dedupe specs |
| `/devbooks:delivery` | devbooks-delivery-workflow | End-to-end delivery workflow |

### Standalone Skills

| Command | Skill | Description |
|------|-------|------|
| `/devbooks:entropy` | devbooks-entropy-monitor | System entropy metrics |
| `/devbooks:federation` | devbooks-federation | Cross-repo federation analysis |
| `/devbooks:bootstrap` | devbooks-brownfield-bootstrap | Brownfield project bootstrap |
| `/devbooks:index` | devbooks-index-bootstrap | Generate a SCIP index |

---

## DevBooks Comparisons

### vs. OpenSpec

[OpenSpec](https://github.com/Fission-AI/OpenSpec) is a lightweight spec-driven framework with three core commands (proposal/apply/archive), organizing changes by feature folders.

**What DevBooks adds:**
- **Role isolation**: hard boundary between Test Owner and Coder (separate chats)
- **Quality gates**: 5+ verification gates to block false completion
- **21 Skills**: proposal, debate, review, entropy metrics, federation, etc.
- **Evidence-based done**: tests/build define “done”, not self-evaluation

**Choose OpenSpec**: you want a lightweight spec workflow.

**Choose DevBooks**: you need role separation and verification gates for larger changes.

### vs. spec-kit

[GitHub spec-kit](https://github.com/github/spec-kit) is a spec-driven toolkit with a constitution file, multi-step refinement, and structured planning.

**What DevBooks adds:**
- **Brownfield-first**: generates baseline specs for existing repos
- **Role isolation**: test authoring and implementation are separated
- **Quality gates**: runtime verification, not just workflow guidance
- **Prototype mode**: safe experiments without polluting main `src/`

**Choose spec-kit**: greenfield projects with supported AI tools.

**Choose DevBooks**: brownfield repos or when you want enforced gates.

### vs. Kiro.dev

[Kiro](https://kiro.dev/) is an AWS agentic IDE with a three-phase workflow (EARS requirements, design, tasks), but stores specs separately from implementation artifacts.

**DevBooks differences:**
- **Change package**: proposal/design/spec/plan/verification/evidence in one place for lifecycle traceability
- **Role isolation**: Test Owner and Coder are separated
- **Quality gates**: verified through gates, not just task completion

**Choose Kiro**: you want an IDE experience and AWS ecosystem integration.

**Choose DevBooks**: you want change packages to bundle artifacts and enforce role boundaries.

### vs. no spec

Without specs, the assistant generates code from vague prompts, leading to unpredictable output, scope creep, and “hallucinated completion”.

**DevBooks brings:**
- Specs agreed before implementation
- Quality gates that verify real completion
- Role isolation to prevent self-verification
- Evidence chain per change

---

## Core Principles

| Principle | Meaning |
|------|------|
| **Protocol first** | truth/change/archive live in the repo, not only in chat logs |
| **Anchor first** | done is defined by tests/static checks/build/evidence |
| **Role isolation** | Test Owner and Coder must work in separate conversations |
| **Truth root separation** | `<truth-root>` is read-only truth; `<change-root>` is the workspace |
| **Structural gates** | prioritize complexity/coupling/test quality, not proxy metrics |

---

## Advanced Features

<details>
<summary><strong>Quality gates</strong></summary>

DevBooks uses quality gates to block “false done”:

| Gate | Trigger mode | What it checks |
|------|----------|----------|
| Green evidence | archive, strict | `evidence/green-final/` exists and is non-empty |
| Task completion | strict | all tasks are done or SKIP-APPROVED |
| Test failure block | archive, strict | no failures in green evidence |
| P0 skip approval | strict | P0 skips require an approval record |
| Role boundary | apply --role | Coder cannot modify tests/, Test Owner cannot modify src/ |

Core scripts (in `../skills/devbooks-delivery-workflow/scripts/`):
- `change-check.sh --mode proposal|apply|archive|strict`
- `handoff-check.sh` - handoff boundary checks
- `audit-scope.sh` - full audit scan
- `progress-dashboard.sh` - progress visualization

</details>

<details>
<summary><strong>Prototype mode</strong></summary>

When the technical approach is uncertain:

1. Create a prototype: `change-scaffold.sh <change-id> --prototype`
2. Test Owner with `--prototype`: characterization tests (no Red baseline required)
3. Coder with `--prototype`: output to `prototype/src/` (isolates main src)
4. Promote or discard: `prototype-promote.sh <change-id>`

Prototype mode prevents experimental code from polluting the main tree.

Scripts live in `../skills/devbooks-delivery-workflow/scripts/`.

</details>

<details>
<summary><strong>Entropy monitoring</strong></summary>

DevBooks tracks four dimensions of system entropy:

| Metric | What it measures |
|------|----------|
| Structural entropy | module complexity and coupling |
| Change entropy | change patterns and volatility |
| Test entropy | coverage/quality decay over time |
| Dependency entropy | external dependency health |

Use `/devbooks:entropy` to generate reports and identify refactor opportunities.

Scripts (in `../skills/devbooks-entropy-monitor/scripts/`): `entropy-measure.sh`, `entropy-report.sh`

</details>

<details>
<summary><strong>Brownfield project bootstrap</strong></summary>

When `<truth-root>` is empty:

```
/devbooks:bootstrap
```

Generates:
- project profile and glossary
- baseline specs from existing code
- minimal verification anchors
- module dependency map
- technical debt hotspots

</details>

<details>
<summary><strong>Cross-repo federation</strong></summary>

For multi-repo analysis:

```
/devbooks:federation
```

Analyzes cross-repo contracts and dependencies to support coordinated changes.

</details>

<details>
<summary><strong>MCP auto-detection</strong></summary>

DevBooks Skills support graceful MCP (Model Context Protocol) degradation: you can run the full workflow without MCP/CKB; when CKB (Code Knowledge Base) is detected, DevBooks automatically enables graph-based capabilities for more accurate “scope/reference/call chain” analysis.

### What is it for?

- **More accurate impact analysis**: upgrades from “file-level guesses” to “symbol references + call graphs”
- **More focused reviews**: automatically pulls hotspots and prioritizes high-risk areas (tech debt/high churn)
- **Less manual grep**: reduces noise and repeated confirmation in large repos

### MCP status and behavior

| MCP status | Behavior |
|----------|------|
| CKB available | Enhanced mode: symbol-level impact/references/call graph/hotspots (`mcp__ckb__analyzeImpact`, `mcp__ckb__findReferences`, `mcp__ckb__getCallGraph`, `mcp__ckb__getHotspots`) |
| CKB unavailable | Basic mode: Grep + Glob text search (full functionality, lower precision) |

### Auto detection

- Skills that depend on MCP call `mcp__ckb__getStatus` first (2s timeout)
- Timeout/failure → silently falls back to basic mode (non-blocking)
- No manual “basic/enhanced” switch required

To enable enhanced mode: configure CKB per `../docs/推荐MCP.md` and run `/devbooks:index` to generate `index.scip`.

</details>

<details>
<summary><strong>Proposal debate workflow</strong></summary>

For strict proposal review, run the triangle debate:

```
/devbooks:debate
```

Three roles:
1. **Author**: creates and defends the proposal
2. **Challenger**: challenges assumptions, finds gaps, identifies risks
3. **Judge**: makes the final decision and records rationale

Decision: `Approved`, `Revise`, `Rejected`

</details>

---

## Migration from Other Frameworks

DevBooks provides migration scripts to help you transition from other spec-driven development tools.

### Migrate from OpenSpec

If you're currently using [OpenSpec](https://github.com/Fission-AI/OpenSpec) with an `openspec/` directory:

```bash
# Download and run the migration script
curl -sL https://raw.githubusercontent.com/ozbombor/dev-playbooks-cn/master/scripts/migrate-from-openspec.sh | bash

# Or run with options
./scripts/migrate-from-openspec.sh --project-root . --dry-run  # Preview changes
./scripts/migrate-from-openspec.sh --project-root . --keep-old # Keep original directory
```

**What gets migrated:**
- `openspec/specs/` → `dev-playbooks/specs/`
- `openspec/changes/` → `dev-playbooks/changes/`
- `openspec/project.md` → `dev-playbooks/project.md`
- All path references are automatically updated

### Migrate from GitHub spec-kit

If you're using [GitHub spec-kit](https://github.com/github/spec-kit) with `specs/` and `memory/` directories:

```bash
# Download and run the migration script
curl -sL https://raw.githubusercontent.com/ozbombor/dev-playbooks-cn/master/scripts/migrate-from-speckit.sh | bash

# Or run with options
./scripts/migrate-from-speckit.sh --project-root . --dry-run  # Preview changes
./scripts/migrate-from-speckit.sh --project-root . --keep-old # Keep original directories
```

**Mapping rules:**

| Spec-Kit | DevBooks |
|----------|----------|
| `memory/constitution.md` | `dev-playbooks/specs/_meta/constitution.md` |
| `specs/[feature]/spec.md` | `changes/[feature]/design.md` |
| `specs/[feature]/plan.md` | `changes/[feature]/proposal.md` |
| `specs/[feature]/tasks.md` | `changes/[feature]/tasks.md` |
| `specs/[feature]/quickstart.md` | `changes/[feature]/verification.md` |
| `specs/[feature]/contracts/` | `changes/[feature]/specs/` |

### Migration Features

Both migration scripts support:

- **Idempotent execution**: Safe to run multiple times
- **Checkpoints**: Resume from where you left off if interrupted
- **Dry-run mode**: Preview changes before applying
- **Automatic backup**: Original files are backed up to `.devbooks/backup/`
- **Reference updates**: Path references in documents are automatically updated

### Post-Migration Steps

After migration:

1. Run `dev-playbooks-cn init` to set up DevBooks Skills
2. Review migrated files in `dev-playbooks/`
3. Update `verification.md` files with proper AC mappings
4. Run `/devbooks:bootstrap` if you need baseline specs

---

## Repository Structure

```
skills/                    # devbooks-* Skill sources (some ship scripts/)
templates/                 # project init templates (used by `dev-playbooks-cn init`)
templates/dev-playbooks/   # DevBooks protocol directory template (copied into your project as `dev-playbooks/`)
scripts/                   # install & helper scripts
docs/                      # documentation
bin/                       # CLI entry
```

---

## Documentation

- [Slash command guide](../docs/Slash 命令使用指南.md)
- [Skills guide](../skills/Skills使用说明.md)
- [MCP configuration recommendations](../docs/推荐MCP.md)
- [Integration template (protocol-agnostic)](../docs/DevBooks集成模板（协议无关）.md)
- [Installation prompt](../docs/DevBooks安装提示词.md)

---

## License

MIT
