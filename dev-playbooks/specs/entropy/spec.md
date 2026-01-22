# entropy

---
owner: Spec Gardener
last_verified: 2026-01-10
status: Active
freshness_check: 3 Months
---

## Purpose

Describe entropy measurement visualization capabilities: Mermaid charts + ASCII dashboard + terminal compatibility.

---

## Requirements

### Requirement: REQ-ENT-001 Mermaid Chart Support

The system **SHALL** include Mermaid charts in entropy measurement reports to improve readability.

**Chart Types**:
1. **Trend Line Chart**: Display entropy metric trends over time (30 days)
2. **Hotspot Bar Chart**: Display hotspot files and their complexity
3. **Radar Chart**: Display comparison of four entropy types (structural/change/test/dependency)

**Acceptance Criteria**:
- Report includes at least 2 Mermaid charts
- Mermaid code block syntax is correct and can be rendered by GitHub/GitLab
- Chart data matches text tables
- Mermaid code blocks do not break readability when viewed in terminal

#### Scenario: SC-ENT-001 Generate Mermaid Charts

- **GIVEN** Entropy measurement tool is available
- **WHEN** Execute `./tools/devbooks-entropy-viz.sh --output report.md`
- **THEN** Report contains at least 2 `\`\`\`mermaid` code blocks

**Trace**: AC-006, SPEC-ENT-001 CT-ENT-001

---

### Requirement: REQ-ENT-002 ASCII Dashboard

The system **SHALL** include ASCII dashboard in entropy measurement reports to provide terminal-friendly real-time feedback.

**Dashboard Content**:
1. **Overall Health Score**: 0-100 score, colored progress bar
2. **Four Entropy Metrics**: Structural, change, test, dependency entropy, each with progress bar and status icon
3. **Threshold Warning**: Display warning indicator when exceeding threshold

**Acceptance Criteria**:
- Dashboard uses ANSI color codes (green checkmark, yellow warning, red alert)
- Supports `NO_COLOR` environment variable (degrades to plain text when colors disabled)
- Progress bar length fixed (40 characters) to avoid terminal line wrap
- Status icons are clear and understandable

#### Scenario: SC-ENT-002 Generate ASCII Dashboard

- **GIVEN** Entropy measurement tool is available
- **WHEN** Execute `./tools/devbooks-entropy-viz.sh --output report.md`
- **THEN** Report contains overall health score and progress bar characters

**Trace**: AC-006, SPEC-ENT-001 CT-ENT-002

---

### Requirement: REQ-ENT-003 Backward Compatibility

The system **SHALL** maintain backward compatibility; new visualizations should not break existing text tables.

**Compatibility Requirements**:
- Original text tables remain unchanged (position, format, content)
- New visualizations inserted as separate sections
- Old version renderers that don't support Mermaid can still read text tables
- Configuration item `features.entropy_visualization` can disable visualization

#### Scenario: SC-ENT-003 Disable Visualization

- **GIVEN** Configuration `features.entropy_visualization: false`
- **WHEN** Execute entropy measurement tool
- **THEN** Report does not contain Mermaid charts and ASCII dashboard
- **AND** Report format matches original version

**Trace**: AC-008, SPEC-ENT-001 CT-ENT-003

---

### Requirement: REQ-ENT-004 Terminal Compatibility

The system **SHALL** ensure ASCII dashboard displays correctly in various terminal environments.

**Compatibility Testing**:
- macOS Terminal
- iTerm2
- Linux gnome-terminal
- Windows Terminal
- VS Code terminal
- SSH remote terminal

**Acceptance Criteria**:
- All test terminals display ANSI colors correctly
- Supports `NO_COLOR` environment variable
- Does not depend on Unicode special characters (avoid garbled text)
- Width adapts to 80-column terminal

#### Scenario: SC-ENT-004 NO_COLOR Environment Variable

- **GIVEN** `NO_COLOR=1` environment variable is set
- **WHEN** Execute entropy measurement tool
- **THEN** Report does not contain ANSI color codes
- **AND** Status uses text labels: `[OK]`, `[WARNING]`, `[ERROR]`

**Trace**: SPEC-ENT-001 CT-ENT-004

---

### Requirement: REQ-ENT-005 Configurable

The system **SHALL** support visualization feature configuration, allowing users to choose.

**Configuration Items**:
- `features.entropy_visualization`: Whether to enable visualization (default: `true`)
- `features.entropy_mermaid`: Whether to generate Mermaid charts (default: `true`)
- `features.entropy_ascii_dashboard`: Whether to generate ASCII dashboard (default: `true`)

#### Scenario: SC-ENT-005 Disable Mermaid Separately

- **GIVEN** Configuration `features.entropy_mermaid: false`
- **WHEN** Execute entropy measurement tool
- **THEN** Report does not contain Mermaid charts but contains ASCII dashboard

**Trace**: SPEC-ENT-001 CT-ENT-003

---

### Requirement: REQ-ENT-006 Test Coverage

The system **SHALL** provide adequate test coverage for entropy visualization features.

**Test Requirements**:
- Entropy visualization test cases >= 3 (approval condition)
- Cover Mermaid chart generation
- Cover ASCII dashboard generation
- Cover terminal compatibility

#### Scenario: SC-ENT-006 Test Coverage

- **GIVEN** Entropy visualization test suite is available
- **WHEN** Run all entropy visualization tests
- **THEN** Test cases >= 3 and all pass

**Trace**: SPEC-ENT-001 CT-ENT-005

---

## Data-Driven Examples

### ASCII Dashboard Specification

#### Colored Version (default)

| Element | ANSI Color Code | Icon |
|---------|-----------------|------|
| Good | `\033[32m` | checkmark |
| Warning | `\033[33m` | warning |
| Error | `\033[31m` | red_circle |
| Reset | `\033[0m` | - |

**Progress Bar Characters**:
- Fill: `█` (U+2588)
- Empty: `░` (U+2591)
- Separator: `━` (U+2501)

#### Plain Text Version (NO_COLOR)

| Element | Text Label | Progress Bar |
|---------|------------|--------------|
| Good | `[OK]` | `#` |
| Warning | `[WARNING]` | `#` |
| Error | `[ERROR]` | `#` |

### Mermaid Chart Types

| Chart Type | Purpose | Mermaid Syntax |
|------------|---------|----------------|
| xychart-beta | Trend line chart | `xychart-beta title "..." x-axis [...] y-axis "..." 0 --> 100 line [...]` |
| graph TD | Hotspot file chart | `graph TD A["Filename<br/>Complexity: N"] style A fill:#FFC107` |
| graph LR | Radar chart alternative | `graph LR A[Metric1: N%] B[Metric2: M%]` |

### Configuration Item Reference Table

| Configuration Item | Type | Default | Description |
|--------------------|------|---------|-------------|
| features.entropy_visualization | boolean | true | Master switch |
| features.entropy_mermaid | boolean | true | Mermaid charts |
| features.entropy_ascii_dashboard | boolean | true | ASCII dashboard |

---

*Spec created by boost-local-intelligence change package (2026-01-10), archived by Spec Gardener*
