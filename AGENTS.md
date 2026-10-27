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

## First, know where you are running

Check with `uname -sm`. The setup needs an Apple Silicon Mac, which prints `Darwin arm64`.

- **On the user's Mac:** it may already be a working setup. Inspect before you change anything, and follow "Do not touch" below.
- **Anywhere else** (Linux, Windows, CI, a cloud sandbox): you cannot run LM Studio, the bootstrap, or the verification script. You can still edit documentation and run `scripts/check-repository.sh`. Never claim the stack was verified. Say exactly what you ran and what you could not run.

## Required behavior

1. Read `README.md`, `docs/LM-STUDIO-SETUP.md`, `docs/SECURITY.md`, and `docs/TROUBLESHOOTING.md` before changing configuration.
2. Never print, copy, or commit API keys, GitHub tokens, server passwords, or remote pairing URLs.
3. Inspect an existing `~/.config/opencode/opencode.json` before replacing it.
4. Preserve unrelated providers and settings when merging configuration.
5. Prefer `config/opencode.local-models.safe.json` unless the user explicitly requests unrestricted permissions.
6. Confirm exact model IDs from `lms ls` and `/v1/models` instead of guessing.
7. Use the local endpoint `http://127.0.0.1:1234/v1` unless the user intentionally configured another port.
8. Run `scripts/verify-local-stack.sh` after setup.
9. Test inference with a deterministic short response before attempting file operations.
10. Explain that remote pairing controls the host Mac and does not move local inference into the cloud.
11. Prefer `scripts/bootstrap-macos.sh` for a fresh macOS installation. It backs up an existing configuration before applying a template, and `--merge` keeps unrelated providers and settings.
12. Do not add application binaries to this repository. Retrieve OpenCode from the official installer so version and architecture remain current.
13. When LM Studio is missing, use the Homebrew cask or official download. Launch it once before expecting the bundled `lms` CLI to work.
14. Do not download 26 GB of models without warning the user about storage and possible quantization prompts.
15. Run `scripts/check-repository.sh` before committing documentation or configuration changes.

## Do not touch unless the user asks

- The user's live `~/.config/opencode/opencode.json` and its `.backup.*` copies. Use `--merge` when other providers or settings exist.
- Models that are already downloaded or loaded. Do not unload or delete them.
- Remote pairing. Do not run `opencode service set remote true` or `opencode pair --remote` on your own initiative.
- Unrestricted permissions. Use the safe template unless the user explicitly asks otherwise.
- The model IDs and permission rules in `config/`. They were verified on the reference Mac. Change them only with evidence from `lms ls` and `/v1/models`.

## Procedure

1. Read the files listed in rule 1.
2. Check the platform and tools: `uname -sm`, `command -v brew git jq curl`, and free disk space with `df -h ~`.
3. Inspect the current state without changing it: `lms ls`, `lms ps`, `lms server status`, `opencode --version`, and the existing OpenCode config. If the config holds keys, do not print them.
4. If models are missing, warn the user about the 26 GB download and possible quantization prompts, then wait for approval (rule 14).
5. Run the bootstrap with the flags from the next section. It is safe to rerun.
6. Run `./scripts/verify-local-stack.sh --inference` and resolve every FAIL using `docs/TROUBLESHOOTING.md`.
7. Tell the user to enable the provider and model once under **Manage Models** in OpenCode Desktop. This cannot be scripted.
8. Check GitHub with `gh auth status` only. Never display the token.
9. Set up remote pairing only if the user asked for it, and explain rule 10.
10. Report what you ran, what passed, what failed, and what you could not verify.

## Choosing bootstrap flags

| Situation | Command |
|---|---|
| Fresh Mac, nothing installed | `./scripts/bootstrap-macos.sh --install-lm-studio --download-models --desktop` |
| LM Studio and models already present | `./scripts/bootstrap-macos.sh --desktop` |
| An OpenCode config with other providers or settings exists | add `--merge` |
| The user explicitly asked for no approval prompts | add `--unrestricted` after reading `docs/SECURITY.md` |
| Mac with less than 24 GB of memory | skip `--download-models`, then follow "Smaller Macs" in `docs/LM-STUDIO-SETUP.md` |
| No Homebrew | install Homebrew, or install LM Studio from its download page and leave out `--install-lm-studio` and `--desktop` |

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
./scripts/verify-local-stack.sh --inference
```

## Deterministic model test

```bash
opencode run \
  --model lmstudio/qwen/qwen3.5-9b \
  --auto \
  "Reply with exactly: LOCAL_QWEN_OK"
```

Do not proceed to autonomous repository edits until this test succeeds. `./scripts/verify-local-stack.sh --inference` runs this test and a direct LM Studio request for you.

## Definition of done

All of these are true:

- `./scripts/verify-local-stack.sh --inference` ends with `All required checks passed.`
- `opencode models | grep lmstudio` lists the local models.
- `opencode debug config` shows the intended permission policy, which is the safe one unless the user asked for unrestricted.
- No credential, token, or pairing URL appears in any output, file, or commit.
- `./scripts/check-repository.sh` passes, if repository files changed.
- The user has been told what remains manual: the Manage Models switch in OpenCode Desktop, `gh auth login`, and optional remote pairing.

## When something fails

Start at `docs/TROUBLESHOOTING.md`. It has an entry for each of these:

- `lms` not found, or the bootstrap cannot find LM Studio
- Port 1234 in use, or OpenCode cannot reach the model
- OpenCode says the model is not found
- The model is configured but missing from OpenCode Desktop
- The model answers but does not use tools correctly
- OpenCode still asks for permission
- Remote pairing stalls or the link has expired
- Git pushes with the wrong saved GitHub account

## Maintaining this repository

- Run `scripts/check-repository.sh` before every commit. It checks shell syntax, JSON, SVG well-formedness, whitespace, credential-like strings, em dashes, and internal links.
- Write plain ASCII punctuation. No em dashes and no emoji.
- Keep scripts compatible with the bash 3.2 that macOS ships: no associative arrays, `mapfile`, or `${var,,}`.
- Illustrations live in `docs/images/` as SVG text. Keep them self-contained, with no scripts, no external files, and no web fonts. Applications and other binaries stay out of the repository.
- Model IDs appear in both files under `config/`, `scripts/bootstrap-macos.sh`, `scripts/verify-local-stack.sh`, `README.md`, `docs/LM-STUDIO-SETUP.md`, `docs/TROUBLESHOOTING.md`, `docs/images/setup-roadmap.svg`, and this file. Change them together.
- Bootstrap flags are described in the script's usage text, `README.md`, and the table above. Keep the three in step.
- Update the "Last verified" line in `README.md` only after a real run on real hardware.
- `docs/SESSION-NOTES.md` records which commands were confirmed against official documentation and which were not. Read it before "correcting" a command that looks undocumented.
