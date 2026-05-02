# AGENTS.md

## Repo Shape

- This repo is a Claude/Codex/OpenCode skill plugin, not a package-managed app; there is no root `package.json`, lockfile, CI config, or test runner.
- Slash-command behavior lives in `skills/<command>/SKILL.md`; the reusable workflow bundle copied into target projects lives in `.dev-workflow/`.
- `.claude-plugin/plugin.json` is the distributable plugin metadata; `scripts/build-plugin.sh` packages `.claude-plugin/`, `skills/`, `.dev-workflow/`, `install.sh`, and `README.md` into `dist/dev-workflow/`.

## Commands

- Install locally with `./install.sh`; it is interactive and asks whether to install for Claude Code, Codex, OpenCode, or all three.
- OpenCode requires both `~/.config/opencode/skills/<name>/SKILL.md` and `~/.config/opencode/commands/<name>.md`; skills alone do not create `/story` commands.
- Override install targets with `CLAUDE_SKILLS_DIR`, `CODEX_SKILLS_DIR`, `OPENCODE_SKILLS_DIR`, and `OPENCODE_COMMANDS_DIR`.
- Build a distributable copy with `./scripts/build-plugin.sh`; pass an optional output dir as the first argument.
- Focused script syntax checks: `bash -n install.sh` and `bash -n scripts/build-plugin.sh`.

## Workflow Conventions

- `/story` and `/epic` are hard contracts: any invocation must create or resume markdown-tracked artifacts, not be handled as an untracked ad hoc task.
- Story state is canonical in `story.md` frontmatter, with lookup/resume through `docs/progress.md`.
- Approval gates are mandatory: never move a story from planning to task generation, or imported epic stories into execution, without explicit user approval.
- After approval, execution is autonomous; update `story.md`, `decisions.md`, and `docs/progress.md` immediately as work progresses.
- Deprecated `/feature*` skills are wrappers only; preserve redirects to `/story*` or `/workflow-setup`.

## Path Gotchas

- Standalone story paths in the current workflow are `stories/{id}-{slug}/`, while epic stories are under `epics/{id}-{slug}/stories/{story-id}-{slug}/`.
- Target projects get `.dev-workflow/`, `docs/progress.md`, `epics/`, and `stories/` from `/workflow-setup`; `docs/progress.md` is live state and must not be overwritten by force setup.
- Keep `.dev-workflow/templates/` and the skill references in sync when changing story file shape or phase/state rules.
