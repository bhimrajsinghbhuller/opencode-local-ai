#!/usr/bin/env bash

set -euo pipefail

policy="safe"
install_desktop="false"
install_lm_studio="false"
download_models="false"
merge_config="false"

usage() {
  printf '%s\n' "Usage: ./scripts/bootstrap-macos.sh [--safe|--unrestricted] [--merge] [--desktop] [--install-lm-studio] [--download-models]"
  printf '%s\n' ""
  printf '%s\n' "  --safe               Install the recommended permission policy (default)"
  printf '%s\n' "  --unrestricted       Install the complete permission-bypass policy"
  printf '%s\n' "  --merge              Merge the template into an existing OpenCode config instead of replacing it (needs jq)"
  printf '%s\n' "  --desktop            Install OpenCode Desktop with Homebrew"
  printf '%s\n' "  --install-lm-studio  Install and launch LM Studio with Homebrew"
  printf '%s\n' "  --download-models    Download Qwen 3.5 9B, Gemma 3 12B, GPT-OSS 20B, and the Nomic embedding model"
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
    --install-lm-studio)
      install_lm_studio="true"
      ;;
    --download-models)
      download_models="true"
      ;;
    --merge)
      merge_config="true"
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

if test "$(uname -m)" != "arm64"; then
  printf '%s\n' "This guide and bootstrap target Apple Silicon Macs." >&2
  exit 1
fi

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repository_directory="$(cd "$script_directory/.." && pwd)"

if ! command -v curl >/dev/null 2>&1; then
  printf '%s\n' "curl is required." >&2
  exit 1
fi

if test "$merge_config" = "true" && ! command -v jq >/dev/null 2>&1; then
  printf '%s\n' "jq is required for --merge. Install it with: brew install jq" >&2
  exit 1
fi

use_lms_install_directory() {
  if ! command -v lms >/dev/null 2>&1 && test -x "$HOME/.lmstudio/bin/lms"; then
    PATH="$HOME/.lmstudio/bin:$PATH"
  fi
}

use_lms_install_directory

if test "$install_lm_studio" = "true"; then
  if ! command -v brew >/dev/null 2>&1; then
    printf '%s\n' "Homebrew is required for --install-lm-studio." >&2
    exit 1
  fi
  printf '%s\n' "Installing LM Studio..."
  brew install --cask lm-studio
  open -a "LM Studio"
  printf '%s\n' "LM Studio has been opened. Complete its first-launch screen if one appears."
  use_lms_install_directory
  if ! command -v lms >/dev/null 2>&1 && test -t 0; then
    printf '%s' "After completing first launch, press Return to continue: "
    read -r _
    hash -r
    use_lms_install_directory
  fi
fi

if ! command -v lms >/dev/null 2>&1; then
  printf '%s\n' "LM Studio CLI was not found. Launch LM Studio once and rerun this script." >&2
  printf '%s\n' "If it is still missing, run: ~/.lmstudio/bin/lms bootstrap  (then open a new Terminal)" >&2
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
if ! lms server start --port 1234 --bind 127.0.0.1 >/dev/null; then
  printf '%s\n' "lms server start reported an error. Checking whether the server is already running..."
fi

server_ready="false"
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if curl -fsS http://127.0.0.1:1234/v1/models >/dev/null 2>&1; then
    server_ready="true"
    break
  fi
  sleep 1
done

if test "$server_ready" != "true"; then
  printf '%s\n' "The LM Studio API is not reachable at http://127.0.0.1:1234. Start the server in LM Studio under Developer, then rerun this script." >&2
  exit 1
fi

download_model_if_missing() {
  local download_id="$1"
  local model_key="${2:-$1}"
  local downloaded
  downloaded="$(lms ls 2>/dev/null || true)"
  if grep -Fq "$model_key" <<<"$downloaded"; then
    printf 'Already downloaded: %s\n' "$model_key"
  else
    printf 'Downloading %s...\n' "$download_id"
    lms get "$download_id"
  fi
}

if test "$download_models" = "true"; then
  available_gb="$(df -Pk "$HOME" 2>/dev/null | awk 'NR == 2 { printf "%d", $4 / 1024 / 1024 }' || true)"
  printf 'Model downloads may require more than 26 GB of disk space. Free disk space: %s GB.\n' "${available_gb:-unknown}"
  if test -n "$available_gb" && test "$available_gb" -lt 35; then
    printf '%s\n' "Free space is low for the full model set. Free some space or press Control-C now."
  fi
  download_model_if_missing "qwen/qwen3.5-9b"
  download_model_if_missing "google/gemma-3-12b"
  download_model_if_missing "openai/gpt-oss-20b"
  download_model_if_missing "nomic-ai/nomic-embed-text-v1.5" "text-embedding-nomic-embed-text-v1.5" ||
    printf '%s\n' "The optional embedding model was not downloaded. Continuing."
fi

downloaded_models="$(lms ls 2>/dev/null || true)"
loaded_models="$(lms ps 2>/dev/null || true)"

if grep -Fq 'qwen/qwen3.5-9b' <<<"$downloaded_models"; then
  if grep -Eq '(^|[[:space:]])qwen/qwen3\.5-9b(:[0-9]+)?([[:space:]]|$)' <<<"$loaded_models"; then
    printf '%s\n' "Qwen 3.5 9B is already loaded."
  else
    printf '%s\n' "Loading qwen/qwen3.5-9b..."
    lms load qwen/qwen3.5-9b --gpu max --context-length 32768 >/dev/null
  fi
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
  if test "$merge_config" = "true"; then
    printf '%s\n' "The selected template will be merged into the active config. Other providers and settings are kept."
  else
    printf '%s\n' "The selected template will replace the active config. Restore the backup to recover unrelated settings, or rerun with --merge to keep them."
  fi
fi

if test "$policy" = "unrestricted"; then
  template_path="$repository_directory/config/opencode.local-models.unrestricted.json"
else
  template_path="$repository_directory/config/opencode.local-models.safe.json"
fi

if test "$merge_config" = "true" && test -f "$config_path"; then
  merged_path="$(mktemp -t opencode-merged-config.XXXXXX)"
  if ! jq -s '.[0] * .[1]' "$config_path" "$template_path" >"$merged_path"; then
    rm -f "$merged_path"
    printf '%s\n' "Could not merge: the existing config is not plain JSON. It was left unchanged." >&2
    exit 1
  fi
  cat "$merged_path" >"$config_path"
  rm -f "$merged_path"
  printf 'Merged the %s OpenCode policy into %s\n' "$policy" "$config_path"
else
  cp "$template_path" "$config_path"
  printf 'Installed the %s OpenCode policy at %s\n' "$policy" "$config_path"
fi

"$opencode_command" service restart >/dev/null 2>&1 || "$opencode_command" service start >/dev/null

printf '%s\n' ""
PATH="$(dirname "$opencode_command"):$PATH" "$repository_directory/scripts/verify-local-stack.sh"

printf '%s\n' ""
printf '%s\n' "Setup complete. Prove the model answers with: ./scripts/verify-local-stack.sh --inference"
printf '%s\n' "Then open a project with: opencode /path/to/project"
