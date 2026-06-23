# /learn — Expert Learning Guide Generator for Claude Code

A Claude Code skill that generates structured, visually rich learning guides for any topic using the **Expert Learning Framework** (5-phase methodology based on cognitive science research).

Type `/learn SQL window functions` and get a complete, personalised guide in minutes — with Mermaid diagrams, measurable practice drills, an interactive flashcard widget, and a spaced repetition schedule.

---

## What it produces

For any topic you name, the skill generates a single `.md` file containing:

| Section | What's inside |
|---|---|
| **At a Glance** | Your goal, experience level, estimated time to competency |
| **Phase 1: Mental Model** | Feynman-style explanation, best analogy, Mermaid mindmap |
| **Phase 2: Core Curriculum** | The 20% of concepts that unlock 80% of use, concept table, learning-path flowchart |
| **Phase 3: Deliberate Practice Drills** | One drill per chunk — each with a measurable success condition and session formula |
| **Phase 4: Feedback Loop Setup** | Adapted to the skill type (technical / creative / interpersonal / physical) |
| **Phase 5: Spaced Repetition Schedule** | Day 1 / 3 / 7 / 14 / 30 review tasks, topic-specific |
| **Quick Reference Checklist** | Before / during / long-term retention checklists |
| **Interactive Flashcards** | Self-contained HTML widget — flip, prev/next, card counter |
| **Resources** | Best single resource per concept, sourced via live web research |

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

If you just want the prebuilt artifact without cloning:

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
/learn machine learning fundamentals
```

**First run:** Claude will ask 2–3 questions (your goal, experience level, session length) and save them to `~/.claude/learn-preferences.json`.

**Subsequent runs:** Preferences are loaded automatically — only your goal for the new topic is asked.

To update your preferences, say: *"update my learning preferences"*

---

## How it works

```
/learn <topic>
  ├── Load stored preferences (~/.claude/learn-preferences.json)
  ├── Ask: purpose + experience level + session length (first run only)
  ├── Decompose topic into 4–8 ordered learning chunks
  ├── Workflow: parallel web research agents (one per chunk)
  │     ├── WebSearch for best resource per chunk
  │     ├── WebSearch for common beginner mistakes
  │     └── Return: key concepts, drill, resource, connections
  ├── Synthesise into full guide (all 9 sections)
  ├── Review agent: verify completeness before saving
  │     └── Checks: sections present, drills measurable, flashcards complete,
  │           no template placeholders, resources have real URLs
  └── Save <topic-slug>-learning-guide.md to current directory
```

The review step runs against a spec bundled inside `learn.skill` — no external agent files needed.

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
