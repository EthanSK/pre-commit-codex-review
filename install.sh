#!/bin/bash
set -euo pipefail

SKILL_DIR="$HOME/.claude/skills/pre-commit-codex-review"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$SKILL_DIR"
cp "$SCRIPT_DIR/SKILL.md" "$SKILL_DIR/SKILL.md"

mkdir -p "$SKILL_DIR/scripts" "$SKILL_DIR/references"
cp "$SCRIPT_DIR/skill-update.json" "$SKILL_DIR/skill-update.json"
cp "$SCRIPT_DIR/scripts/skill-update-state.py" "$SKILL_DIR/scripts/skill-update-state.py"
cp "$SCRIPT_DIR/references/public-updates.md" "$SKILL_DIR/references/public-updates.md"

echo "Installed pre-commit-codex-review skill to $SKILL_DIR"
echo ""
echo "Prerequisites:"
echo "  - Codex CLI: codex login (uses ChatGPT subscription)"
echo "  - OR OpenClaw configured with OpenAI model route"
echo ""
echo "The skill will activate automatically on your next Claude Code commit."
