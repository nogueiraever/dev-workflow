#!/usr/bin/env bash
set -euo pipefail

# Build the feature-workflow plugin for distribution.
# Packages only the plugin-required files into a clean output directory.
#
# Usage:
#   ./scripts/build-plugin.sh [output-dir]
#
# Default output: ./dist/feature-workflow/

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="${1:-$REPO_ROOT/dist/feature-workflow}"

echo "Building feature-workflow plugin..."
echo "  Source: $REPO_ROOT"
echo "  Output: $OUTPUT_DIR"

# Clean previous build
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# --- Plugin metadata ---
cp -R "$REPO_ROOT/.claude-plugin" "$OUTPUT_DIR/.claude-plugin"

# --- Skills (the slash commands) ---
cp -R "$REPO_ROOT/skills" "$OUTPUT_DIR/skills"

# --- Workflow infrastructure (bundled for /feature-setup to copy into projects) ---
cp -R "$REPO_ROOT/.ai-workflow" "$OUTPUT_DIR/.ai-workflow"

# --- Feature templates (bundled for /feature-setup to copy into projects) ---
mkdir -p "$OUTPUT_DIR/docs/features"
cp -R "$REPO_ROOT/docs/features/_template" "$OUTPUT_DIR/docs/features/_template"

# --- Documentation ---
if [ -f "$REPO_ROOT/readme.md" ]; then
  cp "$REPO_ROOT/readme.md" "$OUTPUT_DIR/README.md"
fi

# --- Summary ---
echo ""
echo "Plugin built successfully:"
echo ""
find "$OUTPUT_DIR" -type f | sort | while read -r f; do
  echo "  ${f#$OUTPUT_DIR/}"
done
echo ""
echo "Total files: $(find "$OUTPUT_DIR" -type f | wc -l | tr -d ' ')"
echo ""
echo "To install locally:"
echo "  Copy $OUTPUT_DIR to ~/.claude/plugins/feature-workflow/"
echo ""
echo "To distribute via git:"
echo "  Push the output directory to a GitHub repo, then users install with:"
echo "  /plugin install feature-workflow@<marketplace>"
