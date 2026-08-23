---
name: session-close
version: "0.2.0"
description: Close out a session — invoke when user says "close out", "wrap up", "done for now", "save state", "closing out", "end session", "let's close", or similar. Updates project briefs, Area MOCs, Program briefs, contact cards, and Agendas; enforces brief structural hygiene (moves completed items out of Next Actions into the Log, dedups tasks, consolidates Continuation Prompts) and reconciles open Next Actions against reality with evidence-cited staleness probes (propose-only); runs infrastructure drift check, skill codification scan (atomic + composite), INBOX sweep for session-generated files, and retro evaluation.
user-invocable: true
argument-hint: "optional: project name or scope hint"
---
<!-- ported-from: session-close@0.17.0 sha256:0354761b0547 -->

Close out the current session by updating all touched vault artifacts and optionally triggering a retrospective.

## Overview

This skill extends the standard session closeout protocol with three additions:
1. **Broader artifact updates** — not just the project brief, but also related Area MOCs, Program briefs, and Agendas
2. **INBOX sweep for session-generated files** — review and route out artifacts (manifests, lint reports, triages) this session dropped in `Inbox/`, lifting any buried follow-up items into briefs with wikilinks back to source
3. **Retro evaluation** — a quick assessment of whether the session's work warrants a retrospective

## Fast path — re-invocation detection

If this is the **second or later** invocation of `/session-close` in the same conversation (detected by checking whether the active project brief's `Continuation Prompt` was updated within the last 10 minutes), skip phases where state is already correct and only run the delta. Specifically:

1. Check the active project brief's Continuation Prompt block's referenced date (or the file's mtime). If updated within the last 10 minutes, this is a re-invocation.
2. **Re-run selectively:**
   - Always re-run Phase 2.5 (Infrastructure Version Control) — the working tree may have changed since the first pass (e.g., new commits landed, files pushed).
   - Always re-run Phase 3 (Retro evaluation) — scoring is cheap and the user may have new context.
   - **Skip** Phase 0 (Deep Work), Phase 1 cross-linking, Phase 1 permission review, Phase 1 agent-runtime infrastructure check, Phase 2b Area MOCs, Phase 2c vault index sync (already ran), Phase 2.4 contact sync, and Phase 2.7 skill codification — none of these change on a second pass in the same conversation.
   - **Conditionally re-run** Phase 1 brief updates and Phase 1 lessons.md — only if the user did something between the two invocations (committed code, ran a command, made a decision). If nothing changed, just report "no delta, everything from first pass still holds."
3. **Announce the fast path** at the start: "Second `/session-close` in this conversation — running delta-only mode. Phases X/Y/Z skipped (already ran first pass), phases A/B re-running because state may have changed."

Rationale: the first full pass of `/session-close` takes ~30 seconds and produces a clean state. A full second pass duplicates that work. The delta-only mode only re-runs phases where state could have changed (git state, retro scoring) and reports the rest as unchanged. Evidence: 2026-04-15 retro — first `/session-close` left 4 bug fixes uncommitted; user committed and pushed them manually between invocations; second `/session-close` only needed to update the brief's Log with one new row and flip the "commit pending" item in Next Actions to done.

## Session log (cross-session state tracking)

At the very end of Phase 1 (after brief is updated but before Phase 2), append a one-line JSON record to `~/.claude/session-log.ndjson`:

```bash
mkdir -p ~/.claude
printf '%s\n' "$(jq -n \
  --arg ts "$(date -u +%FT%TZ)" \
  --arg project "$PROJECT_NAME" \
  --arg brief "$BRIEF_PATH" \
  --argjson files_touched "$FILES_TOUCHED_JSON" \
  '{event:"session-close",ts:$ts,project:$project,brief:$brief,files_touched:$files_touched}')" \
  >> ~/.claude/session-log.ndjson
```

Where:
- `$PROJECT_NAME` — derived from the active brief (e.g., `acme_pricing_project`)
- `$BRIEF_PATH` — absolute path to the vault brief
- `$FILES_TOUCHED_JSON` — JSON array of files this session edited (from git status + Read/Edit tracking)

This log is consumed by future sessions that need to answer "when was the last session on this project, and what did it touch?" — primarily useful during post-compaction recovery and cross-session state drift diagnosis. Do not read it during normal operation — treat it as a write-only ledger until a skill explicitly consumes it.

## Phase 0 — Deep Work Session Detection

Before starting standard session closeout, check for an active Deep Work session:

1. **Detect:** Check if `~/.claude/plugins/deep-work/state/deep-work-session.json` exists
2. If no active session, skip to Phase 1.
3. If yes, perform the Deep Work teardown:

### Step A: Status Sweep
- Read the manifest at `~/.claude/plugins/deep-work/state/deep-work-session.json`
- Read all per-tab status files (`~/.claude/plugins/deep-work/state/w*t*.status`)
- Present a summary table to the user:
  ```
  Window 1 Tab 1: task-name [STATUS]
  Window 1 Tab 2: task-name [STATUS]
  ...
  ```
- For any tab with status `working` or `waiting_on_user`, ask: "These tabs are still active. Checkpoint or abandon?"

### Step B: Project Brief Update
- Read the project name from the manifest
- Find the corresponding project brief in `Projects/`
- Write a Continuation Prompt summarizing:
  - What was accomplished across all windows
  - What tasks are unfinished and their current state
  - Any blockers or dependencies discovered
  - Which worktrees are kept for resumption

### Step C: Decision Trace Capture
- Ask the user: "Were any significant design decisions made during this session that should be recorded as decision traces?"
- If yes, record them per the standard decision trace protocol

### Step D: Worktree Cleanup
- Ask: "Clean up worktrees for completed tasks? (Worktrees for unfinished tasks will be kept)"
- If `~/.claude/plugins/deep-work/scripts/deep-work-teardown.sh` exists and is executable:
  - If yes: `~/.claude/plugins/deep-work/scripts/deep-work-teardown.sh --worktrees`
  - If no:  `~/.claude/plugins/deep-work/scripts/deep-work-teardown.sh`
- **If the script is missing or non-executable** (it is NOT bundled on all machines — evidence: 2026-04-19 session on this machine), fall back to inline cleanup. Do not improvise — use these exact commands:
  ```bash
  SESSION_ID=$(jq -r '.session_id' ~/.claude/plugins/deep-work/state/deep-work-session.json)
  mkdir -p ~/.claude/plugins/deep-work/state/archive
  mv ~/.claude/plugins/deep-work/state/deep-work-session.json \
     ~/.claude/plugins/deep-work/state/archive/deep-work-session-${SESSION_ID}.json
  mv ~/.claude/plugins/deep-work/state/s*-prompt.md \
     ~/.claude/plugins/deep-work/state/archive/ 2>/dev/null || true
  mv ~/.claude/plugins/deep-work/state/w*t*.status \
     ~/.claude/plugins/deep-work/state/archive/ 2>/dev/null || true
  ```
  Worktree cleanup (if any) is then manual per `using-git-worktrees` skill — announce this to the user.

### Step E: State Archival
- If the teardown script ran: it handles moving state files to `state/archive/`.
- If the inline fallback ran: state files are already archived by the commands above.
- Confirm to user: "Deep Work state archived. Other Ghostty windows can be closed when ready."

4. Continue with Phase 1.

## Phase 0.5 — Forced Brief Target (argument resolution)

`/session-close` accepts an optional project hint. When provided, it forces which project brief every downstream phase updates instead of relying on session inference.

1. **No project hint** — skip this phase and let Phase 1 infer the active brief from the session.
2. **Project hint present** — search `Projects/` recursively for a fuzzy, case-insensitive match against folder names, brief filenames, and brief titles.
   - **One strong match** — pin that brief and project name for every downstream phase. Announce the resolved path and that it overrides session inference.
   - **Multiple strong matches** — list the candidates and ask the user which one to use. Do not guess.
   - **No match** — stop, report the search terms used, and ask for the brief path. Never silently fall back to a different inferred project after the user supplied a hint.

When a forced target is pinned, Phase 1 must use it and skip its own brief search. If the observed work appears to concern another project, warn once, honor the forced target, and leave the other brief untouched.

## Phase 1 — Standard Session Closeout

Read and follow `./_bundled/protocols/session-closeout-protocol.md` (the bundled copy shipped with this skill), or your own customized copy at `{{AGENT_DIR}}/session-closeout-protocol.md` if you maintain one. Execute all steps:
- Identify and update the vault project brief (continuation prompt, next actions, log, waiting for, working notes)
- Cross-linking
- Permission review
- Lessons log update
- Cross-pollination check

The vault working directory is {{VAULT_ROOT}}. Some phases below also reference `{{AGENT_DIR}}` — wherever you keep your Claude Code skills, hooks, and maintenance scripts (e.g. `~/.claude`).

## Phase 1.7 — Continuation Prompt Quality Gate

The Continuation Prompt is the load-bearing artifact for resuming in the next session. Validate the prompt after Phase 1 writes it and before finalizing the closeout.

Triggered: Phase 1 wrote or updated a `### Continuation Prompt` in the active brief.

Skipped silently: no active brief, a purely conversational session, or Phase 1 made no prompt edit.

### 1.7a: Extract the prompt

Read the `### Continuation Prompt` block Phase 1 just wrote.

### 1.7b: Score against the rubric

Each check is binary pass/fail:

| # | Check | Pass condition | Fail signal |
|---|---|---|---|
| 1 | **Resume locus** | Names a specific file path, line number, function, milestone, or subtask | Uses only vague language such as "continue", "explore", "review", or "look at" |
| 2 | **Files touched** | Lists at least one file or section explicitly | Says "various" or "multiple", or omits the list |
| 3 | **Mode + cwd** | States the working directory or mode when non-default | A non-default location is implied but unstated |
| 4 | **Next-action verb** | Uses an imperative such as run, draft, verify, fix, write, test, commit, push, ship, send, or review | Starts with explore, look at, think about, consider, or see |
| 5 | **Internal links** | Includes at least one internal note reference in the prompt body | Contains no internal note reference |

For a closeout-style prompt that opens with completed state, pass check 4 when its follow-up section uses imperative verbs.

### 1.7c: Decision logic

- **5/5** — continue silently.
- **4/5** — record the warning in the closeout summary and continue.
- **3/5 or lower** — show the failed checks and ask the user to choose: enrich now, accept as-is, or show the prompt.

### 1.7d: Enrichment loop

If the user chooses enrichment, ask: "What's the specific next action and where should the next session start?" Update the prompt while preserving its other sections, then re-score once. If it still fails, accept it as-is and record the warning. Never rewrite the prompt without user approval.

### 1.7e: Log

Add this line to the closeout summary:

```text
Continuation Prompt quality: N/5 — [silent | accepted-with-warnings | enriched]
```

If the session log record supports extra fields, also record the integer score as `prompt_quality`.

### Rules

- Keep the rubric at five checks; do not expand it during a closeout.
- Apply the mode-and-cwd check only when the session used a non-default location or mode.
- Inspect internal links in the prompt body, not in headings.
- If Phase 1 should have written a prompt but none exists, surface that as a Phase 1 failure and investigate before closing.
- Re-run this gate on every same-conversation re-invocation because the prompt may have changed.

## Phase 1.9 — Brief Structural Hygiene

Deterministic structural check on the brief Phase 1 just wrote. Phase 1 judges *content*; this phase enforces the brief's *structural invariants* — one Continuation Prompt, deduped tasks, no completed items still sitting in Next Actions. Those are the two failure modes that make a brief rot: Continuation Prompts pile up, and Next Actions becomes a jumble of done and not-done.

Triggered: after Phase 1, whenever Phase 1 edited an active brief. Skipped silently: no active brief, or no brief edits this session.

### 1.9a: Check the invariants

Read the active brief and check:

| Invariant | Violated when |
|---|---|
| **Single Continuation Prompt** | more than one CP *body* exists |
| **No completed items in Next Actions** | any `- [x]` line remains under `## Next Actions` |
| **No duplicate tasks** | two `- [ ]` lines say the same thing |
| **Log is append-only** | a Log row was rewritten rather than added |

> **Count CP bodies, not headings — and strip code blocks first.** Continuation-Prompt accumulation keeps ONE heading and stacks extra `> **Date:**` bodies underneath it. A raw heading count finds nothing and false-fires on any fenced *example* CP inside a document. Strip fenced blocks and inline code, then count both headings and `> **Date:**` bodies.

### 1.9b: Auto-fix the mechanical issues

Safe to fix without asking — these relocate and dedup structure, they never rewrite prose:

- **Lingering `- [x]` in Next Actions** → move each one to `## Log` as a one-row entry, then remove it from Next Actions. Next Actions is for what is still open; the record of what got done belongs in the Log.
- **Duplicate `- [ ]` lines** → collapse to one, keeping the richest variant (the one carrying a due date, priority, or owner).
- **Stale or archived duplicate CP blocks** → consolidate into the single current CP, merging any still-relevant carryover first.

### 1.9c: Surface anything needing judgment

Do NOT auto-merge when a decision is required — ask instead:

- Two CP blocks that both look current (you cannot tell which is canonical).
- A second CP that may be deliberate instructional content — offer to demote it to plain text rather than delete it.

Prompt: `⚠ Brief hygiene: <issue>. [F]ix as proposed / [K]eep / [S]how.`

### 1.9d: Report

```
Brief hygiene: <clean | auto-fixed: N [x]→Log, M dup tasks, K CPs consolidated | surfaced: …>
```

### Rules

- Never rewrite Continuation Prompt *prose* here. This phase only relocates, dedups, and consolidates.
- After auto-fixing, re-check once — the invariants must come back clean.

## Phase 1.95 — Next-Actions Reality Reconciliation (propose-only)

Phase 1 resolves the items **this session's own work** completed. Nothing before this phase ever asks whether an item still open in the brief was completed by *someone else* — another session, another machine, a scheduled job, a counterparty, or a change that quietly retired the item's premise. That unowned case is how briefs go stale while looking maintained.

The failure is real and it survives careful closes: an item reading *"fix the red CI on main"* can sit open for two weeks after the PR that turned CI green — including through a meticulous close of that same brief — because every close before this one only reconciled its **own** thread's work, never the brief as a whole. And a stale brief poisons whatever reads it downstream: anything generating proposals from Next Actions will happily generate one for work that is already done.

Triggered: after Phase 1.9, whenever an active brief exists. Skipped silently: no active brief, or a purely conversational session.

### 1.95a: Enumerate open items

Collect from the active brief:
- every `- [ ]` line in `## Next Actions` and `## Waiting For`;
- every follow-up line inside the **current** `### Continuation Prompt` block — carryover lists live there and are the observed blind spot. Older CP blocks below the current one are historical record: never scan them, never edit them.

### 1.95b: Deterministic staleness probes — run these first

These are plain checks, not model judgment. Flag an item when a probe hits, and **every flag must name its evidence** — never a naked "this looks done":

| Probe | Fires when | Evidence to cite |
|---|---|---|
| **Log-contradiction** | the item shares distinctive tokens (module, PR number, script name, error string) with a LATER-dated `## Log` row carrying a completion marker (`✅` / `RESOLVED` / `SHIPPED` / `VERIFIED`) | the Log row's date + marker |
| **Retired mechanism** | the item says to run a skill or script that no longer exists, or whose description now begins `RETIRED` | the missing path / retirement marker |
| **Version-pin regression** | the item pins `vX.Y.Z` of something whose current version is already higher | both version strings |
| **Expired scheduled check** | a "verify on `<date>`" item whose date is more than 21 days past | the date vs today |
| **Supersession range** | the item's leading `(N)` ordinal falls inside a range a Log row declares superseded | the Log row's date and the step range it names |

Probes justify a *question*, never a verdict.

### 1.95c: Session-evidence pass

Also flag any open item whose completion **this session directly observed** — a test run you read, a file you confirmed on disk, a merged PR, a reply that arrived. Same evidence-naming requirement.

### 1.95d: Surface — never auto-retire

Truth stays with the user. A probe hit means "suspected stale"; only the user confirms what is actually true.

- **Interactive close** → one batched question, at most 6 items per close; per item offer: `[R]etire → move to Log with the evidence / [K]eep (still real) / [E]dit scope (partially done — restate what remains)`.
- **Non-interactive close** (background job, scheduled run) → list the flags in the report as `⚠ suspected-stale` lines with their evidence, and make **zero** edits.

Applying an approved retirement reuses Phase 1.9b's mechanics: move the item into `## Log` as one row that **cites the evidence** — e.g. `| 2026-08-23 | Task | Retired stale item "fix the red CI" — CI green since PR #37 (2026-08-09). |`. For a follow-up line inside the current CP, strike it in place with a `→ ✅` annotation rather than deleting it.

### 1.95e: Report (mandatory line)

Every full close MUST print:

```
Next-Actions reality check: N scanned, M flagged, K retired, J kept
```

`0 flagged` is a valid result. A close report **missing the line entirely** means the sweep never ran — that is the difference between "nothing was stale" and "nobody looked", and they must never print identically.

### Rules

- Propose-only, always — even a 100 %-certain hit (a script that demonstrably no longer exists) is surfaced, not auto-applied. Cost of asking: seconds. Cost of a wrong auto-retire: a real commitment silently disappears.
- `## Waiting For` items flag only on the deterministic probes. Whether a counterparty delivered is exactly the kind of truth this phase must not decide on its own.
- This phase only retires items. It never adds them, never rewords beyond an approved `[E]dit`, and never reprioritizes.
- Scope is the **active brief only**. Sweeping the whole backlog is a separate job, not something a per-session close should attempt.

## Phase 1.5 — Stale Frontmatter Sweep

After the standard brief update but before Phase 2, audit frontmatter on the active project brief against the session's observable state. Purpose: catch drift where code/milestones advanced but the brief's frontmatter flags still say "incubating" or "standard" priority.

### 1.5a: Read the active brief's frontmatter

Extract these fields from the active project brief:
- `status` (expected values: incubating | active | paused | done | archived)
- `priority` (expected values: standard | high | critical)
- `category` (project | program | …)

### 1.5b: Compute drift signals

Compare frontmatter against session evidence:

| Signal | Condition | Proposed Flip |
|--------|-----------|---------------|
| **Incubating-but-active** | `status: incubating` AND the brief's Log has ≥2 entries dated within the last 14 days, OR this session appended a milestone completion | propose `status: active` |
| **Active-but-cold** | `status: active` AND the Log's most recent entry is >60 days old | propose `status: paused` |
| **Standard-but-critical** | `priority: standard` AND the session closed a milestone that the brief's roadmap marked as P0/critical, OR the session fixed a production-data-correctness bug | propose `priority: high` |
| **Missing category** | Brief has no `category:` field AND lives in `Projects/` | propose `category: project` |

### 1.5c: Propose, never auto-apply

For each drift signal detected, surface a one-line proposal to the user:

> `⚠ Frontmatter drift: [[Brief Name]] shows 'status: incubating' but milestone M15 completed this session — flip to 'status: active'? [Y/n]`

Batch proposals in a single list if multiple drifts detected. Accept user's yes/no per line. Apply only after approval.

**Rules:**
- Never flip `status: done` or `status: archived` in this phase — those require explicit user intent (use `/session-close archive` or an explicit request)
- Never lower priority (`high` → `standard`) in this phase — only raise. Lowering requires conversation about why.
- If the user declines all, silently record the gap and move on. Do not re-prompt in the same session.
- Include this as a line in the Phase 2f Extended Updates report: `Frontmatter Sweep: N drifts detected, M applied, K declined`

**Evidence:** one retro found that a session had closed a production-data-correctness milestone on a project's Pricing brief, but the brief still showed `status: incubating` + `priority: standard` because the frontmatter hadn't been flipped during the implementation work. Manual flip during retro caught it, but a sweep would have surfaced it at session-close time.

## Phase 2 — Extended Artifact Updates

After completing the standard closeout, update related artifacts that were affected by the session's work.

### 2a: Identify Touched Artifacts

Review the session's work and identify:
- **Area MOCs** (`Areas/XX AREA/XX AREA.md`) — the area-level index files for areas the work touched
- **Program briefs** (`Areas/` files with `category: program`) — parent programs of projects worked on
- **Agendas** (`Areas/**/AGENDAS/` or `Areas/**/Agenda*.md`) — meeting agendas where session work produced items to discuss

### 2b: Update Area MOCs

For each affected Area MOC:
- Verify project/program links are current (new projects referenced, archived ones removed)
- Add any new sub-area entries if the session created them
- Keep updates minimal — only reflect changes from this session

### 2c: Sync Vault Indexes

Run the vault index sync script to refresh all program sub-project indexes and the hierarchy dashboard. This helper script is optional and, if you sync this vault across more than one machine, may only be present on one of them — soft-skip with a notice when it's missing rather than failing the closeout:

```bash
SCRIPT="{{AGENT_DIR}}/scripts/sync_vault_indexes.sh"
if [[ -x "$SCRIPT" ]]; then
  bash "$SCRIPT" --apply
else
  echo "sync_vault_indexes.sh not present on this machine — skipping vault index sync (run it on whichever machine keeps your maintenance scripts)"
fi
```

When the script runs, it updates two things atomically:
1. **Per-program Sub-Project Index blocks** — the `<!-- SUB-PROJECT-INDEX -->` tables inside each program note
2. **your hub/index folder's `Program Hierarchy.md`** (e.g. `Hub/Program Hierarchy.md`) — the vault-wide dashboard (all programs grouped by area with children trees)

Report the script output to the user (number of programs updated, any missing markers). If the script was skipped, note that in the Phase 2f extended updates summary so the user knows to run it on whichever machine keeps the maintenance scripts later if the session created new programs or sub-projects.

### 2d: Update Program Briefs

For each affected Program (beyond the automated index sync above):
- Add log entries for significant milestones achieved in sub-projects
- Update the Continuation Prompt if the program's next steps changed as a result of this session

### 2e: Update Agendas

For each relevant Agenda:
- Add discussion items, decisions, or follow-ups that emerged from the session
- Add items to the appropriate section (topics to discuss, decisions made, action items)
- Only add items that genuinely need to be raised in the next meeting with that person/group

### 2e-sync: Plan Sync Drift Detection

After updating agendas, scan documents touched during the session for `sync_status` frontmatter:

1. **Development state reminder:** If a synced document was modified during this session and still has `sync_status: development`, remind the user: "N documentos sincronizados tienen cambios pendientes de push. Usar `/plan-push` cuando esten listos."
2. **Stale development warning:** If any synced document has `sync_status: development` and `sync_checkout_date` is older than 14 days, escalate: "ALERTA: [[Document Name]] ha estado en desarrollo por N dias sin publicar. Considerar publicar o descartar cambios."
3. **High changelog count:** If any synced document has more than 5 un-synced entries in the Changelog / Sync Queue, note: "[[Document Name]] tiene N cambios pendientes de sync. Considerar publicar pronto."
4. **Inverse drift — edit without `/plan-checkout`:** For each file modified during this session, grep its frontmatter. If `sync_status: production` AND the file was edited in-session, the user skipped `/plan-checkout`. Auto-repair the drift:
   - Flip `sync_status: production` → `development`
   - Bump `sync_checkout_date` to today
   - Append a row to `lessons.md` noting the drift (one line, `created:` date)
   - Add to the Phase 2f extended updates report: *"⚠ N synced doc(s) edited without `/plan-checkout`. Frontmatter auto-repaired. Next time, run `/plan-checkout` first — it fetches latest from Google Doc (avoiding team-edit conflicts) and sets the 'I'm working on this' signal."*

Report these findings as part of the Phase 2f extended updates summary.

### 2f: Report Extended Updates

Tell the user what was updated beyond the project brief:
- List each artifact updated and what changed
- If no extended artifacts needed updating, say so

## Phase 2.4 — Contact Sync

Scan the session for people-related information and sync contact cards.

### 2.4a: Scan Session for Contact Information

Review the session's conversation and work for:
- **People mentioned by name** with new facts discovered (roles, emails, companies, relationship context, project involvement)
- **Meeting attendees** from agendas or minutes processed during the session
- **Negotiation counterparts** discussed during prep or coaching

### 2.4b: Cross-Reference Against Existing Contacts

For each person identified:

1. Check `Resources/COMMUNITY/CONTACTS/` for an existing card
2. Check `Resources/IMPORTANT DOCS/Vault Contacts.md` for a table row

Categorize each person:
- **Existing contact + new info** → queue for Silent Update
- **New priority contact** (a work stakeholder, active project collaborator, negotiation counterpart, community/cohort member, recurring meeting attendee) → queue for Quick Add
- **New non-priority contact** → skip

### 2.4c: Execute Contact Updates

- **Silent Updates:** Run the `/contact-card` Silent Update procedure for each existing contact with new info. No user confirmation needed.
- **Quick Adds:** Present the list of new priority contacts to the user: "New contacts this session: {list with role/company}. Create quick contact cards? [Y/n]". If approved, run Quick Add for each.

### 2.4d: Enrich Suggestions

After executing updates and quick-adds, check if any contacts discussed this session have thin profiles worth enriching:

1. **Scan contacts touched this session** (both updated and newly created) for:
   - Cards with the `quick-add` tag (stubs that were never enriched)
   - Cards with fewer than 3 populated body sections (Profile, Background, Vault References, etc.)
   - Cards missing key fields (no email, no company, no role) that the session context suggests could be filled

2. **If enrichable contacts found**, suggest:
   > "These contacts were discussed this session and have thin profiles:
   > - [[Name1]] (stub, missing background + vault references)
   > - [[Name2]] (no email, no company)
   >
   > Enrich them now? `/contact-card enrich` pulls Google Contacts, vault mentions, and optional web research. [Y/n]"

3. **If user approves**, run `/contact-card enrich {Name}` for each. This is the full Enrich mode — automated sources, no Q&A, but richer than Quick Add. The session context is still fresh, making vault mentions scan especially effective.

4. **If user declines**, skip — the stubs remain available for enrichment in any future session.

### 2.4e: Report

Include in the Phase 2f Extended Updates report:
```
Contact Sync:
- Updated N existing cards: [[Name1]] (new email), [[Name2]] (new role)
- Created M new cards: [[Name3]] (via quick-add)
- Enriched P cards: [[Name4]] (Google Contacts + vault mentions)
- Skipped K non-priority mentions
```

If no contact updates were needed, report: "Contact Sync: no new contact information this session."

## Phase 2.5 — Infrastructure Version Control

Check if this session modified any version-controlled infrastructure files.

### Detection

This phase assumes your Claude Code skills/hooks/conventions live in their own git repo — call that path `{{AGENT_DIR}}` (e.g. `~/.claude`, or a dedicated folder if you keep it inside a larger notes vault).

Run: `git -C "{{AGENT_DIR}}" status --short 2>/dev/null`

If no `.git` directory exists or git returns empty, skip this phase silently.

**Scope to this session only.** The `{{AGENT_DIR}}` repo may contain working-tree drift from prior sessions that was never committed. Do NOT commit that drift — it is not ours to claim. For each modified file in the status output, ask: "Did *this session* touch this file?" If no, exclude it from consideration. If this session touched zero infrastructure files, skip the phase entirely even if there is unrelated drift present.

### If Changes Detected

1. Confirm the modified files listed by git overlap with files this session actually touched. Discard any that don't.
2. If the overlap is empty, skip the phase. Do NOT report on pre-existing drift — noting it as "skipped" in the extended-updates report is enough.
3. If the overlap is non-empty, show the user a summary of *only those files*: `git -C "{{AGENT_DIR}}" diff --stat -- <files>`
4. Present the changes and ask:
   > "This session modified N infrastructure files (CLAUDE.md/hooks/skills/conventions). Commit to track the change? [Y/n]"
5. If yes:
   - Create a feature branch: `git checkout -b session-YYYY-MM-DD-HHmm`
   - Stage only the files this session touched by name: `git add <file1> <file2> ...` (never `git add -A`, which would sweep up unrelated drift)
   - Commit with a message summarizing what changed (derive from session context)
   - Merge to main: `git checkout main && git merge session-YYYY-MM-DD-HHmm && git branch -d session-YYYY-MM-DD-HHmm`
6. If no: skip — the diff will still show up next time.

### Skip Conditions

- No `{{AGENT_DIR}}/.git` directory → skip silently
- Only submodule status changes (skills with dirty `.git` dirs) → skip (these are normal)
- No real file content changes → skip
- Working-tree drift exists but **none of the modified files were touched this session** → skip silently (note in the Phase 2f report that pre-existing drift was observed and deferred)

### Total-Debt Surveillance Sub-Check

Even when the session-scoped overlap is empty (skip path above), count the **total** number of uncommitted items in the `{{AGENT_DIR}}` working tree. If the total ≥ 20, surface the debt in the Phase 2f report even though nothing from this session needs committing:

```bash
total=$(git -C "{{AGENT_DIR}}" status --short 2>/dev/null | wc -l | tr -d ' ')
if [[ "$total" -ge 20 ]]; then
  echo "⚠ Commit debt accumulating in your agent-config repo: $total uncommitted items (pre-existing drift from prior sessions)."
  echo "  Consider a dedicated /session-close pass, or a cleanup session, to bring this back to zero."
fi
```

Include the warning in the Phase 2f extended-updates report. Do NOT auto-commit pre-existing drift — the rule above still applies ("scope to this session only"). This check exists because the scope guard is correct on a per-session basis but silently lets debt pile up across sessions.

**Evidence:** one session discovered dozens of uncommitted items in an agent-config repo — drift that had been accumulating silently for weeks because each session's /session-close correctly scoped out pre-existing drift, but no session ever flagged the accumulation. Threshold of 20 gives ~2 weeks of reasonable drift before suggesting cleanup.

### Untracked Critical Subtree Governance Sub-Check

Several subtrees under `{{AGENT_DIR}}/` contain load-bearing infrastructure but are NOT tracked by the parent repo. Every edit to these subtrees silently escapes version control unless surfaced here.

**Known untracked critical subtrees** (update this list when new ones are discovered):

| Subtree | Contents | Discovered |
|---------|----------|------------|
| `skills/_shared/` | Shared-node infrastructure consumed by many skills | 2026-04-11 |
| `plugins/` | Local plugin sources (e.g., an onboarding plugin) and their references/templates | 2026-04-17 |

**Routing (apply for each entry):**

1. Check if the subtree appears in `git status` (tracked) or is listed as untracked (`??`). The easiest check: `git -C "{{AGENT_DIR}}" ls-files --error-unmatch "<subtree>/<any-known-file>"` — errors out if untracked.
2. Cross-reference: did this session modify any file under the subtree?
3. If session DID modify AND subtree IS untracked → flag the governance gap:

   > "This session modified `<subtree>/<file>` but `<subtree>` is currently untracked in your `{{AGENT_DIR}}` repo. Your edit exists only on disk. Options:
   > - (a) `git add "<subtree>/"` to start tracking the whole subtree in the parent repo (simple)
   > - (b) Promote `<subtree>/` to its own git submodule (independent release cycle)
   > - (c) Leave untracked and defer the decision
   >
   > What should I do?"

4. If session did NOT modify the subtree OR the subtree IS tracked → silent skip for that entry.

**When to extend the table:** If `/session-close` Phase 2.5 ever surprises you with "wait, THAT subtree is also untracked?" on a new directory, add the row here and in your own plugin registry pattern (discovery date + what it contains). The list should grow as silent-escape-from-VCS patterns surface.

## Phase 2.7 — Skill Codification Scan

Review the session's work for recurring patterns that should be packaged into skills. See [[No One-Off Work]].

### 2.7a: Scan Session for Recurring Work

Review all tasks performed during this session and evaluate each against these signals:

1. **Repeatable pattern** — same structure, different inputs (e.g., "process this spreadsheet" where the steps would be identical for next month's data)
2. **Category of work** — the user asked for a *type* of work, not a one-time action (e.g., "analyze this stock" vs. "rename this file")
3. **Natural cadence** — the work touches a domain with inherent periodicity (reporting, syncing, reviewing, cleaning, auditing)
4. **Prior art exists** — similar work was done in a previous session (check project brief logs, skills directory)
5. **Multi-step template** — the task involved 3+ steps that could be templated and reused
6. **Composite workflow** — the session manually chained 2+ existing skills in a specific order with context-forwarding between them (e.g., `/deep-research → /brainstorming → /ce:plan`). Composite candidates deserve their own subsection in 2.7c because they're structurally different from atomic skills — see 2.7c-composite below.

### 2.7b: Check MECE Coverage

For each candidate identified, check `~/.claude/skills/` for existing skills that might already cover it:
- If an existing skill covers it → note that the skill should be *extended*, not duplicated
- If no existing skill covers it → flag as a new skill candidate

### 2.7c: Present Proposals

If candidates were found, present them to the user. **Split the presentation into two subsections** if both atomic and composite candidates exist — they have different evaluation criteria and different creation paths.

#### 2.7c-atomic: Atomic skill candidates

Standard one-skill proposals (single workflow, not chaining existing skills):

> **Atomic skill candidates from this session:**
> - *[description of work]* — [which signal triggered] → Propose: `/skill-name` (new) or extend `/existing-skill`
>
> Want to codify any of these now, or defer to a future session?

#### 2.7c-composite: Composite skill candidates

Skills that chain 2+ existing skills in a specific order with context-forwarding between them. These deserve separate treatment because:

- **Evaluation signals are different.** Ask: (a) does the composition add value beyond manual orchestration? (b) is there a non-obvious ordering rule that gets lost when run manually? (c) does each stage's output need transformation before feeding the next? (d) does the pipeline need output-path overrides (INBOX convention, etc.)?
- **Creation path is different.** Composite SKILL.md wraps existing skills rather than implementing fresh workflow. It must document: the hard ordering rule, the context-forwarding contract per stage, the abort conditions at each stage, the path-override behavior.
- **Proposal format:**
  > **Composite skill candidate:**
  > - *Pipeline observed:* `/skill-a → /skill-b → /skill-c` (N stages, M context handoffs)
  > - *Ordering rule discovered:* [describe the non-obvious order constraint, if any]
  > - *Value beyond manual:* [why the composition deserves codification vs. users chaining manually]
  > - *Path-override concerns:* [any skill defaults that must be overridden]
  > - Propose: `/composite-name` (new) or add composite documentation to existing hub skill

If a composite candidate is approved: read every child skill's SKILL.md before writing the wrapper — composites are brittle if they don't match the underlying skills' input/output contracts.

### 2.7d: Act on Approval

If the user approves any candidates:
- For **new skills**: invoke `/skill-create` with the skill description pre-filled from the session's work
- For **extensions**: read the existing skill's SKILL.md and propose specific additions

If the user defers: acknowledge and move on. The proposal is logged in the session closeout note for future reference.

### 2.7e: Report

Include in session closeout summary:
```
Skill Codification:
- Scanned N tasks for recurring patterns
- Found M candidates: [list]
- Codified K / Deferred (M-K) / Extended E existing skills
```

If no candidates were found: "Skill Codification: no recurring patterns detected this session."

### 2.7f: Skills Audit Registration Check

For any `SKILL.md` files created or modified this session under `{{AGENT_DIR}}/skills/`, verify they appear as rows in your canonical skills audit doc (e.g. `Resources/AI & SOFTWARE/Agent Workflow Assignment — Skills & Crons Audit.md`, or wherever you keep a similar skills registry — this check is optional if you don't maintain one).

**Detection:**
1. Find session-touched skill files: `git -C "{{AGENT_DIR}}" diff --name-only HEAD -- "skills/**/SKILL.md"` (plus untracked: `git status --short -- "skills/"`). If the repo doesn't track these, fall back to comparing mtimes against session start.
2. For each touched skill, grep the audit doc for a row with that skill's name. Missing rows = drift.

**If drift found:**
- Present the list to the user: "N new/modified skills aren't registered in the audit doc: {list}. Register now? [Y/n]"
- If Y: either (a) append stub rows inline (quick), or (b) invoke `/skills-audit` for a full reconciliation (slower but catches accumulated drift from prior sessions).
- If N: log the gap in the session summary and move on.

**If no drift:** silent pass.

**Rationale:** Skill registration is a manual step that gets skipped during fast-building phases. Drift accumulates silently until the audit doc becomes fiction. This check is the cheapest place to catch it — right after the work was done, while context is still hot. Precedent: a large multi-week integration effort once let the audit doc drift dozens of skills out of date before a retro finally caught it.

## Phase 2.8 — INBOX Sweep for Session-Generated Files

`Inbox/` is the intentional staging surface for user-review artifacts (manifests, lint reports, triage outputs, research briefs, plans). Skills correctly drop their outputs here. `/session-close` is the chokepoint where those artifacts get **routed to their permanent destination AND linked back to the project/program/area/wiki they relate to** — otherwise INBOX accumulates and the artifacts become unreachable.

### Default posture: route by default, keep-in-INBOX only with reason

Session-generated files should NOT be left in INBOX by default. The default disposition for each file is "route it out with a wikilink back." Only keep a file in INBOX when the user explicitly needs to review it in a dedicated future session AND no brief/MOC/wiki yet exists to link it from.

Per [[Inbox Routing]]: INBOX is an entry point, not a storage tier. Per [[Linking Conventions]] (Hard-Coded Reference Rule): every vault file reference in an active note must be a wikilink. Per [[Compile Convention]]: when the file contains knowledge, propagate it to the relevant wiki pages with provenance.

### 2.8a: List session-generated INBOX files

List the contents of `Inbox/`. For each file, determine whether this session produced it (by mtime against session start, or by file-naming pattern matching the session's work).

### 2.8b: Pending-in-artifact sweep (sub-check)

For each session-generated file in INBOX that looks like a report or manifest (contains sections like `## Consolidated Next Actions`, `## Open Items`, `## Outstanding`, `## Deferred`, `## Follow-ups`, or grep hits for `defer|pending|TODO|not yet|backfill|unresolved`), scan those sections and surface uncaptured follow-up items:

> "⚠ `[[filename]]` contains N uncaptured follow-up items in its `## Consolidated Next Actions` section. Lift them into the project brief (with wikilinks back to source) before archiving? [Y/n]"

If Y: append each item to the active project brief's Next Actions, preserving the wikilink back to the source report. If N: record the decision in the session summary and proceed.

**Evidence:** 2026-04-19 Phase 11 close — 5 deferred items (P7, P8, P9, P10, W1/P6) were buried in the Phase 11 rollup's Consolidated Next Actions section and nearly archived uncaptured. User asked "is there any followup left?" which is the question this check now asks proactively.

### 2.8c: Classify and propose disposition + linking

For each file, first classify by content type, then propose destination + linking:

| Content type | Destination | Linking action |
|---|---|---|
| **Project/program deliverable** (plan, spec, brief, analysis, execution artifact for a specific project) | Project folder (`Projects/<Project>/` or subfolder like `scripts-YYYY-MM-DD/`) OR Program folder | Add wikilink from the project/program brief's Log or Working Notes, pointing to the moved file |
| **Area-level reference** (report, policy, reusable analysis for an Area or Sub-Area) | `Resources/<Area>/` matching the Area MOC's domain | Add wikilink from the Area MOC or relevant sub-area MOC |
| **Wiki-worthy knowledge** (durable insight, pattern, technique, research finding belonging to a domain wiki) | Domain wiki folder under `Resources/<domain>/Wiki/` | Invoke [[Compile Convention]] — propagate findings to relevant wiki pages with provenance; append entry to wiki's `log.md`; preserve source file in wiki-adjacent archive |
| **Unreviewed content** (blog posts, videos, x.com saves not yet processed) | `Hub/READ_REVIEW/` | No linking yet; will be linked when `/read-review` processes it |
| **Operational report / execution log** (one-shot script, backup, lint report post-action, triage post-action) | `{{AGENT_DIR}}/reports/` OR project-adjacent (`Projects/<Project>/scripts-YYYY-MM-DD/`) | Wikilink from the brief's Log entry that references the operation |
| **Archived deliverable** (work that's complete and historically referenced but no longer live) | `Archives/<category>/` | Preserve any existing wikilinks; no new outbound links from archives |
| **Transient artifact** (tmp scratch, debug output, no ongoing reference) | Delete | N/A |
| **Genuinely needs dedicated review** (content the user must read before routing, no brief yet to link from) | Keep in INBOX | Record in session summary with note "needs dedicated review session" |

**Linking is non-optional for routed files.** Moving a file without linking makes it orphan — it passes `ls` but fails `grep -r '[[filename'` across the vault. The artifact exists but no one will rediscover it. If there's no obvious place to link from (no project brief, no MOC, no wiki page), that's a signal the file may belong in "needs dedicated review" — not that linking should be skipped.

Present the plan as a table:

| File | Session-generated? | Pending items? | Content type | Destination | Link from |
|------|-------------------|----------------|--------------|-------------|-----------|
| `plan.md` | ✓ | 3 lifted | Project deliverable | `Projects/Foo/` | `[[Foo Brief]]` Log |
| `triage.md` | ✓ | 0 | Operational report | `{{AGENT_DIR}}/reports/` | `[[Foo Brief]]` Log entry |
| `research.md` | ✓ | 0 | Wiki-worthy | `Resources/<domain>/Wiki/` | Via `/compile` → pages + log.md |

### 2.8d: Execute on approval

Ask the user: "Execute this INBOX disposition plan? [Y / revise / defer]". If Y, execute moves **and the linking actions** in a single pass — a move without its linking action is considered incomplete. If revise, walk through the plan line-by-line. If defer, leave INBOX alone and note in the Phase 2f report.

For each moved file, the session closeout is not complete until both:
1. File has been moved to destination
2. Wikilink to the moved file has been added to the referenced brief / MOC / wiki page (or `/compile` has been invoked for wiki-worthy content)

Verify post-move: a quick `grep` of the moved file's filename across the vault should return at least one wikilink match.

### 2.8e: Report

Include in the Phase 2f extended updates summary:
```
INBOX Sweep:
- N session-generated files identified
- M routed to destinations (per content-type classifier) with wikilinks
- K kept in INBOX (dedicated review pending)
- Q deleted
- R pending items lifted into project brief with source wikilinks
- W wiki pages compiled (if /compile was invoked)
```

### Rules

- Never touch INBOX files this session did NOT generate without explicit user approval — they may be staged by other workflows or earlier sessions.
- Always preserve source wikilinks when lifting items into briefs — future readers need to trace residuals back to their origin report.
- **Always add linking when routing** — per [[Linking Conventions]] Hard-Coded Reference Rule. A routed-but-unlinked file is an orphan.
- **Default to routing, not keeping.** "Keep in INBOX" is the exception, not the norm.
- If the session was purely conversational (no file generation), skip this phase with one-line note: "INBOX Sweep: no session-generated files."

## Phase 3 — Retro Evaluation

Perform a lightweight check to determine if a retrospective would be valuable. Do NOT run a full retro — just evaluate.

### Retro Indicators (check these)

Score the session against these indicators. Each YES adds 1 point:

1. **Milestone completed** — a project milestone was reached or a significant deliverable shipped
2. **Significant failure or pivot** — something broke, a plan changed substantially, or an approach was abandoned
3. **New pattern discovered** — a workflow, convention, or architectural pattern was established that could be reused
4. **Protocol gap** — the session exposed a gap in CLAUDE.md rules, protocols, or decision traces
5. **Multi-session project checkpoint** — this is the 3rd+ session on the same project without a retro
6. **Complex agent work** — the session used agent teams, batch operations, or multi-step workflows that could be optimized
7. **User friction** — there were permission issues, repeated clarifications, or workflow friction worth examining

### Decision Logic

- **0-1 points:** No retro needed. Inform the user: "No retro indicators triggered — skipping."
- **2-3 points:** Suggest retro. Present the triggered indicators and ask: "A lightweight retro could be valuable. Want me to run `/retro`?"
- **4+ points:** Strongly recommend retro. Present the triggered indicators and say: "Multiple retro indicators triggered — I'd strongly recommend running `/retro` before closing out."

### If User Approves

Invoke the `/retro` skill, passing the current session mode (Vault Management or Programming Projects) and any relevant scope hints.

### If User Declines

Acknowledge and close out. The session closeout from Phase 1 is already complete.

## Rules

- Phase 1 follows the session closeout protocol exactly — this skill does not override it
- Phase 2 artifact updates follow vault protection rules — copy to INBOX if modifying canonical files, unless the file is a project brief being updated per closeout protocol
- Phase 2 updates are surgical — only reflect changes from this session, don't reorganize or restructure
- Phase 3 is advisory — the user always decides whether to run a retro
- If no projects were worked on (purely exploratory/conversational session), skip Phase 2 and still run Phase 3
- Present the retro evaluation transparently — show which indicators triggered and which didn't

## Dependencies

### Required

- **shared-node [[people-resolver]]** — resolves names to contact cards silently during Phase 2.4 contact sync (mode: silent). Location: `{{AGENT_DIR}}/skills/_shared/nodes/people-resolver.md`. Fallback via [[Shared Node Bundling]]: `./_bundled/nodes/people-resolver.md`.
- **shared-node [[brief-updater]]** — updates project brief Log + Continuation Prompt during Phase 1 (modes: log-entry, continuation-prompt). Location: `{{AGENT_DIR}}/skills/_shared/nodes/brief-updater.md`. Fallback: `./_bundled/nodes/brief-updater.md`.
- **protocol-doc session-closeout-protocol.md** — defines the canonical session-closeout flow that Phase 1 follows verbatim (brief identification, cross-linking, permission review, lessons log, cross-pollination). Path: `{{AGENT_DIR}}/session-closeout-protocol.md` (or wherever you keep shared protocol docs). For starter-pack members: ship a bundled copy at `./_bundled/protocols/session-closeout-protocol.md`.
- **cli git** — Phase 2.5 Infrastructure Version Control drift detection in the `{{AGENT_DIR}}` repo. Install: pre-installed on macOS, otherwise `xcode-select --install` (macOS) or https://git-scm.com (Windows). Phase 2.5 gracefully skips if no `.git` directory is present (silent skip, not a failure).
- **cli jq** — Phase 1 session-log.ndjson append uses `jq -n` to construct the JSON record. Install: `brew install jq` (macOS), `choco install jq` or `winget install jqlang.jq` (Windows), or https://jqlang.github.io/jq/download/.

### Optional

- **helper-script sync_vault_indexes.sh** — refreshes per-program sub-project indexes + Program Hierarchy dashboard during Phase 2c. Fallback if not available: Phase 2c soft-skips with a printed notice and closeout continues (this script is optional and, if you sync this vault across more than one machine, may only exist on one of them). Location: `{{AGENT_DIR}}/scripts/sync_vault_indexes.sh`.

### Vault Conventions

- Assumes PARA structure in vault root (`Projects/`, `Areas/`, `Resources/`, `Archives/`). See [[Inbox Routing]].
- Assumes [[Brief Template Compliance]] on all project briefs (frontmatter + Outcome + Next Actions + Waiting For + Log).
- Applies [[Inbox Routing]] during Phase 2.8 INBOX sweep.
- Applies [[Linking Conventions]] (Hard-Coded Reference Rule) — every routed file gets a wikilink back from its new home.
- Applies [[Compile Convention]] when Phase 2.8c routes wiki-worthy content to domain wikis.
- Applies [[No One-Off Work]] during Phase 2.7 skill codification scan.

### Does NOT Require

- No MCPs (no Granola, Slack, Google Workspace, or SQL Server calls).
- No desktop apps (no external GUI automation).
- No external services or API keys (no network calls to third parties).
- No Python packages beyond the standard library.
- No plugins (pure skill — no dependencies on `compound-engineering`, `superpowers`, etc.).

## Related Skills
- [[contact-card]] — new people mentioned in session
- [[skill-create]] — recurring pattern detected that should be codified
