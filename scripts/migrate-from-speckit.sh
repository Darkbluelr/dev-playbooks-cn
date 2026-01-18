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

VERSION="1.2.0"

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
  --keep-old          Keep specs/memory directories after migration (don't archive)
  --force             Force re-execute all steps (ignore checkpoints)
  --help, -h          Show help

Migration Steps:
  1. [STRUCTURE]    Create dev-playbooks/ directory structure
  2. [CONSTITUTION] Migrate memory/constitution.md
  3. [FEATURES]     Migrate specs/[feature]/ to changes/
  4. [CONFIG]       Create/update .devbooks/config.yaml
  5. [REFS]         Update path references in all documents
  6. [COMMANDS]     Remove spec-kit AI tool commands
  7. [ARCHIVE]      Archive original directories to .devbooks/archive/

Archive includes:
  - specs/ directory -> .devbooks/archive/speckit-specs-{timestamp}/
  - memory/ directory -> .devbooks/archive/speckit-memory-{timestamp}/
  - templates/ directory (if spec-kit style)
  - scripts/bash/ and scripts/powershell/ (spec-kit scripts)
  - AI tool command directories

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
  - Reference updates: automatic batch path replacement (optimized)
  - Archive support: original files preserved in .devbooks/archive/
  - dev-playbooks/ only contains necessary migrated structure

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

    # Use grep -rl to find files containing spec-kit style references (much faster)
    # Exclude common large directories for performance
    local exclude_dirs="--exclude-dir=node_modules --exclude-dir=.git --exclude-dir=vendor --exclude-dir=dist --exclude-dir=build --exclude-dir=.devbooks/backup --exclude-dir=.devbooks/archive"

    # Find all files with spec-kit style references
    local files_to_update
    files_to_update=$(grep -rlE $exclude_dirs "(specs/[^/]+/|memory/constitution)" "${project_root}" 2>/dev/null || true)

    if [[ -z "$files_to_update" ]]; then
        log_info "No files contain spec-kit style references"
        save_checkpoint "REFS"
        log_pass "Updated references in 0 files"
        return 0
    fi

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        [[ ! -f "$file" ]] && continue

        # Skip binary files
        case "$file" in
            *.png|*.jpg|*.jpeg|*.gif|*.ico|*.pdf|*.zip|*.tar|*.gz) continue ;;
        esac

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
        fi
        files_updated=$((files_updated + 1))
    done <<< "$files_to_update"

    save_checkpoint "REFS"
    log_pass "Updated references in ${files_updated} files"
}

# Step 6: Remove spec-kit AI tool commands
step_commands() {
    log_step "6. Removing spec-kit AI tool commands"

    if is_step_done "COMMANDS" && [[ "$force" == false ]]; then
        log_info "Commands already cleaned up (skipping)"
        return 0
    fi

    local removed_count=0

    # AI tool command directories to remove (spec-kit uses "speckit" prefix)
    local command_dirs=(
        ".claude/commands/speckit"
        ".codex/commands/speckit"
        ".cursor/commands/speckit"
        ".windsurf/workflows/speckit"
        ".continue/prompts/speckit"
        ".gemini/commands/speckit"
        ".qoder/commands/speckit"
        ".qwen/commands/speckit"
        ".opencode/command/speckit"
        ".github/agents/speckit"
        ".kilocode/rules/speckit"
        ".augment/rules/speckit"
        ".roo/rules/speckit"
        ".codebuddy/commands/speckit"
        ".amazonq/prompts/speckit"
        ".agents/commands/speckit"
        ".shai/commands/speckit"
        ".bob/commands/speckit"
    )

    for cmd_dir in "${command_dirs[@]}"; do
        local full_path="${project_root}/${cmd_dir}"
        if [[ -d "$full_path" ]]; then
            if [[ "$dry_run" == true ]]; then
                log_info "[DRY-RUN] Archive $full_path"
            else
                local archive_dir="${project_root}/.devbooks/archive/commands-$(basename "$cmd_dir")-$(date +%Y%m%d%H%M%S)"
                mkdir -p "$(dirname "$archive_dir")"
                mv "$full_path" "$archive_dir"
                log_info "Archived ${cmd_dir} to ${archive_dir}"
            fi
            removed_count=$((removed_count + 1))
        fi
    done

    # Remove spec-kit specific directories
    local speckit_dirs=(
        "scripts/bash"
        "scripts/powershell"
    )

    for sk_dir in "${speckit_dirs[@]}"; do
        local full_path="${project_root}/${sk_dir}"
        if [[ -d "$full_path" ]]; then
            # Check if it contains spec-kit scripts (by looking for spec-kit patterns)
            if ls "${full_path}"/*.sh 2>/dev/null | xargs grep -l "spec-kit\|speckit\|SPEC_FILE\|create-new-feature" 2>/dev/null | head -1 > /dev/null; then
                if [[ "$dry_run" == true ]]; then
                    log_info "[DRY-RUN] archive $full_path (spec-kit scripts)"
                else
                    local archive_dir="${project_root}/.devbooks/archive/speckit-scripts-$(date +%Y%m%d%H%M%S)"
                    mkdir -p "$(dirname "$archive_dir")"
                    mv "$full_path" "$archive_dir"
                    log_info "Archived ${sk_dir}/ to ${archive_dir}"
                fi
                removed_count=$((removed_count + 1))
            fi
        fi
    done

    # Check for templates/ directory with spec-kit templates
    local templates_dir="${project_root}/templates"
    if [[ -d "$templates_dir" ]]; then
        # Check if it's spec-kit templates (look for spec-template.md or commands/)
        if [[ -f "${templates_dir}/spec-template.md" ]] || [[ -d "${templates_dir}/commands" ]]; then
            if [[ "$dry_run" == true ]]; then
                log_info "[DRY-RUN] archive $templates_dir (spec-kit templates)"
            else
                local archive_dir="${project_root}/.devbooks/archive/speckit-templates-$(date +%Y%m%d%H%M%S)"
                mkdir -p "$(dirname "$archive_dir")"
                mv "$templates_dir" "$archive_dir"
                log_info "Archived templates/ to ${archive_dir}"
            fi
            removed_count=$((removed_count + 1))
        fi
    fi

    # Clean up spec-kit references in instruction files
    local instruction_files=(
        "CLAUDE.md"
        "AGENTS.md"
        "GEMINI.md"
        ".github/copilot-instructions.md"
    )

    for inst_file in "${instruction_files[@]}"; do
        local full_path="${project_root}/${inst_file}"
        if [[ -f "$full_path" ]]; then
            # Check if contains spec-kit references
            if grep -qiE "(spec-kit|speckit|/speckit\.|spec-driven)" "$full_path" 2>/dev/null; then
                if [[ "$dry_run" == true ]]; then
                    log_info "[DRY-RUN] Removing spec-kit references from $inst_file"
                else
                    # Create backup
                    cp "$full_path" "${full_path}.speckit-backup"

                    # Remove spec-kit-specific blocks
                    if [[ "$(uname)" == "Darwin" ]]; then
                        sed -i '' '/<!-- SPECKIT:START -->/,/<!-- SPECKIT:END -->/d' "$full_path"
                        sed -i '' '/<!-- SPEC-KIT:START -->/,/<!-- SPEC-KIT:END -->/d' "$full_path"
                        # Remove speckit command references
                        sed -i '' 's|/speckit\.[a-z]*||g' "$full_path"
                    else
                        sed -i '/<!-- SPECKIT:START -->/,/<!-- SPECKIT:END -->/d' "$full_path"
                        sed -i '/<!-- SPEC-KIT:START -->/,/<!-- SPEC-KIT:END -->/d' "$full_path"
                        sed -i 's|/speckit\.[a-z]*||g' "$full_path"
                    fi
                    log_info "Cleaned spec-kit references from $inst_file (backup: ${inst_file}.speckit-backup)"
                fi
            fi
        fi
    done

    save_checkpoint "COMMANDS"
    log_pass "Removed ${removed_count} spec-kit directories/commands"
}

# Step 7: Archive and cleanup
step_cleanup() {
    log_step "7. Archive and cleanup"

    if is_step_done "CLEANUP" && [[ "$force" == false ]]; then
        log_info "Cleanup already complete (skipping)"
        return 0
    fi

    local dirs_to_archive=(
        "specs"
        "memory"
    )
    local archive_base="${project_root}/.devbooks/archive"

    if [[ "$keep_old" == true ]]; then
        log_info "Keeping original directories (--keep-old)"
    else
        for dir in "${dirs_to_archive[@]}"; do
            local src_dir="${project_root}/${dir}"
            if [[ -d "$src_dir" ]]; then
                if [[ "$dry_run" == true ]]; then
                    log_info "[DRY-RUN] archive $src_dir"
                else
                    # Archive to .devbooks/archive/
                    local archive_dir="${archive_base}/speckit-${dir}-$(date +%Y%m%d%H%M%S)"
                    mkdir -p "$archive_base"
                    mv "$src_dir" "$archive_dir"
                    log_info "Archived ${dir}/ to ${archive_dir}"
                fi
            fi
        done
        log_info "Original files preserved in .devbooks/archive/, dev-playbooks/ contains migrated structure"
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
    step_commands
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
