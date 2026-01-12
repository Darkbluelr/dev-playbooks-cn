#!/bin/bash
# skills/devbooks-delivery-workflow/scripts/constitution-check.sh
# Constitution Compliance Check Script
#
# Checks if the project's constitution.md exists and is correctly formatted.
#
# Usage:
#   ./constitution-check.sh [project-root]
#   ./constitution-check.sh --help
#
# Exit codes:
#   0 - Constitution exists and is valid
#   1 - Constitution missing or invalid
#   2 - Usage error

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Version
VERSION="1.0.0"

# Show help
show_help() {
    cat << 'EOF'
Constitution Compliance Check Script (constitution-check.sh)

Usage:
  ./constitution-check.sh [options] [project-root]

Options:
  --help, -h       Show this help message
  --version, -v    Show version information
  --quiet, -q      Quiet mode, only output errors

Arguments:
  project-root     Project root directory, defaults to current directory

Checks:
  1. constitution.md file exists
  2. Contains "Part Zero" section
  3. Contains "GIP-" prefixed rules (at least 1)
  4. Contains "Escape Hatches" section

Exit codes:
  0 - Constitution exists and is valid
  1 - Constitution missing or invalid
  2 - Usage error

Examples:
  ./constitution-check.sh                    # Check current directory
  ./constitution-check.sh /path/to/project   # Check specified directory
  ./constitution-check.sh --quiet            # Quiet mode

EOF
}

# Show version
show_version() {
    echo "constitution-check.sh v${VERSION}"
}

# Log functions
log_info() {
    [[ "$QUIET" == "false" ]] && echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    [[ "$QUIET" == "false" ]] && echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $*" >&2
}

log_pass() {
    [[ "$QUIET" == "false" ]] && echo -e "${GREEN}[PASS]${NC} $*"
}

# Resolve truth root directory
# Prioritize checking dev-playbooks/, fallback to devbooks/
resolve_truth_root() {
    local root="$1"

    # Check root configuration in .devbooks/config.yaml
    if [[ -f "${root}/.devbooks/config.yaml" ]]; then
        local config_root
        config_root=$(grep "^root:" "${root}/.devbooks/config.yaml" 2>/dev/null | sed 's/root: *//' | tr -d "'" | tr -d '"' | tr -d '/' || true)
        if [[ -n "$config_root" && -d "${root}/${config_root}" ]]; then
            echo "${root}/${config_root}"
            return 0
        fi
    fi

    # Prioritize new path dev-playbooks/
    if [[ -d "${root}/dev-playbooks" ]]; then
        echo "${root}/dev-playbooks"
        return 0
    fi

    # Fallback to old path devbooks/
    if [[ -d "${root}/devbooks" ]]; then
        echo "${root}/devbooks"
        return 0
    fi

    # Not found
    echo ""
    return 1
}

# Check constitution
check_constitution() {
    local root="${1:-.}"
    local errors=0
    local checks_passed=0
    local total_checks=4

    # Resolve truth root directory
    local config_root
    config_root=$(resolve_truth_root "$root") || {
        log_error "Cannot find configuration root directory (dev-playbooks/ or devbooks/)"
        return 1
    }

    local constitution="${config_root}/constitution.md"

    log_info "Checking constitution file: $constitution"

    # Check 1: File exists
    if [[ -f "$constitution" ]]; then
        log_pass "constitution.md exists"
        ((checks_passed++))
    else
        log_error "constitution.md does not exist: $constitution"
        ((errors++))
    fi

    # If file does not exist, return immediately
    if [[ ! -f "$constitution" ]]; then
        echo ""
        log_error "Constitution check failed: $errors errors"
        return 1
    fi

    # Check 2: Part Zero section
    if grep -qE "^#+ *Part Zero" "$constitution" 2>/dev/null; then
        log_pass "Contains 'Part Zero' section"
        ((checks_passed++))
    else
        log_error "Missing 'Part Zero' section"
        ((errors++))
    fi

    # Check 3: GIP rules
    local gip_count
    gip_count=$(grep -cE "^#+ *GIP-[0-9]+" "$constitution" 2>/dev/null || echo "0")
    if [[ "$gip_count" -gt 0 ]]; then
        log_pass "Contains GIP rules (${gip_count} rules)"
        ((checks_passed++))
    else
        log_error "Missing GIP rules (need at least 1 GIP-xxx)"
        ((errors++))
    fi

    # Check 4: Escape Hatches section
    if grep -qE "^#+ *(Escape Hatches?)" "$constitution" 2>/dev/null; then
        log_pass "Contains 'Escape Hatches' section"
        ((checks_passed++))
    else
        log_error "Missing 'Escape Hatches' section"
        ((errors++))
    fi

    # Output summary
    echo ""
    if [[ "$errors" -eq 0 ]]; then
        log_info "Constitution check passed: ${checks_passed}/${total_checks} checks passed"
        return 0
    else
        log_error "Constitution check failed: ${checks_passed}/${total_checks} checks passed, ${errors} errors"
        return 1
    fi
}

# Main function
main() {
    QUIET="false"
    local project_root="."

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_help
                exit 0
                ;;
            --version|-v)
                show_version
                exit 0
                ;;
            --quiet|-q)
                QUIET="true"
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                echo "Use --help to see help" >&2
                exit 2
                ;;
            *)
                project_root="$1"
                shift
                ;;
        esac
    done

    # Check project root directory
    if [[ ! -d "$project_root" ]]; then
        log_error "Project root directory does not exist: $project_root"
        exit 2
    fi

    # Execute check
    if check_constitution "$project_root"; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
