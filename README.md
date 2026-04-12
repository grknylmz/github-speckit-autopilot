# Spec Kit Autopilot

A [spec-kit](https://github.com/github/spec-kit) extension that provides an automated pipeline for spec-driven development. Run a single command and the autopilot chains through specify, clarify, plan, and tasks — with auto-answered clarifications and enforced unit + integration test coverage.

## Features

- **One-command pipeline**: `/speckit.autopilot.run <feature description>` runs the entire workflow
- **Auto-answered clarifications**: All specification clarification questions are answered using best-practice recommendations
- **Enforced test coverage**: Every generated task includes unit tests and integration tests — no optional test skipping
- **Pipeline status check**: `/speckit.autopilot.status` shows which phases are complete and what's next
- **Resume support**: Re-running autopilot detects existing artifacts and resumes from the right phase

## Installation

```bash
cd /path/to/your/spec-kit-project
specify extension add --dev /path/to/github-speckit-autopilot
```

Or install from the repository:

```bash
specify extension add autopilot --from https://github.com/gurkanyilmaz/github-speckit-autopilot
```

## Usage

### Run the Full Pipeline

```
/speckit.autopilot.run Add user authentication with OAuth2 and JWT tokens
```

This single command will:

1. **Specify** — Generate a feature specification from your description
2. **Clarify** — Auto-answer up to 5 clarification questions with recommended options
3. **Plan** — Generate the implementation plan with data models and contracts
4. **Tasks** — Generate dependency-ordered tasks with enforced unit + integration tests

### Check Pipeline Status

```
/speckit.autopilot.status
```

Shows which phases are complete, what artifacts exist, and suggests the next command.

### After Autopilot

Once the pipeline completes, you can:

- `/speckit.implement` — Execute the generated task plan
- `/speckit.analyze` — Check for cross-artifact consistency

## Configuration

Configuration is stored in `.specify/extensions/autopilot/autopilot-config.yml`. Key settings:

| Setting | Default | Description |
|---------|---------|-------------|
| `test_enforcement.unit_tests` | `true` | Always generate unit test tasks |
| `test_enforcement.integration_tests` | `true` | Always generate integration test tasks |
| `test_enforcement.coverage_target` | `80` | Minimum test coverage percentage |
| `clarify.auto_answer` | `true` | Auto-answer clarification questions |
| `clarify.use_recommended` | `true` | Use AI-recommended option for each question |
| `clarify.max_auto_questions` | `5` | Max clarification questions to auto-answer |
| `pipeline.stop_on_failure` | `true` | Stop pipeline if any phase fails |

## Pipeline Phases

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌──────────────────┐
│   SPECIFY   │────▶│   CLARIFY   │────▶│    PLAN     │────▶│     TASKS        │
│             │     │  (auto-     │     │             │     │  (with enforced   │
│  Generate   │     │  answered)  │     │  Research,  │     │  unit + integ.    │
│  feature    │     │             │     │  data model,│     │  tests)           │
│  spec       │     │  Resolve    │     │  contracts  │     │                   │
│             │     │  ambiguity  │     │             │     │                   │
└─────────────┘     └─────────────┘     └─────────────┘     └──────────────────┘
```

## Test Enforcement

This is the core differentiator of the autopilot extension. The standard spec-kit tasks command makes tests optional. Autopilot overrides this:

- **Every implementation task** gets a corresponding unit test task
- **Every integration point** gets a corresponding integration test task
- **Test tasks appear before implementation tasks** in each phase (TDD ordering)
- **Coverage target** is enforced at the final polish phase

## Requirements

- spec-kit >= 0.1.0
- Core commands: `speckit.specify`, `speckit.clarify`, `speckit.plan`, `speckit.tasks`

## License

MIT
