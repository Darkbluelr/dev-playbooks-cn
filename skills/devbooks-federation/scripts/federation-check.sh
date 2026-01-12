#!/bin/bash
# DevBooks 跨仓库联邦检查脚本
# 用途：检查变更是否涉及联邦契约，并生成影响报告

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}[Federation]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[Federation]${NC} $1"; }
echo_error() { echo -e "${RED}[Federation]${NC} $1"; }

# 参数解析
PROJECT_ROOT="."
CHANGE_FILES=""
OUTPUT=""
QUIET=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --project-root) PROJECT_ROOT="$2"; shift 2 ;;
        --change-files) CHANGE_FILES="$2"; shift 2 ;;
        --output) OUTPUT="$2"; shift 2 ;;
        --quiet) QUIET=true; shift ;;
        -h|--help)
            echo "用法: federation-check.sh [options]"
            echo ""
            echo "Options:"
            echo "  --project-root <dir>   项目根目录 (默认: .)"
            echo "  --change-files <list>  变更文件列表 (逗号分隔)"
            echo "  --output <file>        输出报告路径"
            echo "  --quiet                静默模式"
            exit 0
            ;;
        *) echo_error "未知参数: $1"; exit 1 ;;
    esac
done

cd "$PROJECT_ROOT"

# 查找联邦配置
FEDERATION_CONFIG=""
if [ -f ".devbooks/federation.yaml" ]; then
    FEDERATION_CONFIG=".devbooks/federation.yaml"
elif [ -f "dev-playbooks/federation.yaml" ]; then
    FEDERATION_CONFIG="dev-playbooks/federation.yaml"
fi

if [ -z "$FEDERATION_CONFIG" ]; then
    [ "$QUIET" = false ] && echo_info "未找到联邦配置，跳过检查"
    exit 0
fi

[ "$QUIET" = false ] && echo_info "使用联邦配置: $FEDERATION_CONFIG"

# 如果没有指定变更文件，尝试从 git 获取
if [ -z "$CHANGE_FILES" ]; then
    if [ -d ".git" ]; then
        CHANGE_FILES=$(git diff --cached --name-only 2>/dev/null | tr '\n' ',' | sed 's/,$//')
        if [ -z "$CHANGE_FILES" ]; then
            CHANGE_FILES=$(git diff --name-only HEAD~1 2>/dev/null | tr '\n' ',' | sed 's/,$//')
        fi
    fi
fi

if [ -z "$CHANGE_FILES" ]; then
    [ "$QUIET" = false ] && echo_info "无变更文件，跳过检查"
    exit 0
fi

[ "$QUIET" = false ] && echo_info "检查变更文件: $CHANGE_FILES"

# 提取契约文件（简单实现：从 YAML 提取 contracts 行）
CONTRACT_PATTERNS=$(grep -E "^\s+-\s+\"" "$FEDERATION_CONFIG" 2>/dev/null | sed 's/.*"\([^"]*\)".*/\1/' | tr '\n' '|' | sed 's/|$//')

if [ -z "$CONTRACT_PATTERNS" ]; then
    [ "$QUIET" = false ] && echo_info "未定义契约文件，跳过检查"
    exit 0
fi

# 检查变更是否涉及契约
CONTRACT_CHANGES=""
IFS=',' read -ra FILES <<< "$CHANGE_FILES"
for file in "${FILES[@]}"; do
    if echo "$file" | grep -qE "$CONTRACT_PATTERNS"; then
        CONTRACT_CHANGES="$CONTRACT_CHANGES$file,"
    fi
done
CONTRACT_CHANGES=${CONTRACT_CHANGES%,}

if [ -z "$CONTRACT_CHANGES" ]; then
    [ "$QUIET" = false ] && echo_info "变更不涉及契约文件"
    exit 0
fi

# 发现契约变更
echo_warn "发现契约变更: $CONTRACT_CHANGES"

# 生成报告
REPORT=$(cat << EOF
# 跨仓库影响分析报告

> 自动生成于 $(date +%Y-%m-%d)
> 联邦配置: $FEDERATION_CONFIG

## 契约变更

以下文件涉及联邦契约：

$(echo "$CONTRACT_CHANGES" | tr ',' '\n' | while read f; do echo "- \`$f\`"; done)

## 建议动作

1. [ ] 确认变更类型（Breaking / Deprecation / Enhancement / Patch）
2. [ ] 运行 \`devbooks-federation\` 进行完整跨仓库影响分析
3. [ ] 如果是 Breaking 变更，通知下游消费者
4. [ ] 更新 CHANGELOG

## 下游消费者

$(grep -A20 "downstreams:" "$FEDERATION_CONFIG" 2>/dev/null | grep -E "^\s+-\s+name:" | sed 's/.*name:\s*"\([^"]*\)".*/- \1/' || echo "（请查看 federation.yaml）")

---

> 提示：使用 \`devbooks-federation\` Skill 进行完整分析
EOF
)

# 输出报告
if [ -n "$OUTPUT" ]; then
    echo "$REPORT" > "$OUTPUT"
    echo_info "报告已生成: $OUTPUT"
else
    echo ""
    echo "$REPORT"
fi

# 返回非零状态表示有契约变更
exit 1
