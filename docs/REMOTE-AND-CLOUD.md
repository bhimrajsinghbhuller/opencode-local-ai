# Remote Access and Cloud Operation

## Remote control of the local Mac

This mode preserves local inference and avoids model API charges.

```bash
opencode service set remote true
opencode service start
opencode pair --remote
```

OpenCode prints a one-time URL and QR code. The URL expires after five minutes and works once. Open it on the trusted iPhone or remote computer, not on the host Mac. A paired browser session normally remains signed in until its session expires or the server password changes.

Requirements:

- The Mac remains powered on and awake.
- The Mac remains connected to the internet.
- The OpenCode background service remains running.
- LM Studio remains available.
- The selected model remains loaded or can be loaded when requested.

The remote device is a controller. The Mac is still the computer performing inference and executing tools.

## Local network access

For devices on the same trusted network, OpenCode can also be bound to a network interface. Remote pairing is usually simpler because it supplies authentication and an encrypted route. Do not expose an unauthenticated agent server to a public or untrusted network.

## What OpenCode Console does

OpenCode Console can provide cloud-hosted models, workspace policies, and usage controls. Choosing a cloud model moves inference to the model provider, but the OpenCode client still executes local tools unless OpenCode itself is running on a remote machine.

Free cloud models may be rate limited or capacity limited. A model labeled `Free` should not be interpreted as guaranteed unlimited service.

## A true cloud agent

To continue working while the Mac is off, run the complete stack on another always-on computer:

1. Provision a cloud virtual machine.
2. Install OpenCode on that machine.
3. Clone the GitHub repository there.
4. Authenticate GitHub using a narrowly scoped credential.
5. Use a cloud model API, or provision a GPU machine and run a local-model server there.
6. Protect the OpenCode server with strong authentication and restrictive network rules.
7. Pair a client to that server.

A CPU-only free virtual machine is generally not a satisfying host for a 9B coding model. Cloud GPU instances and hosted inference normally have a monetary cost.

## Local, remote, and cloud comparison

| Design | Mac must stay on | Inference location | Repository location | Common cost |
|---|---:|---|---|---:|
| Local OpenCode + local Qwen | Yes | Mac | Mac | No token bill |
| Remote browser + local Qwen | Yes | Mac | Mac | No token bill |
| Local OpenCode + cloud model | Yes for local tools | Provider | Mac | API or subscription |
| Cloud OpenCode + cloud model | No | Provider | Cloud VM | VM plus inference |
| Cloud OpenCode + self-hosted Qwen | No | Cloud GPU | Cloud VM | GPU plus storage |

## Disable remote access

```bash
opencode service set remote false
opencode service start
```

Change the server password to invalidate paired sessions if a device or link may have been exposed.
