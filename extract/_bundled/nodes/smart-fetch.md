---
name: smart-fetch
description: "External-content enrichment with density assessment — fetch thin notes via URL (Twitter via bird + fxtwitter fallback, PDFs via Read), and resolve `![[image.ext]]`/`![[file.pdf]]` vault embeds via Read (multimodal)"
version: 4
---

Assesses note content density against a 500-character threshold and enriches thin notes by (a) fetching external URLs or (b) resolving vault embeds (`![[path.png|jpg|jpeg|webp|pdf]]`) via the multimodal Read tool. Twitter/X links use the bird CLI with fxtwitter fallback. Non-embed PDFs are read locally. Fetch/resolve failures never block processing — the skill continues with available content.

## Core Logic

### Content Density Assessment

Count substantive characters in the note body — exclude YAML frontmatter, tags (`#tag`), and wikilinks (`[[...]]`). If the body has **fewer than 500 characters** of substantive content AND contains a URL or a resolvable vault embed, the note is **thin** and should be enriched. If **500+ characters**, work with note content only (unless the note explicitly says "see link for details" or similar).

### Source Detection Order

Sources are detected in this priority order. First match drives fetch/resolve; additional matches may still be fetched if the mode's step-list calls for it.

1. Frontmatter `source:` or `url:` field
2. Inline markdown links `[text](url)`
3. Bare URLs in the body
4. Trailing `Source:` lines
5. **Vault embeds** — `![[path.(png|jpg|jpeg|webp|pdf)]]` anywhere in the body. Image and PDF embeds are resolvable via the multimodal Read tool. Other embed extensions (`.xlsx`, `.docx`, `.pptx`, `.mp4`, etc.) are detected but NOT resolvable — skip with a notice, don't block. A note that contains BOTH a URL and an image embed is enriched by both in order (URL first, then embed), per the consuming mode's step-list.

### Twitter/X URL Handling — Fallback Chain

X.com and twitter.com URLs require JS rendering and fail via direct WebFetch. Use this fallback chain:

**Step 1 — PRIMARY: bird CLI**

Extract the tweet ID from the URL, then run:
```bash
bunx @steipete/bird read <url> --json
```
- Uses AUTH_TOKEN/CT0 from env vars or `~/.config/last30days/.env`
- Returns: full tweet text (including Notes/Articles), author, date, engagement, quoted tweets, thread context
- If bird fails (no auth, timeout, rate limit, not installed) → fall through to Step 2

**Step 2 — FALLBACK: fxtwitter API proxy**

1. Replace the domain (`x.com` or `twitter.com`) with `api.fxtwitter.com`. Keep the path identical.
2. Strip all query parameters (`?s=12&t=...`).
3. Fetch via WebFetch. Returns structured data: full tweet text, author, date, engagement metrics, quoted tweets, thread content.

Example: `https://x.com/chamath/status/2007151450695037224` becomes `https://api.fxtwitter.com/chamath/status/2007151450695037224`

**Step 3 — LAST RESORT:** If both fail, note the failure and work with available note content. Never block.

**Always fetch tweets even if the note already has some text** — tweets often have quoted tweets, threads, or context not captured in the note.

**See also:** keep your own reliability/runbook note (e.g. in your inbox folder) documenting your Twitter/X auth setup — browser cookie export, token refresh, and any multi-machine configuration — so troubleshooting fetch failures doesn't start from scratch each time.

### PDF Handling

Read PDFs using the Read tool with the `pages` parameter. For large PDFs (>10 pages), read in chunks. If too large to process, note this and recommend the user read it manually.

### Vault Embed Handling

When a thin note contains `![[path.(png|jpg|jpeg|webp|pdf)]]` syntax, resolve the embed to its text/visual content via the Read tool. Read is multimodal — it accepts PNG, JPG, JPEG, WEBP, and PDF paths natively and returns their content for LLM processing.

**Resolution steps:**

1. Extract the path from the `![[...]]` match.
2. **If the path is basename-only** (e.g., `![[chart.png]]` — no `/` separator): Obsidian-style resolution — search the vault for a file with that exact basename under any folder. Prefer the path closest to the note itself. If multiple matches exist, prefer matches under the same wiki or area folder as the note; emit an info line noting the ambiguity.
3. **If the path is directory-prefixed** (e.g., `![[Archives/attachments/Foo.resources/img.png]]`): try literal resolution FIRST — build `{{VAULT_ROOT}}/<literal path>` and check if the file exists. If yes, use it. If no, **fall back to basename search** — extract just the filename (`img.png`) and resolve as in step 2. Matches Obsidian's own renderer behavior when vault restructuring has invalidated path prefixes but files still exist by basename. On a successful fallback, emit an info line: *"Embed path stale — `![[<original path>]]` resolved via basename fallback to `<actual location>`. Source file's embed path needs updating."*
4. Build the absolute vault path from whichever resolution step succeeded and call Read on it.
5. Treat the returned content as "fetched content" for the consuming mode — it feeds the extraction block, the compile pass, or whatever downstream consumer the mode serves.
6. If a note has multiple resolvable embeds, resolve each in document order. Cap at 5 per note to prevent runaway Read calls; note the cap hit if relevant.
7. If BOTH literal and basename resolution fail for a directory-prefixed embed, OR basename returns zero matches for a basename-only embed, treat it as a resolution failure — skip with an info line and continue (never block).

**Non-resolvable embeds:** extensions outside the resolvable set (`.xlsx`, `.docx`, `.pptx`, `.mp4`, `.zip`, etc.) are detected but skipped. Emit a single notice: *"Skipped non-resolvable embed: `![[X.xlsx]]` — Read does not process this format. Consider manual extraction."*

**Embed-only thin notes:** a note with `<500 chars` substantive text and an image/PDF embed but no URL is still thin — the embed is the source. Enrich via embed resolution.

**Mixed notes (URL + embed):** enrich via URL first, then resolve the embed. Both contribute to the extraction. This order matches the precedence in "Source Detection Order" above.

### Failure Handling

If any fetch or embed resolution fails (network error, 404, timeout, missing file, unsupported format), note the failure and work with whatever content exists in the note. **Never block, never retry.**

---

## Modes

### full
**Used by:** inbox-clear, read-review

Fetch/resolve to enrich the note body for classification or review:

1. Read note contents.
2. Assess density (<500 chars substantive content?).
3. If thin AND contains a URL:
   - **Twitter/X URL** — fetch using the Twitter/X Fallback Chain above (bird → fxtwitter → work with content). Always fetch, even if note has some text.
   - **Other URL** — fetch directly via WebFetch. Write a brief summary into the note body, then classify based on enriched content.
4. If thin AND contains `![[path.(png|jpg|jpeg|webp|pdf)]]` vault embeds — resolve each via the Vault Embed Handling protocol above (Read the resolved absolute path). Cap at 5 resolutions per note. Embed content feeds the same enrichment pipeline as fetched URL content.
5. If thin AND URL-only with **no substantive body**:
   - **Twitter/X** — route to READ_REVIEW (do not fetch during inbox-clear; fetch during read-review).
   - **Other** — fetch, enrich, then classify.
6. **Title-only notes** (no body at all) — the title still carries signal. Classify based on the title. Default to READ_REVIEW if uncertain.
7. If 500+ chars — skip fetch, work with note content.

**Raw source preservation:** Consuming skills (e.g., read-review) may preserve the full fetched text as an immutable raw source at the end of the note. The smart-fetch step itself only enriches; the consuming skill decides whether to persist the full response.

### extract
**Used by:** extract

Fetch URL and/or resolve embeds, then produce the full 6-section extraction block:

1. Read note contents.
2. Assess density and fetch URL if thin (same threshold and proxy rules as `full` mode).
3. For tweets: always fetch using the Twitter/X Fallback Chain (bird → fxtwitter), even if note has text.
4. If thin AND the note contains `![[path.(png|jpg|jpeg|webp|pdf)]]` embeds — resolve each via the Vault Embed Handling protocol above. Cap at 5 per note. Extracted content feeds the same extraction block alongside any URL content. A note may be enriched by URL, by embed, or by both; absence of a URL does not disqualify embed-only notes from the thin-note path.
5. Generate the extraction block:
   - **Executive Summary** (3 lines: what, core insight, why it matters)
   - **Key Takeaways** (3-7 items)
   - **Action Items** (concrete, linked to areas/projects)
   - **Vault Connections** (areas, libraries, projects, reference)
   - **Evergreen Extraction Candidates** (atomic insights, omit if none)
   - **Further Reading** (related external resources, omit if none)
6. Insert block at top of note after YAML frontmatter. Preserve all existing content below.
7. Add `extracted: YYYY-MM-DD` to frontmatter.

### check-only
**Used by:** any skill wanting to preview density

Assess density only — no fetching, no mutation:

1. Read note contents.
2. Count substantive characters (excluding frontmatter, tags, wikilinks).
3. Detect URLs (using URL Detection Order).
4. Return structured recommendation:
   - `recommendation`: `fetch` | `skip`
   - `reason`: why (e.g., "Note has 127 chars and contains URL", "Note has 843 chars — sufficient content")
   - `url`: detected URL (if any)
   - `url_type`: `twitter` | `pdf` | `web` | `none`
