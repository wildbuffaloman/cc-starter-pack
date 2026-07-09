---
name: fermi-decomposition
version: "0.1.1"
description: "Break seemingly immeasurable quantities into estimable components using structured factor decomposition. Use when estimating unknown quantities, sizing markets, or turning vague problems into structured estimates."
user-invocable: true
argument-hint: "quantity to estimate (e.g., 'piano tuners in Chicago', 'annual cost of employee turnover', 'SaaS market size in Austin')"
type: flexible
---

# Fermi Decomposition

Break "immeasurable" quantities into estimable components.

Based on the methodology from *How To Measure Anything* by Douglas Hubbard.

## When to Use

- User asks "How many X are there?" for unknown quantities
- User needs to estimate something seemingly immeasurable
- Strategic planning, market sizing, cost estimation
- Any vague problem needing structure

## Method

### Step 1: Identify the Target Quantity

Clarify exactly what needs estimating:

- "How many piano tuners in Chicago?" → piano tuners actively working
- "Cost of employee turnover?" → annual direct + indirect costs

### Step 2: Find a Decomposition Path

Break into factors that multiply (or add) to the target.

**Check domain knowledge first:** Before committing to a path, verify the user knows the key concepts. If not, offer an alternative.

- Path A (direct): Volume × Density × Conversion — requires knowing constants
- Path B (comparison): "About the same as X" — uses analogies to known quantities
- Path C (iterative): Break into ever-smaller pieces until estimable

**Examples:**

- **Piano Tuners:** Tuners = (Population / People per Piano) × (Pianos per Tuner per Year)
- **Employee Turnover:** Cost = Headcount × Turnover Rate × (Recruiting Cost + Training Cost + Productivity Loss)
- **Atoms in sand (if chemistry unknown):** Compare volume to known objects, then use "atoms per cm³" rule of thumb (~10²² atoms/cm³ for solids)

### Step 3: Estimate Each Component

For each factor, provide a range (90% confidence):

- Population of Chicago: 2.7M ± 200k
- People per piano: 50-200 (guess: 100)
- Pianos tuned per tuner per year: 500-1500

### Step 4: Combine with Uncertainty

Multiply point estimates for central guess.

**For each high-uncertainty component, suggest a remedy:**

- Too uncertain? → Look up: [specific source, e.g., census data, industry reports]
- Can't estimate? → Compare to: [known reference, e.g., "about the same as X"]
- Still stuck? → Use Rule of Five: sample 5 random instances

Track which components contribute most uncertainty — these are priority for actual measurement.

### Step 5: Sanity Check

- Does answer make order-of-magnitude sense?
- What would need to be true for this to be 10x higher or lower?

**If estimate feels wrong, check:**

1. Component ranges — any bounds too narrow or wide?
2. Formula logic — units consistent? division vs multiplication correct?
3. Missing factors — any key variables omitted?
4. Base rates — how does this compare to known similar quantities?

## Output Format

**Decomposition:** [Equation showing factor breakdown]

**Component Estimates:**
- Factor A: [value] (90% CI: [low]-[high])
- Factor B: [value] (90% CI: [low]-[high])
...

**Combined Estimate:** [central estimate] (range: [low]-[high])

**Key Uncertainties:** [which factors most affect result, and how to reduce each]

**Alternative Paths:** [if user lacks domain knowledge for primary path]

## Examples

### Example 1: Piano Tuners in Chicago

**Target:** Active piano tuners in Chicago metro

**Decomposition:** Tuners = Population / (Households per Piano) / (Tunings per Piano per Year) / (Pianos per Tuner per Year)

**Estimates:**
- Chicago population: 2.7M
- People per household: 2.5 → ~1.08M households
- Households with pianos: ~1 in 50 → ~22,000 pianos
- Tunings per piano per year: 1
- Pianos a tuner can service per year: ~800

**Result:** ~27 tuners (actual: ~290 — within 10x)

### Example 2: SaaS Market Size in Austin

**Target:** Annual addressable market for B2B productivity tool in Austin

**Decomposition:** Market = Companies × Adoption Rate × Price × Retention

**Estimates:**
- Austin metro companies (10+ employees): ~15,000
- Adoption rate for productivity tools: 5-15%
- Annual price: $500-2000 per company
- Net retention: 80-95%

**Result:** $3.75M - $42.75M annual market (wide range signals need for better data)

### Example 3: Employee Turnover Cost

**Target:** Annual cost of employee turnover for a 500-person tech company

**Decomposition:** Cost = Headcount × Turnover Rate × (Replacement Cost + Productivity Loss)

**Estimates:**
- Headcount: 500
- Annual turnover rate: 15-25% (tech industry average)
- Replacement cost per employee: $50,000-150,000 (recruiting + onboarding)
- Productivity loss (months to full ramp): 3-6 months salary (~$25K-50K)
- Total cost per departure: $75,000-200,000

**Result:** 75-125 departures/year × $75K-200K = $5.6M - $25M annual cost (actual industry rule of thumb: 50-200% of salary — within range)
