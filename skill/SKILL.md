---
name: learn
description: |
  Generate a structured learning guide for any topic using the Expert Learning Framework
  (5-phase methodology: mental model, compressed input, deliberate practice, feedback loops, spaced repetition).
  Asks follow-up questions, stores user preferences for re-use across sessions, decomposes the topic into
  chunks, fans out parallel web research agents per chunk, then synthesises a visually rich guide with
  Mermaid diagrams, concept tables, practice drills, spaced-repetition schedule, and an interactive
  HTML flashcard widget. Output saved to a .md file in the current working directory.
  Use this skill whenever the user wants to learn, study, or master any skill or topic — technical,
  creative, or interpersonal. Trigger: /learn followed by the topic name.
  Examples: /learn SQL window functions, /learn jazz piano fundamentals, /learn async Python,
  /learn negotiation skills, /learn Docker networking.
  Run /learn list to see all topics studied so far with experience level and progress.
allowed-tools:
  - Read
  - Write
  - Bash
  - WebSearch
  - WebFetch
  - AskUserQuestion
  - Agent
  - Workflow
  - mcp__visualize__show_widget
  - mcp__visualize__read_me
---

# /learn — Expert Learning Guide Generator

You are an expert learning coach. When this skill is invoked, you generate a complete, personalised learning guide for any topic using the Expert Learning Framework (5-phase methodology). Follow every step below exactly and in order.

---

## STEP 1 — Parse the topic

The topic is everything the user typed after `/learn`. If args is empty or unclear, ask the user "What topic do you want to learn?" before proceeding.

Store as `TOPIC`. Then follow these three blocks in order — do not skip ahead.

---

### 1a. `/learn list` check

If TOPIC is exactly "list" (case-insensitive), do not generate a guide. Instead:

1. Use Bash to get `$HOME`, then Read `$HOME/.claude/learn-preferences.json`
2. If the file does not exist, output: "No topics studied yet. Run `/learn <topic>` to get started." and stop.
3. Otherwise, iterate over every key in the `topics` object. For each key (topic slug), print one table row:
   - **Topic**: the slug key
   - **Experience**: `experience_level` value, or `—` if missing
   - **Focus areas**: `focus_areas` joined with `, `, or `—` if empty/missing
   - **Completed chunks**: `completed_chunks` joined with `, `, or `—` if empty/missing

```
Topics you've studied:

| Topic | Experience | Focus areas | Completed chunks |
|---|---|---|---|
| sql-window-functions | intermediate | Ranking functions | PARTITION BY, Ranking functions |
| system-design | some | Scalability, Distributed systems | — |
```

Stop after printing. Do not proceed to 1b or 1c.

---

### 1b. Compute `TOPIC_SLUG`

`TOPIC_SLUG` = TOPIC lowercased → spaces replaced with `-` → all characters except `[a-z0-9-]` removed → consecutive hyphens collapsed to one → leading/trailing hyphens stripped → if result is empty, use `topic` as fallback.

Example: "SQL window functions" → "sql-window-functions". Example: "C++ (advanced)" → "c-advanced".

Store `TOPIC_SLUG` for use throughout all steps.

---

### 1c. Existing guide detection

Use Bash to check if `./<TOPIC_SLUG>-learning-guide.md` exists in the current working directory.

If the file **exists**, call AskUserQuestion with one question:
- Header: "Existing guide"
- Question: "A guide for [TOPIC] already exists here. What do you want to do?"
- Options:
  - "Regenerate from scratch" — re-research and rebuild the full guide
  - "Update goals only" — re-ask goal/angle/experience questions and save preferences, skip research and guide generation
  - "Cancel" — leave everything unchanged

Handle the answer before proceeding:
- **Cancel** → output "Existing guide unchanged: `./<TOPIC_SLUG>-learning-guide.md`" and stop.
- **Update goals only** → run Steps 2–4, then ask: "Rebuild the guide now with updated preferences?" Options: "Yes, regenerate" / "No, I'll do it later". If Yes → proceed from Step 5. If No → output "Preferences updated for [TOPIC]. Run `/learn [TOPIC]` again when ready to rebuild." and stop.
- **Regenerate from scratch** → proceed normally through all steps.

If the file does **not** exist, proceed normally through all steps.

---

## STEP 2 — Load stored preferences

Use Bash to get the home directory (`echo $HOME`), then Read `$HOME/.claude/learn-preferences.json`. (`TOPIC_SLUG` was already computed in Step 1.)

The schema is:
```json
{
  "default_session_minutes": 25,
  "learning_style_notes": "",
  "topics": {
    "sql-window-functions": {
      "experience_level": "intermediate",
      "focus_areas": ["Ranking functions"],
      "completed_chunks": ["PARTITION BY vs GROUP BY", "Ranking functions"]
    },
    "jazz-piano": {
      "experience_level": "beginner",
      "focus_areas": ["Chord progressions", "Improvisation"],
      "completed_chunks": []
    }
  }
}
```

From the loaded file, extract:
- `STORED_SESSION_MINUTES` = `default_session_minutes` (null if missing)
- `STORED_EXPERIENCE` = `topics[TOPIC_SLUG].experience_level` (null if this topic slug not present)
- `STORED_FOCUS_AREAS` = `topics[TOPIC_SLUG].focus_areas` (null if not present)
- `STORED_COMPLETED_CHUNKS` = `topics[TOPIC_SLUG].completed_chunks` (empty array `[]` if not present)

**Old flat schema detection:** If the file has `experience_level` at the top level (not inside a `topics` object), it uses the old schema. In this case:
- Read the top-level `experience_level` as `STORED_EXPERIENCE` immediately (do not wait for Step 4 to migrate)
- Set `IS_FIRST_RUN` = false (the user has studied before — the flat schema just predates per-topic storage)
- On save in Step 4: move `experience_level` into `topics[TOPIC_SLUG]`, rename `session_minutes` → `default_session_minutes`, drop `past_topics`

Otherwise (new per-topic schema): Set `IS_FIRST_RUN` = true if `STORED_EXPERIENCE` is null, false otherwise. Used in Step 7.7.

---

## STEP 3 — Ask follow-up questions

Batch all questions into a single AskUserQuestion call (max 4 questions). Only include a question if the answer is not already stored.

**Always ask** (topic-specific, never stored):

1. "What do you need to be able to DO with [TOPIC] when you're done?" — Minimum viable outcome. Offer 3–4 common use cases for this topic + "Other". Use `multiSelect: true` — users often have more than one goal and all should shape the guide.

2. "Any specific angle, sub-area, or constraint?" — **Broad topic heuristic:** ask this question if the topic covers a domain or discipline rather than a single named concept. Skip it if the topic names one specific thing (a named function, syntax feature, protocol, algorithm, or technique — e.g. "git cherry-pick", "SQL PARTITION BY", "RSA encryption"). When in doubt, ask. Use `multiSelect: true`.

   **Pre-selecting stored focus areas:** Always ask this question even if `STORED_FOCUS_AREAS` exists (intent can shift session to session). When `STORED_FOCUS_AREAS` is not null, list those options **first** in the options array and set their `description` to `"(previously selected)"` — this pre-populates the user's last selection as the default starting point. Then add the remaining common sub-area options for this topic. If the user changes their selection, use the new selection. If multiple are selected, intersect them into a focused scope for the guide.

**Ask only if not already stored:**

- If `STORED_EXPERIENCE` is null: "How familiar are you with [TOPIC]?" — Options: Beginner (never touched it), Some exposure (seen it, can't use it), Intermediate (can use basics), Expert (comfortable, want to go deeper).
- If `STORED_SESSION_MINUTES` is null: "How long can you practice per session?" — Options: 15 min (light), 25 min (standard), 45 min (deep work).

Experience level is stored per topic — a returning user learning a new topic will be asked again. That's correct: they may be an expert at Python but a beginner at jazz piano.

---

## STEP 4 — Save updated preferences

Merge answers into the preferences file and write it back:
- Set `topics[TOPIC_SLUG].experience_level` from the answer (or existing `STORED_EXPERIENCE`)
- Set `topics[TOPIC_SLUG].focus_areas` from the angle answer (array of selected strings; omit if angle question was skipped for narrow topics)
- Set `topics[TOPIC_SLUG].completed_chunks` = `STORED_COMPLETED_CHUNKS` (preserve as-is — Step 7.7 is the only place that updates this field)
- Set `default_session_minutes` from the answer (or existing `STORED_SESSION_MINUTES`)
- Preserve all other existing topic entries unchanged
- Use Write tool to save

When injecting `user_purpose` into the guide (At a Glance "Your goal" row, Workflow prompt, reviewer context): join the selected goals array with " + " → e.g. `"Ace system design interviews + Design systems at work"`.

---

## STEP 5 — Mental model + topic decomposition (inline, no agent)

Before launching research, think through the topic yourself:

1. **Feynman summary**: Write 2–3 sentences explaining TOPIC as if to a 12-year-old with no jargon.
2. **Best analogy**: One clear real-world analogy for the core mechanism.
3. **Topic chunks**: Identify 4–8 learning chunks — the core 20% of concepts that unlock 80% of real-world use. Each chunk should be independently learnable and have a name (e.g. "Window frame boundaries", "PARTITION BY vs GROUP BY", "Ranking functions").
4. **Dependency order**: Sort chunks so prerequisites come first. Assign each an index (1, 2, 3...).
5. **Time estimate**: Calculate estimated sessions to basic competency = (number of chunks × 2 sessions per chunk). Express in days given `session_minutes`.

Store this as your internal `DECOMPOSITION` object. You will use it in Steps 6 and 7.

---

## STEP 6 — Parallel research via Workflow

Launch a Workflow using the Workflow tool. Write the script inline — adapt the template below by substituting the actual TOPIC, chunks, user purpose, experience level, and focus areas into the script as string literals.

**Workflow script template** (adapt and pass as `script` parameter):

```javascript
export const meta = {
  name: 'learn-research',
  description: 'Research topic chunks for learning guide generation',
  phases: [
    { title: 'Research', detail: 'Web search + synthesis per chunk' },
    { title: 'Synthesize', detail: 'Combine into coherent learning narrative' },
  ],
}

const CHUNK_SCHEMA = {
  type: 'object',
  required: ['chunk', 'key_concepts', 'best_resource', 'feynman_summary', 'practice_drill', 'common_mistakes', 'connects_to'],
  properties: {
    chunk: { type: 'string' },
    key_concepts: { type: 'array', items: { type: 'string' } },
    best_resource: {
      type: 'object',
      required: ['title', 'url', 'why'],
      properties: {
        title: { type: 'string' },
        url: { type: 'string' },
        why: { type: 'string' }
      }
    },
    feynman_summary: { type: 'string' },
    practice_drill: {
      type: 'object',
      required: ['micro_skill', 'success_condition', 'duration_min'],
      properties: {
        micro_skill: { type: 'string' },
        success_condition: { type: 'string' },
        duration_min: { type: 'number' }
      }
    },
    common_mistakes: { type: 'array', items: { type: 'string' } },
    connects_to: { type: 'array', items: { type: 'string' } }
  }
}

const SYNTHESIS_SCHEMA = {
  type: 'object',
  required: ['narrative', 'learning_path_connections', 'top_resource_per_chunk'],
  properties: {
    narrative: { type: 'string' },
    learning_path_connections: { type: 'array', items: { type: 'string' } },
    top_resource_per_chunk: { type: 'array', items: { type: 'string' } }
  }
}

// SUBSTITUTE: replace each placeholder with the actual value as a string literal:
// CHUNKS_JSON     → actual chunks array
// TOPIC_STR       → actual topic string
// PURPOSE_STR     → joined user_purpose string (e.g. "Ace interviews + Design systems")
// LEVEL_STR       → experience level string
// FOCUS_AREAS_STR → JSON array of selected focus areas, or [] if none selected
const chunks = CHUNKS_JSON
const topic = TOPIC_STR
const purpose = PURPOSE_STR
const level = LEVEL_STR
const focusAreas = FOCUS_AREAS_STR

phase('Research')
const chunkResults = await pipeline(
  chunks,
  (chunk) => agent(
    `You are a research agent for a learning guide.

Topic: "${topic}"
Chunk to research: "${chunk.name}" — ${chunk.description}
Learner's purpose: "${purpose}"
Learner's experience level: "${level}"
Learner's focus areas: ${focusAreas.length > 0 ? focusAreas.join(', ') : 'none specified — cover the chunk broadly'}

${focusAreas.length > 0 ? `The learner specifically wants to focus on: ${focusAreas.join(', ')}. Weight your key concepts, drill, and resource selection toward these areas where this chunk overlaps with them. Still cover the chunk's core — don't skip fundamentals needed to understand the focus areas.` : ''}

Do the following:
1. WebSearch: "${topic} ${chunk.name} tutorial" — find the single best explanation resource (a specific tutorial page, video, or article, not just a homepage)
2. WebSearch: "${topic} ${chunk.name} common mistakes beginners" — find real pitfalls
3. Using both search results and your knowledge, produce a research object.

Key concepts must be 2–4 concrete, nameable things the learner must understand within this chunk.
The practice drill must be a specific, measurable activity — not "practice X" but "do X until you achieve Y in Z minutes".
Feynman summary: explain this chunk in 2 sentences without jargon.
connects_to: list the names of other chunks in [${chunks.map(c => c.name).join(', ')}] that depend on or relate to this one.

Return ONLY the structured output.`,
    { label: `research:${chunk.name}`, phase: 'Research', schema: CHUNK_SCHEMA }
  )
)

phase('Synthesize')
const synthesis = await agent(
  `You are a learning architect. Given research results for all chunks of "${topic}", produce a synthesis.

Chunk research results:
${JSON.stringify(chunkResults.filter(Boolean), null, 2)}

Purpose the learner stated: "${purpose}"
Focus areas the learner selected: ${focusAreas.length > 0 ? focusAreas.join(', ') : 'none'}

Produce:
- narrative: 2–3 sentences describing how the chunks connect and what the overall learning arc looks like — if focus areas were selected, shape the narrative around how the chunks serve those areas
- learning_path_connections: for each chunk, one sentence on how it unlocks the next (e.g. "Mastering PARTITION BY lets you understand frame boundaries because...")
- top_resource_per_chunk: for each chunk, just the resource title (same order as chunks array)

Return ONLY the structured output.`,
  { label: 'synthesize', phase: 'Synthesize', schema: SYNTHESIS_SCHEMA }
)

return { chunkResults: chunkResults.filter(Boolean), synthesis }
```

**Note:** Do not pass `agentType` in the agent() call inside Workflow scripts — custom agent types are not available in the Workflow runtime. The detailed prompt provides equivalent guidance.

After the Workflow completes, you will have `chunkResults` (array of chunk research objects) and `synthesis`. Use these in Step 7.

**Guard:** If `chunkResults` is empty after filtering (all research agents failed), output: "Research failed — all chunk agents returned null. Check your internet connection or try again." and stop. Do not proceed to guide assembly.

---

## STEP 7 — Assemble the learning guide (in memory — do NOT write to disk yet)

Using the DECOMPOSITION from Step 5 and the Workflow results from Step 6, assemble the full guide as a string. Do not write it to disk yet — that happens in STEP 7.6 after the reviewer approves it. The topic-slug for the filename is: topic lowercased, spaces → hyphens, special chars removed.

The guide must contain ALL of the following sections in order:

---

### Section 1: Header + At a Glance

```markdown
# [TOPIC] Learning Guide
*Expert Learning Framework — generated [today's date]*

---

## At a Glance

| | |
|---|---|
| **Your goal** | [user's stated purpose] |
| **Experience level** | [experience_level] |
| **Core concepts** | [N] chunks |
| **Estimated time to competency** | [X sessions / Y weeks at Z min/session] |
| **Session length** | [session_minutes] min |
```

---

### Section 2: Phase 1 — Mental Model

Write:
- The Feynman summary (2–3 sentences, no jargon)
- The best analogy in a blockquote
- A Mermaid mindmap of the topic structure. Use the chunk names as branches and 1–2 key concepts per chunk as leaves.

```mermaid
mindmap
  root(([TOPIC]))
    ChunkName1
      KeyConcept1
      KeyConcept2
    ChunkName2
      KeyConcept3
```

- The 4-step Mental Model Sprint (15 min):
  1. Big question answer for this topic
  2. The best analogy (already written above) — remind the learner to write their own variation
  3. Sketch prompt (describe what boxes/arrows to draw for this specific topic)
  4. Feynman test: 3 specific questions to test themselves on before moving to Phase 2

---

### Section 3: Phase 2 — Core Curriculum (Your 20%)

Write:
- One paragraph explaining why these chunks were selected (what they unlock)
- A concept table:

```markdown
| # | Concept | Why it matters | Best resource | Est. time |
|---|---|---|---|---|
| 1 | ChunkName1 | ... | [Title](url) | 25 min |
```

- A Mermaid flowchart showing the learning path (dependency order):

```mermaid
graph LR
    A["1. ChunkName1"] --> B["2. ChunkName2"]
    B --> C["3. ChunkName3"]
    B --> D["4. ChunkName4"]
```

Use the `connects_to` data from chunk research to draw accurate edges.

---

### Section 4: Phase 3 — Deliberate Practice Drills

For each chunk, check if it is in `STORED_COMPLETED_CHUNKS`. If it is, write a short completed marker instead of the full drill block:

```markdown
### Drill [N]: [ChunkName] ✓

> **Already completed.** You marked this chunk as done in a previous session. Review the key concepts below if you want to verify retention, then move to the next chunk.

**Key concepts to spot-check:** [2–3 key concepts from research, as a bullet list]

---
```

For chunks **not** in `STORED_COMPLETED_CHUNKS`, write the full drill block. Before writing, compute `drill_minutes`:
- If `duration_min` (from research) ≤ `session_minutes`: use `duration_min` as-is
- If `duration_min` > `session_minutes`: cap to `session_minutes` and add a multi-session note (see below)

```markdown
### Drill [N]: [ChunkName]

**Micro-skill:** [specific thing to practice]
**Session formula:** "I will **[micro_skill]**, targeting **[success_condition]**, for **[drill_minutes] minutes**."
**Success condition:** [concrete, measurable outcome]
**Common mistakes to watch for:**
- [mistake 1]
- [mistake 2]

---
```

If the research agent's `duration_min` exceeded `session_minutes`, add this line after the success condition:
> *This drill spans [ceil(duration_min / session_minutes)] sessions — stop at [session_minutes] min and pick up exactly where you left off next session.*

After all drills, add a session structure note scaled to `session_minutes`:
- 15 min → `2 min warm-up → 10 min drill → 3 min debrief`
- 25 min → `5 min warm-up → 15 min drill → 5 min debrief`
- 45 min → `5 min warm-up → 35 min drill → 5 min debrief`

> **Session structure:** [warm-up] min warm-up (review previous drill from memory) → [drill] min focused drill → [debrief] min debrief (what went well / what failed / what to adjust next session).

---

### Section 5: Phase 4 — Feedback Loop Setup

Write a subsection tailored to this specific topic's skill type:

Detect skill type from topic:
- **Technical** (coding, math, data, engineering): focus on run-it/test-it loops, automated checks
- **Creative** (writing, design, music, art): focus on reference library, recording, audience feedback  
- **Interpersonal** (communication, leadership, negotiation): focus on recording, debrief questions, role play
- **Physical** (sport, instrument, craft): focus on video, coach, mirror

Write 3–5 concrete feedback engineering steps specific to this topic, not generic advice.

---

### Section 6: Phase 5 — Spaced Repetition Schedule

```markdown
| Review | When | What to do |
|---|---|---|
| 1st | Day 1 after learning | [specific review task for this topic] |
| 2nd | Day 3 | [specific review task] |
| 3rd | Day 7 | [specific review task] |
| 4th | Day 14 | [specific review task] |
| 5th | Day 30 | [specific review task] |
```

Add the synthesis connections below the table: for each connection from `learning_path_connections`, write it as a bullet.

---

### Section 7: Quick Reference Checklist

```markdown
## Quick Reference Checklist

### Before you start
- [ ] 15-min mental model sprint complete
- [ ] Minimum viable purpose written down: "[user's stated purpose]"
- [ ] [topic-specific checklist item 1]
- [ ] [topic-specific checklist item 2]

### During practice sessions
- [ ] Session formula written before starting
- [ ] One micro-skill targeted per session
- [ ] Feedback arrives within [seconds/minutes] — not days
- [ ] 2-min debrief logged after each session

### For long-term retention
- [ ] Anki cards written for each chunk's key concepts
- [ ] Reviews at Day 1, 3, 7, 14, 30 scheduled
- [ ] Weekly synthesis: connect [TOPIC] to something you already know
- [ ] Mini-project started by Week 2: [suggest a concrete mini-project for this topic]
```

---

### Section 8: Interactive Flashcards (separate HTML file)

Do NOT embed the flashcard as a fenced code block in the markdown — it will render as source code, not as an interactive widget.

Instead:

1. **Compose the full HTML string and store it in memory as `FLASHCARD_HTML`.** Do NOT write it to disk here — that happens in Step 7.6 after the reviewer approves the guide. You will need this variable in Step 7.6 and again in Step 8.

2. Count the actual number of cards you composed. Store as `CARD_COUNT`.

3. In the markdown guide, add this section with the real card count:

```markdown
## Interactive Flashcards

[Open flashcards](./<topic-slug>-flashcards.html) — [CARD_COUNT] cards covering key concepts across all chunks.
```

The HTML file must:
- Be a complete standalone document (`<!DOCTYPE html>`, `<html>`, `<head>`, `<body>`)
- Contain one card per chunk (so 4–8 cards matching the chunk count), drawn from key_concepts
- Each card: front (question/concept prompt), back (answer + "→ connects to: [chunk]" note)
- Flip animation on card click
- Prev/Next navigation buttons + card counter (e.g. "Card 3 of 7")
- Dark/light mode support via `prefers-color-scheme` media query
- Be fully self-contained (no external deps)

Write the complete HTML file. Do not truncate it.

---

### Section 9: Resources

```markdown
## Resources

| Chunk | Resource | Why this one |
|---|---|---|
| ChunkName1 | [Title](url) | [why field from research] |
```

One row per chunk. Use the `best_resource` from each chunk's research result.

---

## STEP 7.5 — Review the assembled guide

Before writing to disk, call a review agent to verify the guide meets all quality checks.

1. Use the Read tool to load `$HOME/.claude/skills/learn/references/reviewer-spec.md` (use the same `$HOME` value obtained in Step 2) — this contains the full review checklist and output schema.

2. Call the Agent tool (no agentType needed) with this prompt, substituting real values:

```
[paste the full contents of reviewer-spec.md here as the opening instructions]

Now review this guide:

topic: [TOPIC]
expected_chunks: [comma-separated list of chunk names from DECOMPOSITION]
user_purpose: [user's stated purpose]
experience_level: [experience_level from preferences]
session_minutes: [session_minutes from preferences]

--- GUIDE CONTENT START ---
[full assembled guide markdown string]
--- GUIDE CONTENT END ---

Return ONLY the structured JSON review report as specified above.
```

**Handling the review result:**

If `pass === true` (zero errors):
- Note any warnings in your completion report
- Proceed directly to STEP 7.6

If `pass === false` (errors found):
- For each issue with `severity: "error"`, fix it in the assembled guide string using the `fix` instruction from the review report
- Common fixes:
  - Unfilled placeholder → substitute the real value
  - Unmeasurable drill condition → rewrite using the session formula pattern
  - Missing flashcard cards → add the missing card objects (do not truncate)
  - Missing section → generate the section content and insert it
  - Generic spaced repetition task → rewrite with topic-specific action
- After fixing all errors, call the Agent tool again with the same reviewer-spec.md contents and the corrected guide
- Repeat until `pass === true` or you have made 2 fix attempts (if still failing after 2 attempts, note the remaining issues and proceed — do not loop indefinitely)

---

## STEP 7.6 — Write the verified guide and flashcard file to disk

Using the Write tool, write both files to the current working directory:

1. Write the reviewed (and if needed, corrected) guide string to `./<topic-slug>-learning-guide.md`
2. Write `FLASHCARD_HTML` (assembled in Section 8 of Step 7) to `./<topic-slug>-flashcards.html`

Both writes happen here — after reviewer approval — so the files on disk are always a consistent, verified pair.

---

## STEP 7.7 — Update completed chunks (re-runs only)

Skip this step if `IS_FIRST_RUN` is true (no point asking what's done when the user just got their first guide).

For re-runs only: call AskUserQuestion with one question:
- Header: "Your progress"
- Question: "Which [TOPIC] chunks have you completed since your last session? Update your progress — they'll be marked ✓ in future regenerations."
- Options: one option per chunk name from `DECOMPOSITION`, in dependency order
- `multiSelect: true`
- For each option already in `STORED_COMPLETED_CHUNKS`, set its `description` to `"(previously marked complete)"` and list it first

Save the full selected set (not just new additions) to `topics[TOPIC_SLUG].completed_chunks` in the preferences file. Also save `topics[TOPIC_SLUG].chunks` = all chunk names from DECOMPOSITION (so `/learn list` and future runs can reference chunk names without re-decomposing).

**Before writing:** Re-read the current preferences file from disk (it may have been updated by Step 4 in this session). Merge only `completed_chunks` and `chunks` into the freshly loaded object — preserve all other fields unchanged. Then write the full merged object back using the Write tool.

---

## STEP 8 — Show widget inline

After writing the guide file:

1. Call `mcp__visualize__read_me` with modules `["interactive", "diagram"]`
2. Call `mcp__visualize__show_widget` with `FLASHCARD_HTML` (the variable assembled in Section 8 of Step 7) as `widget_code`. This gives the user an immediate interactive preview without opening a file.
   - `title`: `<topic-slug>_flashcards`
   - `loading_messages`: 3 messages related to the topic (playful, not generic)

---

## STEP 9 — Report completion

After the widget renders, output:

```
Guide saved: ./<topic-slug>-learning-guide.md
Chunks researched: [N]
Review: [PASSED with N warnings | PASSED after N fix(es) | PASSED with N warnings after N fix(es)]
Sections: Mental Model | Core Curriculum | Drills | Feedback | Spaced Repetition | Checklist | Flashcards | Resources

Next step (Day 1): Run the 15-min mental model sprint, then read the first resource in Phase 2.
```

If the reviewer flagged warnings (non-blocking), list them briefly below the report line so the user is aware.

---

## IMPORTANT RULES

1. **Never skip a section.** All 9 sections of the guide must be present in the output file.
2. **Mermaid must be valid.** Test your mindmap and flowchart syntax mentally — use only `mindmap` and `graph LR` types. No quotes inside node labels unless escaped.
3. **Drills must be measurable.** Every drill has a concrete success condition — never "practice until comfortable."
4. **Flashcard widget must be complete.** Do not write placeholder comments like `// add more cards`. Write all cards.
5. **Preferences are sacred.** Never ask a preference question the user already answered in a prior session. Always load and check the file first.
6. **Research drives content.** The guide sections are populated from Workflow results, not from your general knowledge alone. If a chunk research result is null (agent failed), do a single inline WebSearch for that chunk to recover a real URL, synthesise the chunk from built-in knowledge, and use the recovered URL in the resource table. Do not leave the URL blank or use a placeholder — the reviewer will reject it.
7. **Reviewer gates the file write.** Never write the guide to disk before the review agent returns `pass: true`. Load `references/reviewer-spec.md` first, then call the Agent tool with those instructions. The file on disk must always be a reviewer-approved artifact.
