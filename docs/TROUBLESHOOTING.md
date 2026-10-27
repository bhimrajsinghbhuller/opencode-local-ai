# Troubleshooting

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
