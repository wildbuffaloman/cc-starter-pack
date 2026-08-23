---
name: inbox-clear
version: "0.0.1"
description: "Clear your inbox folder using the GTD decision tree — classify every item, propose a destination for each, and execute only what you approve. Two-phase: a read-only classification pass writes a manifest of checkbox decisions, then an execution pass acts on the boxes you tick. Use when the user says 'clear the inbox', 'inbox triage', 'process my inbox', or '/inbox-clear'."
user-invocable: true
argument-hint: "optional filename to process a single note, or no argument to clear the whole inbox"
---
<!-- ported-from: inbox-clear@0.13.0 sha256:db7711e04245 -->

Clear your inbox folder using GTD methodology — classify every item, propose concrete actions, and execute after your approval.

## Philosophy

Inbox zero is the goal. Every item exits the inbox — promoted, routed, merged, or deleted.

Pipeline: `Capture → Classify → Promote / Route / Merge / Read-Review`

Core principles:

- **Action-oriented.** Classify, then execute. No item stays in the inbox after processing.
- **Two-phase safety.** Phase 1 is strictly read-only: it classifies and writes a manifest. Phase 2 acts, and only on the checkboxes you ticked. Nothing moves before you approve it.
- **Preserve by default.** If it is in the inbox, there is something to extract — even a title carries signal. Never default to DELETE. Route to read-review when uncertain.
- **No autonomous deletion.** A real delete happens only when you explicitly approve it for a specific item. The default safe landing for ambiguous, thin, or low-context notes is ROUTE TO READ-REVIEW.
- **Opt-in execution, per decision.** Every decision is its own checkbox — the move, each extracted task, each frontmatter change. An unticked line does not happen. There is no "approve all."
- **Explicit routing invariant.** Every classified item MUST name where the source file ends up. No disposition may leave a file in limbo. **"Report only" is not a valid routing** — if you extract a task, the source file still needs its own destination.
- **Single-appearance invariant.** Each inbox file appears in exactly one decision block, with all of its decisions as child lines. A file is never split across sections, so you never have to approve the same thing twice.

## Inputs

- **No argument** — full inbox clear. Classifies everything, writes a manifest, executes after approval.
- **A filename** — single-note mode. Classifies one note interactively.

## Folder Assumptions

This skill assumes a PARA-style vault. Adjust these paths to your own structure — they are referenced throughout:

| Role | Default path |
|---|---|
| Inbox (source) | `00 INBOX/` |
| Projects | `01 PROJECTS/` |
| Areas | `02 AREAS/` |
| Reference | `03 REFERENCE/` |
| Deeper-review queue | `00 READ_REVIEW/` |
| Archive / recoverable trash | `04 ARCHIVES/` |

If your vault uses different names, ask the user once at the start and use theirs for the whole run.

## Move Safety — read this before writing ANY file-move code

> **If your vault is not git-tracked, a lost file is lost forever.**

A bare `mv` into a directory that does not exist yet **does not fail**. POSIX `mv` treats the missing final component as a *destination filename*:

```bash
$ mv "note.md" "04 ARCHIVES/trash/2026-08-23"   # dated dir does NOT exist
$ echo $?
0        # ← "success". note.md is now an extensionless FILE named 2026-08-23.
$ mv "note2.md" "04 ARCHIVES/trash/2026-08-23"  # next move
         # ← CLOBBERS it. note.md's content is now UNRECOVERABLE.
```

The move reports success, the file vanishes from your vault app, and a report can cheerfully print a rollback command for a path that never existed. **The failure is invisible — that is what makes it dangerous.**

Three layers, all mandatory on every move this skill performs:

| Layer | Guarantee | How |
|---|---|---|
| **L1 — create the parent first** | The destination directory exists before the move. Necessary, but **not sufficient alone**. | `mkdir -p "$(dirname "$DST")"` |
| **L2 — verify after** | Prove the bytes arrived and the source is gone. **A move you cannot prove is a hard error.** | `[ -f "$DST" ]` and compare `shasum -a 256` against the pre-move hash |
| **L3 — never overwrite** | If anything already exists at the destination, refuse and hold the item. | `mv -n`, then confirm the source is actually gone — `mv -n` exits 0 even when it declines |

Always give `mv` a **full destination path including the filename**, never a bare directory — that is precisely the trap above.

> **Never report a move you did not verify.** Only a move confirmed present at its destination may appear as completed in the execution report. Do not print a size, a hash, or a rollback command computed from what you *intended* to do — read them back from the destination *after* the move, or omit them. A report that fabricates evidence is worse than one that admits an error, because it looks more trustworthy than reality.

## GTD Decision Tree

For each inbox item:

```
1. READ the item.
   Non-markdown files (PDF, image, spreadsheet) and folders have no frontmatter —
   fall through to content and filename heuristics. Classify a folder as ONE unit;
   never decompose its contents.

2. CHECK FRONTMATTER STATUS (if present, and if your vault uses one).
   • An in-progress status (draft / open / stub / in-progress) → the item STAYS.
     This is the only KEEP.
   • A finished status (done / executed / closed / published / superseded)
     → it is finished and belongs in its permanent home, not the inbox. Route it.
   • No status → fall through to the content heuristics below.

3. CONTRADICTION TIEBREAK — when the body disagrees with the status, surface BOTH.
   A status field is authored by hand and goes stale. If frontmatter says in-progress
   but the body plainly reads finished (a DONE/COMPLETE heading, a fully-ticked
   checklist, a closing summary) — or the reverse — do NOT silently trust the
   frontmatter. Emit one row naming both readings and the disposition each implies:
     "frontmatter says draft → STAYS · body reads COMPLETE → would archive. Which?"
   Rationale: silently trusting a stale status is what parks a finished note in the
   inbox forever, and it is invisible because "it stayed" looks like normal operation.

4. DEDUP — search the vault for notes covering the same ground.

5. CLASSIFY:
   a. Is it actionable?
      YES:
        - What is the next action?
        - Belongs to an existing project? → LINK TO PROJECT + extract the task
        - A new project seed?            → SPAWN PROJECT (skeleton brief)
        - Belongs to an area?            → ROUTE TO AREA
        - A standalone task?             → EXTRACT TASK **+ a routing for the source**
      NO:
        - Reference material?            → ROUTE TO REFERENCE (name the subfolder)
        - An atomic, reusable insight?   → EXTRACT EVERGREEN + route the source
        - A someday-maybe idea?          → ROUTE TO SOMEDAY-MAYBE
        - Thin, ambiguous, or unclear?   → ROUTE TO READ-REVIEW

6. FIND CONNECTIONS — related projects, areas, and notes worth wikilinking.

7. ASSIGN CONFIDENCE — HIGH / MEDIUM / LOW.

8. CONFIDENCE GATE — if confidence is LOW, override the disposition to
   ROUTE TO READ-REVIEW, reason "insufficient info — deferred for a deeper pass."
   Every item either gets a confident disposition or it goes to read-review.

9. RESOLVE THE SOURCE DESTINATION — every item MUST end at a real path (or an
   explicit DELETE). Task-extraction dispositions are always compound:
   the task goes somewhere AND the file goes somewhere.
```

## Dispositions

> **Routing invariant:** every disposition produces an explicit destination for the source file, or an explicit `DELETE`. "Report only" is never valid.

| Disposition | Source file destination | What happens |
|---|---|---|
| ROUTE TO REFERENCE | `03 REFERENCE/<subfolder>/` | Move the file |
| ROUTE TO AREA | `02 AREAS/<area>/` | Move the file |
| ROUTE TO SOMEDAY-MAYBE | your someday-maybe folder | Move the file |
| LINK TO PROJECT | `03 REFERENCE/<subfolder>/` or the project's own resources folder | Move the file, add a wikilink to the project brief, write the task into its next-actions section |
| SPAWN PROJECT | `01 PROJECTS/<new project>/` | Create a skeleton brief (`/project-create` if you have it), move the source in as context |
| EXTRACT EVERGREEN | a real reference/area destination — **still required** | Create the evergreen note; the source is a compound disposition and needs its own routing |
| EXTRACT TASK + *(secondary)* | **must pick one:** reference · area · read-review · someday-maybe · `DELETE` (only for an empty shell whose title IS the action) | Task written to the target brief; source routed or deleted per your choice |
| ROUTE TO READ-REVIEW | `00 READ_REVIEW/` | Move for a deeper pass — the default safe landing |
| MERGE | `00 READ_REVIEW/` (the original) | Unique content appended to the target note; original kept for post-merge verification |
| DELETE | removed | **Only** on explicit approval, or a 0-byte shell whose task was already extracted. Never proposed on its own for a file with content. |

### Confidence scoring

- **HIGH** — clear classification, obvious destination, no ambiguity.
- **MEDIUM** — reasonable guess, one or two plausible destinations.
- **LOW** — needs your judgment. Routes to read-review by the gate above.

## Phase 1 — Classify and Propose (read-only)

1. List every top-level entry in the inbox — **all file types, plus folders**, not just markdown.
2. Run the GTD tree on each.
3. Write the manifest to the inbox as `YYYY-MM-DD-inbox-manifest.md`.
4. **Change nothing else.** Phase 1 never moves, edits, or deletes a file.

> **Never claim what you did not read.** If you classified from a filename and frontmatter without opening the body, you may not propose DELETE or MERGE on a suspected duplicate (a title match is a hypothesis *about* content, not a reading of it — a "duplicate" is sometimes a superset, and deleting it destroys the only complete copy). Neither may you emit a confidently-targeted task. Say what you actually inspected, and propose the weaker, reversible disposition instead.

> **Redact secrets.** If an item contains a credential-shaped token — an API key, a private key, a password — write `«REDACTED»` in the manifest instead of the value, and flag the item. A manifest is a new file: quoting a live secret into it multiplies the exposure, and if the source is later archived the manifest becomes the surviving copy.

### Manifest structure

```markdown
# Inbox Clearance Manifest — YYYY-MM-DD

Items: N · Mode: full | single-note

## Summary
Brief prose: what is here, what patterns showed up, anything needing your judgment.

## Questions
Anything ambiguous enough that a wrong guess would be costly.

## How to Approve
Tick `[x]` on every line you approve, then tell me to execute.
Untick or delete a line to reject it. An unticked line does NOT happen.

## Decisions — one block per item

### [[Note Title]]
- [ ] **ROUTE TO REFERENCE** → `03 REFERENCE/AI/Note Title.md` · confidence: HIGH
  - [ ] task: "Draft the follow-up" → [[Some Project]]
  - [ ] frontmatter: set `category: reference`
  - ℹ️ evidence: mentions X, connects to [[Other Note]]
```

## Phase 2 — Execute (after approval)

1. **Re-check every ticked item still exists** at the path the manifest recorded. Files move between passes. If it is gone, or has already been filed somewhere sensible that is *not* the approved destination, **report it — do not execute.** Honoring a stale row would move a correctly-filed note back out of its home.
2. Execute each ticked line, using the three move-safety layers on every move.
3. **Deletes come last**, only for explicitly-approved items, and only after the manifest is saved.
4. Write an execution report: files moved, tasks created, files deleted, files skipped, and every error.
5. Move the completed manifest out of the inbox — it is an inbox item too.

## Rules

- **Phase 1 never writes.** Classification is read-only, full stop.
- **Phase 2 acts only on ticked boxes.** No autonomous "approve all". An unmarked manifest moves nothing.
- **Every move uses all three safety layers.** `mkdir -p` first, verify after, never overwrite. A bare `mv` to a bare directory is a defect.
- **Never report an unverified move.** Only a move you confirmed at its destination may be reported as done.
- **Explicit routing invariant.** Every ticked disposition names a real destination or an explicit DELETE. Halt and report if a ticked line lacks one.
- **Default safe landing is read-review** for anything thin, ambiguous, or low-confidence.
- **DELETE requires explicit approval** — never proposed alone for a file with content.
- **Preserve by default.** When torn between two dispositions, pick the one that moves the note out of the inbox soonest without losing information.
- **Use wikilinks** for note references, without the `.md` extension.
- **Filenames with spaces, emoji, or accents** — always quote paths; never build a command by string concatenation.

## Dependencies

### Required

- Nothing beyond Claude Code's built-in tools (Read, Write, Edit, Glob, Grep, Bash for `mv` / `mkdir` / `shasum`). This skill reads notes, writes a manifest, and moves files — all via built-ins.

### Optional

- **WebFetch** — to enrich a thin capture that is mostly a bare URL before classifying it. If unavailable, classify from the title and route ambiguous items to read-review.

### Vault Conventions

- Assumes a **PARA-style** structure (see § Folder Assumptions) — inbox, projects, areas, reference. Ask once and adapt if the user's vault differs.
- Assumes new notes land in an inbox folder rather than at the vault root.
- Uses `[[wikilinks]]` for all note references.

### Does NOT Require

- No MCPs.
- No CLIs beyond standard POSIX tools.
- No external services or API keys.
- No Python or Node packages.
- No plugins.
- No git — and note that if your vault is *not* git-tracked, the move-safety rules above are the only protection you have.

