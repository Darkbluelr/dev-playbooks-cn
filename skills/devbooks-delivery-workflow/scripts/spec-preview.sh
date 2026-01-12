#!/bin/bash
# skills/devbooks-delivery-workflow/scripts/spec-preview.sh
# Spec Conflict Pre-check Script
#
# Reads the spec delta from a change package and checks for conflicts in the staging layer.
#
# Usage:
#   ./spec-preview.sh <change-id> [options]
#   ./spec-preview.sh --help
#
# Exit codes:
#   0 - No conflicts
#   1 - Conflicts detected
#   2 - Usage error

set -euo pipefail

VERSION="1.0.0"

# Defaults
project_root="."
change_root="changes"
truth_root="specs"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Show help
show_help() {
    cat << 'EOF'
Spec Conflict Pre-check Script (spec-preview.sh)

Usage:
  ./spec-preview.sh <change-id> [options]

Options:
  --project-root DIR  Project root directory, default is current directory
  --change-root DIR   Change package directory, default is changes
  --truth-root DIR    Truth source directory, default is specs
  --help, -h          Show this help message
  --version, -v       Show version information

Conflict detection:
  1. File-level conflicts: Same target file modified by multiple change packages
  2. Content-level conflicts: Same REQ-xxx being modified

Exit codes:
  0 - No conflicts
  1 - Conflicts detected
  2 - Usage error

Examples:
  ./spec-preview.sh my-feature
  ./spec-preview.sh my-feature --change-root dev-playbooks/changes

EOF
}

show_version() {
    echo "spec-preview.sh v${VERSION}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $*"
}

# Main function
main() {
    local change_id=""

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
            --project-root)
                project_root="${2:-.}"
                shift 2
                ;;
            --change-root)
                change_root="${2:-changes}"
                shift 2
                ;;
            --truth-root)
                truth_root="${2:-specs}"
                shift 2
                ;;
            -*)
                log_error "Unknown option: $1"
                exit 2
                ;;
            *)
                change_id="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$change_id" ]]; then
        log_error "Missing change-id"
        exit 2
    fi

    # Build paths
    local change_dir="${project_root}/${change_root}/${change_id}"
    local staged_dir="${project_root}/${truth_root}/_staged"
    local specs_delta_dir="${change_dir}/specs"

    log_info "Pre-checking change package: ${change_id}"
    log_info "  Change directory: ${change_dir}"
    log_info "  Staging directory: ${staged_dir}"

    # Check change package exists
    if [[ ! -d "$change_dir" ]]; then
        log_error "Change package does not exist: ${change_dir}"
        exit 2
    fi

    # Check if there is spec delta
    if [[ ! -d "$specs_delta_dir" ]]; then
        log_info "No spec delta, skipping pre-check"
        exit 0
    fi

    local conflicts=0
    local file_conflicts=""
    local req_conflicts=""

    # File-level conflict detection
    log_info "Checking file-level conflicts..."
    while IFS= read -r delta_file; do
        [[ -z "$delta_file" ]] && continue

        local relative_path="${delta_file#$specs_delta_dir/}"
        local staged_path="${staged_dir}/${relative_path}"

        if [[ -f "$staged_path" ]]; then
            file_conflicts="${file_conflicts}  ${relative_path}\n"
            conflicts=$((conflicts + 1))
        fi
    done < <(find "$specs_delta_dir" -type f -name "*.md" 2>/dev/null)

    # Content-level conflict detection (REQ-xxx)
    log_info "Checking content-level conflicts..."
    local current_reqs
    current_reqs=$(grep -rhoE "REQ-[A-Z0-9]+-[0-9]+" "$specs_delta_dir" 2>/dev/null | sort -u || true)

    if [[ -n "$current_reqs" && -d "$staged_dir" ]]; then
        while IFS= read -r req; do
            [[ -z "$req" ]] && continue

            if grep -rq "$req" "$staged_dir" 2>/dev/null; then
                req_conflicts="${req_conflicts}  ${req}\n"
                conflicts=$((conflicts + 1))
            fi
        done <<< "$current_reqs"
    fi

    # Output results
    echo ""
    if [[ $conflicts -gt 0 ]]; then
        log_error "Detected ${conflicts} conflict(s)"

        if [[ -n "$file_conflicts" ]]; then
            echo -e "\nFile-level conflicts:"
            echo -e "$file_conflicts"
        fi

        if [[ -n "$req_conflicts" ]]; then
            echo -e "\nContent-level conflicts (REQ-xxx):"
            echo -e "$req_conflicts"
        fi

        exit 1
    fi

    log_pass "No conflicts, ready to stage"
    exit 0
}

main "$@"
