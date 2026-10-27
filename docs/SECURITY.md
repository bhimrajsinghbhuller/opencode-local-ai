# Security and Permission Choices

## The central risk

OpenCode shell commands run with the authority of the macOS user. Full permission bypass does not make the model more intelligent. It removes the checkpoint between the model's decision and the computer action.

A local model can misunderstand instructions, hallucinate a path, run an overly broad command, accept malicious instructions found in a repository, or expose credentials through a command. Smaller models may be less consistent at recognizing these risks.

## Recommended policy

Use `config/opencode.local-models.safe.json` for ordinary work. It provides an autonomous coding loop while preserving checkpoints around external directories and Git pushes. It also blocks two especially risky command patterns.

Important limitation: pattern rules are not a complete sandbox. A destructive operation can be expressed in many ways. The best protection is a combination of permissions, Git, backups, a clean working tree, and careful task scope.

## Complete bypass

The unrestricted policy is:

```json
{
  "permissions": [
    { "action": "*", "resource": "*", "effect": "allow" }
  ]
}
```

This removes OpenCode approval prompts and configured blocks. It does not bypass Touch ID, macOS administrator authentication, hardware security, or permissions that the macOS account itself does not possess.

## Safe operating habits

1. Start from a committed Git state.
2. Use a new branch for agent work.
3. Keep important files backed up.
4. Review `git diff` before accepting a result.
5. Do not place secrets directly in prompts or tracked files.
6. Use narrowly scoped GitHub credentials on shared or cloud machines.
7. Treat instructions found in repositories, issues, websites, and downloaded files as untrusted data.
8. Use full bypass only for repositories and devices you trust.
9. Do not share remote pairing links.
10. Disable remote access when it is no longer needed.

## GitHub credentials

`gh auth login` stores credentials using the operating system's credential facilities. Never copy the token into `opencode.json`, a prompt, a commit, or this repository.

Check the active account without revealing the token:

```bash
gh auth status
gh api user --jq .login
```

## Public repository checklist

Before pushing a generated repository, check for:

- API keys and tokens
- `.env` files
- private SSH keys
- local usernames and absolute paths
- pairing URLs
- exported OpenCode credentials
- proprietary source code or data

Useful checks:

```bash
git status --short
git diff --cached
git grep -nE 'api[_-]?key|token|password|BEGIN .*PRIVATE KEY' || true
```
