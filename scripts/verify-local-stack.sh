#!/usr/bin/env bash

set -u

failures=0
opencode_cmd=""
run_inference="false"

usage() {
  printf '%s\n' "Usage: ./scripts/verify-local-stack.sh [--inference]"
  printf '%s\n' ""
  printf '%s\n' "  --inference  Also send a live test prompt to LM Studio and through OpenCode"
}

for argument in "$@"; do
  case "$argument" in
    --inference)
      run_inference="true"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$argument" >&2
      usage >&2
      exit 2
      ;;
  esac
done

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

if ! has_command lms && test -x "$HOME/.lmstudio/bin/lms"; then
  PATH="$HOME/.lmstudio/bin:$PATH"
fi

printf 'OpenCode + Local AI verification\n\n'

if test "$(uname -s)" = "Darwin" && test "$(uname -m)" = "arm64"; then
  pass "Platform is Apple Silicon macOS"
else
  warn "This guide was tested on Apple Silicon macOS"
fi

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

if has_command lms && lms ls 2>/dev/null | grep -Fq 'qwen/qwen3.5-9b'; then
  pass "Qwen 3.5 9B is downloaded"
else
  warn "Qwen 3.5 9B is not downloaded under the expected model ID"
fi

if has_command lms && lms ps 2>/dev/null | grep -Eq '(^|[[:space:]])qwen/qwen3\.5-9b(:[0-9]+)?([[:space:]]|$)'; then
  pass "Qwen 3.5 9B is loaded"
else
  warn "Qwen 3.5 9B is not currently loaded"
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

if test "$run_inference" = "true"; then
  printf '\nLive inference tests (these use the loaded model and can take a minute)\n'

  direct_response="$(curl -sS --max-time 180 http://127.0.0.1:1234/v1/chat/completions \
    -H 'Content-Type: application/json' \
    -d '{"model":"qwen/qwen3.5-9b","messages":[{"role":"user","content":"Reply with exactly LM_STUDIO_OK"}],"temperature":0}' 2>/dev/null)"
  if printf '%s' "$direct_response" | grep -Fq 'LM_STUDIO_OK'; then
    pass "LM Studio answered the direct test prompt"
  else
    fail "LM Studio did not return LM_STUDIO_OK. Is qwen/qwen3.5-9b loaded?"
  fi

  if test -n "$opencode_cmd"; then
    opencode_response="$(perl -e 'alarm shift; exec @ARGV' 240 "$opencode_cmd" run \
      --model lmstudio/qwen/qwen3.5-9b --auto "Reply with exactly: LOCAL_QWEN_OK" 2>&1)"
    if printf '%s\n' "$opencode_response" | grep -F 'LOCAL_QWEN_OK' | grep -Fvq 'Reply with'; then
      pass "OpenCode returned LOCAL_QWEN_OK through the local model"
    else
      fail "OpenCode did not return LOCAL_QWEN_OK"
    fi
  fi
fi

printf '\n'
if test "$failures" -eq 0; then
  printf 'All required checks passed.\n'
  exit 0
fi

printf '%s required check(s) failed. See docs/TROUBLESHOOTING.md.\n' "$failures"
exit 1
