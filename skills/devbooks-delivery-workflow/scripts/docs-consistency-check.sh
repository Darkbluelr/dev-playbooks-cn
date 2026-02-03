#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: docs-consistency-check.sh <change-id> [options]

Generate a machine-readable docs consistency gate report:
  <change-root>/<change-id>/evidence/gates/docs-consistency.report.json

This is used as a G6 scope evidence artifact when applicable.

Options:
  --project-root <dir>   Project root directory (default: pwd or $DEVBOOKS_PROJECT_ROOT)
  --change-root <dir>    Change packages root (default: changes or $DEVBOOKS_CHANGE_ROOT)
  --truth-root <dir>     Truth root directory (unused; accepted for CLI consistency) (default: specs or $DEVBOOKS_TRUTH_ROOT)
  --dry-run              Do not write output file; print JSON to stdout
  -h, --help             Show this help message

Exit codes:
  0 - pass (no missing references)
  1 - fail (missing references found)
  2 - usage error
EOF
}

if [[ $# -eq 0 ]]; then
  usage
  exit 2
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

CHANGE_ID="$1"
shift

PROJECT_ROOT="${DEVBOOKS_PROJECT_ROOT:-$(pwd)}"
CHANGE_ROOT="${DEVBOOKS_CHANGE_ROOT:-changes}"
TRUTH_ROOT="${DEVBOOKS_TRUTH_ROOT:-specs}"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root)
      PROJECT_ROOT="${2:-}"
      shift 2
      ;;
    --change-root)
      CHANGE_ROOT="${2:-}"
      shift 2
      ;;
    --truth-root)
      TRUTH_ROOT="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$CHANGE_ID" || "$CHANGE_ID" == "-"* || "$CHANGE_ID" =~ [[:space:]] ]]; then
  echo "error: invalid change-id: '$CHANGE_ID'" >&2
  exit 2
fi

PROJECT_ROOT="${PROJECT_ROOT%/}"
CHANGE_ROOT="${CHANGE_ROOT%/}"
TRUTH_ROOT="${TRUTH_ROOT%/}"

if [[ "$CHANGE_ROOT" = /* ]]; then
  CHANGE_DIR="${CHANGE_ROOT}/${CHANGE_ID}"
else
  CHANGE_DIR="${PROJECT_ROOT}/${CHANGE_ROOT}/${CHANGE_ID}"
fi

PROPOSAL_FILE="${CHANGE_DIR}/proposal.md"
DEFAULT_CONTRACT_PATH="${CHANGE_DIR}/completion.contract.yaml"
REPORT_REL="evidence/gates/docs-consistency.report.json"
REPORT_PATH="${CHANGE_DIR}/${REPORT_REL}"

extract_front_matter_value() {
  local file="$1"
  local key="$2"
  awk -v k="$key" '
    BEGIN { in_yaml=0 }
    NR==1 && $0=="---" { in_yaml=1; next }
    in_yaml==1 && $0=="---" { exit }
    in_yaml==1 && $0 ~ ("^" k ":[[:space:]]*") {
      sub(("^" k ":[[:space:]]*"), "", $0)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      gsub(/^["'"'"']|["'"'"']$/, "", $0)
      print $0
      exit
    }
  ' "$file" 2>/dev/null || true
}

resolve_contract_path() {
  local raw="$1"
  if [[ -z "$raw" ]]; then
    printf '%s' "$DEFAULT_CONTRACT_PATH"
    return 0
  fi
  if [[ "$raw" = /* ]]; then
    printf '%s' "$raw"
    return 0
  fi
  raw="${raw#./}"
  printf '%s' "${CHANGE_DIR}/${raw}"
}

CONTRACT_PATH="$DEFAULT_CONTRACT_PATH"
if [[ -f "$PROPOSAL_FILE" ]]; then
  raw_contract="$(extract_front_matter_value "$PROPOSAL_FILE" "completion_contract")"
  CONTRACT_PATH="$(resolve_contract_path "$raw_contract")"
fi

timestamp_utc="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

if [[ ! -d "$CHANGE_DIR" ]]; then
  report_json="$(python3 - <<PY
import json
print(json.dumps({
  "schema_version": "1.0.0",
  "status": "fail",
  "generated_at": "${timestamp_utc}",
  "truth_root": "${TRUTH_ROOT}",
  "issues_count": 1,
  "checked_files": [],
  "missing_paths": ["<missing change directory>"],
  "note": "change directory not found: ${CHANGE_DIR}"
}, ensure_ascii=False))
PY
)"
  if [[ "$DRY_RUN" == true ]]; then
    printf '%s\n' "$report_json"
  else
    mkdir -p "$(dirname "$REPORT_PATH")"
    printf '%s\n' "$report_json" > "$REPORT_PATH"
  fi
  exit 1
fi

if [[ ! -f "$CONTRACT_PATH" ]]; then
  report_json="$(python3 - <<PY
import json
print(json.dumps({
  "schema_version": "1.0.0",
  "status": "fail",
  "generated_at": "${timestamp_utc}",
  "truth_root": "${TRUTH_ROOT}",
  "issues_count": 1,
  "checked_files": [],
  "missing_paths": ["<missing completion contract>"],
  "note": "completion contract not found: ${CONTRACT_PATH}"
}, ensure_ascii=False))
PY
)"
  if [[ "$DRY_RUN" == true ]]; then
    printf '%s\n' "$report_json"
  else
    mkdir -p "$(dirname "$REPORT_PATH")"
    printf '%s\n' "$report_json" > "$REPORT_PATH"
  fi
  exit 1
fi

deliverable_paths_csv="$(
  awk '
    BEGIN { in_deliverables=0; have_id=0; have_path=0; id=""; path="" }
    function flush() {
      if (have_path && path != "") print path
      have_id=0; have_path=0; id=""; path=""
    }
    /^[^[:space:]][^:]*:[[:space:]]*$/ {
      if (in_deliverables==1) flush()
      in_deliverables=0
    }
    /^deliverables:[[:space:]]*$/ { in_deliverables=1; next }
    in_deliverables==1 {
      if ($0 ~ /^[[:space:]]*-[[:space:]]*id:[[:space:]]*/) {
        flush()
        line=$0
        sub(/^[[:space:]]*-[[:space:]]*id:[[:space:]]*/, "", line)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
        gsub(/^["'"'"']|["'"'"']$/, "", line)
        id=line
        have_id=1
        next
      }
      if ($0 ~ /^[[:space:]]+path:[[:space:]]*/) {
        line=$0
        sub(/^[[:space:]]+path:[[:space:]]*/, "", line)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
        gsub(/^["'"'"']|["'"'"']$/, "", line)
        path=line
        have_path=1
        next
      }
    }
    END { if (in_deliverables==1) flush() }
  ' "$CONTRACT_PATH" 2>/dev/null | awk 'NF' | LC_ALL=C sort -u | paste -sd, -
)"

report_json="$(
  python3 - "$PROJECT_ROOT" "$TRUTH_ROOT" "$deliverable_paths_csv" "$timestamp_utc" <<'PY'
import json
import os
import re
import sys
from pathlib import Path

project_root = Path(sys.argv[1]).resolve()
truth_root = sys.argv[2] if len(sys.argv) > 2 else ""
csv = sys.argv[3] if len(sys.argv) > 3 else ""
generated_at = sys.argv[4] if len(sys.argv) > 4 else ""
deliverables = [p for p in csv.split(",") if p]

def is_docs_like(path: str) -> bool:
    return (
        path == "README.md"
        or path.startswith("docs/")
        or path.startswith("dev-playbooks/docs/")
        or path.startswith("templates/")
    )

def is_markdown(path: str) -> bool:
    return path.endswith(".md") or path == "README.md"

def normalize_candidate(raw: str) -> str:
    raw = raw.strip()
    if raw.startswith("<") and raw.endswith(">"):
        raw = raw[1:-1].strip()
    return raw

def strip_suffixes(raw: str) -> str:
    raw = raw.split("#", 1)[0]
    raw = raw.split("?", 1)[0]
    raw = re.sub(r":\d+(?::\d+)?$", "", raw)
    return raw

def should_skip_ref(raw: str) -> bool:
    if not raw:
        return True
    lowered = raw.lower()
    if lowered.startswith(("http://", "https://", "mailto:", "tel:")):
        return True
    if raw.startswith("#"):
        return True
    if raw.startswith(("truth://", "capability://")):
        return True
    if any(ch in raw for ch in ["<", ">", "{", "}", "*", "|"]):
        return True
    return False

def resolve_ref(current_file: Path, ref: str) -> Path | None:
    ref = normalize_candidate(ref)
    ref = strip_suffixes(ref)
    if should_skip_ref(ref):
        return None

    # Handle absolute-repo links like "/docs/..."
    if ref.startswith("/"):
        ref = ref.lstrip("/")
        candidate = (project_root / ref).resolve()
        if project_root in candidate.parents or candidate == project_root:
            return candidate
        return None

    # For explicit relative refs, resolve from current file directory.
    if ref.startswith("./") or ref.startswith("../"):
        candidate = (current_file.parent / ref).resolve()
        if project_root in candidate.parents or candidate == project_root:
            return candidate
        return None

    # Default: treat as repo-relative path.
    candidate = (project_root / ref).resolve()
    if project_root in candidate.parents or candidate == project_root:
        return candidate
    return None

def extract_inline_code_refs(text: str) -> list[str]:
    refs = []
    for m in re.finditer(r"`([^`\n]+)`", text):
        token = m.group(1).strip()
        if " " in token or "\t" in token:
            continue
        if token.startswith(("-", "--")):
            continue
        if "/" not in token and "." not in token:
            continue
        refs.append(token)
    return refs

def extract_markdown_link_refs(text: str) -> list[str]:
    refs = []
    for m in re.finditer(r"\]\(([^)]+)\)", text):
        target = m.group(1).strip()
        if not target:
            continue
        target = target.split()[0]
        refs.append(target)
    return refs

checked_files = []
missing = []
issues = []

for rel in deliverables:
    rel = rel.strip().lstrip("./")
    if not is_docs_like(rel):
        continue
    if not is_markdown(rel):
        continue

    file_path = (project_root / rel).resolve()
    if not file_path.exists():
        missing.append(rel)
        issues.append({"path": rel, "reason": "missing deliverable file"})
        continue
    if not file_path.is_file():
        missing.append(rel)
        issues.append({"path": rel, "reason": "deliverable is not a file"})
        continue

    checked_files.append(str(file_path))
    try:
        text = file_path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        missing.append(rel)
        issues.append({"path": rel, "reason": "cannot read file"})
        continue

    refs = extract_inline_code_refs(text) + extract_markdown_link_refs(text)
    for ref in refs:
        resolved = resolve_ref(file_path, ref)
        if resolved is None:
            continue
        if not resolved.exists():
            rel_missing = os.path.relpath(resolved, project_root)
            missing.append(rel_missing)
            issues.append({"path": rel, "ref": ref, "missing": rel_missing})

missing_sorted = sorted(set(missing))
issues_unique = []
seen = set()
for item in issues:
    key = json.dumps(item, sort_keys=True, ensure_ascii=False)
    if key in seen:
        continue
    seen.add(key)
    issues_unique.append(item)

report = {
    "schema_version": "1.0.0",
    "generated_at": generated_at,
    "status": "pass" if len(missing_sorted) == 0 else "fail",
    "truth_root": truth_root,
    "issues_count": len(missing_sorted),
    "summary": {
        "issues_count": len(missing_sorted),
        "checked_files_count": len(checked_files),
    },
    "checked_files": checked_files,
    "missing_paths": missing_sorted,
    "issues": issues_unique,
}

print(json.dumps(report, ensure_ascii=False, indent=2))
PY
)"

if [[ "$DRY_RUN" == true ]]; then
  printf '%s\n' "$report_json"
else
  mkdir -p "$(dirname "$REPORT_PATH")"
  printf '%s\n' "$report_json" > "$REPORT_PATH"
fi

status_value="$(printf '%s\n' "$report_json" | grep -Eo '"status"[[:space:]]*:[[:space:]]*"[^"]+"' | head -n 1 | sed -E 's/.*"status"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
if [[ "$status_value" == "pass" ]]; then
  exit 0
fi
exit 1
