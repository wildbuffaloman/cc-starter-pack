---
name: permissions
description: Display current Claude Code permission settings and allowed tools
---

Show the user the current permission configuration:

1. Read and display contents of `.claude/settings.json` if it exists
2. Read and display contents of `.claude/settings.local.json` if it exists
3. Read and display contents of `~/.claude/settings.json` if it exists (user-level)
4. Summarize which tools are allowed/blocked
5. Explain how to modify permissions

If no settings files exist, explain how to create them and configure permissions.

Example settings.json structure:
```json
{
  "permissions": {
    "allow": ["Bash(git *)", "Read", "Write", "Edit"],
    "deny": ["Bash(rm -rf *)"]
  }
}
```

## Dependencies

### Required

- Nothing beyond Claude Code's built-in Read tool. This skill reads up to three settings files in known paths (`.claude/settings.json`, `.claude/settings.local.json`, `~/.claude/settings.json`) and renders their contents. No external dependencies.

### Optional

- None.

### Vault Conventions

- None. This skill inspects Claude Code configuration, not vault content.

### Does NOT Require

- No MCPs, CLIs, desktop apps, external services, Python/Node packages, shared-nodes, helper scripts, or plugins.
- No network calls.
- No vault access.
