# Retrospective Protocol — Programming Projects

> Load when: a retrospective is approved.

## Triggers

**User-triggered:**
- User explicitly says: "Run retrospective" / "Retro now"

**Agent-suggested (must prompt user):**
The agent must prompt to run a retrospective when:
- work is about to be marked "done"
- a milestone slice is shipped
- a PR is about to be created
- a bug required multiple correction attempts
- a significant refactor was done
- a new dependency/tooling change was introduced
- context size approaches handoff threshold

The retrospective runs **only after explicit user confirmation.**

## Protocol

When a retrospective is approved:

1. Diff the recent Lessons Learned log.
2. Identify recurring mistakes, friction patterns, and successful strategies.
3. Review the project holistically: assess logic consistency, identify redundant or inefficient code, and flag architectural concerns.
4. **Honest grading — gate every proposal.** Before proposing any rule, grade the underlying lesson against all three tests. A proposal that fails any one of these is NOT a rule — it stays in `notes/lessons.md` or is forwarded to a skill/hook/convention instead.
   - **Recurrence test:** Is the failure mode likely to hit ≥5 times/year across the set of projects the rule would govern? One-time incidents do not earn a top-level rule.
   - **Specificity test:** Does the lesson name a specific, checkable failure mode (not a vague principle)? "Verify X before doing Y" passes; "be careful with X" does not.
   - **Cheap-to-state test:** Can the rule be stated in ≤3 sentences with a concrete example or a grep-able check? If it needs a paragraph of caveats, it belongs in a convention file, not a CLAUDE.md bullet.

   Present the grading transparently to the user for each candidate: "I see N candidates from this session. Grading them — A passes all three, B fails recurrence (one-time fluke), C passes two but needs a full convention." The user decides; never launder a failed proposal into a rule by softening the language.

5. **Route with leanness in mind — CLAUDE.md is the last resort.** For each proposal that passed grading, pick the leanest sink that works. Preferred routing, in order:
   1. **Skill / plugin / command** — if the behavior can be encoded as a workflow step, extend the relevant skill or propose a new one. This scales with domain, not surface area.
   2. **Hook** — if the rule is a deterministic pre/post check (credential scan, git safety, format enforcement), propose a hook in `CLAUDE CODE RESOURCES/hooks/` or `~/.claude/hooks/`.
   3. **`notes/lessons.md`** (project-local) — the default sink for anything that's real but narrow. Lessons accumulate freely here with no leanness bar.
   4. **Convention file** in your shared conventions folder — for cross-project behaviors that need more than 3 sentences. Referenced from CLAUDE.md via the trigger table, not inlined.
   5. **Project-level `CLAUDE.md`** (e.g., `<project-name>/CLAUDE.md`) — moderate bar. Project files may carry domain-specific rules that wouldn't survive the top-level grading gate. A recurring project-specific pattern earns its spot here.
   6. **Top-level CLAUDE.md files** (`Programming Projects/CLAUDE.md`, vault root `CLAUDE.md`, plus any other specialized top-level CLAUDE.md files you maintain — e.g. for a dedicated vault-management assistant or an agent-runtime project) — **highest bar.** Only add rules that pass the grading gate above AND have a high-conviction signal: the rule prevents an expensive failure mode that nothing else in the routing chain catches. Each line in these files is read every session — bloat is permanent tax. When in doubt, don't add; push to a convention or a skill.

   Report the routing decision per proposal: "Proposal X → project CLAUDE.md. Proposal Y → lessons.md only (passed grading but route is cheaper). Proposal Z → new skill step." If the user asks to put something in a top-level CLAUDE.md that failed the routing test, push back once with the cheaper sink, then accept their call.

6. Categorize each surviving proposal by target file:
   - `[GEN]` → top-level `Programming Projects/CLAUDE.md` (only if it cleared step 5's top-level bar)
   - `[CLAUDE]` → Claude-specific tooling adjustment (settings, hooks, skills)
   - `[PROJECT:<name>]` → project-specific rule for that project's CLAUDE.md
   - `[CONVENTION:<name>]` → new or amended convention file
   - `[SKILL:<name>]` → skill extension or new skill
   - `[LESSON]` → stays in `notes/lessons.md` only
7. **Merge reusable learnings:** If a project-specific CLAUDE.md contains patterns that would benefit other projects, identify reusable patterns, generalize them (remove project-specific details), re-grade them against step 4's tests, and — only if they clear — propose adding them to the canonical CLAUDE.md. Most should land in a shared convention instead.
8. **Skill/Plugin/Command Enrichment Check.** Review the session's work and ask: "Did this session produce a workflow, technique, or capability that an existing skill, plugin, or command should absorb?" Specifically:
   - **Existing skills:** Scan the skills used in this session and any skills whose domain overlaps with the work done. If the session discovered new steps, edge cases, patterns, or sub-workflows that the skill doesn't cover — propose specific additions to that SKILL.md.
   - **Existing plugins/commands:** If the session used a plugin command and found it lacking (missing flags, missing sub-commands, inadequate defaults) — propose the enhancement.
   - **New skill candidates:** If the session performed a multi-step workflow that isn't covered by any existing skill and is likely to recur — propose creating a new skill via `/skill-create`.
   - **Convention updates:** If the session established or validated a practice that should be captured as a shared, cross-project convention — propose adding or amending the relevant convention doc.
   - Present all proposals to the user. Do not auto-apply. The user decides which enrichments to execute.
   - If executing enrichments, read the target skill fully before editing — skills are complex and edits must be surgical.
8b. **Project Improvement Scan.** Run `/improve-project --light` to surface feature and improvement proposals across Product & UX, Infrastructure & DevOps, and Data & API dimensions. This uses session context — what the user worked on, what friction was observed, what files were touched — to ground proposals in reality. Present proposals inline as part of the retro output. If the light scan produces ≥3 HIGH-confidence proposals, offer to run a deep scan: "The light scan found several promising improvement areas. Want me to run `/improve-project --deep`?" Continue with the rest of the retro regardless of the user's answer.
9. Present proposals to the user. For each, show: the lesson, the grading outcome (step 4), the routing recommendation (step 5), and the categorization tag (step 6). The user sees the full reasoning, not just a bullet list.
10. **Only after explicit approval:** update the relevant file(s).
11. **Review the canonical CLAUDE.md for clarity:** Remove redundant instructions, fix inconsistencies, simplify confusing wording, and tighten formatting. This is a leanness sweep — if a bullet has grown stale or its failure mode hasn't recurred in 6+ months, flag it for removal.
12. **Update the user's Workflow doc:** If the retrospective surfaced tips or reminders, append them to the `Retrospective Inbox` section of `Claude Code Workflow.md`. Format: `### YYYY-MM-DD — <project>` followed by bullets.
13. **Cross-pollination check.** Review the sibling Vault Management CLAUDE.md for any recently added general rules or patterns worth porting. Propose — never auto-apply. Apply the same grading + routing discipline: don't port a rule into a top-level CLAUDE.md unless it clears the bar.
14. **Permission review.** Recall which tool permissions the user had to manually authorize during the session (Bash commands, file edits, web fetches, MCP tools, etc.). For each:
    - State the permission and what it allows (use the reference table below).
    - Explain the risk level of pre-authorizing it — distinguish between scoped rules (e.g., `Bash(npm run *)`) and blanket rules (e.g., `Bash`).
    - Recommend scoped rules where possible. Warn against blanket pre-authorization of `Bash`, `Edit`, or `WebFetch` without specifiers.
    - Ask the user if they'd like to add any of these to their permissions settings (`~/.claude/settings.json` for global, or `.claude/settings.json` in the project for project-scoped).
    - If the user approves, make the edits to the appropriate settings file.

### Permission Reference (for step 14)

| Permission | What it allows | Risk if blanket-authorized |
|---|---|---|
| `Bash(command pattern)` | Run shell commands matching the pattern. `*` is wildcard. Word boundaries matter: `Bash(ls *)` ≠ `Bash(ls*)`. | **High.** Blanket `Bash` allows *any* shell command — file deletion, network access, credential exfiltration. Always scope to specific commands. |
| `Read(path pattern)` | Read files matching the glob pattern. Supports `*`, `**`, `~`, `//absolute`. | **Medium.** Blanket `Read` exposes `.env`, `.ssh/`, secrets, credentials. Scope to source directories. |
| `Edit(path pattern)` | Modify files matching the glob pattern. Same glob syntax as Read. | **Medium-High.** Blanket `Edit` allows modifying configs, injecting code, altering build scripts. Scope to source directories. |
| `Write(path pattern)` | Create new files matching the glob pattern. | **Medium.** Similar to Edit — can create files in unexpected locations. Scope to project directories. |
| `WebFetch(domain:example.com)` | Fetch content from matching domains. | **Low-Medium.** Blanket `WebFetch` allows accessing any URL including internal services. Scope to known domains. |
| `mcp__server__tool` | Use a specific MCP tool. `mcp__server__*` allows all tools from that server. | **Varies.** Depends on what the MCP server can do (e.g., Google Workspace tools can send emails, modify files). Prefer per-tool rules. |
| `Task(agent_type)` | Spawn subagents of a given type. | **Low.** Subagents inherit the session's permission mode. Rarely needs pre-authorization. |

**Scoped vs. blanket examples:**
- Safe: `Bash(python manage.py *)`, `Bash(bun run *)`, `Bash(git commit *)`, `Edit(src/**/*.ts)`
- Risky: `Bash`, `Edit`, `Read`, `WebFetch` (no specifiers = everything allowed)
- Deny patterns protect sensitive paths: `Read(.env*)`, `Read(~/.ssh/**)`, `Bash(rm -rf *)`

**Rule evaluation order:** Deny → Ask → Allow (first match wins; deny always takes precedence).

## Governance

- The canonical CLAUDE.md is the constitution — treated as scarce resource, not a dumping ground.
- Lessons are never auto-promoted into rules. Grading (step 4) gates every promotion.
- All rule changes require user confirmation.
- The system improves through deliberate reflection, not drift.
- **Leanness bias:** Top-level CLAUDE.md files (`Programming Projects/CLAUDE.md`, vault root `CLAUDE.md`, and any other specialized top-level CLAUDE.md files you maintain) are loaded every session — every line is permanent tax. Improvements should be routed *anywhere but* these files unless a high-conviction signal demands it. Project-level CLAUDE.md files are more lenient but still subject to the grading gate. Conventions, skills, hooks, and `notes/lessons.md` are the preferred sinks.
- **Scope guard:** Cross-project rules land in canonical CLAUDE.md only after passing the grading + routing steps. Project-specific learnings go in that project's `notes/lessons.md` or project CLAUDE.md.
- **Recurrence audit:** During step 11 (clarity review), any rule whose failure mode hasn't recurred in ≥6 months is a removal candidate — the protocol rewards shrinking these files, not just growing them.

> All rule and skill changes require user confirmation. The system improves through deliberate reflection, not drift.
