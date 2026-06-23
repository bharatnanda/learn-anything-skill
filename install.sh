#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_SRC="$REPO_DIR/skill"
DEST="$HOME/.claude/skills/learn"

if [ ! -d "$SKILL_SRC" ]; then
  echo "Error: skill/ directory not found next to install.sh"
  exit 1
fi

echo "Installing /learn skill..."
mkdir -p "$DEST/references"
cp "$SKILL_SRC/SKILL.md" "$DEST/SKILL.md"
cp "$SKILL_SRC/references/reviewer-spec.md" "$DEST/references/reviewer-spec.md"
echo "Done. Restart Claude Code and run /learn to get started."
