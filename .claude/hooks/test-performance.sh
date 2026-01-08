#!/bin/bash
# Performance benchmark for augment-context.sh

HOOK_SCRIPT="/Users/ozbombor/Projects/dev-playbooks/.claude/hooks/augment-context.sh"

# 测试用例
declare -a TEST_CASES=(
  "修复 getUserById 函数的 bug"
  "分析 UserService 的依赖关系"
  "重构 src/utils/auth.ts 文件"
  "实现 validateEmail 和 sendNotification 功能"
  "优化 DatabaseConnection 类的性能"
)

echo "================================"
echo "augment-context.sh 性能测试"
echo "================================"
echo ""

# 清理缓存
rm -rf "${TMPDIR:-/tmp}/.devbooks-cache" 2>/dev/null
mkdir -p "${TMPDIR:-/tmp}/.devbooks-cache"

total_time=0
success_count=0

for i in "${!TEST_CASES[@]}"; do
  test_case="${TEST_CASES[$i]}"
  echo "测试 $((i+1))/${#TEST_CASES[@]}: $test_case"

  # 构造输入
  input=$(jq -n --arg prompt "$test_case" '{prompt: $prompt}')

  # 测量执行时间
  start_time=$(date +%s.%N)

  # 执行 hook（设置工作目录）
  result=$(echo "$input" | WORKING_DIRECTORY="$(pwd)" timeout 5 bash "$HOOK_SCRIPT" 2>&1)
  exit_code=$?

  end_time=$(date +%s.%N)
  elapsed=$(echo "$end_time - $start_time" | bc)

  # 统计
  total_time=$(echo "$total_time + $elapsed" | bc)

  if [ $exit_code -eq 0 ]; then
    success_count=$((success_count + 1))
    status="✅"
  else
    status="❌"
  fi

  echo "  $status 耗时: ${elapsed}s (exit code: $exit_code)"

  # 显示结果摘要
  if [ $exit_code -eq 0 ]; then
    ctx=$(echo "$result" | jq -r '.additionalContext' 2>/dev/null | head -20)
    if [ -n "$ctx" ]; then
      echo "  输出预览："
      echo "$ctx" | head -5 | sed 's/^/    /'
      echo "    ..."
    fi
  else
    echo "  错误: $result" | head -3 | sed 's/^/    /'
  fi

  echo ""
done

# 测试缓存性能
echo "================================"
echo "缓存性能测试"
echo "================================"
echo ""

cached_test="${TEST_CASES[0]}"
input=$(jq -n --arg prompt "$cached_test" '{prompt: $prompt}')

echo "第一次执行（无缓存）:"
start_time=$(date +%s.%N)
echo "$input" | WORKING_DIRECTORY="$(pwd)" timeout 5 bash "$HOOK_SCRIPT" > /dev/null 2>&1
end_time=$(date +%s.%N)
first_run=$(echo "$end_time - $start_time" | bc)
echo "  耗时: ${first_run}s"

echo ""
echo "第二次执行（有缓存）:"
start_time=$(date +%s.%N)
echo "$input" | WORKING_DIRECTORY="$(pwd)" timeout 5 bash "$HOOK_SCRIPT" > /dev/null 2>&1
end_time=$(date +%s.%N)
second_run=$(echo "$end_time - $start_time" | bc)
echo "  耗时: ${second_run}s"

speedup=$(echo "scale=2; $first_run / $second_run" | bc)
echo "  加速比: ${speedup}x"

# 总结
echo ""
echo "================================"
echo "性能总结"
echo "================================"
avg_time=$(echo "scale=3; $total_time / ${#TEST_CASES[@]}" | bc)
echo "测试用例数: ${#TEST_CASES[@]}"
echo "成功数: $success_count"
echo "总耗时: ${total_time}s"
echo "平均耗时: ${avg_time}s"
echo ""

if (( $(echo "$avg_time < 3" | bc -l) )); then
  echo "✅ 性能目标达成（平均 < 3 秒）"
else
  echo "⚠️ 性能目标未达成（平均 >= 3 秒）"
fi

# 缓存统计
cache_dir="${TMPDIR:-/tmp}/.devbooks-cache"
if [ -d "$cache_dir" ]; then
  cache_count=$(ls -1 "$cache_dir" 2>/dev/null | wc -l)
  echo "缓存文件数: $cache_count"
fi
