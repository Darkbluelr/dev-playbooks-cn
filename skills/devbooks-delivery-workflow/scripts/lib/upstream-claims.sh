#!/usr/bin/env bash

# upstream-claims.sh
# Shared upstream_claims parsing + evaluation helpers.
#
# This file is intended to be sourced by:
# - skills/devbooks-delivery-workflow/scripts/check-upstream-claims.sh
# - skills/devbooks-delivery-workflow/scripts/archive-decider.sh

UC_TRUTH_DIR=""
UC_CHANGE_ROOT_DIR=""
UC_LAST_ERROR=""

declare -a UC_SET_REFS=()
declare -a UC_CLAIMS=()
declare -a UC_NEXT_ACTION_REFS=()
declare -a UC_COVERED_CSV=()
declare -a UC_DEFERRED_CSV=()

declare -a UC_EVAL_SET_REFS=()
declare -a UC_EVAL_SET_PATHS=()
declare -a UC_EVAL_CLAIMS=()
declare -a UC_EVAL_STATUS=()
declare -a UC_EVAL_MUST_TOTAL=()
declare -a UC_EVAL_MUST_COVERED=()
declare -a UC_EVAL_UNCOVERED_MUST_CSV=()
declare -a UC_EVAL_DEFERRED_CSV=()
declare -a UC_EVAL_NEXT_ACTION_REFS=()
declare -a UC_EVAL_NEXT_ACTION_PATHS=()
declare -a UC_EVAL_NEXT_ACTION_RESOLVABLE=()
declare -a UC_EVAL_ERRORS_CSV=()

uc_set_context() {
  UC_TRUTH_DIR="${1:-}"
  UC_CHANGE_ROOT_DIR="${2:-}"
}

uc_trim_value() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

uc_strip_quotes() {
  local value
  value="$(uc_trim_value "$1")"
  value="${value#\"}"
  value="${value%\"}"
  value="${value#\'}"
  value="${value%\'}"
  printf '%s' "$value"
}

uc_to_lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

uc_leading_ws_count() {
  local line="$1"
  local ws="${line%%[!$' \t']*}"
  printf '%s' "${#ws}"
}

uc_canonical_dir() {
  local path="$1"
  (cd "$path" 2>/dev/null && pwd -P)
}

uc_canonical_file() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    return 1
  fi
  local dir
  dir="$(dirname "$path")"
  local base
  base="$(basename "$path")"
  local canon_dir
  canon_dir="$(uc_canonical_dir "$dir")" || return 1
  printf '%s/%s' "$canon_dir" "$base"
}

uc_is_under_root() {
  local path="$1"
  local root="$2"
  local canon_path canon_root
  canon_path="$(uc_canonical_file "$path")" || return 1
  canon_root="$(uc_canonical_dir "$root")" || return 1
  case "$canon_path" in
    "$canon_root"/*) return 0 ;;
    *) return 1 ;;
  esac
}

uc_parse_inline_list() {
  local raw="$1"
  raw="$(uc_trim_value "$raw")"

  if [[ "$raw" == "[]" ]]; then
    return 0
  fi

  if [[ "$raw" == \[*\] ]]; then
    raw="${raw#[}"
    raw="${raw%]}"
  fi

  local part
  IFS=',' read -r -a parts <<<"$raw"
  for part in "${parts[@]}"; do
    part="$(uc_strip_quotes "$(uc_trim_value "$part")")"
    if [[ -n "$part" ]]; then
      printf '%s\n' "$part"
    fi
  done
}

uc_append_csv_item() {
  local current="$1"
  local item="$2"
  if [[ -z "$item" ]]; then
    printf '%s' "$current"
    return 0
  fi
  if [[ -z "$current" ]]; then
    printf '%s' "$item"
    return 0
  fi
  printf '%s' "${current},${item}"
}

uc_reset_contract_arrays() {
  UC_SET_REFS=()
  UC_CLAIMS=()
  UC_NEXT_ACTION_REFS=()
  UC_COVERED_CSV=()
  UC_DEFERRED_CSV=()
}

uc_parse_contract_upstream_claims() {
  local file="$1"
  uc_reset_contract_arrays

  if [[ ! -f "$file" ]]; then
    return 1
  fi

  local in_block=false

  local current_set_ref=""
  local current_claim=""
  local current_next_action_ref=""
  local current_covered_csv=""
  local current_deferred_csv=""

  local collecting=""
  local collect_indent=0
  local item_indent="-1"

  add_csv_item() {
    local name="$1"
    local item="$2"
    if [[ "$name" == "covered" ]]; then
      current_covered_csv="$(uc_append_csv_item "$current_covered_csv" "$item")"
      return 0
    fi
    current_deferred_csv="$(uc_append_csv_item "$current_deferred_csv" "$item")"
  }

  append_current() {
    if [[ -z "$current_set_ref" && -z "$current_claim" && -z "$current_next_action_ref" && -z "$current_covered_csv" && -z "$current_deferred_csv" ]]; then
      return 0
    fi
    UC_SET_REFS+=("$current_set_ref")
    UC_CLAIMS+=("$current_claim")
    UC_NEXT_ACTION_REFS+=("$current_next_action_ref")
    UC_COVERED_CSV+=("$current_covered_csv")
    UC_DEFERRED_CSV+=("$current_deferred_csv")
  }

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"

    if [[ "$line" =~ ^[[:space:]]*# ]]; then
      continue
    fi

    if [[ "$in_block" == false ]]; then
      if [[ "$line" =~ ^upstream_claims:[[:space:]]*$ ]]; then
        in_block=true
      fi
      continue
    fi

    # End block: another top-level key encountered.
    if [[ "$line" =~ ^[^[:space:]-][A-Za-z0-9_.-]*: ]]; then
      break
    fi

    # Collecting list items (block list)
    if [[ -n "$collecting" ]]; then
      local indent
      indent="$(uc_leading_ws_count "$line")"
      if (( indent <= collect_indent )); then
        collecting=""
      else
        local trimmed
        trimmed="$(uc_trim_value "$line")"
        if [[ "$trimmed" =~ ^-[[:space:]]*(.*)$ ]]; then
          local item
          item="$(uc_strip_quotes "$(uc_trim_value "${BASH_REMATCH[1]}")")"
          if [[ -n "$item" ]]; then
            add_csv_item "$collecting" "$item"
          fi
          continue
        fi
      fi
    fi

    # Start new claim item (only when '-' is at the upstream_claims item indent).
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]* ]]; then
      local dash_indent
      dash_indent="$(uc_leading_ws_count "$line")"
      if [[ "$item_indent" == "-1" ]]; then
        item_indent="$dash_indent"
      fi

      if [[ "$dash_indent" != "$item_indent" ]]; then
        # Nested list item (e.g., covered/deferred block list). Ignore unless collecting.
        continue
      fi

      collecting=""
      append_current
      current_set_ref=""
      current_claim=""
      current_next_action_ref=""
      current_covered_csv=""
      current_deferred_csv=""

      local rest
      rest="$(uc_trim_value "${line#*-}")"
      if [[ -n "$rest" ]]; then
        # Support "- set_ref: ..."
        local key="${rest%%:*}"
        local value
        value="$(uc_trim_value "${rest#*:}")"
        value="$(uc_strip_quotes "$value")"
        case "$key" in
          set_ref) current_set_ref="$value" ;;
          claim) current_claim="$value" ;;
          next_action_ref) current_next_action_ref="$value" ;;
        esac
      fi
      continue
    fi

    local trimmed
    trimmed="$(uc_trim_value "$line")"
    if [[ ! "$trimmed" =~ ^[A-Za-z0-9_.-]+: ]]; then
      continue
    fi

    local key="${trimmed%%:*}"
    local value
    value="$(uc_trim_value "${trimmed#*:}")"

    case "$key" in
      set_ref)
        current_set_ref="$(uc_strip_quotes "$value")"
        ;;
      claim)
        current_claim="$(uc_strip_quotes "$value")"
        ;;
      next_action_ref)
        current_next_action_ref="$(uc_strip_quotes "$value")"
        ;;
      covered|deferred)
        if [[ -z "$value" ]]; then
          collecting="$key"
          collect_indent="$(uc_leading_ws_count "$line")"
          continue
        fi
        local item
        while IFS= read -r item; do
          add_csv_item "$key" "$item"
        done < <(uc_parse_inline_list "$value")
        ;;
    esac
  done <"$file"

  collecting=""
  append_current
  return 0
}

uc_yaml_top_scalar() {
  local file="$1"
  local key="$2"

  awk -v k="$key" '
    $0 ~ "^" k ":[[:space:]]*" {
      sub("^" k ":[[:space:]]*", "", $0)
      print $0
      exit 0
    }
  ' "$file" 2>/dev/null
}

uc_requirements_index_schema_version_ok() {
  local file="$1"
  UC_LAST_ERROR=""

  if [[ ! -f "$file" ]]; then
    UC_LAST_ERROR="requirements.index not found"
    return 1
  fi

  local raw
  raw="$(uc_yaml_top_scalar "$file" "schema_version" || true)"
  local value
  value="$(uc_strip_quotes "$raw")"
  if [[ "$value" != "1.0.0" ]]; then
    UC_LAST_ERROR="requirements.index schema_version must be 1.0.0 (actual: ${value:-<empty>})"
    return 1
  fi
  return 0
}

uc_collect_requirements_must_ids() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    return 1
  fi

  local in_block=false
  local current_id=""
  local current_severity=""

  flush_current() {
    if [[ -z "$current_id" ]]; then
      return 0
    fi
    if [[ "$(uc_to_lower "$current_severity")" == "must" ]]; then
      printf '%s\n' "$current_id"
    fi
  }

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    if [[ "$line" =~ ^[[:space:]]*# ]]; then
      continue
    fi
    if [[ "$in_block" == false ]]; then
      if [[ "$line" =~ ^requirements:[[:space:]]*$ ]]; then
        in_block=true
      fi
      continue
    fi
    if [[ "$line" =~ ^[^[:space:]-][A-Za-z0-9_.-]*: ]]; then
      break
    fi

    local trimmed
    trimmed="$(uc_trim_value "$line")"
    if [[ "$trimmed" =~ ^-[[:space:]]*id:[[:space:]]*(.*)$ ]]; then
      flush_current
      current_id="$(uc_strip_quotes "$(uc_trim_value "${BASH_REMATCH[1]}")")"
      current_severity=""
      continue
    fi
    if [[ "$trimmed" =~ ^severity:[[:space:]]*(.*)$ ]]; then
      current_severity="$(uc_strip_quotes "$(uc_trim_value "${BASH_REMATCH[1]}")")"
      continue
    fi
  done <"$file"

  flush_current
  return 0
}

uc_list_contains() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

uc_split_csv_to_array() {
  local csv="$1"
  if [[ -z "$csv" ]]; then
    return 0
  fi
  local part
  IFS=',' read -r -a parts <<<"$csv"
  for part in "${parts[@]}"; do
    part="$(uc_trim_value "$part")"
    if [[ -n "$part" ]]; then
      printf '%s\n' "$part"
    fi
  done
}

uc_resolve_set_ref() {
  local set_ref="$1"
  UC_LAST_ERROR=""

  if [[ -z "$set_ref" ]]; then
    UC_LAST_ERROR="missing set_ref"
    return 1
  fi
  if [[ "$set_ref" != truth://* ]]; then
    UC_LAST_ERROR="set_ref must use truth:// (actual: ${set_ref})"
    return 1
  fi
  if [[ "$set_ref" != truth://*requirements.index.yaml && "$set_ref" != truth://*requirements.index.yml ]]; then
    UC_LAST_ERROR="set_ref must point to requirements.index.yaml (actual: ${set_ref})"
    return 1
  fi

  local rel="${set_ref#truth://}"
  rel="${rel#/}"
  local abs="${UC_TRUTH_DIR%/}/${rel}"
  if [[ ! -f "$abs" ]]; then
    UC_LAST_ERROR="set_ref not resolvable: ${set_ref}"
    return 1
  fi
  if ! uc_is_under_root "$abs" "$UC_TRUTH_DIR"; then
    UC_LAST_ERROR="set_ref escapes truth_root: ${set_ref}"
    return 1
  fi

  printf '%s' "$abs"
  return 0
}

uc_resolve_next_action_ref() {
  local ref="$1"
  UC_LAST_ERROR=""

  if [[ -z "$ref" ]]; then
    UC_LAST_ERROR="missing next_action_ref"
    return 1
  fi

  if [[ "$ref" == truth://* ]]; then
    local rel="${ref#truth://}"
    rel="${rel#/}"
    local abs="${UC_TRUTH_DIR%/}/${rel}"
    if [[ ! -f "$abs" ]]; then
      UC_LAST_ERROR="next_action_ref not resolvable: ${ref}"
      return 1
    fi
    if ! uc_is_under_root "$abs" "$UC_TRUTH_DIR"; then
      UC_LAST_ERROR="next_action_ref escapes truth_root: ${ref}"
      return 1
    fi
    printf '%s' "$abs"
    return 0
  fi

  if [[ "$ref" == change://* ]]; then
    local rest="${ref#change://}"
    rest="${rest#/}"
    local ref_change_id="${rest%%/*}"
    local rel="${rest#*/}"
    if [[ "$ref_change_id" == "$rest" ]]; then
      rel=""
    fi

    if [[ -z "$ref_change_id" ]]; then
      UC_LAST_ERROR="next_action_ref invalid change ref: ${ref}"
      return 1
    fi
    if [[ "$rel" != "proposal.md" ]]; then
      UC_LAST_ERROR="next_action_ref for change:// must target proposal.md (actual: ${ref})"
      return 1
    fi

    local candidate="${UC_CHANGE_ROOT_DIR%/}/${ref_change_id}/${rel}"
    if [[ ! -f "$candidate" ]]; then
      candidate="${UC_CHANGE_ROOT_DIR%/}/archive/${ref_change_id}/${rel}"
    fi
    if [[ ! -f "$candidate" ]]; then
      UC_LAST_ERROR="next_action_ref not resolvable: ${ref}"
      return 1
    fi
    if ! uc_is_under_root "$candidate" "$UC_CHANGE_ROOT_DIR"; then
      UC_LAST_ERROR="next_action_ref escapes change_root: ${ref}"
      return 1
    fi
    printf '%s' "$candidate"
    return 0
  fi

  UC_LAST_ERROR="next_action_ref unsupported scheme: ${ref}"
  return 1
}

uc_reset_eval_arrays() {
  UC_EVAL_SET_REFS=()
  UC_EVAL_SET_PATHS=()
  UC_EVAL_CLAIMS=()
  UC_EVAL_STATUS=()
  UC_EVAL_MUST_TOTAL=()
  UC_EVAL_MUST_COVERED=()
  UC_EVAL_UNCOVERED_MUST_CSV=()
  UC_EVAL_DEFERRED_CSV=()
  UC_EVAL_NEXT_ACTION_REFS=()
  UC_EVAL_NEXT_ACTION_PATHS=()
  UC_EVAL_NEXT_ACTION_RESOLVABLE=()
  UC_EVAL_ERRORS_CSV=()
}

uc_evaluate_upstream_claims() {
  uc_reset_eval_arrays

  if [[ ${#UC_SET_REFS[@]} -eq 0 ]]; then
    return 0
  fi

  local overall_fail=false

  local i
  for i in "${!UC_SET_REFS[@]}"; do
    local set_ref="${UC_SET_REFS[$i]}"
    local claim_raw="${UC_CLAIMS[$i]}"
    local next_action_ref="${UC_NEXT_ACTION_REFS[$i]}"
    local covered_csv="${UC_COVERED_CSV[$i]}"
    local deferred_csv="${UC_DEFERRED_CSV[$i]}"

    local claim
    claim="$(uc_to_lower "$claim_raw")"

    local -a covered_ids=()
    local -a deferred_ids=()
    local item
    while IFS= read -r item; do
      [[ -n "$item" ]] || continue
      covered_ids+=("$item")
    done < <(uc_split_csv_to_array "$covered_csv")
    while IFS= read -r item; do
      [[ -n "$item" ]] || continue
      deferred_ids+=("$item")
    done < <(uc_split_csv_to_array "$deferred_csv")

    local -a item_errors=()

    if [[ -z "$set_ref" ]]; then
      item_errors+=("missing set_ref")
    fi
    if [[ -z "$claim" ]]; then
      item_errors+=("missing claim")
    fi

    local set_path=""
    if [[ -n "$set_ref" ]]; then
      set_path="$(uc_resolve_set_ref "$set_ref" || true)"
      if [[ -z "$set_path" ]]; then
        item_errors+=("${UC_LAST_ERROR:-set_ref not resolvable}")
      else
        if ! uc_requirements_index_schema_version_ok "$set_path"; then
          item_errors+=("${UC_LAST_ERROR:-requirements.index schema_version mismatch}")
        fi
      fi
    fi

    local -a must_ids=()
    if [[ -n "$set_path" && -f "$set_path" ]]; then
      while IFS= read -r must_id; do
        [[ -n "$must_id" ]] || continue
        must_ids+=("$must_id")
      done < <(uc_collect_requirements_must_ids "$set_path" || true)
    fi

    local -a overlap_ids=()
    local -a unknown_covered_ids=()
    local -a unknown_deferred_ids=()
    local -a missing_must_ids=()
    local -a unaccounted_must_ids=()

    local id
    for id in "${covered_ids[@]+${covered_ids[@]}}"; do
      if uc_list_contains "$id" "${deferred_ids[@]+${deferred_ids[@]}}"; then
        overlap_ids+=("$id")
      fi
      if [[ ${#must_ids[@]} -gt 0 ]] && ! uc_list_contains "$id" "${must_ids[@]+${must_ids[@]}}"; then
        unknown_covered_ids+=("$id")
      fi
    done
    for id in "${deferred_ids[@]+${deferred_ids[@]}}"; do
      if [[ ${#must_ids[@]} -gt 0 ]] && ! uc_list_contains "$id" "${must_ids[@]+${must_ids[@]}}"; then
        unknown_deferred_ids+=("$id")
      fi
    done

    if [[ ${#overlap_ids[@]} -gt 0 ]]; then
      item_errors+=("covered/deferred overlap")
    fi
    if [[ ${#unknown_covered_ids[@]} -gt 0 ]]; then
      item_errors+=("covered contains unknown ids")
    fi
    if [[ ${#unknown_deferred_ids[@]} -gt 0 ]]; then
      item_errors+=("deferred contains unknown ids")
    fi

    if [[ "$claim" != "complete" && "$claim" != "subset" ]]; then
      item_errors+=("invalid claim: ${claim_raw}")
    fi

    local next_action_path=""
    local next_action_resolvable=false
    if [[ -n "$next_action_ref" ]]; then
      next_action_path="$(uc_resolve_next_action_ref "$next_action_ref" || true)"
      if [[ -n "$next_action_path" ]]; then
        next_action_resolvable=true
      fi
    fi

    if [[ "$claim" == "complete" ]]; then
      if [[ ${#deferred_ids[@]} -gt 0 ]]; then
        item_errors+=("claim=complete requires deferred empty")
      fi
      for id in "${must_ids[@]+${must_ids[@]}}"; do
        if ! uc_list_contains "$id" "${covered_ids[@]+${covered_ids[@]}}"; then
          missing_must_ids+=("$id")
        fi
      done
      if [[ ${#missing_must_ids[@]} -gt 0 ]]; then
        item_errors+=("missing MUST ids for claim=complete")
      fi
    fi

    if [[ "$claim" == "subset" ]]; then
      if [[ ${#deferred_ids[@]} -eq 0 ]]; then
        item_errors+=("claim=subset requires deferred non-empty")
      fi
      if [[ -z "$next_action_ref" ]]; then
        item_errors+=("claim=subset requires next_action_ref")
      elif [[ "$next_action_resolvable" != true ]]; then
        item_errors+=("${UC_LAST_ERROR:-next_action_ref not resolvable}")
      fi

      local -a accounted=( "${covered_ids[@]+${covered_ids[@]}}" "${deferred_ids[@]+${deferred_ids[@]}}" )
      for id in "${must_ids[@]+${must_ids[@]}}"; do
        if ! uc_list_contains "$id" "${accounted[@]+${accounted[@]}}"; then
          unaccounted_must_ids+=("$id")
        fi
      done
      if [[ ${#unaccounted_must_ids[@]} -gt 0 ]]; then
        item_errors+=("unaccounted MUST ids for claim=subset")
      fi
    fi

    local must_total="${#must_ids[@]}"
    local must_covered_count=0
    for id in "${must_ids[@]+${must_ids[@]}}"; do
      if uc_list_contains "$id" "${covered_ids[@]+${covered_ids[@]}}"; then
        must_covered_count=$((must_covered_count + 1))
      fi
    done

    local uncovered_csv=""
    if [[ "$claim" == "subset" ]]; then
      if [[ ${#unaccounted_must_ids[@]} -gt 0 ]]; then
        uncovered_csv="$(printf '%s\n' "${unaccounted_must_ids[@]}" | awk 'NF' | LC_ALL=C sort -u | paste -sd ',' -)"
      fi
    else
      if [[ ${#missing_must_ids[@]} -gt 0 ]]; then
        uncovered_csv="$(printf '%s\n' "${missing_must_ids[@]}" | awk 'NF' | LC_ALL=C sort -u | paste -sd ',' -)"
      fi
    fi

    local deferred_out_csv=""
    if [[ ${#deferred_ids[@]} -gt 0 ]]; then
      deferred_out_csv="$(printf '%s\n' "${deferred_ids[@]}" | awk 'NF' | LC_ALL=C sort -u | paste -sd ',' -)"
    fi

    local item_status="pass"
    if [[ ${#item_errors[@]} -gt 0 ]]; then
      item_status="fail"
      overall_fail=true
    fi

    local errors_csv=""
    if [[ ${#item_errors[@]} -gt 0 ]]; then
      errors_csv="$(printf '%s\n' "${item_errors[@]}" | awk 'NF' | LC_ALL=C sort -u | paste -sd ',' -)"
    fi

    UC_EVAL_SET_REFS+=("$set_ref")
    UC_EVAL_SET_PATHS+=("$set_path")
    UC_EVAL_CLAIMS+=("$claim")
    UC_EVAL_STATUS+=("$item_status")
    UC_EVAL_MUST_TOTAL+=("$must_total")
    UC_EVAL_MUST_COVERED+=("$must_covered_count")
    UC_EVAL_UNCOVERED_MUST_CSV+=("$uncovered_csv")
    UC_EVAL_DEFERRED_CSV+=("$deferred_out_csv")
    UC_EVAL_NEXT_ACTION_REFS+=("$next_action_ref")
    UC_EVAL_NEXT_ACTION_PATHS+=("$next_action_path")
    UC_EVAL_NEXT_ACTION_RESOLVABLE+=("$next_action_resolvable")
    UC_EVAL_ERRORS_CSV+=("$errors_csv")
  done

  if [[ "$overall_fail" == true ]]; then
    return 1
  fi
  return 0
}

