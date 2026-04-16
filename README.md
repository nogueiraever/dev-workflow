# Dev Workflow Plugin for Claude Code

Autonomous story-driven development workflow with persistent markdown tracking, plan approval gates, parallel/sequential task execution, and cross-session resumability. Supports Jira-style external IDs, epic grouping, and multi-developer parallel work.

## Install

```bash
git clone git@github.com:nogueiraever/dev-workflow.git
cd dev-workflow
./install.sh
```

This symlinks skills into `~/.claude/skills/` and copies workflow infrastructure to `~/.dev-workflow/`. Restart Claude Code after installing.

To update, just `git pull` in the cloned repo — the symlink keeps the plugin current.

## Concepts

| Concept | Description |
|---------|-------------|
| **Epic** | Large initiative grouping related stories. Optional. |
| **Story** | Main delivery unit. Goes through the full SDLC lifecycle. |
| **Task** | Smallest implementation unit, tracked inside a story. |

Stories can be standalone or belong to an epic. Both external IDs (e.g., `HRAB-7026`) and auto-generated internal IDs (e.g., `S1`) are supported.

## Usage

### Start a new story

```
/story create --id HRAB-7026 --epic HRAB-7000 --title "Global progress tracking"
```

Or without external IDs (auto-generates `S1`, `S2`, etc.):

```
/story create --title "Quick login copy fix"
```

The workflow will:

1. **Intake** — explore your codebase, ask clarifying questions if needed
2. **Plan** — fill `story.md` plan sections + generate `acceptance-criteria.md`, present for your approval
3. **Tasks** — break the plan into tasks with dependencies and parallel/sequential classification
4. **Execute** — run tasks autonomously, updating tracking docs continuously
5. **Verify** — validate against acceptance criteria
6. **Closeout** — produce a final summary

The plan approval is the only pause point. After you approve, execution is fully autonomous.

### Resume a story

```
/story resume HRAB-7026
```

Or just use the ID directly (smart routing):

```
/story HRAB-7026
```

Resolves the story from `docs/progress.md` and picks up exactly where the previous session left off.

### Check status

```
/story list
```

Lists all stories with their current phase, owner, and epic association.

### Create an epic

```
/epic create --id HRAB-7000 --title "Team collaboration"
```

Then create stories within it:

```
/story create --id HRAB-7026 --epic HRAB-7000 --title "Global progress tracking"
```

### Manual entrypoints

For when you want to run a single phase:

| Command | Phase |
|---------|-------|
| `/story-init <id>` | Intake + planning only |
| `/story-tasks <id>` | Task generation only |
| `/story-execute <id>` | Execution only |
| `/story-verify <id>` | Verification only |

### Project setup

```
/workflow-setup
```

One-time command to initialize workflow infrastructure in your project (copies `.dev-workflow/`, creates `docs/progress.md`, `epics/`, `stories/` directories).

## File structure

```
project/
├── docs/
│   └── progress.md                    # Global index of all epics and stories
├── epics/
│   └── HRAB-7000-team-collaboration/
│       ├── epic.md                    # Epic definition
│       └── stories/
│           └── HRAB-7026-progress/
│               ├── story.md           # Story definition + plan + tasks + state
│               ├── acceptance-criteria.md
│               └── decisions.md
└── stories/
    └── S1-quick-fix/
        ├── story.md
        ├── acceptance-criteria.md
        └── decisions.md
```

### Key files

| File | Purpose |
|------|---------|
| `docs/progress.md` | Global index — all epics and stories with IDs, status, paths |
| `story.md` | Unified story file: scope, plan, tasks, phase state, history |
| `acceptance-criteria.md` | Testable criteria for verification |
| `decisions.md` | Implementation decisions with rationale |
| `epic.md` | Epic definition: goals, scope, linked stories |

`story.md` is the source of truth for each story — it combines what was previously `plan.md`, `progress.md`, and `tasks.md` into a single file. This is what makes the workflow resumable across sessions.

## Migration from /feature

The old `/feature` commands still work as deprecation wrappers that redirect to `/story`. Existing `docs/features/` directories are detected by `/workflow-setup`, which can help migrate them to the new structure.

## Building for distribution

```bash
./scripts/build-plugin.sh
```

Produces a clean `dist/dev-workflow/` directory ready for publishing.

## License

MIT
