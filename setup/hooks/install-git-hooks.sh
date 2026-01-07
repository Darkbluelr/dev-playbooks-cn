#!/bin/bash
# DevBooks Git Hooks 安装脚本
# 用途：为项目安装自动索引 Git Hooks

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-.}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查是否在 Git 仓库中
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo_error "未找到 .git 目录，请在 Git 仓库根目录运行此脚本"
    exit 1
fi

HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

# 检测项目语言栈
detect_language() {
    if [ -f "$PROJECT_ROOT/package.json" ]; then
        echo "typescript"
    elif [ -f "$PROJECT_ROOT/pyproject.toml" ] || [ -f "$PROJECT_ROOT/setup.py" ] || [ -f "$PROJECT_ROOT/requirements.txt" ]; then
        echo "python"
    elif [ -f "$PROJECT_ROOT/go.mod" ]; then
        echo "go"
    elif [ -f "$PROJECT_ROOT/Cargo.toml" ]; then
        echo "rust"
    elif [ -f "$PROJECT_ROOT/pom.xml" ] || [ -f "$PROJECT_ROOT/build.gradle" ]; then
        echo "java"
    else
        echo "unknown"
    fi
}

LANG=$(detect_language)
echo_info "检测到项目语言：$LANG"

# 生成 post-commit hook
cat > "$HOOKS_DIR/post-commit" << 'HOOK_EOF'
#!/bin/bash
# DevBooks: 自动 SCIP 索引 + COD 模型更新 Hook
# 在每次 commit 后异步重建索引和更新 COD 产物

LOCK_FILE="/tmp/scip-index-$(pwd | md5sum | cut -d' ' -f1).lock"

# 防止并发执行
if [ -f "$LOCK_FILE" ]; then
    exit 0
fi

# 检测语言并选择索引器
index_project() {
    touch "$LOCK_FILE"
    trap "rm -f $LOCK_FILE" EXIT

    # 1. 更新 SCIP 索引
    if [ -f "package.json" ]; then
        if command -v scip-typescript &> /dev/null; then
            echo "[DevBooks] 更新 TypeScript/JavaScript 索引..."
            scip-typescript index --output index.scip 2>/dev/null
        fi
    elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
        if command -v scip-python &> /dev/null; then
            echo "[DevBooks] 更新 Python 索引..."
            scip-python index . --output index.scip 2>/dev/null
        fi
    elif [ -f "go.mod" ]; then
        if command -v scip-go &> /dev/null; then
            echo "[DevBooks] 更新 Go 索引..."
            scip-go --output index.scip 2>/dev/null
        fi
    fi

    # 2. 更新 COD 模型（如果脚本存在）
    COD_SCRIPT=""
    if [ -f ".devbooks/scripts/cod-update.sh" ]; then
        COD_SCRIPT=".devbooks/scripts/cod-update.sh"
    elif [ -f "$HOME/.claude/skills/devbooks-brownfield-bootstrap/scripts/cod-update.sh" ]; then
        COD_SCRIPT="$HOME/.claude/skills/devbooks-brownfield-bootstrap/scripts/cod-update.sh"
    elif [ -f "$HOME/.codex/skills/devbooks-brownfield-bootstrap/scripts/cod-update.sh" ]; then
        COD_SCRIPT="$HOME/.codex/skills/devbooks-brownfield-bootstrap/scripts/cod-update.sh"
    fi

    if [ -n "$COD_SCRIPT" ] && [ -x "$COD_SCRIPT" ]; then
        echo "[DevBooks] 更新 COD 模型..."
        bash "$COD_SCRIPT" --project-root "$(pwd)" --quiet 2>/dev/null
    fi
}

# 后台执行，不阻塞 commit
(index_project &) 2>/dev/null
HOOK_EOF

chmod +x "$HOOKS_DIR/post-commit"
echo_info "已安装 post-commit hook"

# 生成 post-merge hook（pull 后也更新索引）
cat > "$HOOKS_DIR/post-merge" << 'HOOK_EOF'
#!/bin/bash
# DevBooks: Pull 后自动更新索引
exec "$(dirname "$0")/post-commit"
HOOK_EOF

chmod +x "$HOOKS_DIR/post-merge"
echo_info "已安装 post-merge hook"

# 生成 post-checkout hook（切换分支后更新索引）
cat > "$HOOKS_DIR/post-checkout" << 'HOOK_EOF'
#!/bin/bash
# DevBooks: 切换分支后自动更新索引
# 只在分支切换时触发（$3 = 1），文件 checkout 时不触发
if [ "$3" = "1" ]; then
    exec "$(dirname "$0")/post-commit"
fi
HOOK_EOF

chmod +x "$HOOKS_DIR/post-checkout"
echo_info "已安装 post-checkout hook"

echo ""
echo_info "Git Hooks 安装完成！"
echo ""
echo "已安装的 Hooks："
echo "  - post-commit    : 每次提交后自动更新 SCIP 索引"
echo "  - post-merge     : 每次 pull 后自动更新 SCIP 索引"
echo "  - post-checkout  : 切换分支后自动更新 SCIP 索引"
echo ""
echo "前提条件："
case $LANG in
    typescript)
        echo "  npm install -g @anthropic-ai/scip-typescript"
        ;;
    python)
        echo "  pip install scip-python"
        ;;
    go)
        echo "  go install github.com/sourcegraph/scip-go@latest"
        ;;
    *)
        echo "  请根据项目语言安装对应的 SCIP 索引器"
        ;;
esac
echo ""
echo "首次运行请手动生成索引，后续将自动增量更新。"
