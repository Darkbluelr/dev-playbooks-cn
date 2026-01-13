#!/bin/bash
# scripts/migrate-from-openspec.sh
# OpenSpec -> DevBooks Migration Script
#
# Migrate openspec/ directory structure to dev-playbooks/.
# Supports idempotent execution, state checkpoints, and reference updates.
#
# Usage:
#   ./migrate-from-openspec.sh [options]
#   ./migrate-from-openspec.sh --help
#
# Exit codes:
#   0 - Migration successful
#   1 - Migration failed
#   2 - Usage error

set -euo pipefail

VERSION="1.0.0"

# Default configuration
project_root="."
dry_run=false
keep_old=false
force=false
checkpoint_file=""

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    cat << 'EOF'
OpenSpec -> DevBooks Migration Script (migrate-from-openspec.sh)

Usage:
  ./migrate-from-openspec.sh [options]

Options:
  --project-root DIR  Project root directory (default: current directory)
  --dry-run           Simulate run, do not actually modify files
  --keep-old          Keep openspec/ directory after migration
  --force             Force re-execute all steps (ignore checkpoints)
  --help, -h          Show help

Migration Steps:
  1. [STRUCTURE] Create dev-playbooks/ directory structure
  2. [CONTENT]   Migrate specs/ and changes/ content
  3. [CONFIG]    Create/update .devbooks/config.yaml
  4. [REFS]      Update path references in all documents
  5. [CLEANUP]   Cleanup (optionally keep old directory)

Features:
  - Idempotent execution: safe to run repeatedly
  - State checkpoints: supports resume from breakpoint
  - Reference updates: automatic batch path replacement
  - Rollback support: backup created before cleanup

EOF
}

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $*"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $*"; }

# Checkpoint management
init_checkpoint() {
    checkpoint_file="${project_root}/.devbooks/.migrate-checkpoint"
    if [[ "$force" == true ]]; then
        rm -f "$checkpoint_file" 2>/dev/null || true
    fi
}

save_checkpoint() {
    local step="$1"
    if [[ "$dry_run" == false ]]; then
        mkdir -p "$(dirname "$checkpoint_file")"
        echo "$step" >> "$checkpoint_file"
    fi
}

is_step_done() {
    local step="$1"
    if [[ -f "$checkpoint_file" ]]; then
        grep -qx "$step" "$checkpoint_file" 2>/dev/null
        return $?
    fi
    return 1
}

# Step 1: Create directory structure
step_structure() {
    log_step "1. Creating directory structure"

    if is_step_done "STRUCTURE" && [[ "$force" == false ]]; then
        log_info "Directory structure already created (skipping)"
        return 0
    fi

    local dirs=(
        "dev-playbooks"
        "dev-playbooks/specs"
        "dev-playbooks/specs/_meta"
        "dev-playbooks/specs/_meta/anti-patterns"
        "dev-playbooks/specs/_staged"
        "dev-playbooks/specs/architecture"
        "dev-playbooks/changes"
        "dev-playbooks/changes/archive"
        "dev-playbooks/scripts"
    )

    for dir in "${dirs[@]}"; do
        local full_path="${project_root}/${dir}"
        if [[ ! -d "$full_path" ]]; then
            if [[ "$dry_run" == true ]]; then
                log_info "[DRY-RUN] mkdir -p $full_path"
            else
                mkdir -p "$full_path"
            fi
        fi
    done

    save_checkpoint "STRUCTURE"
    log_pass "Directory structure creation complete"
}

# Step 2: Migrate content
step_content() {
    log_step "2. Migrating content"

    if is_step_done "CONTENT" && [[ "$force" == false ]]; then
        log_info "Content already migrated (skipping)"
        return 0
    fi

    local openspec_dir="${project_root}/openspec"

    if [[ ! -d "$openspec_dir" ]]; then
        log_warn "openspec/ directory does not exist, skipping content migration"
        save_checkpoint "CONTENT"
        return 0
    fi

    # Migrate specs/
    if [[ -d "${openspec_dir}/specs" ]]; then
        log_info "Migrating specs/ ..."
        if [[ "$dry_run" == true ]]; then
            log_info "[DRY-RUN] cp -r ${openspec_dir}/specs/* ${project_root}/dev-playbooks/specs/"
        else
            cp -r "${openspec_dir}/specs/"* "${project_root}/dev-playbooks/specs/" 2>/dev/null || true
        fi
    fi

    # Migrate changes/
    if [[ -d "${openspec_dir}/changes" ]]; then
        log_info "Migrating changes/ ..."
        if [[ "$dry_run" == true ]]; then
            log_info "[DRY-RUN] cp -r ${openspec_dir}/changes/* ${project_root}/dev-playbooks/changes/"
        else
            cp -r "${openspec_dir}/changes/"* "${project_root}/dev-playbooks/changes/" 2>/dev/null || true
        fi
    fi

    # Migrate project.md
    if [[ -f "${openspec_dir}/project.md" ]]; then
        log_info "Migrating project.md ..."
        if [[ "$dry_run" == true ]]; then
            log_info "[DRY-RUN] cp ${openspec_dir}/project.md ${project_root}/dev-playbooks/project.md"
        else
            cp "${openspec_dir}/project.md" "${project_root}/dev-playbooks/project.md" 2>/dev/null || true
        fi
    fi

    save_checkpoint "CONTENT"
    log_pass "Content migration complete"
}

# Step 3: Create/update configuration
step_config() {
    log_step "3. Creating/updating configuration"

    if is_step_done "CONFIG" && [[ "$force" == false ]]; then
        log_info "Configuration already updated (skipping)"
        return 0
    fi

    local config_dir="${project_root}/.devbooks"
    local config_file="${config_dir}/config.yaml"

    if [[ "$dry_run" == true ]]; then
        log_info "[DRY-RUN] Creating/updating ${config_file}"
    else
        mkdir -p "$config_dir"

        # If configuration file does not exist or needs updating
        if [[ ! -f "$config_file" ]] || grep -q "root: openspec/" "$config_file" 2>/dev/null; then
            cat > "$config_file" << 'YAML'
# DevBooks Configuration
# Generated by migrate-from-openspec.sh

root: dev-playbooks/
constitution: constitution.md
project: project.md

paths:
  specs: specs/
  changes: changes/
  staged: specs/_staged/
  archive: changes/archive/

constraints:
  require_constitution: true
  allow_legacy_protocol: false

fitness:
  mode: warn
  rules_file: specs/architecture/fitness-rules.md

tracing:
  coverage_threshold: 80
  evidence_dir: evidence/
YAML
        fi
    fi

    save_checkpoint "CONFIG"
    log_pass "Configuration update complete"
}

# Step 4: Update references
step_refs() {
    log_step "4. Updating path references"

    if is_step_done "REFS" && [[ "$force" == false ]]; then
        log_info "References already updated (skipping)"
        return 0
    fi

    local files_updated=0

    # Find files that need updating
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        [[ ! -f "$file" ]] && continue

        # Skip binary files and .git directory
        [[ "$file" == *".git"* ]] && continue
        [[ "$file" == *".png" ]] && continue
        [[ "$file" == *".jpg" ]] && continue
        [[ "$file" == *".ico" ]] && continue

        # Check if contains openspec/ references
        if grep -q "openspec/" "$file" 2>/dev/null; then
            if [[ "$dry_run" == true ]]; then
                log_info "[DRY-RUN] Updating references: $file"
            else
                # macOS compatible sed
                if [[ "$(uname)" == "Darwin" ]]; then
                    sed -i '' 's|openspec/|dev-playbooks/|g' "$file"
                else
                    sed -i 's|openspec/|dev-playbooks/|g' "$file"
                fi
            fi
            files_updated=$((files_updated + 1))
        fi
    done < <(find "${project_root}" -type f \( -name "*.md" -o -name "*.yaml" -o -name "*.yml" -o -name "*.sh" -o -name "*.ts" -o -name "*.js" -o -name "*.json" \) 2>/dev/null)

    save_checkpoint "REFS"
    log_pass "Updated references in ${files_updated} files"
}

# Step 5: Cleanup
step_cleanup() {
    log_step "5. Cleanup"

    if is_step_done "CLEANUP" && [[ "$force" == false ]]; then
        log_info "Cleanup already complete (skipping)"
        return 0
    fi

    local openspec_dir="${project_root}/openspec"

    if [[ "$keep_old" == true ]]; then
        log_info "Keeping openspec/ directory (--keep-old)"
    elif [[ -d "$openspec_dir" ]]; then
        if [[ "$dry_run" == true ]]; then
            log_info "[DRY-RUN] rm -rf $openspec_dir"
        else
            # Create backup
            local backup_dir="${project_root}/.devbooks/backup/openspec-$(date +%Y%m%d%H%M%S)"
            mkdir -p "$(dirname "$backup_dir")"
            mv "$openspec_dir" "$backup_dir"
            log_info "Backed up openspec/ to ${backup_dir}"
        fi
    fi

    save_checkpoint "CLEANUP"
    log_pass "Cleanup complete"
}

# Verify migration result
verify_migration() {
    log_step "Verifying migration result"

    local errors=0

    # Check directory structure
    local required_dirs=(
        "dev-playbooks"
        "dev-playbooks/specs"
        "dev-playbooks/changes"
    )

    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "${project_root}/${dir}" ]]; then
            log_error "Missing directory: $dir"
            errors=$((errors + 1))
        fi
    done

    # Check configuration file
    if [[ ! -f "${project_root}/.devbooks/config.yaml" ]]; then
        log_error "Missing configuration file: .devbooks/config.yaml"
        errors=$((errors + 1))
    fi

    # Check remaining references (warning only)
    local remaining_refs
    remaining_refs=$(grep -r "openspec/" "${project_root}" --include="*.md" --include="*.yaml" --include="*.sh" 2>/dev/null | grep -v ".devbooks/backup" | wc -l || echo "0")
    if [[ "$remaining_refs" -gt 0 ]]; then
        log_warn "Still ${remaining_refs} openspec/ references remaining"
    fi

    if [[ "$errors" -eq 0 ]]; then
        log_pass "Migration verification passed"
        return 0
    else
        log_error "Migration verification failed, ${errors} errors"
        return 1
    fi
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h) show_help; exit 0 ;;
            --version|-v) echo "migrate-from-openspec.sh v${VERSION}"; exit 0 ;;
            --project-root) project_root="${2:-.}"; shift 2 ;;
            --dry-run) dry_run=true; shift ;;
            --keep-old) keep_old=true; shift ;;
            --force) force=true; shift ;;
            -*) log_error "Unknown option: $1"; exit 2 ;;
            *) log_error "Unknown argument: $1"; exit 2 ;;
        esac
    done

    log_info "OpenSpec -> DevBooks Migration"
    log_info "Project root: ${project_root}"
    [[ "$dry_run" == true ]] && log_info "Mode: DRY-RUN"
    [[ "$force" == true ]] && log_info "Mode: FORCE"

    init_checkpoint

    # Execute migration steps
    step_structure
    step_content
    step_config
    step_refs
    step_cleanup

    # Verify
    if [[ "$dry_run" == false ]]; then
        verify_migration
    fi

    log_pass "Migration complete!"
    exit 0
}

main "$@"
