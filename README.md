# Feature Workflow Plugin for Claude Code

Autonomous feature development workflow with persistent markdown tracking, plan approval gates, parallel/sequential task execution, and cross-session resumability.

## Install

```bash
git clone git@github.com:nogueiraever/dev-workflow.git
cd dev-workflow
./install.sh
```

This clones the repo and symlinks it into `~/.claude/plugins/dev-workflow`. Restart Claude Code after installing. No per-project setup needed.

To update, just `git pull` in the cloned repo — the symlink keeps the plugin current.

## Usage

### Start a new feature

```
/feature auth-refactor
```

Describe what you want to build. The workflow will:

1. **Intake** — explore your codebase, ask clarifying questions if needed
2. **Plan** — generate `plan.md` + `acceptance-criteria.md`, present for your approval
3. **Tasks** — break the plan into tasks with dependencies and parallel/sequential classification
4. **Execute** — run tasks autonomously, updating tracking docs continuously
5. **Verify** — validate against acceptance criteria
6. **Closeout** — produce a final summary

The plan approval is the only pause point. After you approve, execution is fully autonomous.

### Resume in a new session

```
/feature resume auth-refactor
```

Reads the markdown tracking files and picks up exactly where the previous session left off.

### Check status

```
/feature
```

Lists all active features and their current phase.

### Manual entrypoints

For when you want to run a single phase:

| Command | Phase |
|---------|-------|
| `/feature-init <name>` | Intake + planning only |
| `/feature-tasks <name>` | Task generation only |
| `/feature-execute <name>` | Execution only |
| `/feature-verify <name>` | Verification only |

## How it works

All state is tracked in markdown files under `docs/features/<name>/`:

| File | Purpose |
|------|---------|
| `plan.md` | Scope, strategy, assumptions, risks |
| `tasks.md` | Task breakdown with dependencies and parallel flags |
| `acceptance-criteria.md` | Testable criteria for verification |
| `progress.md` | Current phase, completed/blocked items, phase history |
| `decisions.md` | Implementation decisions with rationale |

These files are the source of truth — not chat memory. This is what makes the workflow resumable across sessions.

## Building for distribution

```bash
./scripts/build-plugin.sh
```

Produces a clean `dist/feature-workflow/` directory ready for publishing.

## License

MIT
