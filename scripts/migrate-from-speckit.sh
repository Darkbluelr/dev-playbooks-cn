#!/bin/bash
# scripts/migrate-from-speckit.sh
# Spec-Kit -> DevBooks Migration Script
#
# Migrate GitHub spec-kit project structure to dev-playbooks/.
# Supports idempotent execution, state checkpoints, and reference updates.
#
# Usage:
#   ./migrate-from-speckit.sh [options]
#   ./migrate-from-speckit.sh --help
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
Spec-Kit -> DevBooks Migration Script (migrate-from-speckit.sh)

Usage:
  ./migrate-from-speckit.sh [options]

Options:
  --project-root DIR  Project root directory (default: current directory)
  --dry-run           Simulate run, do not actually modify files
  --keep-old          Keep specs/ directory after migration
  --force             Force re-execute all steps (ignore checkpoints)
  --help, -h          Show help

Migration Steps:
  1. [STRUCTURE]    Create dev-playbooks/ directory structure
  2. [CONSTITUTION] Migrate memory/constitution.md
  3. [FEATURES]     Migrate specs/[feature]/ to changes/
  4. [CONFIG]       Create/update .devbooks/config.yaml
  5. [REFS]         Update path references in all documents
  6. [CLEANUP]      Cleanup (optionally keep old directories)

Mapping Rules:
  Spec-Kit                         DevBooks
  ────────────────────────────────────────────────────────
  memory/constitution.md        -> dev-playbooks/specs/_meta/constitution.md
  specs/[feature]/spec.md       -> changes/[feature]/design.md
  specs/[feature]/plan.md       -> changes/[feature]/proposal.md
  specs/[feature]/tasks.md      -> changes/[feature]/tasks.md
  specs/[feature]/data-model.md -> changes/[feature]/specs/data-model.md
  specs/[feature]/contracts/    -> changes/[feature]/specs/
  specs/[feature]/quickstart.md -> changes/[feature]/verification.md
  specs/[feature]/research.md   -> changes/[feature]/research.md

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
    checkpoint_file="${project_root}/.devbooks/.migrate-speckit-checkpoint"
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

# Step 2: Migrate constitution
step_constitution() {
    log_step "2. Migrating constitution"

    if is_step_done "CONSTITUTION" && [[ "$force" == false ]]; then
        log_info "Constitution already migrated (skipping)"
        return 0
    fi

    local constitution_src="${project_root}/memory/constitution.md"
    local constitution_dst="${project_root}/dev-playbooks/specs/_meta/constitution.md"

    if [[ -f "$constitution_src" ]]; then
        if [[ "$dry_run" == true ]]; then
            log_info "[DRY-RUN] cp $constitution_src $constitution_dst"
        else
            mkdir -p "$(dirname "$constitution_dst")"
            cp "$constitution_src" "$constitution_dst"
            log_info "Migrated constitution.md"
        fi
    else
        log_warn "No constitution.md found in memory/"
    fi

    # Also check for spec-driven.md as project guidance
    local specdriven_src="${project_root}/spec-driven.md"
    local specdriven_dst="${project_root}/dev-playbooks/specs/_meta/spec-driven.md"

    if [[ -f "$specdriven_src" ]]; then
        if [[ "$dry_run" == true ]]; then
            log_info "[DRY-RUN] cp $specdriven_src $specdriven_dst"
        else
            cp "$specdriven_src" "$specdriven_dst"
            log_info "Migrated spec-driven.md"
        fi
    fi

    save_checkpoint "CONSTITUTION"
    log_pass "Constitution migration complete"
}

# Step 3: Migrate feature specs
step_features() {
    log_step "3. Migrating feature specs"

    if is_step_done "FEATURES" && [[ "$force" == false ]]; then
        log_info "Features already migrated (skipping)"
        return 0
    fi

    local specs_dir="${project_root}/specs"

    if [[ ! -d "$specs_dir" ]]; then
        log_warn "No specs/ directory found, skipping feature migration"
        save_checkpoint "FEATURES"
        return 0
    fi

    local migrated_count=0

    # Find all feature directories
    for feature_dir in "${specs_dir}"/*/; do
        [[ ! -d "$feature_dir" ]] && continue

        local feature_name
        feature_name=$(basename "$feature_dir")

        # Skip template directories
        [[ "$feature_name" == "templates" ]] && continue
        [[ "$feature_name" == "_template" ]] && continue

        local target_dir="${project_root}/dev-playbooks/changes/${feature_name}"
        local target_specs="${target_dir}/specs"

        log_info "Migrating feature: ${feature_name}"

        if [[ "$dry_run" == true ]]; then
            log_info "[DRY-RUN] mkdir -p $target_dir"
            log_info "[DRY-RUN] mkdir -p $target_specs"
        else
            mkdir -p "$target_dir"
            mkdir -p "$target_specs"
        fi

        # Migrate spec.md -> design.md
        if [[ -f "${feature_dir}/spec.md" ]]; then
            if [[ "$dry_run" == true ]]; then
                log_info "[DRY-RUN] cp ${feature_dir}/spec.md ${target_dir}/design.md"
            else
                cp "${feature_dir}/spec.md" "${target_dir}/design.md"
            fi
        fi

        # Migrate plan.md -> proposal.md
        if [[ -f "${feature_dir}/plan.md" ]]; then
            if [[ "$dry_run" == true ]]; then
                log_info "[DRY-RUN] cp ${feature_dir}/plan.md ${target_dir}/proposal.md"
            else
                cp "${feature_dir}/plan.md" "${target_dir}/proposal.md"
            fi
        fi

        # Migrate tasks.md -> tasks.md
        if [[ -f "${feature_dir}/tasks.md" ]]; then
            if [[ "$dry_run" == true ]]; then
                log_info "[DRY-RUN] cp ${feature_dir}/tasks.md ${target_dir}/tasks.md"
            else
                cp "${feature_dir}/tasks.md" "${target_dir}/tasks.md"
            fi
        fi

        # Migrate quickstart.md -> verification.md
        if [[ -f "${feature_dir}/quickstart.md" ]]; then
            if [[ "$dry_run" == true ]]; then
                log_info "[DRY-RUN] cp ${feature_dir}/quickstart.md ${target_dir}/verification.md"
            else
                cp "${feature_dir}/quickstart.md" "${target_dir}/verification.md"
            fi
        fi

        # Migrate research.md -> research.md
        if [[ -f "${feature_dir}/research.md" ]]; then
            if [[ "$dry_run" == true ]]; then
                log_info "[DRY-RUN] cp ${feature_dir}/research.md ${target_dir}/research.md"
            else
                cp "${feature_dir}/research.md" "${target_dir}/research.md"
            fi
        fi

        # Migrate data-model.md -> specs/data-model.md
        if [[ -f "${feature_dir}/data-model.md" ]]; then
            if [[ "$dry_run" == true ]]; then
                log_info "[DRY-RUN] cp ${feature_dir}/data-model.md ${target_specs}/data-model.md"
            else
                cp "${feature_dir}/data-model.md" "${target_specs}/data-model.md"
            fi
        fi

        # Migrate contracts/ -> specs/
        if [[ -d "${feature_dir}/contracts" ]]; then
            if [[ "$dry_run" == true ]]; then
                log_info "[DRY-RUN] cp -r ${feature_dir}/contracts/* ${target_specs}/"
            else
                cp -r "${feature_dir}/contracts/"* "${target_specs}/" 2>/dev/null || true
            fi
        fi

        # Migrate implementation-details/ if exists
        if [[ -d "${feature_dir}/implementation-details" ]]; then
            if [[ "$dry_run" == true ]]; then
                log_info "[DRY-RUN] cp -r ${feature_dir}/implementation-details ${target_dir}/"
            else
                cp -r "${feature_dir}/implementation-details" "${target_dir}/" 2>/dev/null || true
            fi
        fi

        migrated_count=$((migrated_count + 1))
    done

    save_checkpoint "FEATURES"
    log_pass "Migrated ${migrated_count} features"
}

# Step 4: Create/update configuration
step_config() {
    log_step "4. Creating/updating configuration"

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

        # If configuration file does not exist
        if [[ ! -f "$config_file" ]]; then
            cat > "$config_file" << 'YAML'
# DevBooks Configuration
# Generated by migrate-from-speckit.sh
# Migrated from GitHub spec-kit

root: dev-playbooks/
constitution: specs/_meta/constitution.md
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

# Spec-kit migration metadata
migration:
  source: spec-kit
  date: MIGRATED_DATE
YAML
            # Update the migration date
            if [[ "$(uname)" == "Darwin" ]]; then
                sed -i '' "s/MIGRATED_DATE/$(date +%Y-%m-%d)/" "$config_file"
            else
                sed -i "s/MIGRATED_DATE/$(date +%Y-%m-%d)/" "$config_file"
            fi
        fi
    fi

    # Create project.md if it doesn't exist
    local project_file="${project_root}/dev-playbooks/project.md"
    if [[ ! -f "$project_file" ]]; then
        if [[ "$dry_run" == true ]]; then
            log_info "[DRY-RUN] Creating ${project_file}"
        else
            cat > "$project_file" << 'MARKDOWN'
# Project Configuration

> Migrated from GitHub spec-kit

## Project Overview

<!-- Describe your project here -->

## Conventions

- **Truth Root**: `dev-playbooks/specs/`
- **Change Root**: `dev-playbooks/changes/`

## Quality Gates

| Gate | Threshold | Command |
|------|-----------|---------|
| Tests | Pass | `npm test` |
| Build | Success | `npm run build` |

---

**Migrated from**: GitHub spec-kit
**Migration date**: MIGRATED_DATE
MARKDOWN
            if [[ "$(uname)" == "Darwin" ]]; then
                sed -i '' "s/MIGRATED_DATE/$(date +%Y-%m-%d)/" "$project_file"
            else
                sed -i "s/MIGRATED_DATE/$(date +%Y-%m-%d)/" "$project_file"
            fi
        fi
    fi

    save_checkpoint "CONFIG"
    log_pass "Configuration update complete"
}

# Step 5: Update references
step_refs() {
    log_step "5. Updating path references"

    if is_step_done "REFS" && [[ "$force" == false ]]; then
        log_info "References already updated (skipping)"
        return 0
    fi

    local files_updated=0

    # Reference patterns to update
    declare -a patterns=(
        "specs/[^/]*/spec.md:changes/*/design.md"
        "specs/[^/]*/plan.md:changes/*/proposal.md"
        "specs/[^/]*/tasks.md:changes/*/tasks.md"
        "memory/constitution.md:dev-playbooks/specs/_meta/constitution.md"
    )

    # Find files that need updating
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        [[ ! -f "$file" ]] && continue

        # Skip binary files and .git directory
        [[ "$file" == *".git"* ]] && continue
        [[ "$file" == *".png" ]] && continue
        [[ "$file" == *".jpg" ]] && continue
        [[ "$file" == *".ico" ]] && continue

        local modified=false

        # Check if contains spec-kit style references
        if grep -qE "(specs/[^/]+/|memory/constitution)" "$file" 2>/dev/null; then
            if [[ "$dry_run" == true ]]; then
                log_info "[DRY-RUN] Updating references: $file"
            else
                # Update common patterns (macOS compatible)
                if [[ "$(uname)" == "Darwin" ]]; then
                    sed -i '' 's|memory/constitution\.md|dev-playbooks/specs/_meta/constitution.md|g' "$file"
                    sed -i '' 's|spec-driven\.md|dev-playbooks/specs/_meta/spec-driven.md|g' "$file"
                else
                    sed -i 's|memory/constitution\.md|dev-playbooks/specs/_meta/constitution.md|g' "$file"
                    sed -i 's|spec-driven\.md|dev-playbooks/specs/_meta/spec-driven.md|g' "$file"
                fi
                modified=true
            fi
            files_updated=$((files_updated + 1))
        fi
    done < <(find "${project_root}" -type f \( -name "*.md" -o -name "*.yaml" -o -name "*.yml" -o -name "*.sh" -o -name "*.ts" -o -name "*.js" -o -name "*.json" \) 2>/dev/null)

    save_checkpoint "REFS"
    log_pass "Updated references in ${files_updated} files"
}

# Step 6: Cleanup
step_cleanup() {
    log_step "6. Cleanup"

    if is_step_done "CLEANUP" && [[ "$force" == false ]]; then
        log_info "Cleanup already complete (skipping)"
        return 0
    fi

    local dirs_to_backup=(
        "specs"
        "memory"
    )

    if [[ "$keep_old" == true ]]; then
        log_info "Keeping original directories (--keep-old)"
    else
        for dir in "${dirs_to_backup[@]}"; do
            local src_dir="${project_root}/${dir}"
            if [[ -d "$src_dir" ]]; then
                if [[ "$dry_run" == true ]]; then
                    log_info "[DRY-RUN] backup and remove $src_dir"
                else
                    # Create backup
                    local backup_dir="${project_root}/.devbooks/backup/speckit-${dir}-$(date +%Y%m%d%H%M%S)"
                    mkdir -p "$(dirname "$backup_dir")"
                    mv "$src_dir" "$backup_dir"
                    log_info "Backed up ${dir}/ to ${backup_dir}"
                fi
            fi
        done
    fi

    save_checkpoint "CLEANUP"
    log_pass "Cleanup complete"
}

# Verify migration result
verify_migration() {
    log_step "Verifying migration result"

    local errors=0
    local warnings=0

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

    # Check constitution migration
    if [[ ! -f "${project_root}/dev-playbooks/specs/_meta/constitution.md" ]]; then
        log_warn "Constitution not migrated (may not have existed)"
        warnings=$((warnings + 1))
    fi

    # Check for migrated features
    local feature_count
    feature_count=$(find "${project_root}/dev-playbooks/changes" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    log_info "Found ${feature_count} migrated feature(s)"

    if [[ "$errors" -eq 0 ]]; then
        log_pass "Migration verification passed (${warnings} warning(s))"
        return 0
    else
        log_error "Migration verification failed, ${errors} error(s)"
        return 1
    fi
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h) show_help; exit 0 ;;
            --version|-v) echo "migrate-from-speckit.sh v${VERSION}"; exit 0 ;;
            --project-root) project_root="${2:-.}"; shift 2 ;;
            --dry-run) dry_run=true; shift ;;
            --keep-old) keep_old=true; shift ;;
            --force) force=true; shift ;;
            -*) log_error "Unknown option: $1"; exit 2 ;;
            *) log_error "Unknown argument: $1"; exit 2 ;;
        esac
    done

    log_info "Spec-Kit -> DevBooks Migration"
    log_info "Project root: ${project_root}"
    [[ "$dry_run" == true ]] && log_info "Mode: DRY-RUN"
    [[ "$force" == true ]] && log_info "Mode: FORCE"

    init_checkpoint

    # Execute migration steps
    step_structure
    step_constitution
    step_features
    step_config
    step_refs
    step_cleanup

    # Verify
    if [[ "$dry_run" == false ]]; then
        verify_migration
    fi

    log_pass "Migration complete!"
    echo ""
    log_info "Next steps:"
    echo "  1. Review migrated files in dev-playbooks/"
    echo "  2. Update any remaining spec-kit references manually"
    echo "  3. Run 'dev-playbooks-cn init' to set up DevBooks Skills"
    echo "  4. Review and update verification.md files with test mappings"
    exit 0
}

main "$@"
