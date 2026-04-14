# Speckit Autopilot — Copilot Instructions

This project uses a spec-driven development pipeline called Spec Kit Autopilot. When working on features or tasks in this repository, follow the rules and conventions below.

## Command Authority

When the user invokes `speckit.autopilot.run` or asks to run the autopilot pipeline, treat the command files in `commands/` as the authoritative workflow definition.

- Read `commands/speckit.autopilot.run.md` and follow it instead of inventing a parallel inline workflow.
- When that workflow delegates to companion autopilot commands, use the matching files in `commands/` as the source of truth: `speckit.autopilot.constitution`, `speckit.autopilot.verify`, `speckit.autopilot.validate`, and `speckit.autopilot.status`.
- Use `/speckit.autopilot.run` as the only entrypoint. Do not use or suggest `speckit.autopilot.start`.

## Pipeline Architecture

Features are built through a 7-phase pipeline:

1. **Specify** — Generate a feature specification in `spec.md`
2. **Clarify** — Resolve ambiguities in the spec (auto-answered in autopilot mode)
3. **Plan** — Create implementation plan in `plan.md`, plus `data-model.md`, `contracts/`, `quickstart.md`
4. **Tasks** — Generate task list in `tasks.md` with enforced test coverage
5. **Implement** — Execute all tasks in order, run self-validation checks
6. **Verify** — Start the application, run health checks, diagnose issues, self-heal
7. **Validate** — Confirm all artifacts, tests, and self-validation checks pass

Pipeline state is tracked in `FEATURE_DIR/autopilot-state.json`.

## Behavioral Rules

When generating or executing tasks, follow these four rules:

### Rule 1: Think Before Coding

- State assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so.
- If something is unclear, stop and ask.

### Rule 2: Simplicity First

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

### Rule 3: Surgical Changes

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- Every changed line should trace directly to the user's request.

### Rule 4: Goal-Driven Execution

- Every task must include explicit success criteria.
- Transform "implement X" into "implement X, verify: {check}".
- For multi-step tasks, state a plan with verification at each step.

## Three-Pillar Enforcement

Every implementation task MUST have all three pillars:

1. **Unit tests** — Test individual functions/methods in isolation
2. **Integration tests** — Test components working together (API endpoints, database, external services)
3. **Self-validation** — A runnable check the system executes to confirm the feature works without human intervention

Tests are ALWAYS MANDATORY in autopilot mode. There is no "optional" test generation.

## Self-Validation Techniques

Each implementation task requires at least one self-validation step:

| Technique           | When to Use                     | Example                                                   |
| ------------------- | ------------------------------- | --------------------------------------------------------- |
| **Logging**         | Data processing, business logic | Log structured output; check log contains expected values |
| **Smoke test**      | API endpoints, CLI commands     | `curl -f http://localhost:3000/api/health`                |
| **Assertion**       | Calculations, transformations   | `assert(result > 0)`                                      |
| **Build**           | New modules, components         | `npm run build && npm run typecheck` with zero errors     |
| **Schema**          | Data models, migrations         | `npx prisma validate`                                     |
| **Health endpoint** | Services, APIs                  | `GET /health` returns `{status: "ok"}`                    |
| **Dry-run**         | Destructive operations          | `--dry-run` flag outputs what would happen                |
| **Idempotency**     | State mutations                 | Run twice, verify identical state                         |
| **Contract**        | API integrations                | Response matches expected JSON schema                     |
| **Snapshot**        | Output generation, reports      | Compare output against golden snapshot                    |

## Task Format

Tasks in `tasks.md` follow this format:

```markdown
- [ ] T{NNN} [US{N}] {task description}
  - Detail line 1
  - Detail line 2
```

- `T{NNN}` = sequential task ID (T001, T002, ...)
- `[US{N}]` = user story reference (optional)
- Completed tasks use `- [x]` or `- [X]`

### Self-Validation Task Format

```markdown
- [ ] T{NNN} [US{N}] Add self-validation for {Component} in {source-path}
  - Technique: {logging|smoke|assertion|build|schema|health|dry-run|idempotency|contract|snapshot}
  - Validation: {specific check to execute}
  - Success criteria: {what "pass" looks like}
```

## Key File Paths

| File                                                 | Purpose                         |
| ---------------------------------------------------- | ------------------------------- |
| `.specify/specs/{feature}/spec.md`                   | Feature specification           |
| `.specify/specs/{feature}/plan.md`                   | Implementation plan             |
| `.specify/specs/{feature}/tasks.md`                  | Task list                       |
| `.specify/specs/{feature}/autopilot-state.json`      | Pipeline state tracking         |
| `.specify/specs/{feature}/validation-results.log`    | Self-validation results         |
| `.specify/specs/{feature}/verify-results.log`        | Runtime verification results    |
| `.specify/extensions/autopilot/autopilot-config.yml` | Autopilot configuration         |
| `.specify/constitution.md`                           | Project behavioral constitution |

## Configuration

Read `.specify/extensions/autopilot/autopilot-config.yml` for pipeline settings. Key settings:

- `pipeline.phases` — Which phases to run (default: all 7)
- `pipeline.stop_on_failure` — Halt on phase failure (default: true)
- `test_enforcement.coverage_target` — Minimum test coverage % (default: 80)
- `verify.max_iterations` — Max self-heal loops (default: 5)
- `verify.auto_heal` — Generate fix tasks on failure (default: true)

## Task Ordering (TDD)

Within each user story, tasks follow this order:

1. Unit test tasks (before the implementation they test)
2. Implementation tasks (with self-validation built in)
3. Self-validation task (explicit verification step)
4. Integration test tasks (after the components they integrate)

## State File

Generate the bootstrap `autopilot-state.json` immediately when `/speckit.autopilot.run` starts. If the feature directory already exists, write it at once; if the run is creating a brand-new feature, write it immediately after `/speckit.specify` creates the feature directory. Pipeline state is then tracked in `autopilot-state.json` with phase statuses: `pending`, `running`, `complete`, `failed`. The verify phase has additional statuses: `healthy`, `degraded`, `healing`.
