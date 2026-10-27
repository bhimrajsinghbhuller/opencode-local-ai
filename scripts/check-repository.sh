#!/usr/bin/env bash

set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repository_directory="$(cd "$script_directory/.." && pwd)"
cd "$repository_directory"

failures=0

pass() {
  printf 'PASS  %s\n' "$1"
}

fail() {
  printf 'FAIL  %s\n' "$1"
  failures=$((failures + 1))
}

for script_path in scripts/*.sh; do
  if bash -n "$script_path"; then
    pass "Shell syntax: $script_path"
  else
    fail "Shell syntax: $script_path"
  fi
done

if command -v jq >/dev/null 2>&1; then
  for config_path in config/*.json; do
    if jq empty "$config_path"; then
      pass "JSON syntax: $config_path"
    else
      fail "JSON syntax: $config_path"
    fi
  done
else
  fail "jq is required to validate JSON"
fi

if git diff --check; then
  pass "No whitespace errors"
else
  fail "Whitespace errors found"
fi

if git grep -nE 'gho_[A-Za-z0-9]{10}|oc_sk_[A-Za-z0-9]{10}|https://[^ ]+/auth/connect/[A-Za-z0-9]{10}|BEGIN [A-Z ]+PRIVATE KEY' -- . ':!scripts/check-repository.sh'; then
  fail "A credential-like value may be tracked"
else
  pass "No credential-like values detected"
fi

em_dash="$(printf '\342\200\224')"
if git grep -n "$em_dash" -- '*.md' '*.sh' '*.yml' '*.yaml'; then
  fail "Em dash found in repository text"
else
  pass "No em dashes in repository text"
fi

relative_links="$(mktemp -t opencode-local-links.XXXXXX)"
trap 'rm -f "$relative_links"' EXIT

perl -ne 'while (/\]\((?!https?:\/\/|mailto:|#)([^)#]+)(?:#[^)]*)?\)/g) { print "$ARGV\t$1\n" }' $(git ls-files '*.md') >"$relative_links"

while IFS=$'\t' read -r source_path target_path; do
  test -n "$source_path" || continue
  resolved_path="$(dirname "$source_path")/$target_path"
  if test -e "$resolved_path"; then
    pass "Internal link: $source_path -> $target_path"
  else
    fail "Broken internal link: $source_path -> $target_path"
  fi
done <"$relative_links"

printf '\n'
if test "$failures" -eq 0; then
  printf 'Repository validation passed.\n'
  exit 0
fi

printf '%s repository validation check(s) failed.\n' "$failures"
exit 1
