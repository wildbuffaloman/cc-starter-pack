---
name: people-resolver
description: "Resolve person names to contact records via Vault Contacts, Slack MCP, Google Contacts, and web research — single source of truth for people resolution across all skills"
version: 1
---

Resolves person references (names, emails, @-mentions) to structured contact records by cascading through available data sources. Adapts per mode from fast vault-only lookup to full multi-source enrichment. Vault Contacts table is the canonical source of truth.

## Core Logic

### Vault Contacts Loading

Read `{{VAULT_ROOT}}/Resources/IMPORTANT DOCS/Vault Contacts.md`. Parse the markdown table into a lookup keyed by Name. Fields: Name, Last Name, AREA, SUB-AREA, Email, Follows Up Via, Slack Display Name, Slack User ID, Links. Matching: case-insensitive on `Name`, `Name LastName`, `Slack Display Name`, or Email. Strip `[[`/`]]` wikilink brackets before comparing.

### Resolution Chain

```
1. Vault Contacts.md → match by Name/LastName/Email (case-insensitive)
2. Slack MCP → mcp__claude_ai_Slack__slack_search_users by display name
3. Slack MCP → mcp__claude_ai_Slack__slack_search_users by email
4. Google Contacts → gws people people searchContacts across configured accounts
5. Unresolved → flag for user or queue for later handling
```

Not every mode runs all steps. See mode sections below.

### Save-Back

When resolution discovers new data (Slack User ID, email, display name), update or append a row in Vault Contacts. Only modes that explicitly enable save-back perform writes.

---

## Modes

### full
**Used by:** followup, meeting-agenda

Full Vault Contacts + Slack chain with save-back enabled.

1. Load Vault Contacts lookup table.
2. For each person:
   a. Match in lookup table. If found:
      - Check `Follows Up Via`. If populated, **redirect**: resolve the proxy person instead. Note redirect (e.g., "Redirected from @Jane Doe").
      - If `Slack User ID` present → resolved.
   b. No Slack User ID or not found → call `mcp__claude_ai_Slack__slack_search_users` with display name.
      - 1 result → resolved, save Slack User ID + Display Name to Vault Contacts.
      - Multiple → present candidates for user disambiguation, save chosen.
      - 0 results → continue.
   c. If Email known → call `mcp__claude_ai_Slack__slack_search_users` with email. Save back if resolved.
   d. Still unresolved → flag for user to assign manually.
3. **Save-back:** Write new Slack User IDs, Display Names, emails to Vault Contacts. Append rows for new people.

**Meeting-agenda variant:** Input is calendar attendees (name + email from `gws calendar events list`). Before Slack, try Google Contacts:
```python
subprocess.run(['gws', 'people', 'people', 'searchContacts', '--params', json.dumps({
    "query": "<attendee name>", "readMask": "names,emailAddresses,organizations"
})], capture_output=True, text=True)
```
Include organization/role if returned. Fall back to Vault Contacts. Leave email empty if neither source has it.

---

### lookup-only
**Used by:** email-triage, blind-spot-scan, program-setup

Vault Contacts lookup only. No MCP calls. No save-back. No prompts. Fast path.

1. Load Vault Contacts lookup table.
2. Match each name (case-insensitive on Name, Name LastName, Slack Display Name, or Email).
3. Return all matched fields: Name, Last Name, AREA, SUB-AREA, Email, Follows Up Via, Slack Display Name, Slack User ID, Links.
4. No match → return `null`. Do not attempt external lookups, flag, or prompt.

---

### silent
**Used by:** session-close

Background resolution. No user interaction except Quick Add confirmation. Scans session for people, cross-references contacts, queues updates.

1. Scan session conversation for people mentioned by name with new facts (roles, emails, companies, project involvement), meeting attendees from agendas/minutes, and negotiation counterparts.

2. For each person:
   a. Check `{{VAULT_ROOT}}/Resources/COMMUNITY/CONTACTS/` for existing contact card.
   b. Check Vault Contacts table for matching row.
   c. Categorize:
      - **Existing + new info** → queue Silent Update (run `/contact-card` Silent Update, no confirmation needed)
      - **New priority** (a work stakeholder, project collaborator, negotiation counterpart, community/cohort member, recurring attendee) → queue Quick Add. Prompt: "New contacts this session: {list}. Create quick contact cards? [Y/n]"
      - **New non-priority** → skip

3. Check touched contacts for thin profiles worth enriching:
   - `quick-add` tag stubs, cards with <3 body sections, missing key fields session context could fill
   - If found, suggest `/contact-card enrich` for each.

4. **Save-back:** Silent Updates and Quick Adds write to both contact card file and Vault Contacts table row.

---

### enrich
**Used by:** contact-card

Most comprehensive mode. Vault Contacts + Google Contacts multi-account + vault mentions scan + optional web/LinkedIn research.

1. **Vault Contacts lookup** — match by name/email (see Core Logic). Extract all fields as baseline. If no match, flag for addition.

2. **Google Contacts multi-account search:**
```python
import subprocess, json, os

accounts = [
    ("you@work-example.com", {"GOOGLE_WORKSPACE_CLI_CONFIG_DIR": os.path.expanduser("~/.config/gws-work")}),
    ("you@gmail-example.com", {"GOOGLE_WORKSPACE_CLI_CONFIG_DIR": os.path.expanduser("~/.config/gws-personal")}),
]

for label, extra_env in accounts:
    env = {**os.environ, **extra_env}
    result = subprocess.run(
        ["gws", "people", "people", "searchContacts",
         "--params", json.dumps({
             "query": "PERSON_NAME",
             "readMask": "names,emailAddresses,organizations,phoneNumbers,biographies,urls"
         })],
        capture_output=True, text=True, env=env
    )
```
Extract: full name, email addresses, organizations (company + title), phone numbers, biographies, URLs. Merge results across accounts — deduplicate by email address. If no results by full name, retry with first name only, then by email if known.

3. **Vault mentions scan** — Grep across the vault for the person's name, email, and Slack display name:
   - Search locations in priority order: `Areas/`, `Projects/`, `Hub/`, `Resources/`
   - Exclude: `node_modules/`, `.next/`, `Archives/` (include archives only if fewer than 5 hits elsewhere)
   - Cap at 20 most relevant mentions (prioritize by recency and depth)
   - Categorize each mention: meeting minutes, project briefs, program files, agendas, other
   - Build a list of `[[wikilinks]]` to notes that mention this person, organized by category

4. **Web/LinkedIn research** (optional) — launch a research agent (sonnet model) to search LinkedIn, publications, company pages, and social media. In enrich mode, ask the user: "Run deep background research? [Y/n]". If yes, run synchronously and wait for results.

5. **Save-back:** Update Vault Contacts row with any newly discovered fields. If person was not in Vault Contacts, add a new row.
