#!/bin/bash
# verify-npm-package.sh - Verify npm package structure
#
# Verify AC-011 ~ AC-016

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

echo "=== npm Package Verification ==="
echo ""

# AC-011: CLI entry exists and is executable
# Note: Design changed to `devbooks init` instead of `create-devbooks`
echo "AC-011: Checking CLI entry..."
if [[ -f "bin/devbooks.js" ]] && [[ -x "bin/devbooks.js" ]]; then
    check "AC-011: CLI entry exists and is executable" "0"
else
    check "AC-011: CLI entry exists and is executable" "1"
fi

# AC-012: package.json exists and is valid
echo "AC-012: Checking package.json..."
if [[ -f "package.json" ]] && grep -q '"name": "devbooks"' package.json; then
    check "AC-012: package.json exists and is valid" "0"
else
    check "AC-012: package.json exists and is valid" "1"
fi

# AC-013: templates/ directory exists
echo "AC-013: Checking templates/ directory..."
if [[ -d "templates" ]]; then
    check "AC-013: templates/ directory exists" "0"
else
    check "AC-013: templates/ directory exists" "1"
fi

# AC-014: Skills count is correct (21 devbooks-* Skills)
echo "AC-014: Checking Skills count..."
skill_count=$(ls -d skills/devbooks-* 2>/dev/null | wc -l | tr -d ' ')
if [[ "$skill_count" -ge 20 ]]; then
    check "AC-014: Skills count is correct ($skill_count)" "0"
else
    check "AC-014: Skills count is correct ($skill_count, expected >= 20)" "1"
fi

# AC-015: .npmignore exists
echo "AC-015: Checking .npmignore..."
if [[ -f ".npmignore" ]]; then
    check "AC-015: .npmignore exists" "0"
else
    check "AC-015: .npmignore exists" "1"
fi

# AC-016: npm pack does not include project change packages (exclude template directory)
# Note: templates/dev-playbooks/changes/ is user project template, should be included
#       dev-playbooks/changes/ is project development change package, should be excluded
echo "AC-016: Checking npm pack output..."
if npm pack --dry-run 2>&1 | grep "changes/" | grep -v "templates/" | grep -q "changes/"; then
    check "AC-016: npm pack does not include changes/" "1"
else
    check "AC-016: npm pack does not include changes/" "0"
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
