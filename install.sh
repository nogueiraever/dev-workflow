#!/usr/bin/env bash
set -euo pipefail

SKILLS_DIR="$HOME/.claude/skills"
WORKFLOW_DIR="$HOME/.dev-workflow"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# New story/epic skills
NEW_SKILLS=("story" "story-init" "story-tasks" "story-execute" "story-verify" "task" "epic" "workflow-setup")

# Legacy feature skills (kept as deprecation wrappers)
LEGACY_SKILLS=("feature" "feature-init" "feature-tasks" "feature-execute" "feature-verify" "feature-setup")

ALL_SKILLS=("${NEW_SKILLS[@]}" "${LEGACY_SKILLS[@]}")

echo "Installing dev-workflow for Claude Code..."

# Clean up old plugin locations
for old in "$HOME/.claude/plugins/dev-workflow" "$HOME/.claude/plugins/marketplaces/claude-plugins-official/plugins/dev-workflow"; do
  if [ -L "$old" ] || [ -d "$old" ]; then
    rm -rf "$old"
  fi
done

# Symlink each skill into ~/.claude/skills/
mkdir -p "$SKILLS_DIR"
for skill in "${ALL_SKILLS[@]}"; do
  target="$SKILLS_DIR/$skill"
  if [ -L "$target" ] || [ -d "$target" ]; then
    rm -rf "$target"
  fi
  ln -s "$SCRIPT_DIR/skills/$skill" "$target"
  echo "  skill: $skill"
done

# Copy workflow infrastructure to user root
echo ""
if [ -d "$WORKFLOW_DIR" ]; then
  echo "Updating $WORKFLOW_DIR..."
  rm -rf "$WORKFLOW_DIR"
fi
cp -R "$SCRIPT_DIR/.dev-workflow" "$WORKFLOW_DIR"
echo "  workflow: $WORKFLOW_DIR"

echo ""
echo "Installed:"
echo "  ${#ALL_SKILLS[@]} skills -> $SKILLS_DIR"
echo "    New:    ${NEW_SKILLS[*]}"
echo "    Legacy: ${LEGACY_SKILLS[*]} (deprecation wrappers)"
echo "  agents      -> $WORKFLOW_DIR/agents/"
echo "  orchestrators -> $WORKFLOW_DIR/orchestrators/"
echo "  prompts     -> $WORKFLOW_DIR/prompts/"
echo "  rules       -> $WORKFLOW_DIR/rules/"
echo "  templates   -> $WORKFLOW_DIR/templates/"
echo ""
echo "Restart Claude Code, then use:"
echo "  /story create --id HRAB-123 --title \"My story\"  — start a new story"
echo "  /story resume HRAB-123                           — resume a story by ID"
echo "  /story list                                      — list active stories"
echo "  /task Improve empty-state copy                  — adjust active story with approval gate"
echo "  /epic create --id HRAB-100 --title \"My epic\"    — create an epic"
echo "  /epic list                                       — list epics"
echo "  /workflow-setup                                  — initialize a project"
echo ""
echo "Note: /feature commands still work but are deprecated. Use /story instead."
