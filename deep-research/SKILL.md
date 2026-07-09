---
name: deep-research
version: "0.0.1"
description: "Two-phase deep research pipeline: broad sweep + synthesis into structured brief with sources, confidence levels, and recommendations."
user-invocable: true
argument-hint: "<research topic or question>"
---

## Automation-Layer Alternative

If you also run a separate, cost-optimized automation pipeline outside Claude Code (e.g. a lighter-weight multi-agent runtime) for routine research, use that path for standard tasks and reserve this Claude Code skill for cases where:
- Data sensitivity requires Claude-only processing throughout
- The research needs deeper reasoning than a lighter-weight pipeline provides
- You explicitly invoke `/deep-research` from Claude Code

If you don't run a separate automation layer, ignore this section — this skill is fully self-sufficient on its own.

---

Systematic research pipeline for major decisions. Performs a broad research sweep (Phase 1), targeted deep dives to fill gaps (Phase 2), then synthesizes findings into a structured research brief with confidence-graded findings, sourced claims, and actionable recommendations.

## Philosophy

Good decisions require good information, but raw information is not insight. This skill separates research from analysis: first cast a wide net, then go deep on what matters, then synthesize into a brief that makes the decision easier. Every finding carries a confidence level because knowing what you don't know is as important as knowing what you do.

The pipeline supports two modes: (a) the user provides Gemini Deep Research output for Phase 1, giving Claude Code a rich corpus to refine, or (b) Claude Code performs its own broad research sweep as a fallback. Either way, Phase 2 onward is where the real value lives — targeted investigation, cross-referencing, contradiction detection, and structured synthesis.

## Vault Exception

This skill may:
- **Read** files anywhere in your notes/knowledge base for context (project briefs, decision traces, market research, financial data)
- **Create** the finalized brief in `Inbox/Research - <Topic> - YYYY-MM-DD.md`

This skill may NOT:
- Modify existing files
- Create files outside `Inbox/`

## Security Note

If the research topic involves S1 data (personal financial details, strategic plans, credentials), do NOT use Gemini or external providers for Phase 1. Perform all research within Claude Code using WebSearch/WebFetch, and flag the S1 sensitivity in the output brief.

## Inputs

The user provides a research topic or question. Examples:
- "Best ERP systems for food manufacturing under $50K/year"
- "Solana vs Ethereum L2s for DeFi applications in 2026"
- "Dominican Republic yogurt market size and competition"
- "Due diligence on acquiring Lacteos del Caribe"

The user may also paste Gemini Deep Research output as Phase 1 input. If so, skip the broad research sweep and proceed directly to Phase 2.

## Steps

### Step 1: Parse Research Request

Read the user's topic or question. Extract:

1. **Core question** — the central thing we need to answer
2. **Research type** — classify as one of:
   - **Vendor evaluation** — comparing products, services, or providers
   - **Technology assessment** — evaluating tools, platforms, or technical approaches
   - **Market research** — sizing markets, understanding competition, identifying opportunities
   - **Due diligence** — investigating a company, deal, or partnership
   - **General research** — anything that does not fit the above categories
3. **Scope** — boundaries of the research (geography, time horizon, budget constraints)
4. **Sub-questions** — break the core question into 3-6 specific sub-questions that need answers

Present the parsed request to the user for confirmation before proceeding. If the scope is ambiguous, ask for clarification.

### Step 2: Phase 1 — Broad Research Sweep

**If the user provided Gemini Deep Research output:**
1. Parse the raw research corpus
2. Extract key claims, data points, and sources
3. Organize findings by sub-question from Step 1
4. Flag any claims that lack sources or seem unreliable
5. Proceed to Step 3

**If no external research was provided:**
1. Formulate 5-8 search queries covering the sub-questions from Step 1
2. Use WebSearch to execute each query
3. Use WebFetch to read the most relevant results (top 2-3 per query)
4. Extract key claims, data points, and sources from each result
5. Organize raw findings by sub-question
6. Note which sub-questions have strong coverage and which have gaps

### Step 3: Phase 2 — Targeted Deep Dive

1. **Identify gaps** — review Phase 1 findings against the sub-questions. Which questions remain unanswered or weakly supported?
2. **Targeted searches** — formulate specific queries to fill gaps. Use WebSearch and WebFetch for:
   - Missing data points (pricing, market size, timelines)
   - Alternative perspectives on contested claims
   - Technical details that Phase 1 only covered superficially
   - Recent developments (last 3-6 months) that may not appear in older sources
3. **Cross-reference** — for each major claim, verify against at least 2 independent sources. Flag:
   - Claims supported by multiple sources (higher confidence)
   - Claims from a single source only (lower confidence)
   - Contradictions between sources (note both positions)
4. **Vault context** — search your notes/knowledge base for related notes, previous decisions, or existing research that adds context:
   - `Projects/` — related active projects
   - `Areas/` — operational context
   - `Resources/` — existing research and reference materials
   - `decision-traces/` — previous related decisions

### Step 4: Phase 3 — Synthesis & Analysis

1. **Synthesize findings** — combine Phase 1 and Phase 2 into a coherent analysis, organized by sub-topic
2. **Assign confidence levels** to each finding:
   - **High** — multiple reliable sources agree, data is recent, claim is verifiable
   - **Medium** — single reliable source, or multiple sources with minor disagreements, or data is 6-12 months old
   - **Low** — single source of uncertain reliability, conflicting sources, data is stale, or claim is based on estimates/projections
3. **Identify patterns** — what themes emerge across the findings? What do the data points collectively suggest?
4. **Surface implications** — what do the findings mean for the user's decision or situation?
5. **Generate recommendations** — at least 3 options with tradeoffs. For each:
   - What it involves
   - Why the evidence supports it
   - Key risks and mitigation
   - What assumptions it depends on

**Research-type-specific analysis:**
- **Vendor evaluation:** Build a comparison matrix (features, pricing, support, integration, scalability)
- **Technology assessment:** Build a capability matrix (performance, ecosystem, learning curve, community, longevity)
- **Market research:** Include market sizing (TAM/SAM/SOM where possible), competitive landscape map, and trend analysis
- **Due diligence:** Include a risk matrix (financial, operational, legal, reputational) with severity and likelihood ratings

### Step 5: Phase 4 — Output Brief

Create the research brief at `Inbox/Research - <Topic> - YYYY-MM-DD.md` with the following structure:

```markdown
---
category: research-brief
research_type: <vendor-evaluation|technology-assessment|market-research|due-diligence|general>
created: YYYY-MM-DD
status: complete
confidence: <High|Medium|Low>
owner: "[[Your Name]]"
---

# Research Brief: <Topic>

## Executive Summary

<3-5 sentences summarizing the core question, key findings, and top recommendation. Written so someone can read only this section and understand the essential answer.>

## Key Findings

1. **<Finding title>** — <one-sentence summary>. *Confidence: High/Medium/Low*
2. **<Finding title>** — <one-sentence summary>. *Confidence: High/Medium/Low*
3. **<Finding title>** — <one-sentence summary>. *Confidence: High/Medium/Low*
[...]

## Analysis

### <Sub-topic 1>
<Detailed analysis with sourced claims. Each factual assertion links to a source in the Sources section.>

### <Sub-topic 2>
[...]

### <Sub-topic N>
[...]

<!-- For vendor evaluation: -->
### Comparison Matrix
| Criteria | Vendor A | Vendor B | Vendor C |
|----------|----------|----------|----------|
| ...      | ...      | ...      | ...      |

<!-- For technology assessment: -->
### Capability Matrix
| Capability | Technology A | Technology B | Technology C |
|------------|-------------|-------------|-------------|
| ...        | ...         | ...         | ...         |

<!-- For market research: -->
### Market Sizing
- **TAM:** ...
- **SAM:** ...
- **SOM:** ...

### Competitive Landscape
| Competitor | Position | Strengths | Weaknesses |
|------------|----------|-----------|------------|
| ...        | ...      | ...       | ...        |

<!-- For due diligence: -->
### Risk Matrix
| Risk | Category | Likelihood | Severity | Mitigation |
|------|----------|-----------|----------|------------|
| ...  | ...      | ...       | ...      | ...        |

## Recommendations

### Option 1: <Name>
- **What:** <description>
- **Why:** <evidence-based rationale>
- **Tradeoffs:** <what you gain vs what you give up>
- **Key assumption:** <what must be true for this to work>

### Option 2: <Name>
[same structure]

### Option 3: <Name>
[same structure]

**Preferred option:** <X> — <1-sentence rationale>

## Sources

| # | Source | URL | Reliability | Date Accessed |
|---|--------|-----|-------------|---------------|
| 1 | ...    | ... | High/Medium/Low | YYYY-MM-DD |
| 2 | ...    | ... | High/Medium/Low | YYYY-MM-DD |
[...]

## Gaps & Limitations

- <What we could not determine and why>
- <Data that was unavailable or unreliable>
- <Areas where sources conflicted without resolution>

## Suggested Next Steps

- [ ] <What to investigate further>
- [ ] <Who to talk to for validation>
- [ ] <What data to collect before deciding>
```

### Step 6: Present to User

1. Show the **Executive Summary** and **Key Findings** inline in the conversation
2. Reference the full brief location: `Inbox/Research - <Topic> - YYYY-MM-DD.md`
3. Ask: "Any area you want me to investigate further? Or any findings you want me to challenge or verify from a different angle?"

## Rules

- Always cite sources with URLs where available. No unsourced factual claims.
- Confidence levels are mandatory on every finding — never skip them.
- Never present uncertain findings as definitive. Use hedging language ("evidence suggests," "based on available data") for Medium/Low confidence findings.
- Distinguish between facts (sourced data), analysis (derived from data), and opinion (judgment calls). Label each clearly.
- If the topic involves S1 data (personal financial, credentials, strategic plans), do NOT include S1 details in any external research queries. Note the S1 sensitivity in the brief and perform all research within Claude Code.
- Research-type-specific templates are mandatory: vendor evaluation gets a comparison matrix, technology assessment gets a capability matrix, market research gets market sizing, due diligence gets a risk matrix.
- Minimum 3 recommendations with tradeoffs. "Do nothing" or "Gather more data" is a valid recommendation if evidence is insufficient.
- Do not fabricate data, statistics, or market figures. If data is unavailable, state it explicitly and suggest how to obtain it.
- Use WebSearch for all external research — do not rely on training data for market-specific, vendor-specific, or time-sensitive claims.
- Vault working directory: the vault root resolved from your CLAUDE.md chain (or wherever your notes live).
- Report language: match the user's language. If the topic is in Spanish, write in Spanish.
- The brief file name format is strict: `Research - <Topic> - YYYY-MM-DD.md` in `Inbox/`.

## Dependencies

### Required

- Nothing beyond Claude Code's built-in tools (WebSearch, WebFetch, Read, Write, Grep, Glob). This skill runs a research pipeline and writes a structured brief; no external deps.

### Optional

- **external-service Gemini Deep Research output** — if the user pastes Gemini Deep Research results as Phase 1 input, the skill skips its own broad sweep (Step 2) and uses Gemini's corpus directly. Fallback if not provided: the skill performs its own Phase 1 broad sweep via WebSearch + WebFetch (default path, fully self-sufficient). URL: https://gemini.google.com (Deep Research mode).
- **plugin firecrawl** — optional alternative web-scraping path. Not directly called by this skill; if installed, offers standalone `/firecrawl:*` commands for member use. Fallback: WebFetch handles all in-skill fetches natively. Install: `claude plugin install firecrawl` (Phase 0 Part 0 standard install).

### Vault Conventions

- Research brief lands in `Inbox/Research - <Topic> - YYYY-MM-DD.md` — adjust the path if your notes system uses a different inbox convention.
- Strict filename format is enforced per this skill's Rules section.
- S1-data safety follows the security rules in your own CLAUDE.md chain — personal/financial/credential/strategic material is never sent to external LLMs or search providers.

### Does NOT Require

- No MCPs (no Granola, Slack, Google Workspace, SQL Server).
- No CLIs (no gws, gh, accli).
- No desktop apps.
- No API keys (WebSearch and WebFetch are Claude Code built-ins).
- No Python or Node packages.
- No separate automation layer is required — this skill notes an optional lighter-weight alternative at the top, but the Claude Code version runs standalone.
