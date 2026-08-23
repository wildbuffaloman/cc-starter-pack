---
name: context
version: "0.0.2"
description: Show current context window usage and session information
---
<!-- ported-from: context@0.0.2 sha256:cbd674353fba deliberate:personal-only -->

Report the current context window status:

1. Estimate current context usage percentage based on conversation length
2. Suggest running `/compact` if approaching or over 50% — this triggers the smart compaction protocol which preserves plans, tasks, and project state before compacting
3. List major topics/files discussed in this session
4. Note any active plans or in-progress tasks that would need preservation

Keep the response brief and actionable.

Example output format:
```
Context Usage: ~45%
Status: Healthy

Topics discussed:
- Feature branch workflow
- CLAUDE.md configuration
- Custom skills setup

Active plans: none
In-progress tasks: 2

No action needed.
```

If context is at or above 50%:
```
Context Usage: ~55%
Status: Compact recommended

Topics discussed:
- [topics]

Active plan: "Refactor auth module" (3/7 steps done)
In-progress tasks: 2

Recommend running /compact — will preserve plan state and tasks before compacting.
```

## Dependencies

### Required

- Nothing beyond Claude Code itself. This skill is pure-reasoning: it inspects the conversation state and returns a status report. No tools are invoked, no files are read, no external calls are made.

### Optional

- None.

### Vault Conventions

- None. This skill is mode-agnostic and works in any Claude Code session regardless of whether a vault is present.

### Does NOT Require

- No MCPs, CLIs, desktop apps, external services, Python/Node packages, shared-nodes, helper scripts, or plugins.
- No network calls.
- No filesystem access.
