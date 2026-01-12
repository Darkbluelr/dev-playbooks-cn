#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/install-skills.sh [--claude-only|--codex-only] [--with-codex-prompts] [--dry-run]

Installs DevBooks skills (skills/devbooks-*) to:
  - Claude Code: ~/.claude/skills/
  - Codex CLI:   $CODEX_HOME/skills (default: ~/.codex/skills/)

Optionally installs Codex prompt entrypoints (setup/dev-playbooks/prompts/devbooks-*.md) to:
  - Codex CLI:   $CODEX_HOME/prompts (default: ~/.codex/prompts/)
EOF
}

install_claude=true
install_codex=true
install_codex_prompts=false
dry_run=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --claude-only) install_codex=false ;;
    --codex-only) install_claude=false ;;
    --with-codex-prompts) install_codex_prompts=true ;;
    --dry-run) dry_run=true ;;
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

install_into() {
  local dest_root="$1"

  if [[ "$dry_run" == true ]]; then
    echo "[dry-run] ensure dir: $dest_root"
  else
    mkdir -p "$dest_root"
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
}

install_prompts_into() {
  local dest_root="$1"

  local prompts_src="${repo_root}/setup/dev-playbooks/prompts"
  if [[ ! -d "$prompts_src" ]]; then
    echo "error: missing prompts dir: $prompts_src" >&2
    exit 1
  fi

  local prompt_files=()
  for f in "$prompts_src"/devbooks-*.md; do
    [[ -f "$f" ]] || continue
    prompt_files+=("$f")
  done

  if [[ ${#prompt_files[@]} -eq 0 ]]; then
    echo "error: no devbooks-*.md prompts found in $prompts_src" >&2
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
    local dest="${dest_root}/${name}"
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

if [[ "$dry_run" == true ]]; then
  echo "[dry-run] done"
else
  echo "done"
fi
