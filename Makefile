# DevBooks 测试入口
# Phase 0: 最小测试框架

.PHONY: test lint lint-all help-check all clean check-deps

# 默认目标
all: lint test

# 查找 ripgrep 路径（支持 Homebrew 和 Claude Code 内置）
# 注意：使用 POSIX 兼容的权限检查，避免 BSD vs GNU find 差异
RG_PATH := $(shell command -v rg 2>/dev/null || \
	(test -x /opt/homebrew/bin/rg && echo /opt/homebrew/bin/rg) || \
	(test -x /usr/local/bin/rg && echo /usr/local/bin/rg) || \
	(find ~/.cli-versions -name rg -type f \( -perm -u=x -o -perm -g=x -o -perm -o=x \) 2>/dev/null | head -1))

# 如果找到 rg，将其目录加入 PATH
ifneq ($(RG_PATH),)
  RG_DIR := $(dir $(RG_PATH))
  export PATH := $(RG_DIR):$(PATH)
endif

# 检查依赖
check-deps:
	@echo "=== Checking dependencies ==="
	@if [ -z "$(RG_PATH)" ]; then \
		echo "error: ripgrep (rg) not found. Install with: brew install ripgrep"; \
		exit 1; \
	fi
	@echo "  rg: $(RG_PATH)"
	@if ! command -v bats >/dev/null 2>&1; then \
		echo "error: bats not installed. Install with: brew install bats-core"; \
		exit 1; \
	fi
	@echo "  bats: $$(command -v bats)"
	@if ! command -v shellcheck >/dev/null 2>&1; then \
		echo "error: shellcheck not installed. Install with: brew install shellcheck"; \
		exit 1; \
	fi
	@echo "  shellcheck: $$(command -v shellcheck)"
	@echo "All dependencies found."

# 运行所有 BATS 测试
test: check-deps
	@echo "=== Running BATS tests ==="
	@bats tests/harden-devbooks-quality-gates/*.bats

# 运行 shellcheck 静态检查（本变更包的脚本）
# 注意：完整 lint 使用 lint-all 目标
SCRIPTS_DIR := skills/devbooks-delivery-workflow/scripts
CHANGE_SCRIPTS := $(SCRIPTS_DIR)/change-check.sh \
                  $(SCRIPTS_DIR)/handoff-check.sh \
                  $(SCRIPTS_DIR)/env-match-check.sh \
                  $(SCRIPTS_DIR)/audit-scope.sh \
                  $(SCRIPTS_DIR)/progress-dashboard.sh \
                  $(SCRIPTS_DIR)/migrate-to-v2-gates.sh

lint: check-deps
	@echo "=== Running shellcheck (change package scripts) ==="
	@shellcheck -x $(CHANGE_SCRIPTS)
	@echo "All change package scripts pass shellcheck."

# 完整 lint（所有脚本，包含预先存在的警告）
lint-all:
	@echo "=== Running shellcheck (all scripts) ==="
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck -x $(SCRIPTS_DIR)/*.sh; \
	else \
		echo "error: shellcheck not installed. Install with: brew install shellcheck"; \
		exit 1; \
	fi

# 检查所有脚本是否支持 --help
help-check:
	@echo "=== Checking --help support ==="
	@failed=0; \
	for script in skills/devbooks-delivery-workflow/scripts/*.sh; do \
		if ! "$$script" --help >/dev/null 2>&1; then \
			echo "FAIL: $$script does not support --help"; \
			failed=1; \
		else \
			echo "OK: $$script"; \
		fi; \
	done; \
	if [ "$$failed" -eq 1 ]; then exit 1; fi

# 清理测试产物
clean:
	@echo "=== Cleaning test artifacts ==="
	@rm -rf tests/harden-devbooks-quality-gates/tmp/
