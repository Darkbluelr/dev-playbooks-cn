#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

name="$(basename "$0")"
legacy_id="${name#migrate-from-}"
legacy_id="${legacy_id%.sh}"

exec "${script_dir}/migrate-from-legacy.sh" --legacy-id "$legacy_id" "$@"

