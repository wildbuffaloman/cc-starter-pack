---
name: permissions
version: "0.1.0"
description: Display current Claude Code permission settings and allowed tools
---
<!-- ported-from: permissions@0.1.0 sha256:23c566ed8c19 -->

Show the user the current permission configuration:

1. Read and display contents of `.claude/settings.json` if it exists
2. Read and display contents of `.claude/settings.local.json` if it exists
3. Read and display contents of `~/.claude/settings.json` if it exists (user-level)
4. Summarize which tools are allowed/blocked
5. Explain how to modify permissions

If no settings files exist, explain how to create them and configure permissions.

## Auto-mode trust

Auto mode's pre-approved git remotes and SSH hosts live in `~/.claude/settings.json` under `autoMode.environment`. An agent running in auto mode cannot widen that allowlist itself because auto mode blocks self-modification. Show the user the required settings change and ask them to apply it outside the active auto-mode session.

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
