# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-01-19

### Added

#### 🎯 Human-Friendly Document Templates

- **结论先行（Bottom Line Up Front）**: Every document (proposal, design, tasks, verification) now has a 30-second executive summary at the top
  - ✅ What will result: List changes in plain language
  - ❌ What won't result: Clearly state what won't change
  - 📝 One-sentence summary: Understandable even for non-technical people

- **需求对齐（Alignment Check）**: Proposal phase now includes guided questions to uncover hidden requirements
  - 👤 Role identification: Quick Starter / Platform Builder / Rapid Validator
  - 🎯 Core requirements: Explicit + hidden requirements
  - 💡 Multi-perspective recommendations: Different recommendations based on different roles

- **默认批准机制（Default Approval Mechanism）**: Reduce decision fatigue with auto-approval
  - ⏰ User silence = agreement: Auto-approve after timeout
  - 🎛️ Configurable timeout: proposal 48h / design 24h / tasks 24h / verification 12h
  - 🔒 Retain control: Users can reject or customize at any time

- **项目级文档（Project-Level Documents）**: Knowledge retention and decision tracking
  - 📋 User Profile (project-profile.md): Record role, requirements, constraints, preferences
  - 📝 Decision Log (decision-log.md): Record all important decisions for retrospection

#### New Document Templates

- `skills/_shared/references/文档模板-proposal.md` (Chinese)
- `skills/_shared/references/文档模板-design.md` (Chinese)
- `skills/_shared/references/文档模板-tasks.md` (Chinese)
- `skills/_shared/references/文档模板-verification.md` (Chinese)
- `skills/_shared/references/文档模板-project-profile.md` (Chinese)
- `skills/_shared/references/文档模板-decision-log.md` (Chinese)
- `skills/_shared/references/批准配置说明.md` (Chinese)
- `skills/_shared/references/document-template-proposal.md` (English)
- `skills/_shared/references/document-template-design.md` (English)
- `skills/_shared/references/document-template-tasks.md` (English)
- `skills/_shared/references/document-template-verification.md` (English)
- `skills/_shared/references/document-template-project-profile.md` (English)
- `skills/_shared/references/document-template-decision-log.md` (English)
- `skills/_shared/references/approval-configuration-guide.md` (English)

#### Documentation

- Added `docs/v2.0.0-修改总结.md`: Comprehensive summary of v2.0.0 changes
- Updated README.md with v2.0.0 features section (both Chinese and English versions)

### Changed

- **proposal-author skill**: Updated to use new document templates
  - Now generates documents with "Bottom Line Up Front" section
  - Includes "Alignment Check" to uncover hidden requirements
  - Provides multi-perspective recommendations based on user role
  - References new template files in prompts

### Breaking Changes

⚠️ **Document Structure Changes**

- Existing proposal.md files do not conform to the new structure
- Migration may be required for existing projects
- Old format is still supported but not recommended

**Mitigation**:
- Migration script will be provided in future releases
- Backward compatibility maintained for reading old format
- New projects will use new format by default

⚠️ **Approval Mechanism Changes**

- Introduces default approval mechanism which may not fit all team workflows
- Default strategy is `auto_approve` but can be changed to `require_explicit`

**Mitigation**:
- Configurable approval strategy in `.devbooks/config.yaml`
- Can disable auto-approval for high-risk projects
- Timeout values are configurable

### Design Philosophy

This release is inspired by:
- Cognitive Load Theory: Minimize extraneous load, maximize germane load
- Dual Process Theory: Design for both System 1 (fast) and System 2 (slow) thinking
- Nudge Theory: Use default options to guide better decisions
- Inverted Pyramid Structure: Put conclusions first, details later

**Core Principles**:
- 🎯 Assume users are non-technical: Use plain language, avoid jargon
- 🤔 Uncover hidden requirements: Guide users through questions
- ⏰ Reduce decision fatigue: Default approval with configurable timeout
- 📋 Knowledge retention: Project-level documents for long-term reference

### Upgrade Guide

#### For Existing Projects

1. Update npm package:
   ```bash
   npm install -g dev-playbooks-cn@2.0.0
   # or
   npm install -g dev-playbooks@2.0.0
   ```

2. (Optional) Migrate existing documents:
   ```bash
   # Migration script will be provided in future releases
   devbooks migrate --from 1.x --to 2.0.0
   ```

3. (Optional) Configure approval mechanism:
   Create `.devbooks/config.yaml`:
   ```yaml
   approval:
     default_strategy: auto_approve
     timeout:
       proposal: 48
       design: 24
       tasks: 24
       verification: 12
   ```

4. (Optional) Create project-level documents:
   ```bash
   devbooks init-profile
   devbooks init-decision-log
   ```

#### For New Projects

New projects will automatically use the new document templates. No migration needed.

### References

- Report: "Protocol 2026: Cognitive Compatibility and Human-Computer Communication Standards in the AI-Native Era"
- Cognitive Load Theory (CLT)
- Dual Process Theory
- Nudge Theory
- Inverted Pyramid Structure

---

## [1.7.4] - 2026-01-18

### Changed
- Various bug fixes and improvements

---

## [1.7.0] - 2026-01-15

### Added
- Initial release with 18 skills
- Support for Claude Code, Codex CLI, and other AI tools
- Quality gates and role isolation
- MCP integration support

---

[2.0.0]: https://github.com/Darkbluelr/dev-playbooks-cn/compare/v1.7.4...v2.0.0
[1.7.4]: https://github.com/Darkbluelr/dev-playbooks-cn/compare/v1.7.0...v1.7.4
[1.7.0]: https://github.com/Darkbluelr/dev-playbooks-cn/releases/tag/v1.7.0
