#!/bin/bash
# verify-openspec-free.sh - Verify OpenSpec references are cleared
#
# Verify AC-001 ~ AC-004

set -uo pipefail  # Remove -e, handle errors manually

GREEN='\033[0;32m'
RED='\033[0;31m'
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

echo "=== OpenSpec Cleanup Verification ==="
echo ""

# AC-001: No OpenSpec references (exclude legitimate references)
echo "AC-001: Checking OpenSpec references..."
# Exclude legitimate references:
# - backup, changes, .git: history/work directories
# - migrate-from-openspec.sh: migration script
# - verify-*.sh: verification scripts
# - c4.md: architecture documentation (records historical changes)
# - specs/config-protocol/spec.md: rule definition document
# - specs/slash-commands/spec.md: historical record document
ref_count=$(grep -rn "openspec\|OpenSpec" . --include="*.md" --include="*.sh" --include="*.yaml" --include="*.yml" --include="*.js" 2>/dev/null | grep -v backup | grep -v changes | grep -v "\.git" | grep -v "DEVBOOKS-EVOLUTION-PROPOSAL.md" | grep -v "migrate-from-openspec.sh" | grep -v "tests/" | grep -v "verify-openspec-free.sh" | grep -v "verify-all.sh" | grep -v "c4.md" | grep -v "specs/config-protocol/spec.md" | grep -v "specs/slash-commands/spec.md" | wc -l | tr -d ' ') || ref_count=0
if [[ "$ref_count" == "0" ]]; then
    check "AC-001: OpenSpec references cleared" "0"
else
    check "AC-001: OpenSpec references cleared ($ref_count remaining)" "1"
fi

# AC-002: setup/openspec deleted
echo "AC-002: Checking setup/openspec directory..."
if [[ ! -d "setup/openspec" ]]; then
    check "AC-002: setup/openspec deleted" "0"
else
    check "AC-002: setup/openspec deleted" "1"
fi

# AC-003: .claude/commands/openspec deleted
echo "AC-003: Checking .claude/commands/openspec directory..."
if [[ ! -d ".claude/commands/openspec" ]]; then
    check "AC-003: .claude/commands/openspec deleted" "0"
else
    check "AC-003: .claude/commands/openspec deleted" "1"
fi

# AC-004: dev-playbooks/specs/openspec-integration deleted
echo "AC-004: Checking dev-playbooks/specs/openspec-integration directory..."
if [[ ! -d "dev-playbooks/specs/openspec-integration" ]]; then
    check "AC-004: dev-playbooks/specs/openspec-integration deleted" "0"
else
    check "AC-004: dev-playbooks/specs/openspec-integration deleted" "1"
fi

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
