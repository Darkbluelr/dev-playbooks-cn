#!/usr/bin/env bash
set -euo pipefail

RULE_VERSION="delivery-routing/v1"

usage() {
  cat <<'EOF' >&2
usage: intent-routing.sh [--text "<user_request>"]

Outputs a single-line JSON routing decision for Delivery.

Input:
  --text "<user_request>"   Use the provided text as the routing input.
  stdin                     If --text is omitted, read the full stdin as input.

Output (stdout):
  A single-line JSON with required fields:
    - request_kind: debug|change|epic|void|bootstrap|governance
    - ssot_intent: debug|refactor|feature|docs
    - shortest_loop: normalized single-line string
    - upgrade_conditions: string array
    - routing_status: ok|degraded|error
    - rule_version: delivery-routing/v1
    - matched_keywords: string array (deduped, <= 8)

Exit codes:
  0  OK (including degraded)
  2  Empty input (error routing_status, still prints JSON)
EOF
}

json_escape() {
  local input="$1"
  input="${input//\\/\\\\}"
  input="${input//\"/\\\"}"
  input="${input//$'\n'/\\n}"
  input="${input//$'\r'/\\r}"
  input="${input//$'\t'/\\t}"
  printf '%s' "$input"
}

json_array() {
  local first=1
  local item
  printf '%s' "["
  for item in "$@"; do
    if [[ $first -eq 0 ]]; then
      printf '%s' ","
    fi
    first=0
    printf '"%s"' "$(json_escape "$item")"
  done
  printf '%s' "]"
}

contains_any() {
  local haystack="$1"
  shift || true
  local needle
  for needle in "$@"; do
    [[ -n "$needle" ]] || continue
    if has_keyword "$haystack" "$needle"; then
      return 0
    fi
  done
  return 1
}

regex_escape_ere() {
  # Escape ERE metacharacters for grep -E.
  printf '%s' "$1" | sed -E 's/[][(){}.^$*+?|\\]/\\&/g'
}

is_ascii_printable() {
  # True when the string contains only ASCII printable chars (space..~).
  # Use grep so locale can be applied (keyword `[[` can't be env-prefixed).
  local s="${1:-}"
  if [[ -z "$s" ]]; then
    return 0
  fi
  if printf '%s' "$s" | LC_ALL=C grep -Eq '[^ -~]'; then
    return 1
  fi
  return 0
}

has_keyword() {
  local haystack="${1:-}"
  local needle="${2:-}"
  [[ -n "$needle" ]] || return 1

  if is_ascii_printable "$needle"; then
    local escaped
    escaped="$(regex_escape_ere "$needle")"
    printf '%s' "$haystack" | grep -Eq "(^|[^[:alnum:]_])${escaped}([^[:alnum:]_]|$)"
    return $?
  fi

  [[ "$haystack" == *"$needle"* ]]
}

append_matches() {
  local out_name="$1"
  local haystack="$2"
  shift 2 || true

  local needle
  for needle in "$@"; do
    [[ -n "$needle" ]] || continue
    if has_keyword "$haystack" "$needle"; then
      # bash 3.2 compatibility: avoid nameref; use eval to append.
      eval "${out_name}+=(\"${needle}\")"
    fi
  done
}

dedupe_and_limit_8() {
  local name="$1"
  local -a in=()
  eval "in=(\"\${${name}[@]-}\")"

  local -a out=()
  local item
  local seen="|"

  for item in "${in[@]}"; do
    [[ -n "$item" ]] || continue
    if [[ "$seen" == *"|${item}|"* ]]; then
      continue
    fi
    out+=("$item")
    seen="${seen}${item}|"
    if [[ "${#out[@]}" -ge 8 ]]; then
      break
    fi
  done

  if [[ "${#out[@]}" -eq 0 ]]; then
    eval "${name}=()"
    return 0
  fi

  local -a quoted=()
  for item in "${out[@]:-}"; do
    local q
    printf -v q '%q' "$item"
    quoted+=("$q")
  done
  eval "${name}=(${quoted[*]})"
}

main() {
  local text=""
  local have_text_flag=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      --text)
        have_text_flag=true
        text="${2-}"
        shift 2
        ;;
      *)
        echo "error: unknown argument: $1" >&2
        usage
        exit 2
        ;;
    esac
  done

  if [[ "$have_text_flag" != true ]]; then
    # Read full stdin when piped; otherwise keep empty.
    if [[ ! -t 0 ]]; then
      text="$(cat)"
    fi
  fi

  local text_trimmed
  text_trimmed="$(printf '%s' "$text" | tr -d '\r' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"

  # Normalize for ASCII case-insensitive matching (Chinese unaffected).
  local query_lc
  query_lc="$(printf '%s' "$text_trimmed" | tr '[:upper:]' '[:lower:]')"

  # SSOT intent (must match dev-playbooks/specs/intent/spec.md keyword rules).
  local ssot_intent="feature"
  if [[ "$query_lc" =~ (debug|fix|bug|error|issue|problem|crash|fail) ]]; then
    ssot_intent="debug"
  elif [[ "$query_lc" =~ (refactor|optimize|improve|performance|clean|simplify) ]]; then
    ssot_intent="refactor"
  elif [[ "$query_lc" =~ (doc|comment|readme|explain|example|guide) ]]; then
    ssot_intent="docs"
  else
    ssot_intent="feature"
  fi

  local request_kind="change"
  local routing_status="ok"
  local exit_code=0

  local -a matched_keywords=()

  # Empty input: error state (but ssot_intent must stay SSOT-compatible: feature).
  if [[ -z "$text_trimmed" ]]; then
    request_kind="void"
    ssot_intent="feature"
    routing_status="error"
    exit_code=2
  else
    local -a void_keywords=(void 空白 态 不确定 不清楚 不知道 帮我决定 你来决定 need_more_context unclear)
    local -a bootstrap_keywords=(bootstrap brownfield 存量 初始化 基线 baseline 导入 接入 接管 接入协议 接入devbooks)
    local -a governance_keywords=(governance 流程 规范 协议 标准 policy guideline framework devbooks playbooks)
    local -a epic_keywords=(epic 史诗 roadmap 里程碑 milestone phase 阶段 p0 p1 p2 multi-stage 多阶段)
    local -a debug_keywords=(debug 定位 排查 复现 修复 fix bug error issue problem crash fail log 日志 stack 栈 trace 追踪)
    local -a ssot_signal_keywords=(ssot 需求真相 需求索引 索引账本 requirements.index requirements.index.yaml requirements.index.yml requirements.ledger requirements.ledger.yaml)
    local -a ssot_maintain_verbs=(modify update sync maintain align 维护 修改 更新 同步 刷新 对齐 变更 纠偏)
    local -a ssot_bootstrap_verbs=(bootstrap brownfield 初始化 基线 baseline 导入 接入 接管 scaffold create 新建)

    local void_match=false
    local bootstrap_match=false
    local governance_match=false
    local epic_match=false
    local debug_match=false
    local ssot_signal=false
    local ssot_maintain=false
    local ssot_bootstrap=false

    contains_any "$query_lc" "${void_keywords[@]}" && void_match=true
    contains_any "$query_lc" "${bootstrap_keywords[@]}" && bootstrap_match=true
    contains_any "$query_lc" "${governance_keywords[@]}" && governance_match=true
    contains_any "$query_lc" "${epic_keywords[@]}" && epic_match=true
    contains_any "$query_lc" "${debug_keywords[@]}" && debug_match=true

    contains_any "$query_lc" "${ssot_signal_keywords[@]}" && ssot_signal=true
    if [[ "$ssot_signal" == true ]]; then
      contains_any "$query_lc" "${ssot_maintain_verbs[@]}" && ssot_maintain=true
      contains_any "$query_lc" "${ssot_bootstrap_verbs[@]}" && ssot_bootstrap=true
    fi

    # Multi-intent detection (used only for degraded marker).
    local matches_count=0
    [[ "$void_match" == true ]] && matches_count=$((matches_count + 1))
    [[ "$bootstrap_match" == true ]] && matches_count=$((matches_count + 1))
    [[ "$governance_match" == true ]] && matches_count=$((matches_count + 1))
    [[ "$epic_match" == true ]] && matches_count=$((matches_count + 1))
    [[ "$debug_match" == true ]] && matches_count=$((matches_count + 1))
    if [[ "$matches_count" -ge 2 ]]; then
      routing_status="degraded"
    fi

    # Classification priority: void > (ssot_maintain => governance) > bootstrap > governance > epic > debug > change
    if [[ "$void_match" == true ]]; then
      request_kind="void"
      append_matches matched_keywords "$query_lc" "${void_keywords[@]}"
    elif [[ "$ssot_signal" == true && "$ssot_maintain" == true ]]; then
      request_kind="governance"
      append_matches matched_keywords "$query_lc" "${ssot_signal_keywords[@]}"
      append_matches matched_keywords "$query_lc" "${ssot_maintain_verbs[@]}"
      [[ "$routing_status" == "degraded" ]] || routing_status="ok"
    elif [[ "$bootstrap_match" == true || "$ssot_bootstrap" == true ]]; then
      request_kind="bootstrap"
      append_matches matched_keywords "$query_lc" "${bootstrap_keywords[@]}"
      [[ "$ssot_bootstrap" == true ]] && append_matches matched_keywords "$query_lc" "${ssot_signal_keywords[@]}" "${ssot_bootstrap_verbs[@]}"
    elif [[ "$governance_match" == true ]]; then
      request_kind="governance"
      append_matches matched_keywords "$query_lc" "${governance_keywords[@]}"
    elif [[ "$epic_match" == true ]]; then
      request_kind="epic"
      append_matches matched_keywords "$query_lc" "${epic_keywords[@]}"
    elif [[ "$debug_match" == true ]]; then
      request_kind="debug"
      append_matches matched_keywords "$query_lc" "${debug_keywords[@]}"
    else
      request_kind="change"
      # Keep SSOT keywords for explainability when route falls back to change.
      if [[ "$ssot_intent" == "refactor" ]]; then
        append_matches matched_keywords "$query_lc" refactor optimize improve performance clean simplify
      elif [[ "$ssot_intent" == "docs" ]]; then
        append_matches matched_keywords "$query_lc" doc comment readme explain example guide
      elif [[ "$ssot_intent" == "debug" ]]; then
        append_matches matched_keywords "$query_lc" debug fix bug error issue problem crash fail
      fi
    fi
  fi

  dedupe_and_limit_8 matched_keywords

  # shortest_loop is normalized for explainability (used by Delivery prompts/docs).
  local shortest_loop=""
  case "$request_kind" in
    void)
      shortest_loop="Delivery → Void（澄清问题/Freeze/Thaw）→ Delivery（重新路由）"
      ;;
    bootstrap)
      shortest_loop="Delivery → brownfield-bootstrap →（必要时）Proposal/Design/Spec/Plan → Archive"
      ;;
    governance)
      shortest_loop="Delivery → Proposal（Author/Challenge/Judge）→ SSOT Maintainer（当涉及 SSOT/index/ledger）→ docs-consistency（按需）→ Review → Archive"
      ;;
    epic)
      shortest_loop="Delivery → Knife（Plan）→ Proposal（Author/Challenge/Judge）→ Design → Spec → Plan → Test Owner → Coder → Review → Green Verify → Archive"
      ;;
    debug)
      shortest_loop="Delivery → Impact（可选但推荐）→ Test Owner（最小复现/Red）→ Coder（Green）→ Review → Green Verify → Archive"
      ;;
    change)
      shortest_loop="Delivery → Proposal（Author/Challenge/Judge）→ Design → Spec（按需）→ Plan → Test Owner → Coder → Review → Green Verify → Archive"
      ;;
    *)
      request_kind="change"
      routing_status="degraded"
      shortest_loop="Delivery → Proposal（Author/Challenge/Judge）→ Design → Spec（按需）→ Plan → Test Owner → Coder → Review → Green Verify → Archive"
      ;;
  esac

  local -a upgrade_conditions=()

  if [[ "$routing_status" == "error" ]]; then
    upgrade_conditions+=(need_more_context)
  else
    case "$request_kind" in
      governance)
        upgrade_conditions+=(docs_surface adoption_plan backward_compat)
        ;;
      epic)
        upgrade_conditions+=(knife_required architecture_boundary cross_module external_contract)
        ;;
      debug)
        upgrade_conditions+=(external_contract data_model_change cross_module confidence_low)
        ;;
      bootstrap)
        upgrade_conditions+=(brownfield_import truth_mapping)
        ;;
      void)
        upgrade_conditions+=(need_more_context)
        ;;
      change|*)
        upgrade_conditions+=(external_contract architecture_boundary data_model_change cross_module)
        ;;
    esac

    [[ "$routing_status" == "degraded" ]] && upgrade_conditions+=(multi_intent confidence_low)
  fi

  dedupe_and_limit_8 upgrade_conditions

  local upgrade_conditions_json
  if [[ "${#upgrade_conditions[@]}" -eq 0 ]]; then
    upgrade_conditions_json="$(json_array)"
  else
    upgrade_conditions_json="$(json_array "${upgrade_conditions[@]}")"
  fi

  local matched_keywords_json
  if [[ "${#matched_keywords[@]}" -eq 0 ]]; then
    matched_keywords_json="$(json_array)"
  else
    matched_keywords_json="$(json_array "${matched_keywords[@]}")"
  fi

  # Emit single-line JSON (no trailing newline to keep tests deterministic).
  printf '%s' "{"
  printf '"request_kind":"%s",' "$(json_escape "$request_kind")"
  printf '"ssot_intent":"%s",' "$(json_escape "$ssot_intent")"
  printf '"shortest_loop":"%s",' "$(json_escape "$shortest_loop")"
  printf '"upgrade_conditions":%s,' "$upgrade_conditions_json"
  printf '"routing_status":"%s",' "$(json_escape "$routing_status")"
  printf '"rule_version":"%s",' "$(json_escape "$RULE_VERSION")"
  printf '"matched_keywords":%s' "$matched_keywords_json"
  printf '%s' "}"

  exit "$exit_code"
}

main "$@"
