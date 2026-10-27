# Sanitized Setup Record

This document records the decisions and discoveries from the reference installation without including credentials, pairing links, private repository data, or personal filesystem paths.

## Goal

Turn an already installed LM Studio model into a local coding agent with capabilities similar to hosted coding agents:

- Read and edit files
- Organize folders
- Execute shell commands
- Run Python and tests
- Debug failures over multiple steps
- Work with Git and GitHub
- Operate from OpenCode Desktop
- Optionally operate remotely from an iPhone
- Avoid paid model API tokens when using the local provider

## Final component choices

- Model runner: LM Studio
- Default model: `qwen/qwen3.5-9b`
- Agent harness: OpenCode 2.2.0
- Local endpoint: `http://127.0.0.1:1234/v1`
- Provider runtime: `@opencode/ai/providers/openai-compatible`
- Desktop client: OpenCode Desktop
- Repository integration: Git plus GitHub CLI
- Remote client: OpenCode encrypted remote pairing

## Installation sequence

1. Confirmed LM Studio was already installed.
2. Inspected the local models.
3. Started LM Studio's API server on port 1234.
4. Installed OpenCode CLI.
5. Created the global OpenCode provider configuration.
6. Verified that OpenCode listed `lmstudio/qwen/qwen3.5-9b`.
7. Installed OpenCode Desktop.
8. Enabled the LM Studio provider and Qwen model in Manage Models.
9. Sent a deterministic test prompt and received the exact expected response.
10. Added autonomous permissions with guardrails.
11. Switched to complete permission bypass at the user's explicit request.
12. Confirmed GitHub CLI authentication and repository access.
13. Enabled encrypted remote access.
14. Resolved first-time tunnel setup and generated an iPhone pairing link.

## Important discoveries

### LM Studio is the model server, not the agent

LM Studio makes the local model available through an API. OpenCode supplies the agent loop and tools. Both are needed for this design.

### A local API is still an API

No paid provider key is required, but OpenCode still communicates through an API. The difference is that the API address is `127.0.0.1`, which means the same computer.

### Desktop model visibility can be disabled

The provider can be correctly configured while the model remains hidden in OpenCode Desktop. Manage Models must enable both the provider and model.

### Free cloud models are not guaranteed unlimited

The `Free` label means the current token price is zero. It does not promise infinite requests or permanent availability. Local inference avoids cloud rate limits but remains limited by hardware.

### Permission bypass is powerful and separate from model quality

The single wildcard allow rule removes OpenCode's permission prompts. It does not improve reasoning and does not create a security sandbox. Full bypass should be a deliberate trust decision.

### GitHub access comes from developer tools

OpenCode uses `git` and authenticated `gh` commands. The model does not need a special GitHub API connection when those tools are already available.

### Remote pairing is remote control, not cloud inference

The iPhone controls the Mac. Qwen continues to run on the Mac. The Mac, LM Studio, and OpenCode must remain available.

## Problems and fixes

| Problem | Cause or observation | Fix |
|---|---|---|
| Local Qwen absent from Desktop picker | Provider and model switches were disabled | Enabled them in Manage Models |
| Confusion about needing an API | Local model still uses a local API protocol | Configured `http://127.0.0.1:1234/v1` without a paid key |
| Shell commands originally prompted | Shell default was `ask` | Changed ordinary shell actions to `allow` |
| User requested no approvals | Guardrails still asked or denied certain actions | Replaced the rules with one global wildcard `allow` |
| First remote setup appeared stuck | Initial tunnel activation did not finish inside the pairing command | Ran `service set remote true`, started the service, then paired again |
| Pairing URL expired | Link was older than five minutes or had been opened | Generated a new one-time link and opened it directly on the iPhone |
| A later Git push used the wrong account | Git's HTTPS credential helper selected a different saved GitHub account | Switched the GitHub CLI account and reran `gh auth setup-git` |

## Result

The local Qwen model can now be selected in OpenCode and used as a tool-capable coding agent. It can operate files, run commands, use GitHub credentials available to the Mac, and be controlled remotely. Inference remains local whenever the LM Studio model is selected.

## Repository expansion

The reusable repository was expanded beyond the original machine's starting point. It now includes installation of LM Studio itself, downloading all three language models, selecting formats and quantizations, estimating memory, loading and unloading models, starting the server securely on localhost, direct API tests, and an automated start-from-zero macOS bootstrap path.

## Audit record, October 27, 2026

A documentation and script audit was done from a Linux sandbox. The macOS stack could not be run there, so macOS behavior was exercised through stand-in `lms`, `opencode`, `brew`, and `curl` commands, never against the real tools.

Confirmed against the official documentation:

- OpenCode install command, Homebrew name, `providers` and `package` config keys, `settings.baseURL`, and the `permissions` rule schema with last-match-wins ordering
- `lms server start --bind` and its `127.0.0.1` default, `lms load --gpu max`, `--context-length`, `--ttl`, `--estimate-only`, and `lms get` with `--mlx`, `--gguf`, and `--always-show-download-options`
- Homebrew cask names `lm-studio` and `opencode-desktop`, both Apple Silicon compatible
- Pairing links work once and expire in five minutes, and a paired session lasts 30 days
- The embedding model downloads as `nomic-ai/nomic-embed-text-v1.5` and is listed as `text-embedding-nomic-embed-text-v1.5`

Not found on the documentation pages that were checked, although they worked on the reference Mac: `opencode service restart`, `opencode service get remote`, `opencode run --model` and `--auto`, `opencode models`, and `opencode debug config`. They were left as they were.

Changes made because of the audit:

- The scripts now find `lms` in `~/.lmstudio/bin` when it is not on `PATH`.
- The loaded-model check accepts both the table and the block layouts of `lms ps`, which the official page describes as blocks. The old check required a table and would have loaded a second copy of an already loaded model if the layout differed.
- Rerunning the bootstrap no longer depends on `lms server start` succeeding when the server is already up. It checks that the API answers instead.
- `opencode service restart` falls back to `opencode service start` on a first run.
- Model lookups no longer pipe into `grep -q` under `pipefail`, which can report a false miss when the writer outlives the reader.
- The embedding model is now part of `--download-models` and is treated as optional.
- `--merge` keeps other providers and settings, and `verify-local-stack.sh --inference` proves the model answers.
- The SVG illustrations in `docs/images/` were added and are checked by `check-repository.sh`.

The configuration templates were deliberately not changed.
