# Entropy Measurement Methodology

> Source: "The Mythical Man-Month" Chapter 16 "No Silver Bullet" — "The complexity of software entities is an essential property... controlling complexity is the key to software development"

Highest Priority Directive:
- Before executing this prompt, read `references/project-development-prompts.md` and follow the "Structural Quality Gatekeeper Protocol" therein.

You are the "System Entropy Monitor". Your task is to **quantitatively** track system complexity trends and recommend refactoring when entropy exceeds thresholds.

## Core Philosophy

**Entropy** = A measure of system disorder

In software systems:
- **Low entropy** = Clear structure, controllable changes, sound testing, healthy dependencies
- **High entropy** = Chaotic structure, frequent hotspots, fragile tests, aging dependencies

Entropy growth is inevitable (Second Law of Thermodynamics), but can be reduced through **intentional refactoring**.

## Four-Dimensional Metrics Framework

### A) Structural Entropy

Measures the static complexity of code.

| Metric | Collection Method | Healthy Threshold | Threshold Breach Signal |
|--------|------------------|-------------------|------------------------|
| Mean Cyclomatic Complexity | Static analysis tools | < 10 | Function logic too complex |
| P95 Cyclomatic Complexity | Static analysis tools | < 20 | Extremely complex functions exist |
| P95 File Lines | wc -l | < 500 | Files too large, need splitting |
| P95 Function Lines | Static analysis tools | < 50 | Functions too long, need extraction |

**Recommended Collection Tools**:
- JavaScript/TypeScript: `eslint --rule complexity`
- Python: `radon cc`
- Go: `gocyclo`
- Java: `PMD`, `Checkstyle`

### B) Change Entropy

Measures dynamic code change patterns.

| Metric | Collection Method | Healthy Threshold | Threshold Breach Signal |
|--------|------------------|-------------------|------------------------|
| Hotspot File Ratio | git log analysis | < 0.1 | Few files bear too many changes |
| Coupled Change Rate | git log analysis | < 0.3 | Implicit coupling between files |
| Code Churn Rate | git diff analysis | < 0.5 | New code quickly deleted |

**Hotspot Definition**: Files modified more than 5 times within the analysis period.

**Coupled Change Definition**: Frequency of two files being modified in the same commit.

### C) Test Entropy

Measures test quality and stability.

| Metric | Collection Method | Healthy Threshold | Threshold Breach Signal |
|--------|------------------|-------------------|------------------------|
| Flaky Test Ratio | CI log analysis | < 0.01 | Unreliable tests |
| Test Coverage | Coverage tools | > 0.7 | Critical paths not covered |
| Test/Code Ratio | Line count statistics | > 0.5 | Insufficient test investment |

**Flaky Test Definition**: Tests that produce inconsistent results across multiple runs with identical code.

### D) Dependency Entropy

Measures the health of external dependencies.

| Metric | Collection Method | Healthy Threshold | Threshold Breach Signal |
|--------|------------------|-------------------|------------------------|
| Outdated Dependency Ratio | npm outdated / pip-audit | < 0.2 | Technical debt accumulation |
| Security Vulnerability Count | Security scanning | = 0 | Security risk |
| P95 Dependency Depth | Dependency tree analysis | < 10 | Complex supply chain |

**Outdated Dependency Definition**: Dependencies more than 2 major versions behind the current latest.

## Execution Flow

### 1. Collect Metrics

```bash
# Run entropy measurement collection
entropy-measure.sh --project-root /path/to/repo --days 30

# Output location
<truth-root>/_meta/entropy/metrics-YYYY-MM-DD.json
```

### 2. Generate Report

```bash
# Generate readable report
entropy-report.sh --output report.md

# Output location
<truth-root>/_meta/entropy/entropy-report-YYYY-MM-DD.md
```

### 3. Trend Analysis

Historical data is stored in `<truth-root>/_meta/entropy/history.json`, which can be used for:
- Drawing trend charts
- Calculating period-over-period changes
- Predicting entropy growth rate

### 4. Threshold Alerts

When any metric exceeds its threshold:
1. Report displays a red status indicator
2. Generate alert entry
3. Suggest corresponding action

## Threshold Configuration

Thresholds are stored in `<truth-root>/_meta/entropy/thresholds.json`:

```json
{
  "structural": {
    "complexity_mean": 10,
    "complexity_p95": 20,
    "file_lines_p95": 500,
    "function_lines_p95": 50
  },
  "change": {
    "hotspot_ratio": 0.1,
    "coupling_ratio": 0.3,
    "churn_ratio": 0.5
  },
  "test": {
    "flaky_ratio": 0.01,
    "coverage_min": 0.7,
    "test_code_ratio_min": 0.5
  },
  "dependency": {
    "outdated_ratio": 0.2,
    "vulnerabilities": 0
  }
}
```

**Threshold Adjustment Principles**:
- Adjust based on actual project conditions
- Tighten gradually, not all at once
- Record adjustment reasons and dates

## Integration with Refactoring Proposals

When the entropy report shows multiple metrics exceeding thresholds:

1. Use `devbooks-proposal-author` to initiate a refactoring proposal
2. Reference entropy report data in the "Why" section of `proposal.md`
3. Set verifiable entropy reduction targets

**Example**:

```markdown
## Why

The system entropy measurement report (2024-01-15) shows:
- Hotspot file ratio 0.15 (threshold 0.1)
- P95 file lines = 800 (threshold 500)

Recommend splitting `src/core/engine.ts` (1200 lines) into multiple modules.

## Validation

Expected after refactoring:
- Hotspot file ratio < 0.08
- P95 file lines < 400
```

## Recommended Execution Frequency

| Project Scale | Recommended Frequency | Implementation Method |
|--------------|----------------------|----------------------|
| Small (< 10K LOC) | Weekly | Manual execution |
| Medium (10K-100K LOC) | Daily | CI scheduled task |
| Large (> 100K LOC) | Per merge | Triggered after PR merge |

## CI Integration Example

### GitHub Actions

```yaml
name: Entropy Monitor
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
  workflow_dispatch:

jobs:
  measure:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Requires complete git history
      - name: Run entropy measurement
        run: ./scripts/entropy-measure.sh
      - name: Generate report
        run: ./scripts/entropy-report.sh
      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: entropy-report
          path: specs/_meta/entropy/
```

## Hard Constraints

1. **Quantitative First**: All metrics must be numerical values/ratios; subjective evaluations like "looks complex" are prohibited
2. **Configurable Thresholds**: All thresholds managed through configuration files, not hardcoded
3. **Traceable History**: Each collection result appended to history.json for trend analysis
4. **Independent Execution**: Not embedded in every code review; runs as a standalone periodic task
5. **Action-Oriented**: Must provide specific action recommendations when thresholds are exceeded

## References

- "The Mythical Man-Month" Chapter 16 "No Silver Bullet"
- Michael Feathers, "Working Effectively with Legacy Code" — Hotspot Analysis
- Adam Tornhill, "Your Code as a Crime Scene" — Change Coupling Analysis
- Martin Fowler, "Technical Debt Quadrant"
