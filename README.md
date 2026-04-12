# Spec Kit Autopilot

A [spec-kit](https://github.com/github/spec-kit) extension that provides an automated pipeline for spec-driven development. One command chains through specify, clarify, plan, tasks, and implement — with auto-answered clarifications, enforced unit + integration test coverage, **self-validating tasks**, and pipeline state tracking for reliable resume.

## Features

- **One-command pipeline**: `/speckit.autopilot.run <feature description>` orchestrates the entire workflow
- **Delegates to core commands**: Orchestrates rather than re-implements — stays compatible as spec-kit evolves
- **Auto-answered clarifications**: All specification questions answered using best-practice recommendations
- **Enforced test coverage**: Every generated task includes unit tests and integration tests with post-generation validation
- **Self-validating tasks**: Every feature includes a runnable check the autopilot executes to confirm it works (logging, smoke tests, assertions, health checks, etc.)
- **Pipeline state file**: `autopilot-state.json` tracks exact phase status for reliable resume and status checks
- **Configurable phases**: Skip phases, reorder them, or run a subset of the pipeline
- **Validation command**: `/speckit.autopilot.validate` verifies test coverage, self-validation, and behavioral guideline compliance with auto-fix
- **Behavioral constitution**: `/speckit.autopilot.constitution` merges coding rules (think-before-code, simplicity, surgical changes, goal-driven execution) into the project constitution

## Prerequisites

- [spec-kit](https://github.com/github/spec-kit) installed (`uv tool install specify-cli`)
- A spec-kit initialized project (`/speckit.constitution` run at least once)
- An AI agent that supports spec-kit commands (Claude Code, Copilot, Cursor, etc.)

## Installation

### Option 1: Install from GitHub ZIP (Recommended)

```bash
cd /path/to/your/spec-kit-project
specify extension add autopilot --from https://github.com/grknylmz/github-speckit-autopilot/archive/refs/heads/main.zip
```

### Option 2: Install from Local Clone

```bash
# Clone the repository
git clone https://github.com/grknylmz/github-speckit-autopilot.git

# Install into your spec-kit project
cd /path/to/your/spec-kit-project
specify extension add --dev /path/to/github-speckit-autopilot
```

### Verify Installation

```bash
specify extension list

# Should show:
#  ✓ Spec Kit Autopilot (v1.0.0)
#     Automated pipeline orchestrating specify, clarify, plan, and tasks
#     Commands: 3 | Hooks: 0 | Status: Enabled
```

### Confirm Commands Are Registered

```bash
ls .claude/commands/speckit.autopilot.*

# Should show:
# speckit.autopilot.run.md
# speckit.autopilot.start.md   (alias)
# speckit.autopilot.status.md
# speckit.autopilot.validate.md
```

### Uninstall

```bash
specify extension remove autopilot
```

## Usage

### Run the Full Pipeline

```
/speckit.autopilot.run Add user authentication with OAuth2 and JWT tokens
```

This orchestrates:

1. **Specify** — Delegates to `/speckit.specify` to generate the feature spec, auto-resolves NEEDS CLARIFICATION markers
2. **Clarify** — Delegates to `/speckit.clarify`, intercepts questions, auto-answers with recommended options
3. **Plan** — Delegates to `/speckit.plan` for research, data model, contracts
4. **Tasks** — Delegates to `/speckit.tasks` with 3-pillar enforcement: unit tests, integration tests, and self-validation (all mandatory)
5. **Implement** — Delegates to `/speckit.implement` to execute all tasks, then runs self-validation checks and logs results
6. **Validate** — Built-in validation confirms all implementation tasks have tests + self-validation (and post-implementation verification)

### Check Pipeline Status

```
/speckit.autopilot.status
```

Reads the pipeline state file and scans artifacts. Shows which phases are complete, task counts, test coverage status, and recommends the next action.

### Validate Test Coverage

```
/speckit.autopilot.validate
```

Runs 14 validation checks on `tasks.md` (11 pre-implementation + 3 post-implementation):
1. Implementation tasks have unit tests
2. Integration points have integration tests
3. TDD ordering (tests before implementation)
4. Test file paths are specified
5. Coverage sweep task exists
6. Task IDs are sequential
7. Self-validation coverage (every user story has self-validation tasks)
8. Self-validation quality (each specifies technique, validation, and success criteria)
9. Goal-driven tasks (every implementation task has explicit success criteria)
10. Simplicity (single responsibility per task, no multi-responsibility bundling)
11. Surgical (every implementation task specifies exact file paths)

Post-implementation checks:
12. All tasks marked complete (no remaining `- [ ]` tasks)
13. Self-validation results (all checks in validation-results.log passed)
14. Test suite pass (all tests passed after implementation)

Offers auto-fix for any issues found.

### Resume a Failed Pipeline

Just re-run the same command — the state file tracks exactly where to resume:

```
/speckit.autopilot.run
```

### After Autopilot

- `/speckit.autopilot.validate` — Re-validate test coverage and post-implementation results
- `/speckit.autopilot.status` — View pipeline status anytime
- `/speckit.analyze` — Check for cross-artifact consistency

## Configuration

Located at `.specify/extensions/autopilot/autopilot-config.yml`.

### Phase Configuration

Control which phases run:

```yaml
pipeline:
  phases:
    - specify
    - clarify
    - plan
    - tasks
    - implement
```

Common configurations:
- **Full pipeline**: `[specify, clarify, plan, tasks, implement]`
- **Plan only (no execute)**: `[specify, clarify, plan, tasks]`
- **Skip clarify**: `[specify, plan, tasks, implement]`
- **Re-plan only**: `[plan, tasks]`
- **Tasks only**: `[tasks]`
- **Implement only**: `[implement]`

### All Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `test_enforcement.unit_tests` | `true` | Generate unit test tasks |
| `test_enforcement.integration_tests` | `true` | Generate integration test tasks |
| `test_enforcement.coverage_target` | `80` | Minimum coverage percentage |
| `test_enforcement.test_framework` | `"auto-detect"` | Test framework to use |
| `self_validation.enabled` | `true` | Generate self-validation tasks |
| `self_validation.techniques` | `[logging, smoke, ...]` | Allowed validation techniques |
| `self_validation.log_results` | `true` | Log validation results to file |
| `clarify.auto_answer` | `true` | Auto-answer clarification questions |
| `clarify.use_recommended` | `true` | Use AI-recommended option |
| `clarify.max_auto_questions` | `5` | Max questions to auto-answer |
| `pipeline.phases` | `[specify, clarify, plan, tasks, implement]` | Phases to execute |
| `pipeline.stop_on_failure` | `true` | Stop on any phase failure |

## Self-Validation

The core differentiator of autopilot. Every feature built through the pipeline must include a self-validation step — a runnable check the autopilot executes to confirm the feature works without any human intervention.

### Three Pillars Per Task

| Pillar | What It Verifies | Who Runs It |
|--------|-----------------|-------------|
| **Unit tests** | Individual functions/methods work in isolation | Test runner |
| **Integration tests** | Components work together correctly | Test runner |
| **Self-validation** | The built feature actually works at runtime | Autopilot (or developer) |

### Validation Techniques

The autopilot chooses the most appropriate technique per task:

| Technique | Best For | Example |
|-----------|----------|---------|
| **Logging** | Data processing, business logic | Log order creation with id, total, items — check log output |
| **Smoke test** | API endpoints, CLI commands | `curl -f http://localhost:3000/api/health` |
| **Assertion** | Calculations, transformations | `assert(user.age >= 0)` |
| **Build** | New modules, components | `npm run build && npm run typecheck` |
| **Schema** | Data models, migrations | `npx prisma validate && npx prisma migrate status` |
| **Health endpoint** | Services, APIs | `GET /health` returns `{status: "ok"}` |
| **Dry-run** | Destructive operations | `--dry-run` flag shows what would happen |
| **Idempotency** | State mutations | Run twice, verify identical state |
| **Contract** | API integrations | Response matches expected JSON schema |
| **Snapshot** | Output generation, reports | Compare output against golden snapshot |

### Self-Validation Task Format

Every self-validation task in `tasks.md` specifies three things:

```text
- [ ] T{NNN} [US{N}] Add self-validation for {Component} in {source-path}
  - Technique: {which technique}
  - Validation: {what to execute}
  - Success criteria: {what "pass" looks like}
```

## Behavioral Constitution

The autopilot automatically merges behavioral guidelines into the project constitution when the pipeline starts. These rules reduce common LLM coding mistakes and are enforced during task generation and validation.

### The 4 Rules

| Rule | Principle | What It Prevents |
|------|-----------|-----------------|
| **Think Before Coding** | State assumptions, surface tradeoffs, ask before assuming | Implementing the wrong thing |
| **Simplicity First** | Minimum code, no speculative features, no over-abstraction | Overcomplicated solutions |
| **Surgical Changes** | Touch only what you must, match existing style | Collateral damage in diffs |
| **Goal-Driven Execution** | Every task has explicit success criteria, verify before moving on | Tasks that can't self-verify |

### Setup Behavioral Guidelines

```
/speckit.autopilot.constitution
```

This appends the guidelines to `.specify/constitution.md` (idempotent — safe to run multiple times). The autopilot pipeline runs this automatically before the first phase.

### How Rules Apply to Tasks

- **Goal-Driven**: Every task must include success criteria — not just "implement X" but "implement X, verify: {check}"
- **Simplicity**: One responsibility per task. If a task does three things, it gets split.
- **Surgical**: Every task specifies exact file paths. No "update related files" vagueness.
- **Think First**: Ambiguous tasks include a sub-step to surface assumptions before implementing.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     AUTOPILOT ORCHESTRATOR                       │
│                                                                  │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────────┐ │
│  │ SPECIFY  │──▶│ CLARIFY  │──▶│   PLAN   │──▶│    TASKS     │ │
│  │ (core)   │   │ (core +  │   │ (core)   │   │ (core + test │ │
│  │          │   │  auto-   │   │          │   │  enforcement)│ │
│  │          │   │  answer) │   │          │   │              │ │
│  └──────────┘   └──────────┘   └──────────┘   └──────┬───────┘ │
│       │              │              │                  │         │
│       ▼              ▼              ▼                  ▼         │
│  [state.json]   [state.json]  [state.json]     [validate +     │
│   update         update        update           state.json]     │
│                                            │                     │
│                                            ▼                     │
│                                   ┌──────────────┐              │
│                                   │  IMPLEMENT   │              │
│                                   │  (core +     │              │
│                                   │  self-val)   │              │
│                                   └──────┬───────┘              │
│                                          │                      │
│                                          ▼                      │
│                                  [validate + state.json]        │
│                                                                  │
│  Pipeline State File: FEATURE_DIR/autopilot-state.json           │
└─────────────────────────────────────────────────────────────────┘
```

Key design decisions:
- **Orchestrator, not re-implementer** — Delegates to core commands, survives spec-kit updates
- **State file over file-scanning** — `autopilot-state.json` gives precise resume, no guessing
- **Post-generation validation** — Verifies test coverage was actually generated, auto-fixes gaps
- **Additive enhancements** — Test strategy injection appends to core artifacts, doesn't modify them

## Commands

| Command | Description |
|---------|-------------|
| `/speckit.autopilot.run` | Run the full pipeline |
| `/speckit.autopilot.start` | Alias for `run` |
| `/speckit.autopilot.status` | Check pipeline progress |
| `/speckit.autopilot.validate` | Validate test coverage, self-validation, and behavioral compliance |
| `/speckit.autopilot.constitution` | Merge behavioral guidelines into project constitution |

## Requirements

- spec-kit >= 0.1.0
- Core commands: `speckit.specify`, `speckit.clarify`, `speckit.plan`, `speckit.tasks`, `speckit.implement`

## License

MIT
