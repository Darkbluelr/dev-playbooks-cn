#!/bin/bash
# verify-slash-commands.sh - 验证 Slash 命令定义
#
# 验证 AC-001（24 个命令）和 AC-002（命令与 Skill 1:1 对应）

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
            check "AC-002: $cmd.md → $expected_skill（skill 元数据不匹配）" "1"
        fi
    fi
}

echo "=== Slash 命令验证（21 核心 + 3 向后兼容 = 24 个命令） ==="
echo ""

COMMANDS_DIR="templates/claude-commands/devbooks"

# AC-001: 检查命令数量（24 = 21 核心 + 3 向后兼容）
echo "AC-001: 检查命令数量..."
cmd_count=$(ls "$COMMANDS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
if [[ "$cmd_count" -eq 24 ]]; then
    check "AC-001: 命令数量为 24（21 核心 + 3 向后兼容）" "0"
else
    check "AC-001: 命令数量为 24（实际: $cmd_count）" "1"
fi

echo ""
echo "=== 检查 21 个命令文件存在性 ==="

# 21 个命令文件列表
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
        check "AC-011~AC-031: $cmd.md 存在" "0"
    else
        check "AC-011~AC-031: $cmd.md 存在" "1"
    fi
done

echo ""
echo "=== AC-002: 检查命令与 Skill 对应关系 ==="

# 命令 -> Skill 映射检查
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
echo "=== AC-008: 检查向后兼容命令 ==="

# 向后兼容命令列表
COMPAT_COMMANDS=("apply" "archive" "quick")

for cmd in "${COMPAT_COMMANDS[@]}"; do
    if [[ -f "$COMMANDS_DIR/$cmd.md" ]]; then
        if grep -q "backward-compat: true" "$COMMANDS_DIR/$cmd.md"; then
            check "AC-008: $cmd.md 存在且标记为向后兼容" "0"
        else
            check "AC-008: $cmd.md 存在但缺少 backward-compat 标记" "1"
        fi
    else
        check "AC-008: $cmd.md 存在" "1"
    fi
done

echo ""
echo "=== 结果 ==="
echo "通过: $PASSED"
echo "失败: $FAILED"

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}全部通过！${NC}"
    exit 0
else
    echo -e "${RED}存在失败项${NC}"
    exit 1
fi
