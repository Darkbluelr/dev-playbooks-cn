#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/install-skills.sh [--claude-only|--codex-only|--opencode-only] [--with-opencode] [--with-codex-prompts] [--dry-run] [--no-prune]

Installs DevBooks skills (skills/devbooks-*) to:
  - Claude Code: ~/.claude/skills/
  - Codex CLI:   $CODEX_HOME/skills (default: ~/.codex/skills/)
  - OpenCode:    $XDG_CONFIG_HOME/opencode/skill (default: ~/.config/opencode/skill/)

Optionally installs Codex prompt entrypoints (templates/claude-commands/devbooks/*.md) to:
  - Codex CLI:   $CODEX_HOME/prompts (default: ~/.codex/prompts/)

By default, removes devbooks-* skills in the target directory that no longer exist in this repo.
Use --no-prune to keep removed skills.
EOF
}

install_claude=true
install_codex=true
install_opencode=false
install_codex_prompts=false
dry_run=false
prune_removed=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --claude-only) install_codex=false ;;
    --codex-only) install_claude=false ;;
    --opencode-only) install_claude=false; install_codex=false; install_opencode=true ;;
    --with-opencode) install_opencode=true ;;
    --with-codex-prompts) install_codex_prompts=true ;;
    --dry-run) dry_run=true ;;
    --no-prune) prune_removed=false ;;
    *) echo "error: unknown arg: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src_root="${repo_root}/skills"

if [[ ! -d "$src_root" ]]; then
  echo "error: missing skills dir: $src_root" >&2
  exit 1
fi

skill_dirs=()
for d in "$src_root"/devbooks-*; do
  [[ -d "$d" ]] || continue
  skill_dirs+=("$d")
done

if [[ ${#skill_dirs[@]} -eq 0 ]]; then
  echo "error: no devbooks-* skill dirs found in $src_root" >&2
  exit 1
fi

skill_names=()
for d in "${skill_dirs[@]}"; do
  skill_names+=("$(basename "$d")")
done

skill_name_exists() {
  local target="$1"
  local name

  for name in "${skill_names[@]}"; do
    if [[ "$name" == "$target" ]]; then
      return 0
    fi
  done

  return 1
}

copy_dir() {
  local src="$1"
  local dest="$2"

  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "$src/" "$dest/"
    return 0
  fi

  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  cp -R "$src" "$dest"
}

copy_file() {
  local src="$1"
  local dest="$2"

  if command -v rsync >/dev/null 2>&1; then
    rsync -a "$src" "$dest"
    return 0
  fi

  cp "$src" "$dest"
}

prune_removed_skills() {
  local dest_root="$1"

  [[ -d "$dest_root" ]] || return 0

  local path
  for path in "$dest_root"/devbooks-*; do
    [[ -d "$path" ]] || continue

    local name
    name="$(basename "$path")"

    if ! skill_name_exists "$name"; then
      if [[ "$dry_run" == true ]]; then
        echo "[dry-run] remove: $path"
      else
        rm -rf "$path"
      fi
    fi
  done
}

install_into() {
  local dest_root="$1"

  if [[ "$dry_run" == true ]]; then
    echo "[dry-run] ensure dir: $dest_root"
  else
    mkdir -p "$dest_root"
  fi

  # Install _shared directory (used by all skills for common references)
  local shared_src="${src_root}/_shared"
  if [[ -d "$shared_src" ]]; then
    local shared_dest="${dest_root}/_shared"
    if [[ "$dry_run" == true ]]; then
      echo "[dry-run] install: $shared_src -> $shared_dest"
    else
      copy_dir "$shared_src" "$shared_dest"
    fi
  fi

  for src in "${skill_dirs[@]}"; do
    local name
    name="$(basename "$src")"

    if [[ ! -f "$src/SKILL.md" ]]; then
      echo "error: missing SKILL.md: $src/SKILL.md" >&2
      exit 1
    fi

    local dest="${dest_root}/${name}"
    if [[ "$dry_run" == true ]]; then
      echo "[dry-run] install: $src -> $dest"
      continue
    fi

    copy_dir "$src" "$dest"

    if [[ -d "$dest/scripts" ]]; then
      find "$dest/scripts" -type f -name "*.sh" -exec chmod +x {} \;
    fi
  done

  if [[ "$prune_removed" == true ]]; then
    prune_removed_skills "$dest_root"
  fi
}

install_prompts_into() {
  local dest_root="$1"

  local prompts_src="${repo_root}/templates/claude-commands/devbooks"
  if [[ ! -d "$prompts_src" ]]; then
    echo "error: missing prompts dir: $prompts_src" >&2
    exit 1
  fi

  local prompt_files=()
  for f in "$prompts_src"/*.md; do
    [[ -f "$f" ]] || continue
    prompt_files+=("$f")
  done

  if [[ ${#prompt_files[@]} -eq 0 ]]; then
    echo "error: no prompts found in $prompts_src" >&2
    exit 1
  fi

  if [[ "$dry_run" == true ]]; then
    echo "[dry-run] ensure dir: $dest_root"
  else
    mkdir -p "$dest_root"
  fi

  for src in "${prompt_files[@]}"; do
    local name
    name="$(basename "$src")"
    local dest="${dest_root}/devbooks-${name}"
    if [[ "$dry_run" == true ]]; then
      echo "[dry-run] install prompt: $src -> $dest"
      continue
    fi

    copy_file "$src" "$dest"
  done
}

if [[ "$install_claude" == true ]]; then
  install_into "${HOME}/.claude/skills"
fi

if [[ "$install_codex" == true ]]; then
  codex_home="${CODEX_HOME:-${HOME}/.codex}"
  install_into "${codex_home}/skills"
  if [[ "$install_codex_prompts" == true ]]; then
    install_prompts_into "${codex_home}/prompts"
  fi
fi

if [[ "$install_opencode" == true ]]; then
  xdg_config_home="${XDG_CONFIG_HOME:-${HOME}/.config}"
  install_into "${xdg_config_home}/opencode/skill"
fi

if [[ "$dry_run" == true ]]; then
  echo "[dry-run] done"
else
  echo "done"
fi
