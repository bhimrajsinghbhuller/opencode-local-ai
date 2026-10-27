#!/usr/bin/env bash

set -euo pipefail

policy="safe"
install_desktop="false"

usage() {
  printf '%s\n' "Usage: ./scripts/bootstrap-macos.sh [--safe|--unrestricted] [--desktop]"
  printf '%s\n' ""
  printf '%s\n' "  --safe          Install the recommended permission policy (default)"
  printf '%s\n' "  --unrestricted  Install the complete permission-bypass policy"
  printf '%s\n' "  --desktop       Install OpenCode Desktop with Homebrew"
}

for argument in "$@"; do
  case "$argument" in
    --safe)
      policy="safe"
      ;;
    --unrestricted)
      policy="unrestricted"
      ;;
    --desktop)
      install_desktop="true"
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

if test "$(uname -s)" != "Darwin"; then
  printf '%s\n' "This bootstrap script is intended for macOS." >&2
  exit 1
fi

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repository_directory="$(cd "$script_directory/.." && pwd)"

if ! command -v curl >/dev/null 2>&1; then
  printf '%s\n' "curl is required." >&2
  exit 1
fi

if ! command -v lms >/dev/null 2>&1; then
  printf '%s\n' "LM Studio CLI was not found. Install LM Studio or run its CLI installer first." >&2
  exit 1
fi

opencode_command=""
if command -v opencode >/dev/null 2>&1; then
  opencode_command="$(command -v opencode)"
elif test -x "$HOME/.opencode/bin/opencode"; then
  opencode_command="$HOME/.opencode/bin/opencode"
else
  printf '%s\n' "Installing OpenCode with the official installer..."
  curl -fsSL https://opencode.ai/v2/install | bash
  if test -x "$HOME/.opencode/bin/opencode"; then
    opencode_command="$HOME/.opencode/bin/opencode"
  elif command -v opencode >/dev/null 2>&1; then
    opencode_command="$(command -v opencode)"
  else
    printf '%s\n' "OpenCode installation completed, but its executable could not be found." >&2
    exit 1
  fi
fi

if test "$install_desktop" = "true"; then
  if ! command -v brew >/dev/null 2>&1; then
    printf '%s\n' "Homebrew is required for the --desktop option." >&2
    exit 1
  fi
  brew install --cask opencode-desktop
fi

printf '%s\n' "Starting the LM Studio API server..."
lms server start >/dev/null

if lms ls 2>/dev/null | grep -q 'qwen/qwen3.5-9b'; then
  printf '%s\n' "Loading qwen/qwen3.5-9b..."
  lms load qwen/qwen3.5-9b >/dev/null
else
  printf '%s\n' "Qwen 3.5 9B is not downloaded. The provider will still be configured."
fi

config_directory="$HOME/.config/opencode"
config_path="$config_directory/opencode.json"
mkdir -p "$config_directory"

if test -f "$config_path"; then
  backup_path="$config_path.backup.$(date +%Y%m%d-%H%M%S)"
  cp "$config_path" "$backup_path"
  printf 'Existing OpenCode config backed up to %s\n' "$backup_path"
fi

if test "$policy" = "unrestricted"; then
  template_path="$repository_directory/config/opencode.local-models.unrestricted.json"
else
  template_path="$repository_directory/config/opencode.local-models.safe.json"
fi

cp "$template_path" "$config_path"
printf 'Installed the %s OpenCode policy at %s\n' "$policy" "$config_path"

"$opencode_command" service restart >/dev/null

printf '%s\n' ""
PATH="$(dirname "$opencode_command"):$PATH" "$repository_directory/scripts/verify-local-stack.sh"

printf '%s\n' ""
printf '%s\n' "Setup complete. Open a project with: opencode /path/to/project"
