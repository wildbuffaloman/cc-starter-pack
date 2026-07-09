---
name: retro
description: Run a retrospective — routes to the correct protocol based on session mode and review scope
user-invocable: true
argument-hint: "optional: project name, or review scope for vault management — weekly, monthly, quarterly, annual"
---

Run a retrospective on the current session or project.

## Mode Detection

Determine which mode this session is operating in:

1. **Programming Projects** — session is working on code or a specific programming project
2. **Vault Management** — session is doing vault organization, reviews, or CLAUDE.md maintenance
3. **Both** — skill-building sessions or mixed-mode work — run both protocols sequentially

If unclear, ask the user which mode applies.

**Tie-breaker for technical-but-vault-centric sessions:** If the session wrote code/scripts BUT the primary artifacts were vault briefs or Google Sheet state (via gws / Apps Script / sheet formulas), classify as **Vault Management**. Programming Projects mode is reserved for work inside a tracked git repo with its own build/test/commit cycle. Evidence: a session that wrote several Python scripts, but every script was a one-shot gws executor against a Sheet — the artifact was the Sheet + project brief, not a codebase. Vault Management was the correct routing.

## Protocol Routing

Read and follow the corresponding protocol from the vault:

| Mode | Protocol File |
|------|---------------|
| Programming Projects | `{{VAULT_ROOT}}/{{PROTOCOL_DIR}}/retrospective-protocol.md` |
| Vault Management | `{{VAULT_ROOT}}/{{PROTOCOL_DIR}}/vault-self-improvement-protocol.md` |

`{{PROTOCOL_DIR}}` is wherever your vault keeps canonical Claude Code protocol docs (e.g. a `.claude/` folder or a dedicated "AI tooling" folder). If your vault doesn't have this structure, use the bundled copies in `_bundled/protocols/` instead — see the Vault Conventions section below.

## Steps

1. Detect or confirm the session mode
2. If an argument was provided, use it to scope the retro:
   - A project name scopes to that programming project
   - A review scope — weekly, monthly, quarterly, annual — sets the vault management retro depth per its scope table
3. Read the corresponding protocol file
4. Follow the protocol steps exactly as written — the protocol is the source of truth
5. If running both protocols, do Programming Projects first, then Vault Management. Carry cross-pollination findings from one into the other.

## Rules

- Always get explicit user confirmation before applying any changes — per both protocols
- This skill only routes to the protocol — never override or skip protocol steps
- For vault management retros without an explicit scope argument, default to weekly — the lightest touch
- Do not modify any files until the user approves specific proposals

## Dependencies

### Required

- **protocol-doc retrospective-protocol.md** — prescribes retro steps for Programming Projects mode (loaded at runtime and followed verbatim). Path: `{{VAULT_ROOT}}/{{PROTOCOL_DIR}}/retrospective-protocol.md`.
- **protocol-doc vault-self-improvement-protocol.md** — prescribes retro steps for Vault Management mode (loaded at runtime and followed verbatim). Path: `{{VAULT_ROOT}}/{{PROTOCOL_DIR}}/vault-self-improvement-protocol.md`.

### Optional

- None.

### Vault Conventions

- Assumes PARA structure for vault-management retros (scans `Projects/`, `Areas/`, etc.). See your vault's inbox-routing conventions, if any.
- Both protocol files are vault-resident in the author's original setup. For starter-pack members who don't have that particular vault layout, the protocols must be bundled with the skill (see `_bundled/protocols/`) or the target vault must contain them at the expected `{{PROTOCOL_DIR}}` path — otherwise the skill cannot route successfully.

### Does NOT Require

- No MCPs, CLIs, desktop apps, external services, Python/Node packages, shared-nodes, or plugins.
- No network calls.

### Convention Note

- Uses the `protocol-doc` category from the Skill Dependencies Declaration convention (see this repo's README, under "Dependencies Convention"), added specifically to cover markdown protocol documents loaded at runtime. This skill's two Required entries were the surfacing case for the category.
