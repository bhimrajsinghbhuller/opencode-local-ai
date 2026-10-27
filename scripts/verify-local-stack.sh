#!/usr/bin/env bash

set -u

failures=0
opencode_cmd=""

pass() {
  printf 'PASS  %s\n' "$1"
}

warn() {
  printf 'WARN  %s\n' "$1"
}

fail() {
  printf 'FAIL  %s\n' "$1"
  failures=$((failures + 1))
}

has_command() {
  command -v "$1" >/dev/null 2>&1
}

printf 'OpenCode + Local AI verification\n\n'

if has_command lms; then
  pass "LM Studio CLI is installed"
else
  fail "LM Studio CLI was not found"
fi

if has_command curl; then
  pass "curl is installed"
else
  fail "curl was not found"
fi

if has_command opencode; then
  opencode_cmd="$(command -v opencode)"
elif test -x "$HOME/.opencode/bin/opencode"; then
  opencode_cmd="$HOME/.opencode/bin/opencode"
fi

if test -n "$opencode_cmd"; then
  pass "OpenCode is installed: $("$opencode_cmd" --version 2>/dev/null)"
else
  fail "OpenCode was not found in PATH or ~/.opencode/bin"
fi

if has_command git; then
  pass "Git is installed: $(git --version 2>/dev/null)"
else
  fail "Git was not found"
fi

if has_command lms && lms server status >/dev/null 2>&1; then
  pass "LM Studio server is running"
else
  fail "LM Studio server is not reporting healthy status"
fi

models_json="$(mktemp -t opencode-local-models.XXXXXX)"
trap 'rm -f "$models_json"' EXIT

if curl -fsS http://127.0.0.1:1234/v1/models >"$models_json" 2>/dev/null; then
  pass "LM Studio OpenAI-compatible endpoint is reachable"
else
  fail "Cannot reach http://127.0.0.1:1234/v1/models"
fi

if has_command jq && test -s "$models_json"; then
  printf '\nModels reported by LM Studio:\n'
  jq -r '.data[]?.id // empty' "$models_json" | sed 's/^/  - /'
elif test -s "$models_json"; then
  warn "Install jq for a readable model list"
fi

if test -n "$opencode_cmd"; then
  if "$opencode_cmd" debug config >/dev/null 2>&1; then
    pass "OpenCode configuration is valid"
  else
    fail "OpenCode configuration could not be loaded"
  fi

  if "$opencode_cmd" models 2>/dev/null | grep -q '^lmstudio/'; then
    pass "OpenCode can see at least one LM Studio model"
  else
    fail "OpenCode does not list an lmstudio model"
  fi

  if "$opencode_cmd" service status >/dev/null 2>&1; then
    pass "OpenCode background service is running"
  else
    warn "OpenCode background service is not running"
  fi
fi

if has_command gh; then
  if gh auth status >/dev/null 2>&1; then
    pass "GitHub CLI is authenticated"
  else
    warn "GitHub CLI is installed but not authenticated"
  fi
else
  warn "GitHub CLI is not installed"
fi

printf '\n'
if test "$failures" -eq 0; then
  printf 'All required checks passed.\n'
  exit 0
fi

printf '%s required check(s) failed. See docs/TROUBLESHOOTING.md.\n' "$failures"
exit 1
