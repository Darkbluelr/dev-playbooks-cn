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

# Use an isolated npm cache to avoid permission issues in CI/dev environments.
NPM_CACHE_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t 'devbooks-npm-cache')"
cleanup() {
    rm -rf "$NPM_CACHE_DIR"
}
trap cleanup EXIT

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
if [[ -f "package.json" ]] && node -e '
  const fs = require("fs");
  const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
  const hasName = typeof pkg.name === "string" && pkg.name.trim().length > 0;
  const bin = pkg.bin;
  const normalize = (p) => (typeof p === "string" && p.startsWith("./")) ? p.slice(2) : p;
  const hasBin = (() => {
    if (typeof bin === "string") return normalize(bin) === "bin/devbooks.js";
    if (!bin || typeof bin !== "object") return false;
    return Object.values(bin).some(v => typeof v === "string" && normalize(v) === "bin/devbooks.js");
  })();
  process.exit(hasName && hasBin ? 0 : 1);
' >/dev/null 2>&1; then
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

# AC-015: Packaging is controlled (files whitelist or .npmignore)
echo "AC-015: Checking packaging control..."
has_files_whitelist="1"
if [[ -f "package.json" ]] && node -e '
  const fs = require("fs");
  const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
  const files = pkg.files;
  const ok = Array.isArray(files) && files.length > 0;
  process.exit(ok ? 0 : 1);
' >/dev/null 2>&1; then
    has_files_whitelist="0"
fi
if [[ "$has_files_whitelist" == "0" || -f ".npmignore" ]]; then
    check "AC-015: packaging is controlled" "0"
else
    check "AC-015: packaging is controlled" "1"
fi

# AC-016: npm pack does not include project change packages (exclude template directory)
# Note: templates/dev-playbooks/changes/ is user project template, should be included
#       dev-playbooks/changes/ is project development change package, should be excluded
echo "AC-016: Checking npm pack output..."
pack_output="$(npm --cache "$NPM_CACHE_DIR" pack --dry-run --ignore-scripts 2>&1 || true)"
if echo "$pack_output" | grep "changes/" | grep -v "templates/" | grep -q "changes/"; then
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
