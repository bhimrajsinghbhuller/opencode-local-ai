# Troubleshooting

## The bootstrap cannot find OpenCode after installation

The official installer commonly places the executable at `~/.opencode/bin/opencode`. The bootstrap and verification scripts check that path even when a non-interactive shell has not added it to `PATH`.

For interactive terminal use, add the directory to zsh:

```bash
printf '%s\n' 'export PATH="$HOME/.opencode/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
opencode --version
```

## `lms: command not found`

LM Studio places its CLI at `~/.lmstudio/bin/lms` the first time the app has been launched. The repository scripts look there automatically. For your own shell, run LM Studio once, then:

```bash
~/.lmstudio/bin/lms bootstrap
```

Open a new Terminal window and check `lms --help`.

## Port 1234 is already in use

Another program, or a second copy of the LM Studio server, may be holding the port. See what is listening:

```bash
lsof -nP -iTCP:1234 -sTCP:LISTEN
```

Stop that program, or deliberately start LM Studio on another port and change `baseURL` in the OpenCode config to match.

## OpenCode says the model is not found

The model ID in the OpenCode config must match what LM Studio serves, character for character. Compare the two lists:

```bash
curl -sS http://127.0.0.1:1234/v1/models | jq -r '.data[].id'
lms ls
opencode models | grep lmstudio
```

If a download produced a different key, change the key under `models` in `~/.config/opencode/opencode.json` and the `model` value to match, then run `opencode service restart`.

## The bootstrap says the existing config is not plain JSON

`--merge` uses `jq`, which cannot read comments. The config was left untouched. Remove the comments and rerun, or rerun without `--merge` to replace the file. Your original is always saved as `opencode.json.backup.<timestamp>`.

## OpenCode cannot reach the model

Symptoms include connection refused, provider initialization failure, or no response.

Check LM Studio:

```bash
lms server status
lms ls
curl -sS http://127.0.0.1:1234/v1/models | jq
```

If needed:

```bash
lms server start
lms load qwen/qwen3.5-9b
```

Confirm that `baseURL` includes `/v1`:

```json
"baseURL": "http://127.0.0.1:1234/v1"
```

## The model is configured but absent from Desktop

Open the model picker, choose **Manage Models**, enable **LM Studio (local)**, and enable the specific model. Configuration and picker visibility are separate states.

Also verify:

```bash
opencode models | grep lmstudio
opencode debug config
```

## A local model answers but does not use tools correctly

Possible causes:

- The model or quantization has weak tool-call support.
- Context is too small.
- The task is too broad for the model.
- The prompt asks for an explanation instead of an implemented result.
- LM Studio's model settings do not match the expected chat template.

Try a narrow deterministic task first:

```text
Create hello.txt in the current project containing exactly hello, then read the
file back and report its absolute path.
```

Use explicit completion criteria and ask the agent to run verification commands.

## OpenCode still asks for permission

Inspect the effective configuration:

```bash
opencode debug config
```

Permission rules are ordered, and the last matching rule wins. Project or managed policies can also affect the result. Restart the shared service after changing global configuration:

```bash
opencode service restart
```

For complete local bypass, the effective permission list should contain:

```json
[
  { "action": "*", "resource": "*", "effect": "allow" }
]
```

## Remote pairing stalls during first-time setup

Observed symptom:

```text
Setting up remote access; this can take a minute...
```

If it remains there for several minutes, interrupt only the pairing command with `Control-C`, then run:

```bash
opencode service set remote true
opencode service start
opencode service get remote
opencode pair --remote --yes
```

The expected `service get remote` result is `true`. The final command should print a one-time URL and QR code.

## The pairing link says expired

Pairing links work once and expire after five minutes. Generate a fresh link:

```bash
opencode pair --remote --yes
```

Open it directly on the destination device. Do not open it first on the host Mac.

## Remote access works but the model does not

The remote web interface and the LM Studio model server are separate services. Check both:

```bash
opencode service status
lms server status
curl -sS http://127.0.0.1:1234/v1/models | jq
```

The Mac must remain awake. If the Mac sleeps, the remote interface or inference may stop responding.

## GitHub commands fail

```bash
gh auth status
git remote -v
git status
```

Confirm the active GitHub account has access to the repository. A successful OpenCode model connection does not automatically authenticate GitHub.

### Git pushes with the wrong saved GitHub account

On a Mac with multiple GitHub CLI accounts, `gh auth status` can show the intended account as active while Git's HTTPS credential helper still supplies another saved account. A push can then fail with a message such as:

```text
Permission to OWNER/REPOSITORY.git denied to OTHER-ACCOUNT.
```

Switch the active GitHub CLI account and explicitly refresh Git's credential integration:

```bash
gh auth switch --hostname github.com --user INTENDED-ACCOUNT
gh auth setup-git --hostname github.com
git push origin main
```

This changes which stored account Git uses without printing or copying the token.

## Free cloud models return rate-limit errors

Models labeled `Free` can still have usage and capacity limits. Switch back to the local LM Studio model for unmetered local inference, or wait for the cloud capacity limit to reset.

## Logs and service health

```bash
opencode service status
opencode api get /api/info
opencode debug paths log
```

Restart a stuck service:

```bash
opencode service restart
```
