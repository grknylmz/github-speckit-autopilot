# Spec Kit Autopilot

A [spec-kit](https://github.com/github/spec-kit) extension that provides an automated pipeline for spec-driven development. One command chains through specify, clarify, plan, and tasks — with auto-answered clarifications, enforced unit + integration test coverage, and pipeline state tracking for reliable resume.

## Features

- **One-command pipeline**: `/speckit.autopilot.run <feature description>` orchestrates the entire workflow
- **Delegates to core commands**: Orchestrates rather than re-implements — stays compatible as spec-kit evolves
- **Auto-answered clarifications**: All specification questions answered using best-practice recommendations
- **Enforced test coverage**: Every generated task includes unit tests and integration tests with post-generation validation
- **Pipeline state file**: `autopilot-state.json` tracks exact phase status for reliable resume and status checks
- **Configurable phases**: Skip phases, reorder them, or chain into implementation
- **Validation command**: `/speckit.autopilot.validate` verifies test coverage with auto-fix

## Installation

```bash
cd /path/to/your/spec-kit-project
specify extension add --dev /path/to/github-speckit-autopilot
```

Or from a repository:

```bash
specify extension add autopilot --from https://github.com/gurkanyilmaz/github-speckit-autopilot
```

Verify installation:

```bash
specify extension list
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
4. **Tasks** — Delegates to `/speckit.tasks` with test enforcement override (tests are mandatory)
5. **Validate** — Built-in validation checks that all implementation tasks have corresponding tests

### Check Pipeline Status

```
/speckit.autopilot.status
```

Reads the pipeline state file and scans artifacts. Shows which phases are complete, task counts, test coverage status, and recommends the next action.

### Validate Test Coverage

```
/speckit.autopilot.validate
```

Runs 6 validation checks on `tasks.md`:
1. Implementation tasks have unit tests
2. Integration points have integration tests
3. TDD ordering (tests before implementation)
4. Test file paths are specified
5. Coverage sweep task exists
6. Task IDs are sequential

Offers auto-fix for any issues found.

### Resume a Failed Pipeline

Just re-run the same command — the state file tracks exactly where to resume:

```
/speckit.autopilot.run
```

### After Autopilot

- `/speckit.implement` — Execute the generated task plan
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
  chain_implement: false  # set true to auto-run /speckit.implement
```

Common configurations:
- **Full pipeline**: `[specify, clarify, plan, tasks]`
- **Skip clarify**: `[specify, plan, tasks]`
- **Re-plan only**: `[plan, tasks]`
- **Tasks only**: `[tasks]`

### All Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `test_enforcement.unit_tests` | `true` | Generate unit test tasks |
| `test_enforcement.integration_tests` | `true` | Generate integration test tasks |
| `test_enforcement.coverage_target` | `80` | Minimum coverage percentage |
| `test_enforcement.test_framework` | `"auto-detect"` | Test framework to use |
| `clarify.auto_answer` | `true` | Auto-answer clarification questions |
| `clarify.use_recommended` | `true` | Use AI-recommended option |
| `clarify.max_auto_questions` | `5` | Max questions to auto-answer |
| `pipeline.phases` | `[specify, clarify, plan, tasks]` | Phases to execute |
| `pipeline.chain_implement` | `false` | Auto-run implement after tasks |
| `pipeline.stop_on_failure` | `true` | Stop on any phase failure |

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
| `/speckit.autopilot.validate` | Validate test coverage in tasks |

## Requirements

- spec-kit >= 0.1.0
- Core commands: `speckit.specify`, `speckit.clarify`, `speckit.plan`, `speckit.tasks`

## License

MIT
