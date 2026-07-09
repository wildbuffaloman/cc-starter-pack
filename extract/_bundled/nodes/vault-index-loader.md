---
name: vault-index-loader
description: "Pre-load vault index of projects, areas, libraries, reference subfolders, wiki indexes, and evergreen notes for agent injection"
version: 4
---

Builds a structured vault index before agent spawning so each sub-agent can classify, route, link, and match knowledge graph connections without redundant vault searches. Four modes control scope and detail depending on the calling skill's needs.

## Configuration — set these for your vault

This node assumes a PARA-style vault (Projects / Areas / Resources / Archives, plus an inbox). Everything below refers to the placeholders in this table, never to a hardcoded path — set each one to match your own vault's folder names before running:

| Placeholder | Purpose | Example value (plain PARA vault) |
|---|---|---|
| `{{PROJECTS_DIR}}` | Root folder for project/program briefs | `Projects/` |
| `{{PROJECTS_ACTIVE_DIR}}` | Active-projects subfolder | `Projects/Active/` |
| `{{PROJECTS_INCUBATING_DIR}}` | Incubating / not-yet-active projects subfolder | `Projects/Incubating/` |
| `{{PROJECTS_SOMEDAY_DIR}}` | Someday/maybe idea backlog subfolder | `Projects/Someday-Maybe/` |
| `{{AREAS_DIR}}` | Root folder for ongoing areas and programs | `Areas/` |
| `{{RESOURCES_DIR}}` | Root folder for reference material | `Resources/` |
| `{{ARCHIVES_DIR}}` | Root folder for archived material | `Archives/` |
| `{{HUB_DIR}}` | Index/dashboard folder (holds your inbox and any working-notes areas) | `Hub/` |
| `{{INBOX_DIR}}` | Capture inbox for new/unsorted notes | `Hub/Inbox/` |
| `{{REFERENCE_SUBFOLDERS}}` | Flat list of your Resources top-level subfolder names | see Category 4 below |

Some PARA vaults sort their top-level folders with numeric prefixes (e.g. a `Projects/` folder that's actually named `1 Projects/`, or an inbox nested a couple of levels under a numbered hub folder) — if yours does, just fill the placeholder with your vault's literal folder name, prefix and all. If your vault is flatter than the table above — one `Projects/` folder with no Active/Incubating/Someday staging — point `{{PROJECTS_ACTIVE_DIR}}`, `{{PROJECTS_INCUBATING_DIR}}`, and `{{PROJECTS_SOMEDAY_DIR}}` all at `{{PROJECTS_DIR}}` itself and glob it once instead of splitting by subfolder. The category-numbering logic below is unaffected either way.

## Core Logic

### Index Building

1. **Projects** — Glob `{{VAULT_ROOT}}/{{PROJECTS_ACTIVE_DIR}}/*.md` and `{{VAULT_ROOT}}/{{PROJECTS_INCUBATING_DIR}}/*.md`. Read each file's YAML frontmatter. Extract: filename (without `.md`), `status`, `description`.
2. **Areas** — Glob `{{VAULT_ROOT}}/{{AREAS_DIR}}/**/*.md` where frontmatter `category:` is `area` or `program`. Extract: filename, `category`.
3. **Libraries** — Glob `{{VAULT_ROOT}}/{{AREAS_DIR}}/**/*.md` where frontmatter `category:` is `library` or `learning-program`. Extract: filename.
4. **Reference subfolders** — Return your vault's top-level subfolder names under `{{RESOURCES_DIR}}` (no file reads needed — either list directory names live, or maintain `{{REFERENCE_SUBFOLDERS}}` as a fixed list if your taxonomy rarely changes). This repo's reference vault uses 14 subfolders as an example — replace with your own:
   `AI & SOFTWARE`, `BUSINESS`, `CHECKLISTS & TEMPLATES`, `CREATIVE`, `EDUCATION`, `HEALTH`, `IMPORTANT DOCS`, `INVESTING & FINANCE`, `JOURNAL`, `MUSIC`, `PERSONAL`, `READING NOTES`, `TRAVEL`, `WISDOM & PHILOSOPHY`
   The count and labels are entirely vault-specific — do not treat this list as canonical for a vault that isn't the one it was written against.
5. **Evergreen WIP** — Glob `{{VAULT_ROOT}}/{{HUB_DIR}}/Evergreen WIP/*.md`. Extract: filename (without `.md`). Skip this category entirely if your vault has no separate "evergreen notes in progress" folder.
6. **Someday-Maybe** — Glob `{{VAULT_ROOT}}/{{PROJECTS_SOMEDAY_DIR}}/*.md`. Extract: filename (without `.md`), `description`.
7. **Wiki Indexes** — Glob `{{VAULT_ROOT}}/{{RESOURCES_DIR}}/**/Wiki/Wiki Index — *.md` (default location) AND `{{VAULT_ROOT}}/{{AREAS_DIR}}/**/Wiki/Wiki Index — *.md` (exception location, per [[Wiki Page Convention]]). Also include any file whose frontmatter `category:` is `wiki-index`. For each:
   - Extract: wiki path, wiki filename, domain (from frontmatter `domain:` wikilink target, falling back to the parent folder name)
   - Read the `## Page Registry` section — parse table rows, collect every `[[Page Name]]` from the **Page** column (normalize `[[Target|alias]]` → `Target`, strip `#anchor` fragments)
   - Emit a flat deduplicated list of pages per wiki. Page Registry is the single ground-truth table — adapt if your own wiki pages use a different registry format.

### Output Format

Return as structured text block for injection into agent spawn prompts:

```
VAULT INDEX ({{MODE}})
PROJECTS:
- [[Project Name]] | status: active | desc: one-line description
AREAS:
- [[Area Name]] (area)
- [[Program Name]] (program)
LIBRARIES:
- [[Library Name]]
REFERENCE SUBFOLDERS:
AI & SOFTWARE, BUSINESS, CHECKLISTS & TEMPLATES, CREATIVE, EDUCATION, HEALTH, IMPORTANT DOCS, INVESTING & FINANCE, JOURNAL, MUSIC, PERSONAL, READING NOTES, TRAVEL, WISDOM & PHILOSOPHY
EVERGREEN WIP:
- [[Evergreen Title]]
SOMEDAY-MAYBE:
- [[Idea Name]] | desc: one-line description
WIKI INDEXES:
- [[Wiki Index — Agentic AI]] | domain: Agentic AI | path: {{RESOURCES_DIR}}/AI & SOFTWARE/AI/AGENTIC AI/Wiki/ | pages: [[Agent Architecture Fundamentals]], [[Agent Design Patterns]], [[Multi-Agent Systems]], ...
- [[Wiki Index — Claude Code]] | domain: Claude Code | path: {{RESOURCES_DIR}}/AI & SOFTWARE/AI/VIBE CODING/CLAUDE CODE/Wiki/ | pages: [[CLAUDE.md Architecture]], [[Agent Loop & Tool Design]], [[Skills & Hooks]], ...
- [[Wiki Index — Wealth Management]] | domain: Wealth Management | path: {{RESOURCES_DIR}}/INVESTING & FINANCE/WEALTH MANAGEMENT/Wiki/ | cross_area: true | types: concept, framework, playbook, principle, book-note | pages: (Phase 3 compile pending — evergreen investing/estate/tax/insurance concepts)
- [[Wiki Index — Investing]] *(planned)* | domain: Investing | path: TBD (likely {{RESOURCES_DIR}}/INVESTING & FINANCE/INVESTING/Wiki/) | types: thesis | seed content: {{AREAS_DIR}}/BUSINESS/INVESTING/_pending-investing-wiki/ (3 thesis pages)
```

---

## Modes

### full
**Used by:** inbox-clear, read-review
**Categories:** 1-6 (all)

Build the complete index. For projects: path + status + description. For areas/libraries/evergreens: name. For someday-maybe: name + description. Include all of your `{{REFERENCE_SUBFOLDERS}}` names. This gives classification agents maximum context for routing decisions.

### projects-only
**Used by:** compile, reminders-sync
**Categories:** 1-2 (projects + areas)

Projects with status + `description:` frontmatter field for semantic matching against note content. Areas with category label. Skip libraries, reference subfolders, evergreens, and someday-maybe. Used when the agent needs to classify items against existing briefs rather than route to vault destinations.

### minimal
**Used by:** extract
**Categories:** 1-2 (projects + areas)

Names only — no descriptions, no status. Just a flat list of project and area names for wikilink matching. Fastest to build, smallest injection footprint.

### wikis
**Used by:** clean-reference (1f connectivity audit), compile (discovery mode), wiki-create (pre-check for existing wikis), wiki-lint (cross-wiki overlap scans)
**Categories:** 7 (wiki indexes only)

Enumerate every Wiki Index in the vault with its parsed page roster. Default glob targets `{{RESOURCES_DIR}}/**/Wiki/Wiki Index — *.md` — the canonical location per [[Wiki Page Convention]]. Also include the exception path `{{AREAS_DIR}}/**/Wiki/Wiki Index — *.md` for wikis that need to live alongside an Area MOC. For each wiki, emit the path, domain, and a flat deduplicated list of pages drawn from the single `## Page Registry` table (columns: Page · Type · Summary · Sources · Last Updated). Used when a calling skill needs to compute page-overlap between a reference note and existing knowledge domains — the Page Registry is the ground truth for "what does this wiki cover." Do not combine with `full` unless the calling skill needs both indexes; loading wikis alone is the cheapest path for connectivity audits.

### wiki-index
**Used by:** wiki-query (enumerate all Wiki Index files + their folders, with full Page Registry detail per wiki)
**Categories:** 7 (wiki indexes only) — structured per-page output

Load every Wiki Index in the vault and return the full Page Registry as structured data (not just page names). This is the heavier counterpart to `wikis` mode: where `wikis` returns a flat deduplicated name list for overlap scans, `wiki-index` returns each row of each wiki's `## Page Registry` table so the calling skill can rank candidate pages, read their frontmatter, and cite them.

**Discovery globs (same as `wikis` mode):**
- Canonical: `{{VAULT_ROOT}}/{{RESOURCES_DIR}}/**/Wiki/Wiki Index — *.md`
- Exception: `{{VAULT_ROOT}}/{{AREAS_DIR}}/**/Wiki/Wiki Index — *.md`
- Fallback by frontmatter: any file whose frontmatter `category:` is `wiki-index`

**Per-wiki extraction:**
1. Read the Wiki Index file. Extract frontmatter: `domain:` (wikilink or string), `created:`, `last_updated:`, `status:`.
2. Parse the `## Page Registry` table. Expected columns (per [[Wiki Page Convention]]): **Page · Type · Summary · Sources · Last Updated**. Skip empty rows, separator rows (`---`), and header rows.
3. For each row, capture:
   - `page` — the wikilink target (normalize `[[Target|alias]]` → `Target`, strip `#anchor` fragments)
   - `type` — page-type label (e.g., `concept`, `entity`, `pattern`, `position-thesis` — vocabulary is wiki-specific, do not enforce a closed set)
   - `summary` — short description text from the Summary column
   - `sources` — count or list of `[[Source Note]]` wikilinks referenced in the Sources column
   - `last_updated` — date string from the Last Updated column (ISO or human format, pass through as-is)
4. Also capture the wiki folder path (parent of the Wiki Index file) so the calling skill can glob sibling pages and the per-wiki `CLAUDE.md`.

**Output format:**

```
WIKI INDEXES (wiki-index mode)

## Wiki: [[Wiki Index — <Domain>]]
- folder: {{RESOURCES_DIR}}/<path>/Wiki/
- domain: <Domain>
- last_updated: 2026-04-11
- per_wiki_claude_md: Wiki/CLAUDE.md (present | missing)
- page_count: N

| Page | Type | Summary | Sources | Last Updated |
|------|------|---------|---------|--------------|
| [[Page Name]] | concept | One-line summary | 3 | 2026-04-10 |
| [[Other Page]] | entity | Another summary | 1 | 2026-03-28 |
...
```

Emit one block per wiki. If the Page Registry is missing, empty, or malformed, emit the wiki header with `page_count: 0` and a `warn:` line explaining why — do not abort the whole scan. If multiple Wiki Index files live in the same folder (shouldn't happen), emit each separately and flag as a lint concern.

**When to use this instead of `wikis`:** choose `wiki-index` when the calling skill needs to read individual page frontmatter, rank candidates by type, or cite pages with their declared type. Choose `wikis` when all you need is a flat list of page names for overlap/connectivity math. Loading `wiki-index` is strictly more expensive — skip if `wikis` suffices.
