# DevBooks test entrypoint
# Phase 0: minimal test framework

.PHONY: test lint lint-all help-check all clean check-deps

# Default target
all: lint test

# Locate ripgrep (supports Homebrew and Claude Code bundled installs)
# Note: Use POSIX-compatible permission checks to avoid BSD vs GNU find differences
RG_PATH := $(shell command -v rg 2>/dev/null || \
	(test -x /opt/homebrew/bin/rg && echo /opt/homebrew/bin/rg) || \
	(test -x /usr/local/bin/rg && echo /usr/local/bin/rg) || \
	(find ~/.cli-versions -name rg -type f \( -perm -u=x -o -perm -g=x -o -perm -o=x \) 2>/dev/null | head -1))

# If rg is found, add its directory to PATH
ifneq ($(RG_PATH),)
  RG_DIR := $(dir $(RG_PATH))
  export PATH := $(RG_DIR):$(PATH)
endif

# Check dependencies
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

# Run all BATS tests
test: check-deps
	@echo "=== Running BATS tests ==="
	@bats tests/harden-devbooks-quality-gates/*.bats

# Run shellcheck (change package scripts)
# Note: Full lint runs via lint-all target
SCRIPTS_DIR := skills/devbooks-delivery-workflow/scripts
CHANGE_SCRIPTS := $(SCRIPTS_DIR)/change-check.sh \
                  $(SCRIPTS_DIR)/archive-decider.sh \
                  $(SCRIPTS_DIR)/runbook-derive.sh \
                  $(SCRIPTS_DIR)/handoff-check.sh \
                  $(SCRIPTS_DIR)/env-match-check.sh \
                  $(SCRIPTS_DIR)/audit-scope.sh \
                  $(SCRIPTS_DIR)/progress-dashboard.sh \
                  $(SCRIPTS_DIR)/migrate-to-v2-gates.sh \
                  $(SCRIPTS_DIR)/change-metadata-check.sh \
                  $(SCRIPTS_DIR)/reference-integrity-check.sh \
                  $(SCRIPTS_DIR)/check-completion-contract.sh \
                  $(SCRIPTS_DIR)/extension-pack-integrity-check.sh \
                  $(SCRIPTS_DIR)/required-gates-derive.sh \
                  $(SCRIPTS_DIR)/required-gates-check.sh \
                  $(SCRIPTS_DIR)/verification-anchors-check.sh \
                  $(SCRIPTS_DIR)/state-audit-check.sh \
                  $(SCRIPTS_DIR)/void-protocol-check.sh \
                  $(SCRIPTS_DIR)/knife-correctness-check.sh \
                  $(SCRIPTS_DIR)/epic-alignment-check.sh

lint: check-deps
	@echo "=== Running shellcheck (change package scripts) ==="
	@shellcheck -x $(CHANGE_SCRIPTS)
	@echo "All change package scripts pass shellcheck."

# Full lint (all scripts, including pre-existing warnings)
lint-all:
	@echo "=== Running shellcheck (all scripts) ==="
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck -x $(SCRIPTS_DIR)/*.sh; \
	else \
		echo "error: shellcheck not installed. Install with: brew install shellcheck"; \
		exit 1; \
	fi

# Check whether all scripts support --help
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

# Clean test artifacts
clean:
	@echo "=== Cleaning test artifacts ==="
	@rm -rf tests/harden-devbooks-quality-gates/tmp/
