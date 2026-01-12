#!/bin/bash
# verify-openspec-free.sh - 验证 OpenSpec 引用已清除
#
# 验证 AC-001 ~ AC-004

set -uo pipefail  # 移除 -e，手动处理错误

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

echo "=== OpenSpec 清理验证 ==="
echo ""

# AC-001: 无 OpenSpec 引用（排除合法引用）
echo "AC-001: 检查 OpenSpec 引用..."
# 排除合法引用：
# - backup, changes, .git：历史/工作目录
# - migrate-from-openspec.sh：迁移脚本
# - verify-*.sh：验证脚本
# - c4.md：架构文档（记录历史变更）
# - specs/config-protocol/spec.md：规则定义文档
# - specs/slash-commands/spec.md：历史记录文档
ref_count=$(grep -rn "openspec\|OpenSpec" . --include="*.md" --include="*.sh" --include="*.yaml" --include="*.yml" --include="*.js" 2>/dev/null | grep -v backup | grep -v changes | grep -v "\.git" | grep -v "DEVBOOKS-EVOLUTION-PROPOSAL.md" | grep -v "migrate-from-openspec.sh" | grep -v "tests/" | grep -v "verify-openspec-free.sh" | grep -v "verify-all.sh" | grep -v "c4.md" | grep -v "specs/config-protocol/spec.md" | grep -v "specs/slash-commands/spec.md" | wc -l | tr -d ' ') || ref_count=0
if [[ "$ref_count" == "0" ]]; then
    check "AC-001: OpenSpec 引用清零" "0"
else
    check "AC-001: OpenSpec 引用清零（剩余 $ref_count 处）" "1"
fi

# AC-002: setup/openspec 已删除
echo "AC-002: 检查 setup/openspec 目录..."
if [[ ! -d "setup/openspec" ]]; then
    check "AC-002: setup/openspec 已删除" "0"
else
    check "AC-002: setup/openspec 已删除" "1"
fi

# AC-003: .claude/commands/openspec 已删除
echo "AC-003: 检查 .claude/commands/openspec 目录..."
if [[ ! -d ".claude/commands/openspec" ]]; then
    check "AC-003: .claude/commands/openspec 已删除" "0"
else
    check "AC-003: .claude/commands/openspec 已删除" "1"
fi

# AC-004: dev-playbooks/specs/openspec-integration 已删除
echo "AC-004: 检查 dev-playbooks/specs/openspec-integration 目录..."
if [[ ! -d "dev-playbooks/specs/openspec-integration" ]]; then
    check "AC-004: dev-playbooks/specs/openspec-integration 已删除" "0"
else
    check "AC-004: dev-playbooks/specs/openspec-integration 已删除" "1"
fi

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
