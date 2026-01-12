#!/bin/bash
# skills/devbooks-delivery-workflow/scripts/spec-rollback.sh
# Spec Rollback Script
#
# Rolls back spec sync operations.
#
# Usage:
#   ./spec-rollback.sh <change-id> [options]
#   ./spec-rollback.sh --help
#
# Exit codes:
#   0 - Rollback successful
#   1 - Rollback failed
#   2 - Usage error

set -euo pipefail

VERSION="1.0.0"

project_root="."
truth_root="specs"
change_root="changes"
target="staged"
dry_run=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    cat << 'EOF'
Spec Rollback Script (spec-rollback.sh)

Usage:
  ./spec-rollback.sh <change-id> [options]

Options:
  --project-root DIR  Project root directory
  --truth-root DIR    Truth source directory
  --change-root DIR   Change package directory
  --target TARGET     Rollback target: staged | draft
  --dry-run           Simulate run
  --help, -h          Show help

Rollback targets:
  staged - Clean up staging layer (preserve spec delta in change package)
  draft  - Roll back to change package state (clean up staging layer, do not touch specs)

EOF
}

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $*"; }

main() {
    local change_id=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h) show_help; exit 0 ;;
            --version|-v) echo "spec-rollback.sh v${VERSION}"; exit 0 ;;
            --project-root) project_root="${2:-.}"; shift 2 ;;
            --truth-root) truth_root="${2:-specs}"; shift 2 ;;
            --change-root) change_root="${2:-changes}"; shift 2 ;;
            --target) target="${2:-staged}"; shift 2 ;;
            --dry-run) dry_run=true; shift ;;
            -*) log_error "Unknown option: $1"; exit 2 ;;
            *) change_id="$1"; shift ;;
        esac
    done

    if [[ -z "$change_id" ]]; then
        log_error "Missing change-id"
        exit 2
    fi

    case "$target" in
        staged|draft) ;;
        *) log_error "Invalid rollback target: $target"; exit 2 ;;
    esac

    local staged_dir="${project_root}/${truth_root}/_staged/${change_id}"

    log_info "Rolling back change package: ${change_id}"
    log_info "Rollback target: ${target}"

    case "$target" in
        staged)
            # Clean up staging layer
            if [[ -d "$staged_dir" ]]; then
                if [[ "$dry_run" == true ]]; then
                    log_info "[DRY-RUN] Would delete: ${staged_dir}"
                else
                    rm -rf "$staged_dir"
                    log_pass "Cleaned up staging layer: ${staged_dir}"
                fi
            else
                log_info "Staging layer is empty, no cleanup needed"
            fi
            ;;

        draft)
            # Roll back to change package state (clean up staging layer)
            if [[ -d "$staged_dir" ]]; then
                if [[ "$dry_run" == true ]]; then
                    log_info "[DRY-RUN] Would delete: ${staged_dir}"
                else
                    rm -rf "$staged_dir"
                    log_pass "Rolled back to draft state"
                fi
            else
                log_info "Already in draft state"
            fi
            ;;
    esac

    exit 0
}

main "$@"
