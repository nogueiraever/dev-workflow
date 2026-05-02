#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKFLOW_DIR="$HOME/.dev-workflow"

CLAUDE_SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
CODEX_SKILLS_DIR="${CODEX_SKILLS_DIR:-$HOME/.codex/skills}"
OPENCODE_SKILLS_DIR="${OPENCODE_SKILLS_DIR:-$HOME/.opencode/skills}"

# New story/epic skills
NEW_SKILLS=("story" "story-init" "story-tasks" "story-execute" "story-verify" "epic" "workflow-setup")

# Legacy feature skills (kept as deprecation wrappers)
LEGACY_SKILLS=("feature" "feature-init" "feature-tasks" "feature-execute" "feature-verify" "feature-setup")

ALL_SKILLS=("${NEW_SKILLS[@]}" "${LEGACY_SKILLS[@]}")

install_skills() {
  local tool_name="$1"
  local skills_dir="$2"

  echo "Installing skills for $tool_name..."

  # Clean up old Claude plugin locations only when installing Claude
  if [ "$tool_name" = "Claude Code" ]; then
    for old in "$HOME/.claude/plugins/dev-workflow" "$HOME/.claude/plugins/marketplaces/claude-plugins-official/plugins/dev-workflow"; do
      if [ -L "$old" ] || [ -d "$old" ]; then
        rm -rf "$old"
      fi
    done
  fi

  mkdir -p "$skills_dir"
  for skill in "${ALL_SKILLS[@]}"; do
    local target="$skills_dir/$skill"
    if [ -L "$target" ] || [ -d "$target" ]; then
      rm -rf "$target"
    fi
    ln -s "$SCRIPT_DIR/skills/$skill" "$target"
  done

  echo "  ${#ALL_SKILLS[@]} skills -> $skills_dir"
}

install_workflow() {
  echo ""
  if [ -d "$WORKFLOW_DIR" ]; then
    echo "Updating $WORKFLOW_DIR..."
    rm -rf "$WORKFLOW_DIR"
  fi
  cp -R "$SCRIPT_DIR/.dev-workflow" "$WORKFLOW_DIR"
  echo "  workflow: $WORKFLOW_DIR"
}

choose_tools() {
  echo "Select where to install dev-workflow:"
  echo "  1) Claude Code"
  echo "  2) Codex"
  echo "  3) OpenCode"
  echo "  4) All (Claude Code + Codex + OpenCode)"
  printf "Choose an option [1-4]: "
  read -r option

  case "$option" in
    1) SELECTED_TOOLS=("claude") ;;
    2) SELECTED_TOOLS=("codex") ;;
    3) SELECTED_TOOLS=("opencode") ;;
    4) SELECTED_TOOLS=("claude" "codex" "opencode") ;;
    *)
      echo "Invalid option: $option"
      exit 1
      ;;
  esac
}

SELECTED_TOOLS=()
choose_tools

for tool in "${SELECTED_TOOLS[@]}"; do
  case "$tool" in
    claude) install_skills "Claude Code" "$CLAUDE_SKILLS_DIR" ;;
    codex) install_skills "Codex" "$CODEX_SKILLS_DIR" ;;
    opencode) install_skills "OpenCode" "$OPENCODE_SKILLS_DIR" ;;
  esac
done

install_workflow

echo ""
echo "Installed skill groups:"
echo "  New:    ${NEW_SKILLS[*]}"
echo "  Legacy: ${LEGACY_SKILLS[*]} (deprecation wrappers)"
echo "  agents        -> $WORKFLOW_DIR/agents/"
echo "  orchestrators -> $WORKFLOW_DIR/orchestrators/"
echo "  prompts       -> $WORKFLOW_DIR/prompts/"
echo "  rules         -> $WORKFLOW_DIR/rules/"
echo "  templates     -> $WORKFLOW_DIR/templates/"
echo ""
echo "Next steps:"
echo "  1) Restart the selected tool(s)."
echo "  2) Use:"
echo "     /story create --id HRAB-123 --title \"My story\""
echo "     /story resume HRAB-123"
echo "     /story list"
echo "     /epic create --id HRAB-100 --title \"My epic\""
echo "     /epic list"
echo "     /workflow-setup"
echo ""
echo "Note: /feature commands still work but are deprecated. Use /story instead."
