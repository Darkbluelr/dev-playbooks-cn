#!/bin/bash
# verify-npm-package.sh - 验证 npm 包结构
#
# 验证 AC-011 ~ AC-016

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

echo "=== npm 包验证 ==="
echo ""

# AC-011: CLI 入口存在且可执行
# 注意：设计变更为 `devbooks init` 而非 `create-devbooks`
echo "AC-011: 检查 CLI 入口..."
if [[ -f "bin/devbooks.js" ]] && [[ -x "bin/devbooks.js" ]]; then
    check "AC-011: CLI 入口存在且可执行" "0"
else
    check "AC-011: CLI 入口存在且可执行" "1"
fi

# AC-012: package.json 存在且有效
echo "AC-012: 检查 package.json..."
if [[ -f "package.json" ]] && grep -q '"name": "devbooks"' package.json; then
    check "AC-012: package.json 存在且有效" "0"
else
    check "AC-012: package.json 存在且有效" "1"
fi

# AC-013: templates/ 目录存在
echo "AC-013: 检查 templates/ 目录..."
if [[ -d "templates" ]]; then
    check "AC-013: templates/ 目录存在" "0"
else
    check "AC-013: templates/ 目录存在" "1"
fi

# AC-014: Skills 数量正确（21 个 devbooks-* Skills）
echo "AC-014: 检查 Skills 数量..."
skill_count=$(ls -d skills/devbooks-* 2>/dev/null | wc -l | tr -d ' ')
if [[ "$skill_count" -ge 20 ]]; then
    check "AC-014: Skills 数量正确（$skill_count 个）" "0"
else
    check "AC-014: Skills 数量正确（$skill_count 个，期望 >= 20）" "1"
fi

# AC-015: .npmignore 存在
echo "AC-015: 检查 .npmignore..."
if [[ -f ".npmignore" ]]; then
    check "AC-015: .npmignore 存在" "0"
else
    check "AC-015: .npmignore 存在" "1"
fi

# AC-016: npm pack 不包含项目变更包（排除模板目录）
# 注意：templates/dev-playbooks/changes/ 是用户项目模板，应包含
#       dev-playbooks/changes/ 是项目开发变更包，应排除
echo "AC-016: 检查 npm pack 输出..."
if npm pack --dry-run 2>&1 | grep "changes/" | grep -v "templates/" | grep -q "changes/"; then
    check "AC-016: npm pack 不包含 changes/" "1"
else
    check "AC-016: npm pack 不包含 changes/" "0"
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
