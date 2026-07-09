# Session Close-Out Protocol

> Load when: session is ending — context limit, user wraps up, task complete, or any close-out trigger.

## When to Trigger

Run this protocol when ANY of the following occur:
- User says "wrap up", "close out", "done for now", "save state", or similar
- Context window reaches ~50% (after alerting user per shared rules)
- A major task/milestone is completed
- Session is naturally ending for any reason

## Steps

> **Non-negotiable:** Every session that did meaningful work MUST update or create a project brief with a Continuation Prompt before closing. No exceptions — even quick sessions that didn't start with a brief. This is the single most important step in session closeout. It prevents knowledge loss between sessions and ensures smooth continuation. If no brief exists, create one in `Inbox/`.

### 1. Identify the Vault Project Brief

Every work session maps to a project. Find the corresponding vault project brief:

- **Search** `Projects/` (all subcategories) for a note matching the current project/task.
- **Programming projects:** the vault brief may have a different name than the code folder (e.g., `inkys-great-escape/` → `Inky's Amazing Escape Video Game.md`). Check the programming project's CLAUDE.md or README for a `Vault Project Brief:` reference.
- **Vault Management sessions:** the "project" is whatever vault task is being worked on (e.g., "Resources/ Restructure", "Weekly Review").

**If no project brief exists** → create one in `Inbox/` using the template below. Inform the user it needs review and placement into the appropriate `Projects/` subcategory.

### 2. Update the Project Brief

#### Continuation Prompt (top of Next Actions)

At the very top of `## Next Actions`, add or **replace** a `### Continuation Prompt` block. Only the latest prompt is kept — it gets overwritten each session.

Format:

```markdown
### Continuation Prompt
> **Date:** YYYY-MM-DD
> **Mode:** <Vault Management / Programming Projects>
> **Context:** <1-2 sentences — what project, what we were doing>
>
> **Resume from:** <specific next step, file, or location>
> **Key decisions this session:** <critical choices made that affect next steps>
> **Blockers/open questions:** <anything unresolved>
> **Files touched:** <key files modified this session>
```

This block is designed to be **copy-pasteable** into a new Claude Code session to resume work seamlessly.

#### Next Actions

Update the task list — check off completed items, add new ones discovered during the session. **Move completed tasks to the Log** (they no longer belong in Next Actions once done). **Also scan for stale checked items:** any `[x]` items in Next Actions or Waiting For that were completed outside this session (e.g., during meetings, via Trello, or by other team members) should also be moved to the Log now. Empty category sub-headings left behind should be removed.

#### Log

Append dated entries for work accomplished. Rules:

- **One item per row** — never combine multiple items into a dense paragraph.
- **Label each item** as `Task` or `Milestone` in the Type column.
- **Completed tasks** are moved here from Next Actions.
- **Completed milestones** are copied here AND remain (checked off) in the Plan's Milestones section.

```markdown
| YYYY-MM-DD | Task | <Brief summary of work done> |
| YYYY-MM-DD | Milestone | <Milestone name / summary> |
```

#### Waiting For

**Only items the user is waiting on from other people or agents.** Never place self-directed tasks here — those belong in Next Actions.

#### Working Notes (if relevant)

Add any important context, decisions, or technical notes from the session.

### 3. Cross-Linking

Ensure bidirectional references between the vault project brief and its associated workspace.

**For Programming Projects — in the vault project brief**, add to `## Key Resources > ### Reference Materials`:

```markdown
- **Code:** `{{AGENT_DIR}}/Programming Projects/<project-folder>/` (or wherever your local code workspace lives — `{{AGENT_DIR}}` here means the folder where you keep your Claude Code skills/config, e.g. `~/.claude`)
```

**For Programming Projects — in the programming project** (CLAUDE.md or README.md), add near the top:

```markdown
> **Vault Project Brief:** `Projects/<subcategory>/<Project Name>.md`
```

**For Vault Management projects**, link to the workspace if one exists:

```markdown
- **Workspace:** `{{AGENT_DIR}}/<relevant-subfolder>/`
```

Cross-links only need to be set up once — subsequent sessions just verify they exist.

### 3.5. Code Simplification (Programming Projects only)

If this was a Programming Projects session and code was written or modified:

1. Run `/simplify` to review changed code for reuse opportunities, quality issues, and unnecessary complexity.
2. Commit any simplification changes separately (e.g., "Simplify: clean up session changes").
3. If no code was changed this session, skip this step.

### 4. Permission Review (lightweight)

Before ending the session, briefly review which tool permissions the user had to manually authorize:

- List the notable permissions that were prompted during the session (file edits, Bash commands, new tool types) — focus on patterns, not every individual approval.
- Ask if any should be pre-authorized for future sessions.
- If the user approves, update the project-level `.claude/settings.json` (preferred for project-scoped rules) or `~/.claude/settings.json` (for global rules).
- For the full permission reference table and risk guidance, see the permissions step of your retrospective protocol (e.g. `retrospective-protocol.md`, if you maintain one).

### 4.5. Update Lessons Log

If the session produced reusable learnings (workflow discoveries, pitfalls, effective patterns), append them to the appropriate lessons log. One line per insight.

- **Vault Management sessions:** `{{AGENT_DIR}}/lessons.md`
- **Programming Projects sessions:** `<project>/notes/lessons.md`

**Also trigger this step during context compaction** — when the system compresses prior messages, capture any learnings from the compressed context before they're lost.

### 4.6. Background Agent-Runtime Fix Verification Setup

If you run a background agent-runtime system (e.g. a scheduled/cron multi-agent fleet) and this session modified its infrastructure (cron payloads, agent configs, routing, permissions, gateway settings, plugin entries, post-update patches, or a launchd/systemd service definition):

1. **Detect session agent-runtime infrastructure changes** — check any of the following (adapt paths to your own setup):
   - Dated entries in that runtime's per-agent memory log with an mtime inside the session window (changes routed through an agent's own memory log)
   - Config backup files (e.g. `~/.your-agent-runtime/config.json.bak*`) with mtime inside the session window (direct config edits or manual JSON edits):
     ```bash
     find ~/.your-agent-runtime -maxdepth 2 -name 'config.json.bak*' -mmin -240 2>/dev/null
     ```
   - Files under `~/.your-agent-runtime/hooks/` modified inside the session window (post-update patches, wrappers, cron hooks):
     ```bash
     find ~/.your-agent-runtime/hooks -type f -mmin -240 2>/dev/null
     ```
   - Plugin enable/disable toggles in this session's command history (look for a `config set plugins.entries.*` / `plugins.allow`-style pattern)
   - Your gateway's launchd/systemd service file mtime inside the session window
2. If changes merit runtime verification (anything that affects artifact routing, model selection, cross-workspace writes, plugin load state, scheduled sweeps, or gateway startup), prompt: **"Background agent-runtime infrastructure changes detected. Run your fix-verification setup to queue verification checks?"**
3. If the user confirms, invoke it (e.g. a bundled fix-verifier-setup skill, if you have one).
4. Skip if changes are documentation-only or don't produce verifiable artifacts.
5. **If you don't run a background agent-runtime system at all, skip this step entirely.**

> **Why multiple detection paths:** a single per-agent memory-log check only catches changes routed through one code path. Direct edits to the runtime's own config/hooks/service file bypass that log entirely and can be missed. Checking mtimes and command history alongside the memory log covers both paths.

### 4.7. Cross-Pollination Check

If this session involved a cross-cutting AI/automation initiative (an agent-runtime project, an internal tooling project, or any project that's part of a broader AI-projects program you track), check if learnings should flow to sibling projects.

**Trigger:** Any of these happened in this session:
- A milestone was completed
- A significant failure or architecture decision was documented
- A new pattern or protocol was established
- A retro was run

**Actions:**
1. **Push meta-learnings to your umbrella AI/automation program brief** (if you keep one — a parent doc that tracks cross-project learnings across your AI-related work): Append a 1-2 line entry to `Working Notes → Cross-Pollination Log`. Format: `| YYYY-MM-DD | Source project | Learning |`. If you don't maintain a shared umbrella brief, skip this step and go straight to step 2.
2. **Check the source project's AI Ecosystem section** for "Feeds Into" targets. If the learning is directly relevant, append a 1-line note to the target project's `Working Notes → Cross-Pollination Inbox`.
3. **Context-relevant only** — skip routine task completions. Focus on: architecture decisions, failure patterns, proven approaches, reusable patterns.

Brief the user: "Pushed [X] learning to the umbrella program brief and flagged for [Y project]."

### 5. Inform the User

After updating, briefly tell the user:
- What was updated (or created, and where)
- The continuation prompt summary (so they can reference it to start the next session)

---

## Project Brief Template

Use when creating a new brief in `Inbox/`. Match the existing vault project format.

```yaml
---
description:
AREA: "[[]]"
SUB-AREA:
category: project
owner: "[[Your Name]]"
status: active
priority: standard
parent: "[[]]"
depends_on:
tags:
slack_channel:   # Optional — for /followup routing
---
```

```markdown
## Outcome

> <One-sentence desired outcome>

## Why This Matters

- What's at stake if this succeeds?
- What's at stake if this fails or drags?

---

## Next Actions

### Continuation Prompt
> **Date:** YYYY-MM-DD
> **Mode:** <mode>
> **Context:** <what we were doing>
>
> **Resume from:** <next step>
> **Key decisions this session:** <decisions>
> **Blockers/open questions:** <blockers>
> **Files touched:** <files>

- [ ] <next action>

## Waiting For

- [ ]

## Dependencies

- [ ]

---

## Key Resources

### Evergreen Notes
- [[]]

### Reference Materials
-

### People / Collaborators
-

---

## Working Notes



## Log

| Date | Type | Update |
|------|------|--------|
| YYYY-MM-DD | Task | Created brief |
```

---

## Notes

- If a session involves multiple projects, update all relevant briefs.
- This protocol concerns the **vault project brief** in `Projects/`, not the programming project's internal `notes/` directory (which continues to serve its own purpose for technical decisions and lessons).
- For sessions that are purely exploratory or conversational with no project scope, the close-out is optional — use judgment.
