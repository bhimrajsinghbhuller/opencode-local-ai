# Architecture

## Component responsibilities

### The model

Qwen, Gemma, or GPT-OSS produces language and tool-call decisions. The model does not independently browse the filesystem or execute commands. It requests actions through the agent harness.

### LM Studio

LM Studio loads model weights into memory and exposes inference endpoints. In this setup it listens on `127.0.0.1:1234` and implements an OpenAI-compatible API under `/v1`.

### OpenCode

OpenCode owns the conversation, project context, tool definitions, permission evaluation, tool execution, and iterative agent loop. Its background service also owns sessions and remote pairing.

### macOS

Commands execute with the rights of the macOS user running OpenCode. OpenCode is not a virtual machine or security sandbox. macOS privacy prompts, filesystem permissions, Keychain behavior, administrator authentication, and network controls still apply.

### Git and GitHub CLI

Git records local history. GitHub CLI uses the account stored in the system credential store to clone, push, create pull requests, and interact with issues. OpenCode simply invokes those tools.

## Request lifecycle

1. The user opens a project and gives OpenCode a goal.
2. OpenCode builds a prompt containing relevant instructions and tool definitions.
3. The prompt is sent to `http://127.0.0.1:1234/v1`.
4. LM Studio runs the selected local model.
5. The model either answers or requests a tool action.
6. OpenCode evaluates the permission rules.
7. If allowed, OpenCode performs the action and sends the result back to the model.
8. The loop repeats until the model reports completion or needs user input.

This loop is the practical difference between a text chatbot and a coding agent.

## Trust boundaries

```text
Local inference boundary:
  OpenCode <-> localhost <-> LM Studio <-> model weights

External service boundary:
  OpenCode <-> GitHub, package registries, websites, MCP servers, remote tunnel

Filesystem boundary:
  OpenCode tools <-> files available to the macOS user
```

Selecting a local model keeps inference local, but a tool call can still contact external services. Permission settings determine whether that call requires approval.

## Why model size matters

An agent must do more than generate code. It must follow tool schemas, interpret command results, notice failures, preserve context, and choose safe next steps. Larger or coding-specialized models often perform these loops more reliably, but they require more memory and run more slowly.

Qwen 3.5 9B is a practical fit for a 24 GB Apple Silicon Mac because it leaves memory for macOS, LM Studio, OpenCode, the repository, and build tools. Larger models may still work with suitable quantization and context settings.
