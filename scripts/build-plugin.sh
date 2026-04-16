#!/usr/bin/env bash
set -euo pipefail

# Build the dev-workflow plugin for distribution.
# Packages only the plugin-required files into a clean output directory.
#
# Usage:
#   ./scripts/build-plugin.sh [output-dir]
#
# Default output: ./dist/dev-workflow/

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="${1:-$REPO_ROOT/dist/dev-workflow}"

echo "Building dev-workflow plugin..."
echo "  Source: $REPO_ROOT"
echo "  Output: $OUTPUT_DIR"

# Clean previous build
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# --- Plugin metadata ---
cp -R "$REPO_ROOT/.claude-plugin" "$OUTPUT_DIR/.claude-plugin"

# --- Skills (the slash commands) ---
cp -R "$REPO_ROOT/skills" "$OUTPUT_DIR/skills"

# --- Workflow infrastructure (bundled for /workflow-setup to copy into projects) ---
cp -R "$REPO_ROOT/.dev-workflow" "$OUTPUT_DIR/.dev-workflow"

# --- Install script ---
cp "$REPO_ROOT/install.sh" "$OUTPUT_DIR/install.sh"
chmod +x "$OUTPUT_DIR/install.sh"

# --- Documentation ---
for f in README.md readme.md; do
  if [ -f "$REPO_ROOT/$f" ]; then
    cp "$REPO_ROOT/$f" "$OUTPUT_DIR/README.md"
    break
  fi
done

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
echo "  cd $OUTPUT_DIR && ./install.sh"
echo ""
echo "To distribute via git:"
echo "  Push the output directory to a GitHub repo, then users install with:"
echo "  git clone <repo> && cd <repo> && ./install.sh"
