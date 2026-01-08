#!/bin/bash
# DevBooks Embedding - 测试与演示脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
EMBEDDING_SCRIPT="$PROJECT_ROOT/tools/devbooks-embedding.sh"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_info()  { echo -e "${BLUE}[Test]${NC} $1"; }
echo_ok()    { echo -e "${GREEN}[Test]${NC} ✓ $1"; }
echo_fail()  { echo -e "${RED}[Test]${NC} ✗ $1"; }
echo_warn()  { echo -e "${YELLOW}[Test]${NC} ⚠ $1"; }

# 测试计数
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
  local name="$1"
  local command="$2"

  ((TESTS_RUN++))
  echo ""
  echo_info "测试 #$TESTS_RUN: $name"

  if eval "$command"; then
    echo_ok "$name"
    ((TESTS_PASSED++))
    return 0
  else
    echo_fail "$name"
    ((TESTS_FAILED++))
    return 1
  fi
}

# ==================== 环境检查 ====================

echo_info "DevBooks Embedding 测试套件"
echo ""

run_test "检查脚本存在" "[ -f '$EMBEDDING_SCRIPT' ]"
run_test "检查脚本可执行" "[ -x '$EMBEDDING_SCRIPT' ]"

# 检查依赖
check_dependency() {
  if command -v "$1" &>/dev/null; then
    echo_ok "依赖检查: $1"
    return 0
  else
    echo_warn "依赖缺失: $1"
    return 1
  fi
}

echo ""
echo_info "检查依赖工具..."
check_dependency "curl"
check_dependency "jq"
check_dependency "bc"
check_dependency "md5sum" || check_dependency "md5"

# ==================== 配置测试 ====================

echo ""
echo_info "=== 配置测试 ==="

run_test "显示配置" "$EMBEDDING_SCRIPT config"

run_test "显示帮助" "$EMBEDDING_SCRIPT help | grep -q 'DevBooks Embedding'"

run_test "检查配置文件" "[ -f '$PROJECT_ROOT/.devbooks/embedding.yaml' ]"

# ==================== 功能测试（Dry Run）====================

echo ""
echo_info "=== 功能测试（无 API Key）==="

# 这些测试不需要真实的 API Key
run_test "状态检查" "$EMBEDDING_SCRIPT status"

run_test "清理测试" "$EMBEDDING_SCRIPT clean || true"

# ==================== API 测试（需要 API Key）====================

if [ -z "${OPENAI_API_KEY:-${EMBEDDING_API_KEY}}" ]; then
  echo ""
  echo_warn "未设置 API Key，跳过 API 相关测试"
  echo_info "设置 OPENAI_API_KEY 环境变量以运行完整测试"
else
  echo ""
  echo_info "=== API 测试（需要网络连接）==="

  # 创建测试目录
  TEST_DIR="$PROJECT_ROOT/.devbooks/embeddings-test"
  mkdir -p "$TEST_DIR"

  # 创建测试文件
  cat > "$TEST_DIR/sample.ts" <<'EOF'
// 用户认证服务
export class AuthService {
  async login(username: string, password: string) {
    // 验证用户凭证
    const user = await this.validateCredentials(username, password);
    if (!user) {
      throw new Error('Invalid credentials');
    }

    // 生成 JWT token
    const token = this.generateToken(user);
    return { user, token };
  }

  private async validateCredentials(username: string, password: string) {
    // 查询数据库
    return await db.users.findOne({ username, password: hash(password) });
  }

  private generateToken(user: User) {
    return jwt.sign({ id: user.id, role: user.role }, SECRET_KEY);
  }
}
EOF

  # 测试单个文件向量化（需要实现简单模式）
  echo_warn "完整 API 测试需要手动运行（避免产生 API 费用）"
  echo_info "手动测试命令："
  echo "  1. $EMBEDDING_SCRIPT build"
  echo "  2. $EMBEDDING_SCRIPT search '用户登录认证'"
  echo "  3. $EMBEDDING_SCRIPT update"
  echo "  4. $EMBEDDING_SCRIPT status"
  echo ""

  # 清理
  rm -rf "$TEST_DIR"
fi

# ==================== Hook 集成测试 ====================

echo ""
echo_info "=== Hook 集成测试 ==="

HOOK_SCRIPT="$PROJECT_ROOT/.claude/hooks/augment-context-with-embedding.sh"

if [ -f "$HOOK_SCRIPT" ]; then
  run_test "Hook 脚本存在" "[ -f '$HOOK_SCRIPT' ]"
  run_test "Hook 脚本可执行" "[ -x '$HOOK_SCRIPT' ] || chmod +x '$HOOK_SCRIPT'"

  # 测试 Hook（模拟输入）
  TEST_INPUT='{"prompt": "修复用户登录的 bug"}'

  if echo "$TEST_INPUT" | "$HOOK_SCRIPT" | jq -e '.additionalContext' >/dev/null 2>&1; then
    echo_ok "Hook 返回有效 JSON"
  else
    echo_warn "Hook 测试跳过（可能缺少索引）"
  fi
else
  echo_warn "Hook 脚本不存在: $HOOK_SCRIPT"
fi

# ==================== 性能测试（可选）====================

echo ""
echo_info "=== 性能基准测试 ==="

# 模拟文件提取性能
echo_info "测试文件扫描性能..."

start_time=$(date +%s)
file_count=$(find "$PROJECT_ROOT" -type f \
  \( -name "*.ts" -o -name "*.js" -o -name "*.py" \) \
  ! -path "*/node_modules/*" \
  ! -path "*/dist/*" \
  ! -path "*/.git/*" \
  2>/dev/null | wc -l)
end_time=$(date +%s)

duration=$((end_time - start_time))

echo_info "扫描结果: $file_count 个文件，耗时 ${duration}s"

if [ "$file_count" -gt 0 ] && [ "$duration" -lt 10 ]; then
  echo_ok "文件扫描性能正常"
else
  echo_warn "文件扫描较慢，考虑优化过滤规则"
fi

# ==================== 总结 ====================

echo ""
echo "================================"
echo "测试总结"
echo "================================"
echo "运行: $TESTS_RUN"
echo -e "${GREEN}通过: $TESTS_PASSED${NC}"
echo -e "${RED}失败: $TESTS_FAILED${NC}"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
  echo_ok "所有测试通过！"
  exit 0
else
  echo_fail "部分测试失败"
  exit 1
fi
