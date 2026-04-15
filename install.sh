#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="$HOME/.claude/plugins/dev-workflow"
REPO_URL="git@github.com:nogueiraever/dev-workflow.git"

echo "Installing dev-workflow plugin for Claude Code..."

# Check for git
if ! command -v git &>/dev/null; then
  echo "Error: git is required but not installed."
  exit 1
fi

# Install or update
if [ -d "$PLUGIN_DIR" ]; then
  echo "Updating existing installation..."
  git -C "$PLUGIN_DIR" pull --ff-only
else
  echo "Cloning to $PLUGIN_DIR..."
  mkdir -p "$(dirname "$PLUGIN_DIR")"
  git clone "$REPO_URL" "$PLUGIN_DIR"
fi

echo ""
echo "Installed to: $PLUGIN_DIR"
echo ""
echo "Restart Claude Code, then use:"
echo "  /feature new <name>    — start a new feature"
echo "  /feature resume <name> — resume an existing feature"
echo "  /feature               — list active features"
