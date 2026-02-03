#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
usage: knife-correctness-check.sh <change-id> [options]

Validate Knife Plan hard invariants (Knife Correctness Gate):
  - MECE coverage: union(slice.ac_subset) == epic.ac_ids and no overlaps
  - DAG: depends_on graph is acyclic and references valid slice_ids
  - Budget fuse: when slice_limits.tokens is configured, slice budget must not exceed
  - Independent Green: each slice has >=1 verification anchor, and anchors exist in the slice's completion contract

Required when:
  - proposal risk_level=high OR request_kind=epic
  - AND mode is archive/strict

Options:
  --mode <proposal|apply|review|archive|strict>   Mode for enforcement (default: strict)
  --project-root <dir>    Project root directory (default: pwd)
  --change-root <dir>     Change root directory (default: changes)
  --truth-root <dir>      Truth root directory (default: specs)
  --out <path>            Output report path (default: evidence/gates/knife-correctness-check.json)
  -h, --help              Show help

Exit codes:
  0 - pass (or not required)
  1 - fail
  2 - usage error
EOF
}

errorf() {
  printf '%s\n' "ERROR: $*" >&2
}

if [[ $# -eq 0 ]]; then
  usage
  exit 2
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

change_id="$1"
shift

mode="strict"
project_root="${DEVBOOKS_PROJECT_ROOT:-$(pwd)}"
change_root="${DEVBOOKS_CHANGE_ROOT:-changes}"
truth_root="${DEVBOOKS_TRUTH_ROOT:-specs}"
out_path=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --mode)
      mode="${2:-}"
      shift 2
      ;;
    --project-root)
      project_root="${2:-}"
      shift 2
      ;;
    --change-root)
      change_root="${2:-}"
      shift 2
      ;;
    --truth-root)
      truth_root="${2:-}"
      shift 2
      ;;
    --out)
      out_path="${2:-}"
      shift 2
      ;;
    *)
      errorf "unknown option: $1"
      usage
      exit 2
      ;;
  esac
done

case "$mode" in
  proposal|apply|review|archive|strict) ;;
  *)
    errorf "invalid --mode: $mode"
    exit 2
    ;;
esac

if [[ -z "$change_id" || "$change_id" == "-"* || "$change_id" =~ [[:space:]] ]]; then
  errorf "invalid change-id: '$change_id'"
  exit 2
fi

project_root="${project_root%/}"
change_root="${change_root%/}"
truth_root="${truth_root%/}"

if [[ "$change_root" = /* ]]; then
  change_root_dir="$change_root"
else
  change_root_dir="${project_root}/${change_root}"
fi

if [[ "$truth_root" = /* ]]; then
  truth_dir="$truth_root"
else
  truth_dir="${project_root}/${truth_root}"
fi

change_dir="${change_root_dir}/${change_id}"
proposal_file="${change_dir}/proposal.md"

mkdir -p "${change_dir}/evidence/gates"

out_file="${change_dir}/evidence/gates/knife-correctness-check.json"
if [[ -n "$out_path" ]]; then
  if [[ "$out_path" = /* ]]; then
    out_file="$out_path"
  else
    out_file="${change_dir}/${out_path}"
  fi
fi

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

json_array() {
  local first=1
  local item
  printf '['
  for item in "$@"; do
    if [[ $first -eq 0 ]]; then
      printf ','
    fi
    first=0
    printf '"%s"' "$(json_escape "$item")"
  done
  printf ']'
}

timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

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

extract_yaml_top_list() {
  local file="$1"
  local key="$2"
  awk -v k="$key" '
    function trim(s){ gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); gsub(/["'"'"']/, "", s); return s }
    $0 ~ ("^" k ":[[:space:]]*$") { in_list=1; next }
    in_list && /^[^[:space:]]/ { exit }
    in_list && /^[[:space:]]*-[[:space:]]*/ {
      line=$0
      sub(/^[[:space:]]*-[[:space:]]*/, "", line)
      line=trim(line)
      if (line != "") print line
    }
  ' "$file" 2>/dev/null || true
}

discover_slice_limits_tokens() {
  local discovery="${project_root}/scripts/config-discovery.sh"
  local slice_limits_json=""
  local capacity_factor="1.0"

  if [[ -f "$discovery" ]]; then
    slice_limits_json="$(
      bash "$discovery" "$project_root" 2>/dev/null \
        | awk -F= '$1=="SLICE_LIMITS_JSON" && !found { print $2; found=1 }'
    )"
    capacity_factor="$(
      bash "$discovery" "$project_root" 2>/dev/null \
        | awk -F= '$1=="MODEL_CAPACITY_FACTOR" && !found { print $2; found=1 }'
    )"
  fi

  slice_limits_json="$(trim "${slice_limits_json:-}")"
  capacity_factor="$(trim "${capacity_factor:-1.0}")"

  # Unquote SLICE_LIMITS_JSON if it's single-quoted.
  if [[ "$slice_limits_json" == \'*\' ]]; then
    slice_limits_json="${slice_limits_json#\'}"
    slice_limits_json="${slice_limits_json%\'}"
  fi

  if [[ -z "$slice_limits_json" || "$slice_limits_json" == "{}" ]]; then
    printf '%s' ""
    return 0
  fi

  if ! command -v node >/dev/null 2>&1; then
    printf '%s' ""
    return 0
  fi

  node -e '
    const json = process.argv[1] || "{}";
    const capRaw = process.argv[2] || "1.0";
    let cap = Number(capRaw);
    if (!Number.isFinite(cap) || cap <= 0) cap = 1.0;
    let o = {};
    try { o = JSON.parse(json); } catch { o = {}; }
    const t = o && typeof o === "object" ? o.tokens : undefined;
    if (t === undefined || t === null) process.exit(0);
    const n = Number(t);
    if (!Number.isFinite(n) || n <= 0) process.exit(0);
    process.stdout.write(String(n * cap));
  ' "$slice_limits_json" "$capacity_factor" 2>/dev/null || true
}

resolve_change_dir_for_slice() {
  local root_dir="$1"
  local id="$2"
  local dir="${root_dir}/${id}"
  if [[ -d "$dir" ]]; then
    printf '%s' "$dir"
    return 0
  fi
  if [[ -d "${root_dir}/archive/${id}" ]]; then
    printf '%s' "${root_dir}/archive/${id}"
    return 0
  fi
  printf '%s' "$dir"
  return 0
}

extract_completion_contract_check_ids() {
  local contract="$1"
  awk '
    BEGIN { in_checks=0; in_yaml=0 }
    $0 ~ /^checks:[[:space:]]*$/ { in_checks=1; next }
    in_checks && /^[^[:space:]]/ { in_checks=0 }
    in_checks && $0 ~ /^[[:space:]]*-[[:space:]]*id:[[:space:]]*/ {
      line=$0
      sub(/^[[:space:]]*-[[:space:]]*id:[[:space:]]*/, "", line)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      gsub(/["'"'"']/, "", line)
      if (line != "") print line
    }
  ' "$contract" 2>/dev/null || true
}

parse_yaml_slices_kv() {
  local file="$1"
  awk '
    function trim(s){ gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); gsub(/["'"'"']/, "", s); return s }
    BEGIN {
      in_slices=0
      current=""
      in_ac_subset=0
      in_depends=0
      in_anchors=0
      in_budgets=0
      in_budget=0
    }
    /^slices:[[:space:]]*$/ { in_slices=1; next }
    in_slices && /^[^[:space:]]/ { in_slices=0; next }
    in_slices {
      if ($0 ~ /^  - slice_id:[[:space:]]*/) {
        current=$0
        sub(/^  - slice_id:[[:space:]]*/, "", current)
        current=trim(current)
        print current "\tmeta\tslice_id"
        in_ac_subset=0; in_depends=0; in_anchors=0; in_budgets=0; in_budget=0
        next
      }
      if (current == "") next

      if ($0 ~ /^    change_id:[[:space:]]*/) {
        v=$0; sub(/^    change_id:[[:space:]]*/, "", v); v=trim(v)
        if (v != "") print current "\tmeta\tchange_id\t" v
        next
      }

      if ($0 ~ /^    ac_subset:[[:space:]]*$/) { in_ac_subset=1; in_depends=0; in_anchors=0; next }
      if (in_ac_subset && $0 ~ /^    [^[:space:]]/) { in_ac_subset=0 }
      if (in_ac_subset && $0 ~ /^      -[[:space:]]*/) {
        v=$0; sub(/^      -[[:space:]]*/, "", v); v=trim(v)
        if (v != "") print current "\tac\t" v
        next
      }

      if ($0 ~ /^    depends_on:[[:space:]]*\\[\\][[:space:]]*$/) { in_depends=0; next }
      if ($0 ~ /^    depends_on:[[:space:]]*$/) { in_depends=1; in_ac_subset=0; in_anchors=0; next }
      if (in_depends && $0 ~ /^    [^[:space:]]/) { in_depends=0 }
      if (in_depends && $0 ~ /^      -[[:space:]]*/) {
        v=$0; sub(/^      -[[:space:]]*/, "", v); v=trim(v)
        if (v != "") print current "\tdep\t" v
        next
      }

      if ($0 ~ /^    budgets:[[:space:]]*$/) { in_budgets=1; next }
      if (in_budgets && $0 ~ /^    [^[:space:]]/) { in_budgets=0 }
      if (in_budgets && $0 ~ /^      tokens:[[:space:]]*/) {
        v=$0; sub(/^      tokens:[[:space:]]*/, "", v); v=trim(v)
        if (v != "") print current "\tbudget_tokens\t" v
        next
      }

      if ($0 ~ /^    budget:[[:space:]]*$/) { in_budget=1; next }
      if (in_budget && $0 ~ /^    [^[:space:]]/) { in_budget=0 }
      if (in_budget && $0 ~ /^      threshold_tokens:[[:space:]]*/) {
        v=$0; sub(/^      threshold_tokens:[[:space:]]*/, "", v); v=trim(v)
        if (v != "") print current "\tthreshold_tokens\t" v
        next
      }
      if (in_budget && $0 ~ /^      score_tokens:[[:space:]]*/) {
        v=$0; sub(/^      score_tokens:[[:space:]]*/, "", v); v=trim(v)
        if (v != "") print current "\tscore_tokens\t" v
        next
      }
      if (in_budget && $0 ~ /^      overload_action:[[:space:]]*/) {
        v=$0; sub(/^      overload_action:[[:space:]]*/, "", v); v=trim(v)
        if (v != "") print current "\toverload_action\t" v
        next
      }

      if ($0 ~ /^    verification_anchors:[[:space:]]*$/) { in_anchors=1; in_ac_subset=0; in_depends=0; next }
      if (in_anchors && $0 ~ /^    [^[:space:]]/) { in_anchors=0 }
      if (in_anchors && $0 ~ /^      -[[:space:]]*/) {
        v=$0; sub(/^      -[[:space:]]*/, "", v); v=trim(v)
        if (v != "") print current "\tanchor\t" v
        next
      }
    }
  ' "$file" 2>/dev/null || true
}

required=false
risk_level="low"
request_kind=""
epic_id=""

if [[ -f "$proposal_file" ]]; then
  v="$(extract_front_matter_value "$proposal_file" "risk_level")"
  if [[ -n "$v" ]]; then
    risk_level="$v"
  fi
  request_kind="$(extract_front_matter_value "$proposal_file" "request_kind")"
  epic_id="$(extract_front_matter_value "$proposal_file" "epic_id")"
fi

if [[ "$mode" == "archive" || "$mode" == "strict" ]]; then
  if [[ "$risk_level" == "high" || "$request_kind" == "epic" ]]; then
    required=true
  fi
fi

checks=("required-trigger")
artifacts=()
failure_reasons=()
next_action="DevBooks"

knife_plan_path=""
knife_plan_format=""

if [[ "$required" != true ]]; then
  checks+=("skip-not-required")
fi

if [[ "$required" == true ]]; then
  if [[ -z "$epic_id" ]]; then
    failure_reasons+=("missing epic_id in proposal front matter")
  else
    epic_dir="${truth_dir}/_meta/epics/${epic_id}"
    if [[ -f "${epic_dir}/knife-plan.yaml" ]]; then
      knife_plan_path="${epic_dir}/knife-plan.yaml"
      knife_plan_format="yaml"
    elif [[ -f "${epic_dir}/knife-plan.json" ]]; then
      knife_plan_path="${epic_dir}/knife-plan.json"
      knife_plan_format="json"
    else
      failure_reasons+=("missing Knife Plan: ${epic_dir}/knife-plan.(yaml|json)")
    fi
  fi

  if [[ -n "$knife_plan_path" ]]; then
    knife_plan_rel="$knife_plan_path"
    if [[ "$knife_plan_rel" == "${project_root}/"* ]]; then
      knife_plan_rel="${knife_plan_rel#"${project_root}"/}"
    fi
    artifacts+=("$knife_plan_rel")
    checks+=("mece")
    checks+=("dag")
    checks+=("budget-fuse")
    checks+=("independent-green")

    tmp_dir="$(mktemp -d 2>/dev/null || mktemp -d -t devbooks_knife)"
    trap 'rm -rf "$tmp_dir" >/dev/null 2>&1 || true' EXIT

    epic_ac_file="${tmp_dir}/epic_acs.txt"
    slice_all_ac_file="${tmp_dir}/slice_all_acs.txt"
    slice_ids_file="${tmp_dir}/slice_ids.txt"
    edges_file="${tmp_dir}/edges.txt"

    : >"$epic_ac_file"
    : >"$slice_all_ac_file"
    : >"$slice_ids_file"
    : >"$edges_file"

    # Epic AC list (accept either ac_ids or epic_ac_ids)
    if [[ "$knife_plan_format" == "yaml" ]]; then
      while IFS= read -r ac; do
        [[ -n "$ac" ]] || continue
        printf '%s\n' "$ac" >>"$epic_ac_file"
      done < <(extract_yaml_top_list "$knife_plan_path" "ac_ids")
      if [[ ! -s "$epic_ac_file" ]]; then
        while IFS= read -r ac; do
          [[ -n "$ac" ]] || continue
          printf '%s\n' "$ac" >>"$epic_ac_file"
        done < <(extract_yaml_top_list "$knife_plan_path" "epic_ac_ids")
      fi
    fi

    if [[ ! -s "$epic_ac_file" ]]; then
      failure_reasons+=("Knife Plan missing epic AC list (ac_ids[] or epic_ac_ids[])")
    fi

    # Parse slices
    if [[ "$knife_plan_format" != "yaml" ]]; then
      failure_reasons+=("knife-plan.json correctness is not supported yet (expected knife-plan.yaml)")
    else
      kv_file="${tmp_dir}/slices.kv.tsv"
      parse_yaml_slices_kv "$knife_plan_path" >"$kv_file"

      # Extract slice ids
      awk -F'\t' '$2=="meta" && $3=="slice_id"{print $1}' "$kv_file" | sort -u >"$slice_ids_file" || true
      if [[ ! -s "$slice_ids_file" ]]; then
        failure_reasons+=("Knife Plan has no slices[] entries")
      fi

      # Build union AC list and detect overlaps
      awk -F'\t' '$2=="ac"{print $3}' "$kv_file" >>"$slice_all_ac_file" || true

      if [[ -s "$epic_ac_file" && -s "$slice_all_ac_file" ]]; then
        overlaps="$(sort "$slice_all_ac_file" | uniq -d || true)"
        if [[ -n "$overlaps" ]]; then
          overlaps_fmt="$(printf '%s\n' "$overlaps" | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
          failure_reasons+=("MECE violation: AC appears in multiple slices: ${overlaps_fmt}")
        fi

        sort -u "$slice_all_ac_file" >"${tmp_dir}/slice_union.txt"
        sort -u "$epic_ac_file" >"${tmp_dir}/epic_sorted.txt"

        missing_acs="$(comm -23 "${tmp_dir}/epic_sorted.txt" "${tmp_dir}/slice_union.txt" || true)"
        extra_acs="$(comm -23 "${tmp_dir}/slice_union.txt" "${tmp_dir}/epic_sorted.txt" || true)"

        if [[ -n "$missing_acs" ]]; then
          missing_fmt="$(printf '%s\n' "$missing_acs" | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
          failure_reasons+=("MECE violation: missing ACs from slices: ${missing_fmt}")
        fi
        if [[ -n "$extra_acs" ]]; then
          extra_fmt="$(printf '%s\n' "$extra_acs" | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
          failure_reasons+=("MECE violation: extra ACs not in epic: ${extra_fmt}")
        fi
      fi

      # DAG: validate depends_on references and cycle-free graph
      if [[ -s "$slice_ids_file" ]]; then
        while IFS=$'\t' read -r sid field v1 _; do
          if [[ "$field" == "dep" ]]; then
            dep="$v1"
            if ! grep -Fxq "$dep" "$slice_ids_file" 2>/dev/null; then
              failure_reasons+=("DAG violation: slice ${sid} depends_on unknown slice_id: ${dep}")
            else
              printf '%s\t%s\n' "$dep" "$sid" >>"$edges_file"
            fi
          fi
        done <"$kv_file"

        sort -u "$edges_file" -o "$edges_file" 2>/dev/null || true

        remaining_file="${tmp_dir}/remaining.txt"
        cp "$slice_ids_file" "$remaining_file"
        edges_rem="${tmp_dir}/edges_remaining.txt"
        cp "$edges_file" "$edges_rem"

        removed_any=true
        while [[ -s "$remaining_file" && "$removed_any" == true ]]; do
          removed_any=false
          zero_nodes=()
          while IFS= read -r sid; do
            [[ -n "$sid" ]] || continue
            indeg=$(awk -F'\t' -v s="$sid" '$2==s{c++} END{print c+0}' "$edges_rem")
            if [[ "$indeg" -eq 0 ]]; then
              zero_nodes+=("$sid")
            fi
          done <"$remaining_file"

          if [[ ${#zero_nodes[@]} -eq 0 ]]; then
            break
          fi

          removed_any=true
          for z in "${zero_nodes[@]}"; do
            # Remove node from remaining
            grep -Fvx "$z" "$remaining_file" >"${remaining_file}.tmp" || true
            mv -f "${remaining_file}.tmp" "$remaining_file"
            # Remove outgoing edges from z
            awk -F'\t' -v from="$z" '$1!=from' "$edges_rem" >"${edges_rem}.tmp" || true
            mv -f "${edges_rem}.tmp" "$edges_rem"
          done
        done

        if [[ -s "$remaining_file" ]]; then
          failure_reasons+=("DAG violation: cycle detected among slices: $(tr '\n' ' ' <"$remaining_file")")
        fi
      fi

      # Budget fuse (tokens)
      limit_tokens="$(discover_slice_limits_tokens)"
      if [[ -n "$limit_tokens" ]]; then
        while IFS=$'\t' read -r sid field value; do
          if [[ "$field" == "budget_tokens" ]]; then
            b="$(trim "$value")"
            if [[ -n "$b" ]]; then
              if ! [[ "$b" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
                failure_reasons+=("Budget violation: slice ${sid} tokens budget is not a number: ${b}")
              else
                # Compare using node for floats, if available
                if command -v node >/dev/null 2>&1; then
                  over="$(node -e 'const a=Number(process.argv[1]); const b=Number(process.argv[2]); process.stdout.write(String(Number.isFinite(a)&&Number.isFinite(b)&&a>b ? 1:0));' "$b" "$limit_tokens" 2>/dev/null || echo "0")"
                  if [[ "$over" == "1" ]]; then
                    failure_reasons+=("Budget fuse: slice ${sid} tokens=${b} exceeds limit_tokens=${limit_tokens}")
                  fi
                fi
              fi
            fi
          fi
        done < <(awk -F'\t' '$2=="budget_tokens"{print $1"\t"$2"\t"$3}' "$kv_file" 2>/dev/null || true)
      fi

      # Independent green: each slice has >= 1 anchor, anchors exist in completion contract
      while IFS= read -r sid; do
        [[ -n "$sid" ]] || continue
        anchors="$(awk -F'\t' -v s="$sid" '$1==s && $2=="anchor"{print $3}' "$kv_file" 2>/dev/null || true)"
        if [[ -z "$anchors" ]]; then
          failure_reasons+=("Independent Green violation: slice ${sid} has no verification_anchors[]")
          continue
        fi

        slice_change_id="$(awk -F'\t' -v s="$sid" '$1==s && $2=="meta" && $3=="change_id"{print $4; exit}' "$kv_file" 2>/dev/null || true)"
        if [[ -z "$slice_change_id" ]]; then
          failure_reasons+=("Independent Green violation: slice ${sid} missing change_id")
          continue
        fi

        slice_change_dir="$(resolve_change_dir_for_slice "$change_root_dir" "$slice_change_id")"
        if [[ ! -d "$slice_change_dir" ]]; then
          failure_reasons+=("Independent Green violation: change package not found for slice ${sid}: ${slice_change_dir}")
          continue
        fi

        contract="${slice_change_dir}/completion.contract.yaml"
        if [[ ! -f "$contract" ]]; then
          failure_reasons+=("Independent Green violation: completion.contract.yaml missing for slice ${sid}: ${contract}")
          continue
        fi

        contract_ids_file="${tmp_dir}/contract-check-ids-${sid}.txt"
        extract_completion_contract_check_ids "$contract" | sort -u >"$contract_ids_file" || true

        while IFS= read -r a; do
          [[ -n "$a" ]] || continue
          if ! grep -Fxq "$a" "$contract_ids_file" 2>/dev/null; then
            failure_reasons+=("Independent Green violation: slice ${sid} anchor not found in completion contract checks[].id: ${a}")
          fi
        done <<<"$anchors"
      done <"$slice_ids_file"
    fi
  fi
fi

status="pass"
if [[ ${#failure_reasons[@]} -gt 0 ]]; then
  status="fail"
  next_action="Knife"
fi

checks_json="$(json_array "${checks[@]}")"
artifacts_json="[]"
if [[ ${#artifacts[@]} -gt 0 ]]; then
  artifacts_json="$(json_array "${artifacts[@]}")"
fi
reasons_json="[]"
if [[ ${#failure_reasons[@]} -gt 0 ]]; then
  reasons_json="$(json_array "${failure_reasons[@]}")"
fi

tmp="${out_file}.tmp.$$"
cat >"$tmp" <<EOF
{
  "schema_version": "1.0.0",
  "gate_id": "G3",
  "mode": "$(json_escape "$mode")",
  "check_id": "knife-correctness-check",
  "status": "$(json_escape "$status")",
  "timestamp": "$(json_escape "$(timestamp)")",
  "inputs": {
    "change_id": "$(json_escape "$change_id")",
    "required": $( [[ "$required" == true ]] && echo "true" || echo "false" ),
    "risk_level": "$(json_escape "$risk_level")",
    "request_kind": "$(json_escape "$request_kind")",
    "epic_id": "$(json_escape "$epic_id")",
    "truth_dir": "$(json_escape "$truth_dir")"
  },
  "checks": ${checks_json},
  "artifacts": ${artifacts_json},
  "failure_reasons": ${reasons_json},
  "next_action": "$(json_escape "$next_action")"
}
EOF
mv -f "$tmp" "$out_file"

if [[ "$status" != "pass" ]]; then
  errorf "Knife correctness check failed: $out_file"
  printf '%s\n' "${failure_reasons[@]}" >&2
  exit 1
fi

exit 0
