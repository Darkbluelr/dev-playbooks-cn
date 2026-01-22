#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATTERN="(最强大脑|智能|高效|强大|优雅|完美|革命性|颠覆性)"

grep -rE "$PATTERN" "$ROOT_DIR/skills"/*/{SKILL,skill}.md 2>/dev/null || true
