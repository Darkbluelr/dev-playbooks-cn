#!/bin/bash
# verify-all.sh - 运行所有验证脚本
#
# 汇总 AC-001 ~ AC-022 验证结果

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     DevBooks Independence 验证套件            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
echo ""

# 运行各验证脚本
echo -e "${YELLOW}>>> OpenSpec 清理验证 (AC-001 ~ AC-004)${NC}"
echo ""
openspec_result=0
if "$SCRIPT_DIR/verify-openspec-free.sh"; then
    openspec_result=1
fi
echo ""

echo -e "${YELLOW}>>> Slash 命令验证 (AC-005 ~ AC-010)${NC}"
echo ""
slash_result=0
if "$SCRIPT_DIR/verify-slash-commands.sh"; then
    slash_result=1
fi
echo ""

echo -e "${YELLOW}>>> npm 包验证 (AC-011 ~ AC-016)${NC}"
echo ""
npm_result=0
if "$SCRIPT_DIR/verify-npm-package.sh"; then
    npm_result=1
fi
echo ""

echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                   汇总结果                     ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
echo ""

if [[ $openspec_result -eq 1 ]]; then
    echo -e "${GREEN}✅ OpenSpec 清理验证${NC}"
else
    echo -e "${RED}❌ OpenSpec 清理验证${NC}"
fi

if [[ $slash_result -eq 1 ]]; then
    echo -e "${GREEN}✅ Slash 命令验证${NC}"
else
    echo -e "${RED}❌ Slash 命令验证${NC}"
fi

if [[ $npm_result -eq 1 ]]; then
    echo -e "${GREEN}✅ npm 包验证${NC}"
else
    echo -e "${RED}❌ npm 包验证${NC}"
fi

echo ""

total=$((openspec_result + slash_result + npm_result))
if [[ $total -eq 3 ]]; then
    echo -e "${GREEN}🎉 所有验证通过！DevBooks 独立性验证成功。${NC}"
    exit 0
else
    echo -e "${RED}⚠️  部分验证失败，请检查上述输出。${NC}"
    exit 1
fi
