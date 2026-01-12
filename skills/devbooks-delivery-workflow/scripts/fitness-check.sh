#!/bin/bash
# skills/devbooks-delivery-workflow/scripts/fitness-check.sh
# Architecture Fitness Check Script
#
# Executes architecture fitness function checks to verify code conforms to architectural rules.
#
# Usage:
#   ./fitness-check.sh [options]
#   ./fitness-check.sh --help
#
# Options:
#   --mode MODE         Check mode: warn (warning) | error (blocking)
#   --rules FILE        Rules file path
#   --project-root DIR  Project root directory
#   --file FILE         Check a single file (for testing)
#
# Exit codes:
#   0 - Check passed (or warnings in warn mode)
#   1 - Check failed (violations in error mode)
#   2 - Usage error

set -euo pipefail

# Version
VERSION="1.0.0"

# Defaults
mode="warn"
rules_file=""
project_root="."
single_file=""

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
errors=0
warnings=0

# Show help
show_help() {
    cat << 'EOF'
Architecture Fitness Check Script (fitness-check.sh)

Usage:
  ./fitness-check.sh [options]

Options:
  --mode MODE         Check mode: warn (warning only) | error (blocking)
  --rules FILE        Rules file path (default: specs/architecture/fitness-rules.md)
  --project-root DIR  Project root directory, default is current directory
  --file FILE         Check a single file (for testing)
  --help, -h          Show this help message
  --version, -v       Show version information

Supported rule types:
  FR-001: Layered architecture check (Controller -> Service -> Repository)
  FR-002: Circular dependency check (basic version)
  FR-003: Sensitive file protection

Exit codes:
  0 - Check passed (or warnings in warn mode)
  1 - Check failed (violations in error mode)
  2 - Usage error

Examples:
  ./fitness-check.sh                          # Default check
  ./fitness-check.sh --mode error             # Strict mode
  ./fitness-check.sh --rules custom-rules.md  # Custom rules file
  ./fitness-check.sh --file src/test.js       # Check a single file

EOF
}

# Show version
show_version() {
    echo "fitness-check.sh v${VERSION}"
}

# Log functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" >&2
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $*"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $*" >&2
    if [[ "$mode" == "error" ]]; then
        errors=$((errors + 1))
    else
        warnings=$((warnings + 1))
    fi
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
    warnings=$((warnings + 1))
}

# ============================================================================
# FR-001: Layered Architecture Check
# Controller should not call Repository directly
# ============================================================================
check_layered_architecture() {
    log_info "FR-001: Checking layered architecture..."

    local src_dir="${project_root}/src"
    local controllers_dir="${src_dir}/controllers"

    if [[ ! -d "$controllers_dir" ]]; then
        # Try other common paths
        controllers_dir="${src_dir}/controller"
        if [[ ! -d "$controllers_dir" ]]; then
            log_info "  No controllers directory found, skipping"
            return 0
        fi
    fi

    local violations=""

    # Find Controller code that directly calls Repository
    # Pattern: Repository.xxx or import ... from '...repository'
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue

        # Check direct Repository method calls
        local matches
        matches=$(grep -nE "Repository\.(find|save|delete|update|create|get)|new [A-Z][a-zA-Z]*Repository" "$file" 2>/dev/null || true)

        if [[ -n "$matches" ]]; then
            violations="${violations}${file}:\n${matches}\n\n"
        fi
    done < <(find "$controllers_dir" -type f \( -name "*.ts" -o -name "*.js" \) 2>/dev/null)

    if [[ -n "$violations" ]]; then
        log_fail "FR-001: Layered architecture violation - Controller directly accesses Repository"
        echo -e "  Violation details:\n$violations" >&2
        return 1
    fi

    log_pass "FR-001: Layered architecture check passed"
    return 0
}

# ============================================================================
# FR-002: Circular Dependency Check (basic version)
# Detect obvious circular imports
# ============================================================================
check_circular_dependencies() {
    log_info "FR-002: Checking circular dependencies..."

    local src_dir="${project_root}/src"

    if [[ ! -d "$src_dir" ]]; then
        log_info "  No src directory found, skipping"
        return 0
    fi

    # Basic check: mutual references within the same directory
    # This is a simplified version, full detection requires more complex graph analysis

    local circular_count=0

    # Find potential circular reference patterns
    # Example: a.ts import from './b' and b.ts import from './a'
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue

        local dir
        dir=$(dirname "$file")
        local base
        base=$(basename "$file" | sed 's/\.\(ts\|js\|tsx\|jsx\)$//')

        # Get relative imports from this file
        local imports
        imports=$(grep -oE "from ['\"]\.\/[a-zA-Z0-9_-]+['\"]" "$file" 2>/dev/null | sed "s/from ['\"]\.\\///g; s/['\"]//g" || true)

        for imported in $imports; do
            local imported_file="${dir}/${imported}.ts"
            [[ ! -f "$imported_file" ]] && imported_file="${dir}/${imported}.js"
            [[ ! -f "$imported_file" ]] && continue

            # Check if imported file imports back
            if grep -qE "from ['\"]\./${base}['\"]" "$imported_file" 2>/dev/null; then
                log_warn "FR-002: Possible circular dependency: ${file} <-> ${imported_file}"
                circular_count=$((circular_count + 1))
            fi
        done
    done < <(find "$src_dir" -type f \( -name "*.ts" -o -name "*.js" \) 2>/dev/null | head -100)

    if [[ $circular_count -gt 0 ]]; then
        log_warn "FR-002: Detected ${circular_count} possible circular dependencies"
        return 0  # Only warn, do not block
    fi

    log_pass "FR-002: Circular dependency check passed"
    return 0
}

# ============================================================================
# FR-003: Sensitive File Protection
# Prevent sensitive files from being accidentally modified or committed
# ============================================================================
check_sensitive_files() {
    log_info "FR-003: Checking sensitive files..."

    # Sensitive file patterns
    local sensitive_patterns=(
        ".env"
        ".env.local"
        ".env.production"
        "credentials.json"
        "secrets.yaml"
        "*.pem"
        "*.key"
        "id_rsa"
        "id_ed25519"
    )

    local violations=0

    for pattern in "${sensitive_patterns[@]}"; do
        # Check if sensitive files are being tracked
        if command -v git >/dev/null 2>&1 && git -C "$project_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            local tracked
            tracked=$(git -C "$project_root" ls-files "$pattern" 2>/dev/null || true)
            if [[ -n "$tracked" ]]; then
                log_fail "FR-003: Sensitive file tracked by Git: ${tracked}"
                violations=$((violations + 1))
            fi
        fi
    done

    # Check if .gitignore contains sensitive patterns
    local gitignore="${project_root}/.gitignore"
    if [[ -f "$gitignore" ]]; then
        local missing_patterns=()
        for pattern in ".env" "*.key" "*.pem"; do
            if ! grep -qE "^${pattern}$|^\\*${pattern}$" "$gitignore" 2>/dev/null; then
                missing_patterns+=("$pattern")
            fi
        done

        if [[ ${#missing_patterns[@]} -gt 0 ]]; then
            log_warn "FR-003: .gitignore should add sensitive file patterns: ${missing_patterns[*]}"
        fi
    fi

    if [[ $violations -eq 0 ]]; then
        log_pass "FR-003: Sensitive file check passed"
        return 0
    fi

    return 1
}

# ============================================================================
# Check a single file (for testing)
# ============================================================================
check_single_file() {
    local file="$1"

    log_info "Checking file: $file"

    if [[ ! -f "$file" ]]; then
        log_fail "File does not exist: $file"
        return 1
    fi

    # FR-001: Layered architecture check
    if [[ "$file" =~ controller ]]; then
        local matches
        matches=$(grep -nE "Repository\.(find|save|delete|update|create|get)" "$file" 2>/dev/null || true)
        if [[ -n "$matches" ]]; then
            log_fail "FR-001: Controller directly accesses Repository"
            echo "  $matches" >&2
            return 1
        fi
    fi

    log_pass "File check passed: $file"
    return 0
}

# ============================================================================
# Main function
# ============================================================================
main() {
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
            --mode)
                mode="${2:-warn}"
                shift 2
                ;;
            --rules)
                rules_file="${2:-}"
                shift 2
                ;;
            --project-root)
                project_root="${2:-.}"
                shift 2
                ;;
            --file)
                single_file="${2:-}"
                shift 2
                ;;
            -*)
                echo "error: unknown option: $1" >&2
                echo "Use --help for usage" >&2
                exit 2
                ;;
            *)
                shift
                ;;
        esac
    done

    # Validate mode
    case "$mode" in
        warn|error) ;;
        *)
            echo "error: invalid --mode: $mode (must be warn or error)" >&2
            exit 2
            ;;
    esac

    echo "=========================================="
    echo "Architecture Fitness Check (fitness-check.sh)"
    echo "Mode: $mode"
    echo "Project: $project_root"
    echo "=========================================="
    echo ""

    # Single file check mode
    if [[ -n "$single_file" ]]; then
        check_single_file "$single_file"
        exit $?
    fi

    # Run all checks
    check_layered_architecture || true
    check_circular_dependencies || true
    check_sensitive_files || true

    # Output summary
    echo ""
    echo "=========================================="
    echo "Check Complete"
    echo "  Errors: $errors"
    echo "  Warnings: $warnings"
    echo "=========================================="

    if [[ $errors -gt 0 ]]; then
        echo ""
        log_fail "Check failed: ${errors} error(s)"
        exit 1
    fi

    if [[ $warnings -gt 0 ]]; then
        echo ""
        log_warn "Check passed: ${warnings} warning(s)"
        exit 0
    fi

    echo ""
    log_pass "Check passed: no violations"
    exit 0
}

# Run main function
main "$@"
