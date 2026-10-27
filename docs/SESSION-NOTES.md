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
