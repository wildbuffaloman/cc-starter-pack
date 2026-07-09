---
name: skill-create
version: "0.0.1"
description: Create a new Claude Code skill — guided conversation to define the skill's purpose, triggers, steps, and rules, then generate and install the SKILL.md file.
user-invocable: true
argument-hint: "skill name or description of what the skill should do"
---

Create a new Claude Code custom skill through a guided interactive process — define its purpose, invocation pattern, steps, and rules, then generate and install the SKILL.md file into `~/.claude/skills/`.

## Philosophy

Skills are reusable prompt templates that encode repeatable workflows. A good skill is focused (one job), conversational where needed, and self-contained (all instructions in SKILL.md). This skill helps the user design and install new skills without needing to know the SKILL.md format.

## Inputs

The user provides one of:
- **Skill name** — a short kebab-case name (e.g., `code-review`)
- **Description** — a freeform description of what the skill should do
- **Both** — name + description together

## Steps

### Step 1: Understand the Skill

If the user gave only a name or vague description, ask clarifying questions:

1. **What does the skill do?** — One-sentence summary of the workflow it automates.
2. **When should it trigger?** — Is it user-invocable (called via `/skill-name`)? Or should it trigger automatically based on context? What argument does it take?
3. **What tools does it need?** — Does it read/write files, search the web, call APIs, use MCP tools, run shell commands?
4. **Is it interactive?** — Does it need user input during execution, or is it fully automated?
5. **What are the outputs?** — What does the skill produce? Files, messages, terminal output?

Skip questions already answered by the user's input. Batch related questions together.

### Step 2: Research Existing Skills

Scan `~/.claude/skills/` to:
- Check if a skill with the same or similar name already exists (warn if so)
- Find skills with similar patterns that can serve as structural templates
- Read 1-2 relevant existing SKILL.md files to match the user's established conventions

Present findings briefly — existing conflicts, suggested structural patterns.

### Step 3: Design the Skill

Based on the answers, draft the skill design and present it to the user for approval:

- **Name** (kebab-case)
- **Description** (one sentence for the frontmatter)
- **User-invocable** (true/false)
- **Argument hint** (if user-invocable)
- **Steps outline** — numbered list of what the skill does
- **Rules** — constraints and guardrails
- **Vault exception** (if it needs to create/modify files outside normal boundaries)

Ask the user to confirm or adjust before generating.

### Step 4: Generate SKILL.md

Write the full SKILL.md file following this structure:

```markdown
---
name: <kebab-case-name>
version: "0.0.1"
description: <one-sentence description for skill list>
user-invocable: <true|false>
argument-hint: "<hint text>" # only if user-invocable
---

<Opening paragraph — what the skill does and why>

## Philosophy (optional — include if the skill embodies a non-obvious approach)

## Inputs (if applicable)

## Steps

### Step N: Title
<Instructions for each step>

## Rules
<Bullet list of constraints>

## Dependencies

### Required
<!-- Tools/nodes the skill cannot function without. Use canonical category labels
     from [[Skill Dependencies Declaration]]: plugin, mcp, cli, desktop-app,
     python-package, node-package, external-service, shared-node, helper-script,
     protocol-doc, vault-convention. Include a one-line install pointer for each. -->
- **[category] [name]** — [one-line purpose]. Install: [brew/pip/URL/vault-path].

### Optional
<!-- Tools that enhance functionality but have explicit fallback behavior.
     Declare the fallback so the skill degrades predictably. -->
- **[category] [name]** — [what it adds]. Fallback if unavailable: [what happens instead]. Install: [how].

### Vault Conventions
<!-- Named conventions referenced as [[wikilinks]], PARA assumptions, etc.
     Write "None." if the skill is vault-agnostic. -->
- Follows [[Convention Name]].
- Assumes PARA structure (`Projects/`, `Areas/`, etc.).

### Does NOT Require
<!-- Explicit anti-dependencies — useful when users might assume a dep exists.
     Lists what the skill intentionally avoids, not just what it happens to lack. -->
- No MCPs (no Granola, Slack, Google Workspace, SQL Server).
- No desktop apps, no API keys, no Python/Node packages.
- No network calls beyond Claude Code built-ins (if applicable).
```

**Fill every subsection — don't leave comments or placeholders in the final output.** Run a pass checking each `[category]`, `[name]`, `[one-line purpose]` was replaced with real content. If the skill has no deps in a given subsection, write "None." — don't omit the subsection.

**Conventions to follow:**
- Match the tone and depth of the user's existing skills
- Use imperative voice in steps ("Read the file", not "The file should be read")
- Steps that need user input should use AskUserQuestion
- Reference tools by their actual names (Read, Write, Edit, Glob, Grep, Bash, Agent, WebSearch, etc.)
- Keep rules actionable and specific — no vague "be careful" statements
- If the skill interacts with the Obsidian vault, include a Vault Exception section specifying what it may read/write/modify

### Step 5: Evaluate Skill Graph Architecture

Before installing, check if this skill should be a **skill graph** instead of a flat SKILL.md.

**Threshold check:**
- If the generated SKILL.md is ≤400 lines → **stay flat.** Skip to Step 6.
- If the generated SKILL.md is 400-500 lines AND shares capabilities with ≥2 existing skills → **consider graph.**
- If the generated SKILL.md is >500 lines → **recommend graph.**

**When to recommend a graph:**
- The skill has distinct phases or capabilities that can be loaded selectively
- The skill spawns multiple agents with different prompts
- The skill shares scanner/processing logic with other skills (check `_shared/nodes/`)
- A partial run (e.g., "just do X, skip Y") would benefit from loading fewer nodes

**Shared node check (always, even for flat skills):**
Before writing the SKILL.md, scan `_shared/README.md` for existing shared capabilities the new skill could reference instead of reimplementing. Current catalog includes: [[people-resolver]], [[smart-fetch]], [[brief-updater]], [[vault-index-loader]], [[compile-check]], [[gws-subprocess]], [[gmail-ops]], [[staleness-detector]], [[convention-self-check]], [[research-cache]], plus 5 scanner nodes (calendar-pull, vault-project-scan, trello-scan, slack-scan, reminders-scan). If the new skill duplicates logic from a shared node, reference the node instead.

**If graph is recommended:**

1. **Design the graph structure:**
   - SKILL.md becomes a graph index (≤150 lines): frontmatter with `type: skill-graph`, traversal instructions, capabilities table, phase overview, rules
   - Create `nodes/` directory for local capability files (100-300 lines each, self-contained)
   - Reference existing `~/.claude/skills/_shared/nodes/` for shared capabilities (calendar-pull, vault-project-scan, trello-scan, slack-scan, reminders-scan)
   - Inline anything under 80 lines in the index

2. **Graph index frontmatter:**
   ```yaml
   ---
   name: skill-name
   description: "..."
   user-invocable: true
   type: skill-graph
   max_nodes: N
   ---
   ```

3. **Node frontmatter:**
   ```yaml
   ---
   name: node-name
   description: "one-line description"
   version: 1
   ---
   ```

4. **Required sections in graph index:**
   - `## Traversal Instructions` — batch Read guidance, partial run examples
   - `## Capabilities` — table mapping nodes to paths and when-needed conditions
   - Traversal Responsibility rule: "Main agent reads nodes. Subagents receive injected content."

5. **Present the graph design** to the user for approval before writing files.

**Reference implementations:** `~/.claude/skills/weekly-review/` (6 nodes), `~/.claude/skills/close-day/` (3 nodes + 5 shared), `~/.claude/skills/startup-day/` (4 nodes + 5 shared).

### Step 5b: Wire Into the Ecosystem

Every new skill should declare its connections to the skill ecosystem.

1. **Dependencies check:** Read `_shared/README.md` for the capability catalog. For each shared capability the new skill uses, add a `## Dependencies` section:
   ```markdown
   ## Dependencies
   Shared capabilities from `_shared/nodes/` (resolve via `{{VAULT_ROOT}}/.claude/skills/_shared/nodes/{name}.md` — or wherever your tool-managed skills folder lives):
   - [[shared-node-name]] — mode: {mode}
   ```

2. **Related skills check:** Identify existing skills that complement this new skill — skills that the agent should suggest during execution when certain conditions are met. Add:
   ```markdown
   ## Related Skills
   - [[skill-name]] — {when to suggest: discovery trigger}
   ```

3. **Shared node candidate check:** If the new skill introduces logic that 2+ existing skills would also benefit from, propose extracting it as a new `_shared/nodes/` file with modes. Only extract if concrete reuse exists — not speculatively.

4. **Bidirectional linking:** If the new skill should be a Related Skill of an existing skill, update that skill's `## Related Skills` too.

### Step 6: Determine Recurring Cadence & Embedding

After generating the SKILL.md, assess whether this skill should be embedded in a recurring skill. See [[No One-Off Work]].

1. **Cadence check:** Ask "Does this skill need to run on a recurring schedule, or is it purely on-demand?"
   - If purely on-demand → skip to Step 6
   - If recurring → continue

2. **Identify the host:** Based on the cadence, identify the appropriate recurring skill:

   | Cadence | Host Skill |
   |---------|-----------|
   | Per-session | `/session-close` |
   | Daily morning | `/startup-day` |
   | Daily evening | `/close-day` |
   | Weekly | `/weekly-review` |
   | Monthly | `/monthly-review` |
   | Quarterly | `/quarterly-review` |

3. **Read the host skill:** Read the host skill's SKILL.md to understand its phase structure and find the right insertion point.

4. **Present embedding proposal:** Show the user:
   - Which host skill will invoke the new skill
   - At which phase/step it will be invoked
   - What constrained mode applies (if any — e.g., `/close-day` sub-skills run in constrained modes)
   - Whether it should auto-invoke or be trigger-based

5. **If approved:**
   - Add a `## Recurring Invocation` section to the new skill's SKILL.md:
     ```
     ## Recurring Invocation

     This skill is invoked by `/<host-skill>` during <phase/step>.
     Mode: <constrained mode description or "full">
     Trigger: <always | condition-based with description>
     ```
   - Edit the host skill's SKILL.md to add the invocation step at the appropriate location

6. **MECE verification:** Before proceeding, confirm that no existing skill already handles this work. If overlap is found, recommend extending the existing skill instead of creating a new one.

### Step 7: Install

1. Create the directory `~/.claude/skills/<skill-name>/`
2. If graph: also create `~/.claude/skills/<skill-name>/nodes/`
3. Write the SKILL.md file (and node files if graph)
4. Confirm installation and show the invocation command (`/<skill-name>`)
5. If the skill description should appear in the system prompt's skill list, remind the user to restart Claude Code for it to take effect

## Rules

- Skill names must be kebab-case, lowercase, no spaces
- Never overwrite an existing skill without explicit user confirmation
- The generated SKILL.md must be self-contained — no external dependencies beyond standard Claude Code tools and MCP servers the user already has configured
- If the user wants to edit an existing skill, read it first and use Edit instead of Write
- Keep generated skills concise — prefer clarity over exhaustiveness
- Do not add steps or complexity the user did not ask for
- Match the conventions observed in the user's existing skills (frontmatter format, section naming, depth of instructions)
- Before installing any new skill, check whether an existing skill already covers the same work type (MECE ownership per [[No One-Off Work]]). Prefer extending an existing skill over creating a new one.
- If a skill is intended to run on a recurring cadence, it MUST be embedded in the appropriate recurring host skill — do not create a skill that requires the user to remember to invoke it manually on a schedule
- Every generated SKILL.md must include a `## Dependencies` section per [[Skill Dependencies Declaration]] (4 subsections: Required / Optional / Vault Conventions / Does NOT Require). The Step 4 SKILL.md template must be updated to emit this section as a required placeholder, not an optional one.

## Dependencies

### Required

- Nothing beyond Claude Code's built-in tools (Read, Write, Edit, Glob, Grep). This skill scans `~/.claude/skills/` and writes new skill directories; no external deps.

### Optional

- **helper-script _shared/README.md** — catalog of shared-node capabilities in `{{VAULT_ROOT}}/.claude/skills/_shared/README.md` (or wherever your tool-managed skills folder lives). Used in Step 5 to suggest reusable shared nodes before generating new logic. Fallback if missing: Step 5 can scan `_shared/nodes/*.md` filenames directly and still complete. Category-stretch note: this is a markdown README, not a script.

### Vault Conventions

- Must emit `## Dependencies` section per [[Skill Dependencies Declaration]] in every generated SKILL.md.
- Applies [[Skill Graph Structure]] for the ≤400 / 400-500 / >500 line thresholds and the graph-recommend logic in Step 5.
- Applies [[No One-Off Work]] for the MECE coverage check in Step 7 and the recurring-cadence embedding in Step 6.
- Applies [[Linking Conventions]] — shared-node references and Related Skills use wikilinks.

### Does NOT Require

- No MCPs (no Granola, Slack, Google Workspace, etc.).
- No CLIs (no gws, gh, accli).
- No desktop apps.
- No external services or API keys.
- No Python or Node packages.
- No plugins.
