# /learn — Expert Learning Guide Generator for Claude Code

A Claude Code skill that generates structured, visually rich learning guides for any topic using the **Expert Learning Framework** (5-phase methodology based on cognitive science research).

Type `/learn SQL window functions` and get a complete, personalised guide in minutes — with Mermaid diagrams, measurable practice drills, an interactive flashcard app, and a spaced repetition schedule.

---

## What it produces

For any topic, the skill generates two files in your current directory:

**`<topic>-learning-guide.md`** — the full guide:

| Section | What's inside |
|---|---|
| **At a Glance** | Your goal, experience level, estimated time to competency |
| **Phase 1: Mental Model** | Feynman-style explanation, best analogy, Mermaid mindmap |
| **Phase 2: Core Curriculum** | The 20% of concepts that unlock 80% of use, concept table, learning-path flowchart |
| **Phase 3: Deliberate Practice Drills** | One drill per chunk — measurable success condition, session formula; completed chunks show ✓ instead of full drill |
| **Phase 4: Feedback Loop Setup** | Adapted to the skill type (technical / creative / interpersonal / physical) |
| **Phase 5: Spaced Repetition Schedule** | Day 1 / 3 / 7 / 14 / 30 review tasks, topic-specific |
| **Quick Reference Checklist** | Before / during / long-term retention checklists |
| **Resources** | Best single resource per concept, sourced via live web research |

**`<topic>-flashcards.html`** — a standalone interactive flashcard app. Open in any browser — no server needed. Flip animation, prev/next buttons, keyboard shortcuts (`←` `→` `Space`), dark mode support.

---

## Installation

### Option A — Clone and install (recommended)

```bash
git clone https://github.com/your-username/learn-skill.git
cd learn-skill
./install.sh
```

Restart Claude Code. Run `/learn` to get started.

### Option B — Download zip only

```bash
# Download learn.skill from the releases page, then:
unzip -o learn.skill -d ~/.claude/skills
```

The `.skill` file is a standard zip — it extracts to `~/.claude/skills/learn/`.

---

## Usage

```
/learn SQL window functions
/learn async Python
/learn negotiation skills
/learn jazz piano fundamentals
/learn Docker networking
/learn system design

/learn list                  ← see all topics studied so far
```

**First run:** Claude asks your goal (multi-select), focus area, experience level, and session length. Saved to `~/.claude/learn-preferences.json`.

**Subsequent runs on the same topic:** Detects the existing guide file and asks what you want to do:
- **Regenerate from scratch** — re-research and rebuild the full guide
- **Update goals only** — re-ask questions and save preferences, no research
- **Cancel** — leave everything unchanged

Focus areas from your last session appear pre-selected so you can keep or adjust them. After each regeneration you're asked which chunks you've completed — they'll be marked ✓ and skip their drills on the next run.

**New topic:** Experience level is asked per topic — you may be an expert at Python but a beginner at negotiation.

---

## How it works

```
/learn <topic>
  ├── Check for existing guide in CWD → Regenerate / Update goals / Cancel
  ├── Load preferences (~/.claude/learn-preferences.json)
  │     ├── default_session_minutes       — global, asked once
  │     ├── topics.<slug>.experience_level — per topic, asked for new topics
  │     ├── topics.<slug>.focus_areas      — pre-selected on re-runs
  │     └── topics.<slug>.completed_chunks — marked ✓ in drills section
  ├── Ask: goal (multi-select) + focus area (pre-selected) + experience (if new)
  ├── Decompose topic into 4–8 ordered learning chunks
  ├── Workflow: parallel web research agents (one per chunk)
  │     ├── WebSearch: best resource per chunk (weighted toward focus areas)
  │     ├── WebSearch: common beginner mistakes
  │     └── Return: key concepts, drill, resource, connections
  ├── Synthesise full guide (8 sections) + flashcard HTML file
  ├── Review agent: verify quality before saving
  │     └── Checks: all sections present, drills measurable,
  │           no placeholders, resources have real URLs
  ├── Save <topic-slug>-learning-guide.md
  ├── Save <topic-slug>-flashcards.html
  └── Ask: which chunks completed? → save progress to preferences

/learn list
  └── Print all studied topics with experience, focus areas, completed chunks
```

The review spec is bundled inside `learn.skill` — no external agent files needed.

---

## Preferences schema

```json
{
  "default_session_minutes": 25,
  "learning_style_notes": "",
  "topics": {
    "sql-window-functions": {
      "experience_level": "intermediate",
      "focus_areas": ["Ranking functions"],
      "completed_chunks": ["PARTITION BY vs GROUP BY", "Ranking functions"],
      "chunks": ["PARTITION BY vs GROUP BY", "Ranking functions", "Window frame boundaries", "Named windows"]
    },
    "system-design": {
      "experience_level": "some",
      "focus_areas": ["Scalability fundamentals", "Distributed systems"],
      "completed_chunks": [],
      "chunks": ["Scalability Basics", "Load Balancing & Caching", "Database Design", "CAP Theorem", "Distributed Patterns", "API Design", "Interview Framework"]
    }
  }
}
```

---

## Files in this repo

```
learn-skill/
├── skill/
│   ├── SKILL.md                    — skill instructions (source)
│   └── references/
│       └── reviewer-spec.md        — quality review spec (source)
├── install.sh                      — copies skill/ → ~/.claude/skills/learn/
├── learn.skill                     — prebuilt zip (same content, for releases)
└── README.md                       — this file
```

`skill/` is the source of truth — browse, fork, or contribute there. `learn.skill` is the prebuilt zip for users who just want to download and install without cloning.

---

## Requirements

- Claude Code (claude.ai/code or the CLI)
- Tools enabled: `WebSearch`, `WebFetch`, `Workflow`, `Agent`, `Write`, `AskUserQuestion`
- Internet connection (for live web research per topic)

---

## Based on

The Expert Learning Framework in this skill is derived from research in:
- Deliberate practice (Anders Ericsson)
- Spaced repetition (Hermann Ebbinghaus)
- The Feynman learning technique
- Working memory and cognitive load theory (Cowan, 2001)

---

## License

MIT
