# Replication Instructions for Coding Agents

## Objective

Reproduce and verify an OpenCode setup that uses local language models served by LM Studio on macOS.

## Expected result

- LM Studio serves a loaded model on `http://127.0.0.1:1234`.
- OpenCode lists the model under the `lmstudio` provider.
- A deterministic inference test succeeds.
- The OpenCode desktop picker exposes the local model.
- File and shell tools follow the selected permission policy.
- GitHub CLI access is verified without printing credentials.
- Remote pairing is enabled only when the user explicitly requests it.

## Required behavior

1. Read `README.md`, `docs/SECURITY.md`, and `docs/TROUBLESHOOTING.md` before changing configuration.
2. Never print, copy, or commit API keys, GitHub tokens, server passwords, or remote pairing URLs.
3. Inspect an existing `~/.config/opencode/opencode.json` before replacing it.
4. Preserve unrelated providers and settings when merging configuration.
5. Prefer `config/opencode.local-models.safe.json` unless the user explicitly requests unrestricted permissions.
6. Confirm exact model IDs from `lms ls` and `/v1/models` instead of guessing.
7. Use the local endpoint `http://127.0.0.1:1234/v1` unless the user intentionally configured another port.
8. Run `scripts/verify-local-stack.sh` after setup.
9. Test inference with a deterministic short response before attempting file operations.
10. Explain that remote pairing controls the host Mac and does not move local inference into the cloud.
11. Prefer `scripts/bootstrap-macos.sh` for a fresh macOS installation. It backs up an existing configuration before applying a template.
12. Do not add application binaries to this repository. Retrieve OpenCode from the official installer so version and architecture remain current.

## Verification commands

```bash
lms server status
lms ls
curl -sS http://127.0.0.1:1234/v1/models | jq
opencode --version
opencode debug config
opencode models | grep lmstudio
opencode service status
gh auth status
./scripts/verify-local-stack.sh
```

## Deterministic model test

```bash
opencode run \
  --model lmstudio/qwen/qwen3.5-9b \
  --auto \
  "Reply with exactly: LOCAL_QWEN_OK"
```

Do not proceed to autonomous repository edits until this test succeeds.
