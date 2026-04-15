#!/usr/bin/env bash
set -euo pipefail

SKILLS_DIR="$HOME/.claude/skills"
WORKFLOW_DIR="$HOME/.dev-workflow"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS=("feature" "feature-init" "feature-tasks" "feature-execute" "feature-verify" "feature-setup")

echo "Installing dev-workflow for Claude Code..."

# Clean up old plugin locations
for old in "$HOME/.claude/plugins/dev-workflow" "$HOME/.claude/plugins/marketplaces/claude-plugins-official/plugins/dev-workflow"; do
  if [ -L "$old" ] || [ -d "$old" ]; then
    rm -rf "$old"
  fi
done

# Symlink each skill into ~/.claude/skills/
mkdir -p "$SKILLS_DIR"
for skill in "${SKILLS[@]}"; do
  target="$SKILLS_DIR/$skill"
  if [ -L "$target" ] || [ -d "$target" ]; then
    rm -rf "$target"
  fi
  ln -s "$SCRIPT_DIR/skills/$skill" "$target"
  echo "  skill: $skill"
done

# Copy workflow infrastructure and templates to user root
echo ""
if [ -d "$WORKFLOW_DIR" ]; then
  echo "Updating $WORKFLOW_DIR..."
  rm -rf "$WORKFLOW_DIR"
fi
cp -R "$SCRIPT_DIR/.dev-workflow" "$WORKFLOW_DIR"
cp -R "$SCRIPT_DIR/docs" "$WORKFLOW_DIR/docs"
echo "  workflow: $WORKFLOW_DIR"

echo ""
echo "Installed:"
echo "  ${#SKILLS[@]} skills  -> $SKILLS_DIR"
echo "  templates   -> $WORKFLOW_DIR/docs/features/_template/"
echo "  agents      -> $WORKFLOW_DIR/agents/"
echo "  prompts     -> $WORKFLOW_DIR/prompts/"
echo "  rules       -> $WORKFLOW_DIR/rules/"
echo ""
echo "Restart Claude Code, then use:"
echo "  /feature <name>    — start a new feature"
echo "  /feature resume <name> — resume an existing feature"
echo "  /feature               — list active features"
