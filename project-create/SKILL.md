---
name: project-create
version: "0.3.0"
description: Create a Project or Program brief through research, interactive Q&A, template application, vault linking, and INBOX delivery for review. Projects use a two-phase flow — Phase 1 (Scoping) drafts the brief, Phase 2 (Review & Commit) iterates, then creates a dedicated folder and assigns final status.
user-invocable: true
argument-hint: "note path, note title in INBOX, or topic description"
---
<!-- ported-from: project-create@0.3.8 sha256:60433404dd25 -->

Create a Project Brief or Program Brief through a structured interactive process — research the input, run a guided Q&A to scope the initiative, decide project vs. program, apply the correct template, link to relevant vault notes and external references, and deliver for review.

**Projects follow a two-phase commit:**
- **Phase 1 — Scoping**: research + Q&A + draft brief saved to INBOX. The Continuation Prompt contains the Phase 2 activation text so the flow is resumable across sessions.
- **Phase 2 — Review & Commit**: present the draft, let the user edit or brainstorm further, then on confirmation create a dedicated folder under `Projects/<Brief Name>/`, move the brief into it, and set the final status (active or incubating).

**Programs keep a single-phase flow** — draft, save to their area folder, cross-link.

## Philosophy

Every idea deserves a fair shot at becoming a project — but only after it has been properly scoped. This skill applies the vault's project scaffold requirements: Outcome, Plan with 3-7 milestones, Actions with next 10, Log with proof of motion. If it cannot fit that structure, it belongs in incubation, not active projects.

The skill is conversational — it gathers context through research and Q&A before writing anything. The user drives scope decisions; the AI provides structure, research, and vault connections.

Pipeline: `Input -> Research -> Overlap Route -> Q&A -> Classify -> Template -> Link -> Deliver -> Cross-Link`

## Vault Exception

This skill may:
- Create new files in `Inbox/` — the draft project/program brief and any companion files
- **For Projects only**, during Phase 2 finalization: create a new folder under `Projects/<Brief Name>/` and move the confirmed brief from INBOX into that folder
- Read files anywhere in the vault for research and linking
- **Modify an existing brief during an approved Step 1.5 fold-in** — only the exact additions shown to and confirmed by the user
- **Modify existing vault files for cross-linking** — inserting wikilinks to the new brief into related notes (Step 7). All proposed edits must be listed and confirmed by the user before execution. No other modifications to existing files are permitted.
- **Edit the draft brief in place during Phase 2** — iterative revisions before the user confirms the final version are allowed on the draft file itself.

## Inputs

The user provides one of:
- **Note path** — a full path to an existing note to convert into a project brief
- **Note title** — a filename in `Inbox/` to convert
- **Topic description** — a freeform description of the idea or initiative

If the input is a note, read it first. Its contents become the seed material for research and Q&A. If the note is empty or title-only, use the title as the seed topic.

## Steps — Interactive Conversation

Work through these steps. Pause after each step to get user input before moving on.

### Step 1: Research Phase

**1a — Read the input**
If a note was provided, read its full contents. Extract: topic, any stated goals, people mentioned, areas referenced, existing links.

**1b — Vault search**
Search the vault for related material:
- Grep and Glob across `Projects/`, `Areas/`, `Resources/` for notes matching the topic and related keywords
- Check for existing projects or programs that this initiative might relate to, be a sub-project of, or conflict with
- Find relevant Area MOCs, Programs, and Reference materials
- Look for OKRs, strategic plans, or other planning documents that provide context

**1c — Web research** — only if the topic benefits from external knowledge
Use WebSearch to find:
- Best practices, frameworks, or methodologies relevant to the initiative
- Industry benchmarks or reference points
- Common pitfalls and critical success factors

**1d — Present research findings**
Share a concise summary of what was found — vault connections, relevant context, and external insights. This grounds the Q&A in real context.

### Step 1.5: Overlap Check & Routing Decision (mandatory)

Run this forcing gate immediately after research and before the scoping Q&A. Its purpose is to prevent a duplicate brief from being created when the work belongs under, beside, or inside something that already exists.

**1. Build a candidate shortlist.** From the Step 1 results, identify at most five existing briefs that could plausibly overlap. For each candidate, test these signals:

- The request could be a sub-project of the candidate's outcome.
- The request could be a milestone, workstream, or next action inside the candidate.
- The two outcomes or deliverables substantially overlap.
- Creating a new brief would duplicate ownership, tracking, or source material.

**2. Present the routing comparison.** Show the candidate's name and path, the relationship signal, the expected outcome of each route, and your recommendation. Recommend one of:

- **Sub-project** — distinct outcome and execution track, but governed by an existing parent.
- **Fold into existing** — no independent outcome; the work belongs in an existing brief.
- **Sibling or new brief** — distinct outcome that should coexist with the candidate.
- **Considered but distinct** — apparent overlap was checked and rejected for a specific reason.

**3. Require a routing choice.** Ask the user to choose:

1. Create a new brief.
2. Create it as a sub-project of a named parent.
3. Fold the request into a named existing brief.
4. Defer and leave the input unchanged.

Do not continue to Step 2 until the user chooses.

**4. Execute the chosen route.**

- **New brief** — continue to Step 2. Record the considered candidates and why they were distinct in the draft's Working Notes.
- **Sub-project** — pin the chosen parent for the rest of the flow, continue to Step 2, and ensure the final brief's parent relationship and destination agree with that decision.
- **Fold into existing** — stop the new-brief pipeline. Read the target brief, identify the smallest correct home for the request (`Next Actions`, `Waiting For`, a milestone, Working Notes, or the Sub-Project Index), show the exact proposed additions, and edit only after approval. Add a Log row recording the fold-in and source. Preserve, archive, or relocate the original input note only as the user explicitly directs; never silently delete it. Report the updated brief and terminate.
- **Defer** — leave the input unchanged, report the candidate routes considered, and terminate.

**Red flags that favor fold-in or sub-project routing:**

| Signal | Default response |
|---|---|
| Same owner, outcome, and milestone horizon as an active brief | Fold into that brief |
| Independent deliverable but governed by an existing program or project | Create as a sub-project |
| Same topic but different outcome, owner, or lifecycle | Create a sibling/new brief and record why |
| Unsure which existing brief owns it | Defer and ask; do not create a duplicate by default |

### Step 2: Phase 1 — Scoping Q&A

> **Projects:** this is the first of two phases. Phase 1 scopes the brief; Phase 2 (Step 6) reviews and commits it.
> **Programs:** single phase — the answers collected here flow directly into Steps 4 and 5.

Run an adaptive Q&A to fill in all sections of the brief. Use AskUserQuestion with well-informed options based on Step 1 research.

**Core questions to cover** — adapt phrasing and options based on the specific topic:

1. **Trigger and motivation** — What triggered this? Pain points, strategic alignment, or opportunity?
2. **Outcome** — What does "done" look like? One sentence. If the user struggles, propose 2-3 options based on research.
3. **Duration and lifecycle** — Is this something that will be actively managed for more than 12 months, or does it have a concrete completion point?
4. **Scope** — How big is this? Focused project or phased rollout?
5. **Owner and champion** — Who drives this on the ground?
6. **Timeline** — What is the target timeline for the first milestone?
7. **Dependencies** — What must be true or in place before this can start?
8. **Budget and resources** — Is there budget? What resources are needed?
9. **Prior work** — Has anything been done before? What exists already?
10. **Risks** — What could derail this? What are the top 2-3 risks?
11. **Success metrics** — How will you measure success? What KPIs matter?
12. **AI-specific instructions** *(optional — skip if none)* — Are there project-unique AI rules not already covered by the area CLAUDE.md? Examples: terminology/glossary, specific tools or MCPs to always use, process conventions (e.g., "always run `/deep-research` before proposing"). If yes, capture them; they will land under `### AI Context` inside Working Notes. If "no" or "covered at area level", skip — do not create an empty section.

Not all questions apply to every project. Skip questions that are irrelevant or already answered by the input note. Add topic-specific questions based on the research phase findings.

**Batch questions where possible** — use AskUserQuestion with up to 4 questions per call to keep the conversation efficient. Group related questions together.

### Step 3: Project vs. Program Decision

Based on the scoping answers, recommend whether this should be a **Project** or a **Program**.

**Primary test — duration-based classification:**

> "Will this be actively managed >12 months from now?"
> - **YES → PROGRAM** (lives in `Areas/`, `category: program`)
> - **NO → PROJECT** (lives in `Projects/`, `category: project`)

**Supporting criteria** — use these to reinforce or challenge the duration test:
- Does it have 3+ distinct workstreams that could each be a project? → leans Program
- Does it need a sub-project index? → leans Program
- Can one person own and execute it? → leans Project
- Is it a strategic initiative spanning multiple areas? → leans Program

Present the recommendation with reasoning. Let the user decide.

### Step 4: Build the Draft Brief

Apply the correct template based on the decision. For **Projects**, the Continuation Prompt section is populated with the Phase 2 activation text (see 4a below) instead of the standard empty handoff template.

**For Projects** — use the Project Brief Template structure:
```
Frontmatter: description, AREA, SUB-AREA, category: project, status (active|delegated|incubating|blocked|someday-maybe), tags, owner: "[[Name]]", parent: "[[Program]]" (required — must point to a program), depends_on (array of wikilinks), feeds (array of wikilinks), learns_from (array of wikilinks)
H2 Outcome — one sentence blockquote
H2 Why This Matters — success stakes, failure stakes
H2 Continuation Prompt — empty template for session handoffs
H2 Next Actions — concrete next steps from Q&A
H2 Waiting For — items from other people
H2 Dependencies — human-readable list of dependencies with wikilinks and descriptions
H2 AI Ecosystem — Feeds Into (table), Learns From (table)
H2 Key Resources — Evergreen Notes, Reference Materials, People/Collaborators
H2 Working Notes — research findings, frameworks, context from Q&A
H2 Plan with Milestones table — 3-7 milestones with targets
H2 Log — creation entry
```

**For Programs** — use the Program Template structure:
```
Frontmatter: description, AREA, SUB-AREA, category: program, status, review_cadence, tags, owner: "[[Name]]", parent: "[[Parent Program]]" (optional — only for sub-programs), depends_on (array of wikilinks), feeds (array of wikilinks), learns_from (array of wikilinks)
H1 Title
H2 Outcome — one paragraph blockquote
H2 Why This Matters — success stakes, failure stakes
H2 Sub-Project Index — table: #, Sub-Project (wikilink embedded in name), Status, Description
H2 Continuation Prompt — empty template
H2 Next Actions
H2 Dependencies — human-readable list of dependencies with wikilinks and descriptions
H2 AI Ecosystem — Feeds Into (table), Learns From (table)
H2 Waiting For
H2 Key Resources — Evergreen Notes, Reference Materials, People/Collaborators
H2 Working Notes
H2 Plan with Milestones table
H2 Log
```

**Content quality standards:**
- Outcome must be one sentence for projects, one paragraph for programs — concrete and measurable
- Why This Matters must connect to real stakes — strategic plans, OKRs, business impact
- Next Actions must be concrete and actionable — no vague "research X" without specifying what to research and where
- Working Notes contain research findings, frameworks, and context gathered during the process — the institutional memory. When a project has AI-specific instructions that aren't already covered by area-level CLAUDE.md (project-unique terminology, tool preferences, process conventions), add them under an `### AI Context` H3 subsection. Do not duplicate area-level rules here — those auto-load via the CLAUDE.md chain.
- Key Resources must include actual vault wikilinks found during research, not empty placeholders
- Milestones should be 3-7, each with a target date or timeframe
- Tags should include the area, topic keywords, and any relevant programs
- Key Resources subsections are: **Evergreen Notes** (distilled insights), **Reference Materials** (source docs, links), **People / Collaborators**. Never use "Atomic Notes" — the vault term is Evergreen Notes.
- **Table wikilink convention:** Embed `[[wikilinks]]` directly in the name/title column of tables — never use a separate "Link" column. Applies to Sub-Project Index, Milestones, AI Ecosystem tables, and any other table with named entities.

**4a — Phase 2 Activation block (Projects only)**

For projects, populate the `## Continuation Prompt` section with this activation text (substitute `<Brief Name>` with the actual filename stem). Do **not** use the standard empty handoff template — that is only restored after Phase 2 finalizes in Step 6.

```markdown
## Continuation Prompt

> **Status: DRAFT — Phase 2 pending**
> **Created by:** `/project-create`
> **Phase 1 complete:** research, scoping Q&A, and draft brief written.
>
> **To activate Phase 2, paste the following to Claude Code:**
>
> ```
> Resume /project-create Phase 2 for [[<Brief Name>]].
>
> 1. Read the current draft brief.
> 2. Present a concise summary of each H2 section and ask me:
>    "Is there anything else about this project brief you'd like to edit or brainstorm before committing?"
> 3. If I want to iterate — help me revise sections in place (surgical edits on the draft file).
>    Loop the question until I explicitly confirm the final version.
> 4. When I confirm:
>    a. Ask me for the final status via AskUserQuestion — choices: `active` | `incubating`.
>    b. Create the folder `Projects/<Brief Name>/` (exact filename stem, no extension).
>    c. Move the brief from `Inbox/` into that folder.
>    d. Update the `status:` frontmatter field to my choice.
>    e. Replace this Continuation Prompt block with the standard empty handoff template.
>    f. Run the Cross-Link Scan (Step 7 of the `/project-create` skill).
> 5. Report final location, status, and cross-links applied.
> ```
```

While in DRAFT state, set `status: incubating` in frontmatter as a safe default — it will be overwritten in Step 6.

### Step 5: Deliver Draft

**5a — Insert vault links**
For every vault note identified as relevant in Step 1, insert proper `[[wikilinks]]` in the appropriate section — Key Resources for reference materials, Working Notes for context, Dependencies for blockers.

**5b — Insert external references**
For any external resources found in web research, add as markdown links in Key Resources or Working Notes.

**5c — Save the draft**

- **Projects:** save to `Inbox/<Brief Name>.md` with `status: incubating` and the Phase 2 activation Continuation Prompt from Step 4a. Do **not** create the `Projects/<Brief Name>/` folder yet — that happens in Step 6 after the user confirms the final version.
- **Programs:** save to `Inbox/<Brief Name>.md` for review (single-phase flow). The user will move it to `Areas/AREA_FOLDER/` after approving.

**5d — Present summary**
Tell the user:
- Where the draft was saved
- What vault notes were linked
- For projects: that the brief is in DRAFT state and Phase 2 (review & commit) is next — you will proceed immediately to Step 6 in the current session, but if the session ends, the Continuation Prompt can resume Phase 2 in a new session.
- For programs: the recommended destination folder under `Areas/` — remind the user to move the file there after review.
- Any open questions or items flagged for their attention

### Step 6: Phase 2 — Review & Commit (Projects only)

> **Programs skip this step** and proceed directly to Step 7 (Cross-Link Scan). The user moves a program brief manually to its area folder.

This is the commit phase. The draft brief is already on disk in `Inbox/`. Now walk the user through final review, iterate as needed, then physically commit the project by creating its folder, moving the brief into it, and setting the final status.

**6a — Present the draft for review**

Summarize the draft concisely:
- Title and one-line outcome
- Area / sub-area / parent program
- Planned milestones (count + first target)
- Key dependencies and waiting-for items
- Notable gaps or sections flagged during Step 1-5 as "needs user input"

Then ask explicitly:

> **"Is there anything else about this project brief you'd like to edit or brainstorm before committing?"**

**6b — Iterate until confirmed**

If the user wants changes:
- Make surgical edits to the draft file in place (section-level, not full rewrites)
- For bigger brainstorms (e.g., scope expansion, new milestones, risk reassessment), run mini-Q&A via AskUserQuestion and then apply the results
- After each edit cycle, re-summarize what changed and repeat the question in 6a

Loop until the user gives an explicit confirmation — wording like "commit it", "that's final", "good to go", "ship it", or equivalent. **Do not assume confirmation from silence or an ambiguous response** — ask again.

**6c — Ask for final status**

Use AskUserQuestion with exactly two choices:
- `active` — starting work now; counts toward the 7-project WIP cap
- `incubating` — committed to the project, but not starting work this week

Do not offer `delegated`, `blocked`, or `someday-maybe` here — those are edge cases that should be set manually later if relevant.

**6d — Create folder and move the brief**

Execute in order:
1. Create the folder `Projects/<Brief Name>/` (use the exact filename stem, no `.md` extension).
2. Move the brief file from `Inbox/<Brief Name>.md` to `Projects/<Brief Name>/<Brief Name>.md` (prefer `mv` via Bash to preserve timestamps).
3. Update the `status:` frontmatter field in the moved file to the user's choice (`active` or `incubating`).
4. Replace the Phase 2 activation Continuation Prompt block with the standard empty handoff template:
   ```markdown
   ## Continuation Prompt

   > **Date:**
   > **Mode:**
   > **Context:**
   >
   > **Resume from:**
   > **Key decisions this session:**
   > **Blockers/open questions:**
   > **Files touched:**
   ```
5. Add a Log entry for commit: `| <today> | Milestone | Project created and committed via /project-create (status: <active|incubating>) |`

**6e — Confirm commit**

Report to the user:
- Final path: `Projects/<Brief Name>/<Brief Name>.md`
- Final status
- Folder created: yes
- Ready to run Step 7 (Cross-Link Scan)

### Step 7: Cross-Link Scan

**This step is mandatory.** After the brief is committed (projects) or saved to INBOX (programs), run a comprehensive cross-link scan to strengthen the knowledge graph bidirectionally.

**7a — Comprehensive vault scan**
Search across all active vault areas for notes related to the new brief's topic, area, and keywords:
- `Projects/` — sibling projects, sub-projects of the same parent program, projects with overlapping dependencies or feeds
- `Areas/` — Area MOCs, parent program brief, sibling programs, related programs in adjacent areas
- `Resources/` — reference notes, reading notes, templates, and guides related to the topic
- `Inbox/` — other INBOX items that relate

For each candidate note, check both:
- **Frontmatter relationships** — `depends_on`, `feeds`, `learns_from`, `parent` fields that should reference the new brief
- **Body content** — sections like Key Resources, Working Notes, Sub-Project Index, or Related Notes where a wikilink to the new brief would add value

**7b — Build cross-link manifest**
Compile a list of proposed edits, organized by note. For each proposed edit, specify:
- The **target file** path and name
- The **section** where the link should be inserted
- The **link type** — is this a frontmatter relationship (e.g., adding to `depends_on` array) or a body wikilink?
- **Why** — a brief justification for why this link adds value (semantic relationship: supports, depends on, feeds into, sibling of, etc.)

Also identify any **frontmatter relationship updates** needed on the new brief itself (e.g., if the scan reveals a `depends_on` or `feeds` relationship that wasn't captured during Steps 1-5).

**7c — Present manifest for user approval**
Display the full cross-link manifest to the user. Group edits by target file. Include a count of total proposed edits and affected files. The user may:
- Approve all
- Approve selectively (remove specific edits)
- Skip the cross-linking entirely

**7d — Execute approved edits**
For each approved edit:
- Read the target file
- Insert the wikilink in the specified section, matching existing formatting
- For frontmatter array fields, append the new wikilink to the existing array
- For body sections, add the wikilink in the most natural position (e.g., as a new list item, table row, or inline reference)
- Preserve all existing content — surgical insertion only

If the scan also identified updates needed on the new brief itself, apply those as well (updating the brief at its current location — `Projects/<Brief Name>/<Brief Name>.md` for committed projects, or `Inbox/<Brief Name>.md` for programs awaiting manual placement).

**7e — Report results**
Summarize what was linked:
- Number of files updated
- Total wikilinks inserted
- Any edits that failed (e.g., file structure was unexpected) with explanation
- The new brief's updated graph connections

## Rules

- Pause after each major step to get user input — this is a conversation, not a monologue
- Use AskUserQuestion for structured choices — batch up to 4 questions per call
- Only include vault notes that are clearly relevant — when in doubt, leave it out
- Use exact note names without .md extension inside wikilinks
- Do not modify existing vault files except during Step 1.5 (an approved fold-in), Step 6 (Phase 2 commit — moving the draft from INBOX to `Projects/<Brief Name>/`), and Step 7 (Cross-Link Scan — approved wikilink insertions). Draft-brief edits during Phase 2 iteration target only the draft file itself.
- Avoid empty placeholder wikilinks — omit sections with no content rather than leaving blanks
- Web research is optional — skip it for purely internal/organizational projects where external knowledge adds nothing
- If the input note already contains substantial content, pre-fill Q&A answers from it and confirm with the user rather than re-asking
- The vault working directory is resolved at runtime from the CLAUDE.md chain
- **Projects created by this skill go into their own dedicated folder:** `Projects/<Brief Name>/<Brief Name>.md`. The folder is created in Step 6 after the user confirms the final version in Phase 2. Status is tracked via the `status:` frontmatter field.
- **Sibling skill coordination:** When modifying this skill's output convention (folder structure, filename pattern, frontmatter fields, required/optional sections, Continuation Prompt format), update sibling auditor skills in the same change. **Current downstream auditors that must be kept in sync:** `/clean-projects` (audits `Projects/` layout and template compliance). Before finalizing edits here, grep the auditor's SKILL.md for the changed convention and confirm it handles both old and new behavior during any transition. Evidence: a prior session showed the folder-wrapped convention landing in `/project-create` weeks before `/clean-projects` was updated; the drift had to be caught manually.
- Phase 2 restricts status choice to `active` or `incubating`. Other values (`delegated`, `blocked`, `someday-maybe`) can be set manually later if the project's state changes.
- Programs go to `Areas/` under the relevant area folder — saved to INBOX, then moved manually by the user (no two-phase flow, no folder creation).
- Project Briefs always include: Outcome, Why This Matters, Continuation Prompt, Next Actions, Waiting For, Dependencies, Key Resources, Working Notes, Plan with Milestones, Log
- Program Briefs always include: Outcome, Why This Matters, Sub-Project Index, Continuation Prompt, Next Actions, Waiting For, Key Resources, Working Notes, Plan with Milestones, Log
- Never place Learning Programs or area-level concerns as projects — those have their own skill or template
- Log format: one item per row with Date, Type, and Update columns. Type is Task or Milestone.
- Waiting For: only items from other people or agents. Self-tasks go in Next Actions.
- All typed relationships go in YAML frontmatter as wikilinks per vault root CLAUDE.md Graph-Ready Conventions. Use `owner: "[[Name]]"`, `parent: "[[Program]]"`, and arrays for `depends_on`, `feeds`, `learns_from`. No inline Dataview fields in the body. Dependencies and AI Ecosystem sections contain human-readable context only (lists, tables, descriptions).
- **AREA is required** and must be a wikilink to a known area. The vault has area categories (folder groupings) and areas (the actual entities). Never put a category in the AREA field.
  - Valid AREA values are the actual Area/Program entities that live in your own vault's `Areas/` folder — not a hardcoded list. Examples of the kind of entity this means: `[[Health]]`, `[[Family]]`, `[[A Learning Program]]`, `[[A Mastermind Group]]`, `[[Mentoring]]`, `[[Your Company]]`, `[[A Client Or Side Venture]]`, `[[Your Legal Entity]]`, `[[Wealth Management]]`, `[[AI & Software]]`, `[[A Creative Project]]`, `[[Writing]]`, `[[Personal]]`. Build the real list by listing your own `Areas/` folder before running this skill.
  - **Invalid** (these are categories, not areas): top-level category groupings such as `[[Community]]`, `[[Business]]`, `[[Creative]]` — a category folder groups several areas together but is never itself a valid AREA value.
  - To determine the correct AREA, find where the parent program lives in `Areas/` — the area-level folder/MOC is the AREA.
- **SUB-AREA** is optional. If present, it must be a wikilink. Only use when there's a meaningful subdivision within the AREA.
- **priority** must be one of: `critical`, `high`, `standard`, `low`. Default to `standard` if not specified.

## Dependencies

### Required

- Nothing beyond Claude Code's built-in tools (Read, Write, Edit, Glob, Grep, Bash for `mv`, WebSearch, WebFetch, AskUserQuestion). This skill does research, runs Q&A, writes briefs, and updates cross-links — all via built-ins.

### Optional

- **WebSearch / WebFetch** — used in Step 1c for external research on industry/domain topics. Fallback if the user declines web research (purely internal projects): skip Step 1c and proceed with vault-only context. Both are Claude Code built-ins; no external API keys required.

### Vault Conventions

- Applies [[Inbox Routing]] — drafts land in `Inbox/` before the Phase 2 commit moves Projects to `Projects/<Brief Name>/`.
- Applies [[Brief Template Compliance]] — Projects and Programs must include required sections (Outcome, Why This Matters, Next Actions, Waiting For, Log, etc.).
- Applies [[Linking Conventions]] (Hard-Coded Reference Rule) — all note references in the brief and all cross-link edits use `[[wikilinks]]`.
- Applies [[Graph-Ready Conventions]] — frontmatter relationships (`depends_on`, `feeds`, `learns_from`, `parent`, `owner`) are wikilink arrays, never inline Dataview.
- Applies [[Dual-Hierarchy Model]] — Step 3 project-vs-program classification uses the >12-month duration test.
- Assumes PARA structure for vault search in Steps 1b and 7a (`Projects/`, `Areas/`, `Resources/`, `Inbox/`).
- Sibling-skill rule: updates to the output convention (folder layout, frontmatter fields, Continuation Prompt format) must be mirrored in the `/clean-projects` auditor — see Rules section.

### Does NOT Require

- No MCPs (no Granola, Slack, Google Workspace, SQL Server, etc.).
- No CLIs (no gws, gh, accli).
- No desktop apps.
- No external services or API keys.
- No Python or Node packages.
- No plugins.

## Related Skills
- [[decision-brief]] — when the project has open architectural decisions that need structured analysis before implementation
- [[clean-projects]] — downstream auditor that must stay in sync with this skill's output convention (see Rules)
