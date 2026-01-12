#!/bin/bash
# verify-slash-commands.sh - Verify Slash command definitions
#
# Verify AC-001 (24 commands) and AC-002 (command to Skill 1:1 mapping)

set -uo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0

check() {
    local name="$1"
    local result="$2"
    if [[ "$result" == "0" ]]; then
        echo -e "${GREEN}✅ $name${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}❌ $name${NC}"
        FAILED=$((FAILED + 1))
    fi
}

check_skill_mapping() {
    local cmd="$1"
    local expected_skill="$2"
    local file="$COMMANDS_DIR/$cmd.md"
    if [[ -f "$file" ]]; then
        if grep -q "skill: $expected_skill" "$file"; then
            check "AC-002: $cmd.md → $expected_skill" "0"
        else
            check "AC-002: $cmd.md → $expected_skill (skill metadata mismatch)" "1"
        fi
    fi
}

echo "=== Slash Command Verification (21 core + 3 backward compatible = 24 commands) ==="
echo ""

COMMANDS_DIR="templates/claude-commands/devbooks"

# AC-001: Check command count (24 = 21 core + 3 backward compatible)
echo "AC-001: Checking command count..."
cmd_count=$(ls "$COMMANDS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
if [[ "$cmd_count" -eq 24 ]]; then
    check "AC-001: Command count is 24 (21 core + 3 backward compatible)" "0"
else
    check "AC-001: Command count is 24 (actual: $cmd_count)" "1"
fi

echo ""
echo "=== Checking 21 command file existence ==="

# 21 command files list
COMMANDS=(
    "router"
    "proposal"
    "challenger"
    "judge"
    "debate"
    "design"
    "backport"
    "plan"
    "spec"
    "gardener"
    "test"
    "test-review"
    "code"
    "review"
    "delivery"
    "c4"
    "impact"
    "entropy"
    "federation"
    "bootstrap"
    "index"
)

for cmd in "${COMMANDS[@]}"; do
    if [[ -f "$COMMANDS_DIR/$cmd.md" ]]; then
        check "AC-011~AC-031: $cmd.md exists" "0"
    else
        check "AC-011~AC-031: $cmd.md exists" "1"
    fi
done

echo ""
echo "=== AC-002: Checking command to Skill mapping ==="

# Command -> Skill mapping check
check_skill_mapping "router" "devbooks-router"
check_skill_mapping "proposal" "devbooks-proposal-author"
check_skill_mapping "challenger" "devbooks-proposal-challenger"
check_skill_mapping "judge" "devbooks-proposal-judge"
check_skill_mapping "debate" "devbooks-proposal-debate-workflow"
check_skill_mapping "design" "devbooks-design-doc"
check_skill_mapping "backport" "devbooks-design-backport"
check_skill_mapping "plan" "devbooks-implementation-plan"
check_skill_mapping "spec" "devbooks-spec-contract"
check_skill_mapping "gardener" "devbooks-spec-gardener"
check_skill_mapping "test" "devbooks-test-owner"
check_skill_mapping "test-review" "devbooks-test-reviewer"
check_skill_mapping "code" "devbooks-coder"
check_skill_mapping "review" "devbooks-code-review"
check_skill_mapping "delivery" "devbooks-delivery-workflow"
check_skill_mapping "c4" "devbooks-c4-map"
check_skill_mapping "impact" "devbooks-impact-analysis"
check_skill_mapping "entropy" "devbooks-entropy-monitor"
check_skill_mapping "federation" "devbooks-federation"
check_skill_mapping "bootstrap" "devbooks-brownfield-bootstrap"
check_skill_mapping "index" "devbooks-index-bootstrap"

echo ""
echo "=== AC-008: Checking backward compatible commands ==="

# Backward compatible commands list
COMPAT_COMMANDS=("apply" "archive" "quick")

for cmd in "${COMPAT_COMMANDS[@]}"; do
    if [[ -f "$COMMANDS_DIR/$cmd.md" ]]; then
        if grep -q "backward-compat: true" "$COMMANDS_DIR/$cmd.md"; then
            check "AC-008: $cmd.md exists and marked as backward compatible" "0"
        else
            check "AC-008: $cmd.md exists but missing backward-compat marker" "1"
        fi
    else
        check "AC-008: $cmd.md exists" "1"
    fi
done

echo ""
echo "=== Results ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}All passed!${NC}"
    exit 0
else
    echo -e "${RED}Some checks failed${NC}"
    exit 1
fi
