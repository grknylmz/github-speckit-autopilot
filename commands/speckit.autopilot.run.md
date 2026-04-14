---
description: 'Orchestrate the full spec-kit pipeline: specify → clarify (auto-answer) → plan → tasks → implement → verify (runtime health + self-heal) → validate. Delegates to core commands and applies autopilot-specific post-processing.'
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --paths-only
  ps: scripts/powershell/check-prerequisites.ps1 -Json -PathsOnly
---

# Spec Kit Autopilot

Orchestrates the full spec-kit pipeline automatically. This command **delegates** to the core spec-kit commands (`/speckit.specify`, `/speckit.clarify`, `/speckit.plan`, `/speckit.tasks`, `/speckit.implement`) and adds an automation layer on top: auto-answered clarifications, enforced test coverage, self-validating tasks, task execution, and pipeline state tracking.

**Three mandatory pillars for every task**:

1. **Unit tests** — Verify individual functions/methods work in isolation
2. **Integration tests** — Verify components work together correctly
3. **Self-validation** — Each feature built must include a runnable verification that the autopilot can execute to confirm it works without human intervention

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Architecture

This command is an **orchestrator**, not a re-implementation. It:

1. Runs each core command in sequence
2. Intercepts and auto-answers clarification questions
3. Post-processes generated tasks to enforce test coverage and self-validation
4. Persists pipeline state for resume support

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
│                                   │  IMPLEMENT   │◀────┐        │
│                                   │  (core +     │     │        │
│                                   │  self-val)   │     │        │
│                                   └──────┬───────┘     │        │
│                                          │             │        │
│                                          ▼             │        │
│                                  ┌──────────────┐     │        │
│                                  │   VERIFY     │─────┘        │
│                                  │ (start +     │  (self-heal  │
│                                  │  health +    │   loop when   │
│                                  │  diagnose +  │   fix tasks   │
│                                  │  self-heal)  │   created)    │
│                                  └──────┬───────┘              │
│                                         │                       │
│                                         ▼                       │
│                                  ┌──────────────┐              │
│                                  │  VALIDATE    │              │
│                                  │  (built-in)  │              │
│                                  └──────────────┘              │
│                                                                  │
│  Pipeline State File: FEATURE_DIR/autopilot-state.json           │
└─────────────────────────────────────────────────────────────────┘
```

---

## Step 0: Initialization

### 0.0 Ensure Behavioral Constitution

Before any pipeline phase runs, ensure the project constitution includes autopilot behavioral guidelines:

1. Check if the constitution file (`.specify/constitution.md` or `/memory/constitution.md`) contains the `AUTOPILOT-BEHAVIORAL-GUIDELINES` marker.
2. If the marker is **not present**, execute `/speckit.autopilot.constitution` to merge the guidelines into the constitution.
3. If the marker **is present**, skip — guidelines are already in place.
4. These guidelines will be loaded by `/speckit.plan` during its constitution check phase, ensuring all subsequent tasks follow the behavioral rules.

**The 4 behavioral rules** (enforced throughout the pipeline):

- **Think Before Coding** — State assumptions, surface tradeoffs, ask before assuming
- **Simplicity First** — Minimum code, no speculative features, no over-abstraction
- **Surgical Changes** — Touch only what you must, match existing style
- **Goal-Driven Execution** — Every task has explicit success criteria, verify before moving on

### 0.1 Load Configuration

Read `.specify/extensions/autopilot/autopilot-config.yml` if it exists. Merge with extension defaults. Key configuration:

- `pipeline.phases` — Ordered list of phases to run (default: `["specify", "clarify", "plan", "tasks", "implement", "verify", "validate"]`). If `implement` is present, `validate` must remain the last phase.
- `pipeline.stop_on_failure` — Halt on any phase failure (default: `true`).
- `clarify.auto_answer` — Auto-answer clarification questions (default: `true`).
- `clarify.use_recommended` — Use recommended option (default: `true`).
- `clarify.max_auto_questions` — Max questions to auto-answer (default: `5`).
- `test_enforcement.unit_tests` — Enforce unit tests (always `true` in autopilot).
- `test_enforcement.integration_tests` — Enforce integration tests (always `true` in autopilot).
- `self_validation.enabled` — Enforce self-validation tasks (always `true` in autopilot).
- `self_validation.techniques` — Validation techniques to include (default: `["logging", "smoke", "assertion"]`).
- `verify.max_iterations` — Maximum self-heal loops (default: `5`).
- `verify.startup_timeout_seconds` — Seconds to wait for app startup (default: `30`).
- `verify.health_retries` — Health endpoint check retries (default: `3`).
- `verify.auto_heal` — Generate fix tasks and loop back on failure (default: `true`).
- `verify.endpoints` — Explicit endpoints to verify (default: `[]`, auto-detected).

### 0.2 Detect or Create Feature Directory

Run `{SCRIPT}` from repo root and parse JSON payload for `FEATURE_DIR` and `FEATURE_SPEC`.

**If the script returns valid paths** (feature already exists):

- Read `FEATURE_DIR/autopilot-state.json` if it exists to determine resume point.
- If no state file, scan artifacts to determine resume point (see Resume Logic below).

**If the script fails or no feature exists**:

- The feature directory will be created by `/speckit.specify` in Phase 1.

### 0.3 Resume Logic

If `FEATURE_DIR/autopilot-state.json` exists, read it and determine which phases have already completed:

```json
{
	"pipeline_id": "autopilot-YYYYMMDD-HHMMSS",
	"feature_directory": "specs/003-feature-name",
	"phases": {
		"specify": { "status": "complete", "completed_at": "..." },
		"clarify": {
			"status": "complete",
			"completed_at": "...",
			"questions_answered": 4
		},
		"plan": { "status": "failed", "error": "..." },
		"tasks": { "status": "pending" },
		"implement": { "status": "pending" },
		"verify": { "status": "pending" },
		"validate": { "status": "pending" }
	},
	"started_at": "...",
	"last_updated_at": "..."
}
```

**Resume rules**:

- Phase with `status: "complete"` → Skip
- Phase with `status: "failed"` → Retry (if `pipeline.stop_on_failure` is true, ask user first)
- Phase with `status: "pending"` or missing → Execute
- `verify.status: "healing"` → Re-trigger implement phase, then re-verify (self-heal loop)
- If all configured phases are `complete` and `validate` is not `complete` → Run validation and report
- If all configured phases including `validate` are `complete` → Report success without re-running phases

If no state file exists, fall back to artifact detection:

- `spec.md` exists → Specify is done, start from next incomplete phase
- `spec.md` has `## Clarifications` section with `Autopilot Session` → Clarify is done
- `plan.md` exists → Plan is done
- `tasks.md` exists → Tasks are done
- `tasks.md` has all tasks marked `[X]` or `[x]` → Implement is done; run verify next if configured, otherwise run validation

### 0.4 Initialize State File

Create or update `FEATURE_DIR/autopilot-state.json`:

```json
{
	"pipeline_id": "autopilot-YYYYMMDD-HHMMSS",
	"feature_directory": "<resolved-path>",
	"phases": {
		"specify": { "status": "pending" },
		"clarify": { "status": "pending" },
		"plan": { "status": "pending" },
		"tasks": { "status": "pending" },
		"implement": { "status": "pending" },
		"verify": { "status": "pending" },
		"validate": { "status": "pending" }
	},
	"started_at": "<ISO-timestamp>",
	"last_updated_at": "<ISO-timestamp>"
}
```

Update the state file **after each phase completes** (success or failure).

---

## Step 1: SPECIFY (Delegate to Core)

**Skip if** `specify` is not in `pipeline.phases` or state shows `complete`.

### 1.1 Execute

Run the `/speckit.specify` command workflow with the user's feature description (`$ARGUMENTS`). **Follow the core command's instructions exactly** — do not re-implement its logic. The core command handles:

- Short name generation
- Feature directory and spec file creation
- Specification quality validation
- Checklist generation
- Extension hook checking

### 1.2 Autopilot Override: Auto-Resolve NEEDS CLARIFICATION

After the core specify command writes the spec, **if any `[NEEDS CLARIFICATION: ...]` markers remain** (the core command limits these to 3 max):

- For each marker, resolve it immediately using context and industry best practices
- Replace the marker with a concrete decision
- Document the resolution in the spec's Assumptions section

Do NOT present clarification questions to the user at this stage — the clarify phase handles that.

### 1.3 Update State

Update `autopilot-state.json`:

```json
"specify": {
  "status": "complete",
  "completed_at": "<ISO-timestamp>",
  "spec_file": "<path>",
  "feature_directory": "<path>"
}
```

### 1.4 Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AUTOMATION PHASE 1/4: SPECIFY ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Feature Directory: {path}
Spec File: {path}
Clarifications auto-resolved: {N}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**On failure**: Update state with `"status": "failed"` and error details. If `pipeline.stop_on_failure` is true, stop and report.

---

## Step 2: CLARIFY (Delegate + Auto-Answer Interception)

**Skip if** `clarify` is not in `pipeline.phases` or state shows `complete`.

This phase runs the core `/speckit.clarify` command but **intercepts the interactive questioning loop** to auto-answer.

### 2.1 Execute with Auto-Answer Mode

Run the `/speckit.clarify` command workflow. **Follow the core command's instructions** for:

- Running prerequisite scripts
- Loading the spec file
- Performing the structured ambiguity scan across the full taxonomy
- Generating the prioritized queue of clarification questions

### 2.2 Autopilot Override: Auto-Answer All Questions

**Instead of presenting questions to the user one at a time** (which the core command normally does), the autopilot intercepts:

For **each** clarification question (up to `clarify.max_auto_questions`):

1. Read the question and its options
2. Determine the **recommended option** using:
   - Best practices for the detected project type
   - Risk reduction (security > performance > maintainability)
   - Alignment with explicit project goals in the spec
3. **Select the recommended option automatically** — do NOT output the question or wait for user input
4. Record: `Auto-answered: [option] — [rationale]`
5. Apply the clarification to the spec immediately (per core command's integration rules)

For any **remaining ambiguities** beyond `max_auto_questions`:

- Make informed guesses based on context
- Document in the spec's Assumptions section

### 2.3 Clarification Section Format

Write all auto-answers into the spec under:

```markdown
## Clarifications

### Autopilot Session YYYY-MM-DD

> Autopilot auto-answered all clarification questions using recommended options.

- Q: {question} → A: {answer} (Recommended — {1-sentence rationale})
```

Then apply each answer to the relevant spec sections following the core command's integration rules (functional requirements, data model, success criteria, etc.).

### 2.4 Update State

```json
"clarify": {
  "status": "complete",
  "completed_at": "<ISO-timestamp>",
  "questions_answered": N,
  "categories_addressed": ["Functional Scope", "Data Model", "..."]
}
```

### 2.5 Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AUTOMATION PHASE 2/4: CLARIFY ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Questions Auto-Answered: {N} / {max}
Categories: {list}
Spec Updated: {path}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Step 3: PLAN (Delegate to Core)

**Skip if** `plan` is not in `pipeline.phases` or state shows `complete`.

### 3.1 Execute

Run the `/speckit.plan` command workflow. **Follow the core command's instructions exactly** for:

- Running setup scripts
- Loading the spec and constitution
- Technical context, constitution check, gate evaluation
- Phase 0: Research (resolve NEEDS CLARIFICATION)
- Phase 1: Data model, contracts, quickstart, agent context update

### 3.2 Autopilot Enhancement: Test Strategy Injection

**After** the core plan command completes, enhance the generated artifacts with testing information:

1. In `plan.md` Technical Context section, ensure the test framework and strategy are documented
2. If `data-model.md` was generated, append a `## Validation Test Scenarios` section listing testable constraints per entity
3. If `contracts/` were generated, ensure each contract includes test expectations

These enhancements are **additive** — they append to what the core command already produced, without modifying existing content.

### 3.3 Update State

```json
"plan": {
  "status": "complete",
  "completed_at": "<ISO-timestamp>",
  "artifacts": ["plan.md", "data-model.md", "contracts/", "..."],
  "test_framework": "<detected-or-configured>"
}
```

### 3.4 Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AUTOMATION PHASE 3/4: PLAN ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Plan File: {path}
Artifacts: {list}
Test Framework: {detected}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Step 4: TASKS (Delegate + Test Enforcement Post-Processing)

**Skip if** `tasks` is not in `pipeline.phases` or state shows `complete`.

### 4.1 Execute with Override

Run the `/speckit.tasks` command workflow. **Follow the core command's instructions** for:

- Running prerequisite scripts
- Loading all design artifacts (including constitution with behavioral guidelines)
- Task generation organized by user story
- Dependency graph, parallel execution examples

**Behavioral rule enforcement during task generation**:

- **Goal-Driven Execution (Rule 4)**: Every task description must include explicit success criteria — not just "implement X" but "implement X, verify: {check}". Tasks without success criteria are rejected.
- **Simplicity First (Rule 2)**: Each task must have one clear responsibility. If a task does three things, split it into three tasks. No speculative additions beyond what the spec/plan requires.
- **Surgical Changes (Rule 3)**: Task descriptions must specify exact file paths. No vague "update related files" tasks. Every changed line must trace to the spec.
- **Think Before Coding (Rule 1)**: If a task has ambiguous requirements, include a sub-step to surface assumptions before implementing.

### 4.2 Autopilot Override: Tests + Self-Validation Are Mandatory

**Override the core command's default behavior**: The core `/speckit.tasks` says "Tests are OPTIONAL". The autopilot **inverts this rule**:

- **Tests are ALWAYS MANDATORY** when run through autopilot
- Every implementation task that creates/modifies code MUST have corresponding test tasks
- Every feature built MUST include a self-validation step the autopilot can execute to confirm it works
- Apply the enforcement rules below during generation

### 4.3 Three-Pillar Enforcement Rules

These rules apply when generating tasks. They are **non-negotiable** in autopilot mode.

#### Pillar 1: Unit Tests

Required for every task that:

- Creates or modifies a function, method, class, or component
- Implements business logic, validation, or data transformation
- Creates a utility, helper, or service method
- Builds an API endpoint handler

#### Pillar 2: Integration Tests

Required for every task that:

- Connects to a database or external data store
- Creates or modifies an API endpoint
- Integrates with an external service or API
- Implements middleware, auth, or event handling
- Performs file I/O or message queue operations

#### Pillar 3: Self-Validation (CRITICAL)

**Every implementation task MUST include a self-validation mechanism** — a runnable check that the autopilot can execute to confirm the feature works without human intervention.

Self-validation answers the question: "After this task is implemented, how can the system prove to itself that it works?"

**Self-validation techniques** (at least ONE per implementation task, choose the most appropriate):

| Technique                  | When to Use                                                                 | Example                                                                                                          |
| -------------------------- | --------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- | --- | --------------------------------------------- |
| **Logging**                | Any task that processes data, handles requests, or performs transformations | `logger.info("Order created", {id, total, items_count});` — autopilot checks log output contains expected values |
| **Smoke test**             | API endpoints, services, CLI commands, UI components                        | `curl -f http://localhost:3000/api/health                                                                        |     | exit 1` — autopilot runs and checks exit code |
| **Assertion check**        | Business logic, calculations, data transformations                          | `assert(user.age >= 0, "Age must be non-negative")` — autopilot runs assertions                                  |
| **Build verification**     | New modules, components, configurations                                     | `npm run build && npm run typecheck` — autopilot confirms zero errors                                            |
| **Schema/file validation** | Data models, config files, migrations                                       | `npx prisma validate && npx prisma migrate status` — autopilot confirms schema is valid                          |
| **Health endpoint**        | Services, APIs, servers                                                     | `GET /health` returns `{status: "ok", version: "..."}` — autopilot calls and verifies response                   |
| **Dry-run / preview**      | Destructive or complex operations                                           | `--dry-run` flag that outputs what would happen without executing — autopilot checks output                      |
| **Idempotency check**      | State mutations, database writes                                            | Run twice, verify output/state is identical — autopilot detects drift                                            |
| **Contract assertion**     | APIs, integrations                                                          | Response matches expected JSON schema — autopilot validates schema                                               |
| **Snapshot comparison**    | Output generation, reports, templates                                       | Compare output against golden snapshot — autopilot detects deviations                                            |

**Self-validation task format**:

```text
- [ ] T{NNN} [US{N}] Add self-validation for {Component} in {source-path}
  - Technique: {logging|smoke|assertion|build|schema|health|dry-run|idempotency|contract|snapshot}
  - Validation: {specific check the autopilot will execute}
  - Success criteria: {what "pass" looks like — exit code 0, log contains X, response matches Y}
```

**Examples**:

```text
- [ ] T{NNN} [US1] Add self-validation for OrderService in src/services/order.service.ts
  - Technique: logging + assertion
  - Validation: Log order creation with id, total, items_count; assert total > 0 after calculation
  - Success criteria: Log line "[OrderService] Created order {id} total=${total} items={N}" appears; assert(total > 0) passes

- [ ] T{NNN} [US1] Add self-validation for POST /api/orders endpoint in src/routes/orders.ts
  - Technique: smoke test + health endpoint
  - Validation: curl -f -X POST /api/orders with valid payload returns 201; GET /api/health returns ok
  - Success criteria: HTTP 201 with {id, status: "created"}; health endpoint returns 200

- [ ] T{NNN} [US2] Add self-validation for user schema migration in migrations/001_users.sql
  - Technique: schema validation
  - Validation: npx prisma validate && npx prisma migrate status
  - Success criteria: "Schema is valid" + "Database schema is up to date"
```

#### Task ordering (TDD approach within each user story phase):

1. Unit test tasks first (before the implementation they test)
2. Implementation tasks (with self-validation built into the implementation)
3. Self-validation task (explicit verification step the autopilot runs)
4. Integration test tasks (after the components they integrate)

**Complete task format per implementation unit**:

```text
- [ ] T{NNN} [P] [US{N}] Write unit tests for {Component} in {test-path}
  - Test: {scenario 1}
  - Test: {scenario 2}
- [ ] T{NNN} [P] [US{N}] Implement {Component} in {source-path}
- [ ] T{NNN} [US{N}] Add self-validation for {Component} in {source-path}
  - Technique: {technique}
  - Validation: {check}
  - Success criteria: {expected outcome}
- [ ] T{NNN} [P] [US{N}] Write integration tests for {Feature} in {test-path}
  - Test: {scenario 1}
  - Test: {scenario 2}
```

#### Final phase must include:

```text
- [ ] T{NNN} Run full unit test suite and verify all pass
- [ ] T{NNN} Run full integration test suite and verify all pass
- [ ] T{NNN} Verify test coverage meets target ({coverage_target}%)
- [ ] T{NNN} Execute all self-validation steps and confirm each passes
  - For each self-validation task: run the validation command, check success criteria
  - Log results to FEATURE_DIR/validation-results.log
- [ ] T{NNN} Generate validation report from self-validation results
```

### 4.4 Post-Generation Validation

**After** tasks.md is written, run an inline validation:

1. Parse all task lines from `tasks.md`
2. Count:
   - `impl_tasks` — tasks containing "Implement", "Create", "Build", "Add" (excluding test/validation tasks)
   - `unit_test_tasks` — tasks containing "unit test" (case-insensitive)
   - `integ_test_tasks` — tasks containing "integration test" (case-insensitive)
   - `self_validation_tasks` — tasks containing "self-validation" or "self validation" (case-insensitive)
3. Check:
   - `unit_test_tasks >= impl_tasks * 0.5` (at least 1 unit test per 2 implementation tasks)
   - `integ_test_tasks >= 1` (at least 1 integration test task exists)
   - `self_validation_tasks >= impl_tasks * 0.5` (at least 1 self-validation per 2 implementation tasks)
   - Every self-validation task specifies a technique and success criteria
4. If validation fails:
   - **Inject missing test tasks** into `tasks.md` at the appropriate positions
   - **Inject missing self-validation tasks** — generate appropriate self-validation for each uncovered implementation task
   - Re-number all task IDs to maintain sequential order
   - Log what was injected

### 4.5 Update State

```json
"tasks": {
  "status": "complete",
  "completed_at": "<ISO-timestamp>",
  "total_tasks": N,
  "unit_test_tasks": N,
  "integration_test_tasks": N,
  "self_validation_tasks": N,
  "implementation_tasks": N,
  "validation_passed": true
}
```

### 4.6 Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AUTOMATION PHASE 4/4: TASKS (3-Pillar Enforced) ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Tasks File: {path}
Total Tasks: {N}
  Implementation:     {N}
  Unit Tests:         {N}
  Integration Tests:  {N}
  Self-Validation:    {N}
Validation: ✓ All implementation tasks have tests + self-validation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Step 5: IMPLEMENT (Delegate + Self-Validation Execution)

**Skip if** `implement` is not in `pipeline.phases` or state shows `complete`.

### 5.1 Execute

Run the `/speckit.implement` command workflow. **Follow the core command's instructions exactly** — do not re-implement its logic. The core command handles:

- Pre-execution extension hook checking
- Checklist status validation
- Project setup verification (ignore files)
- Task parsing and phase-by-phase execution
- Progress tracking and error handling
- Completion validation
- Post-implementation extension hook checking

### 5.2 Autopilot Enhancement: Execute Self-Validation Steps

**After** the core implement command completes all tasks, execute the self-validation steps that were defined during the Tasks phase:

1. Parse `tasks.md` for all self-validation tasks (lines containing "self-validation" or "self validation")
2. For each self-validation task:
   - Execute the validation command/check described in the task
   - Evaluate against the success criteria defined in the task
   - Record the result (PASS/FAIL) with details
3. Write results to `FEATURE_DIR/validation-results.log`:
   ```
   Self-Validation Results — {timestamp}
   ============================================================
   T{NNN}: {description}
     Technique: {technique}
     Validation: {check executed}
     Result: ✓ PASS / ✗ FAIL
     Details: {output or error message}
   ---
   Summary: {N}/{M} passed
   ============================================================
   ```
4. If any self-validation fails:
   - Report the failures with details
   - Update state with failure information

- Do NOT proceed to the automatic validate pass or verify — let the user investigate

### 5.3 Autopilot Gate: Run Validate Immediately After Implement

After self-validation passes, invoke `/speckit.autopilot.validate` immediately.

- This post-implementation validate pass is **mandatory after every successful implement cycle**, including verify-triggered self-heal iterations.
- Treat it as a quality gate before runtime verification.
- During this pass, post-verify checks may be skipped if verify has not run yet. That is expected.
- If validate reports failures:
  - Set `validate.status: "failed"` with failure details.
  - Stop the pipeline before Step 6.
  - Re-running the autopilot resumes from the failed validation state.

### 5.4 Update State

```json
"implement": {
  "status": "complete",
  "completed_at": "<ISO-timestamp>",
  "tasks_total": N,
  "tasks_completed": N,
  "tests_passed": true,
  "self_validation_passed": true,
  "self_validation_results": "<path-to-validation-log>",
  "validation_results_path": "FEATURE_DIR/validation-results.log"
}
```

### 5.5 Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AUTOMATION PHASE 5/7: IMPLEMENT (Core + Self-Validation) ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Tasks Completed:  {N} / {N}
Test Suite:       {✓ PASSED / ✗ FAILED}
Self-Validation:  {N} / {N} passed
Results Log:      {path}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**On failure**: Update state with `"status": "failed"` and error details. The core implement command marks completed tasks as `[X]` in `tasks.md`, so re-running will skip completed tasks and resume from the failed one.

---

## Step 6: VERIFY (Delegate + Self-Heal Loop)

**Skip if** `verify` is not in `pipeline.phases` or state shows `complete`.

**Prerequisite**: The implement phase must have status `complete` and the most recent post-implementation validate pass must have succeeded before verify runs.

### 6.1 Loop Controller

The verify phase may execute multiple times (each time followed by a re-implementation of fix tasks). The loop is controlled by:

- `verify.max_iterations` from config (default: 5)
- Current iteration tracked in `autopilot-state.json` under `verify.iteration`

On first entry, iteration is 0. Each self-heal cycle increments it by 1.

If `verify.iteration >= verify.max_iterations`:

- Report: "Maximum verify iterations ({N}) reached. Remaining issues require manual investigation."
- Set `verify.status: "failed"` and continue to validate phase.
- If `pipeline.stop_on_failure` is true, halt the pipeline.

### 6.2 Execute Verify Command

Run the `/speckit.autopilot.verify` command workflow. **Follow its instructions exactly** for:

- Stopping any previous instance
- Detecting startup commands
- Starting the application
- Running health checks (logs, endpoints, process)
- Evaluating results
- Diagnosing issues
- Generating fix tasks (self-heal)

### 6.3 Self-Heal Decision

**If verify verdict is `healthy`**:

- Verify command has already cleaned up (stopped the app).
- Proceed to Step 7 (Validate).

**If verify verdict is `failed`, `degraded`, or `startup_failed`**:

- The verify command has generated fix tasks in `tasks.md`.
- Check: `verify.iteration < verify.max_iterations` AND `verify.auto_heal` is `true`.
- If both conditions met:
  1. Set `implement.status: "pending"` in state (to allow re-execution).
  2. Set `implement.tasks_completed` to the count of tasks completed BEFORE the fix tasks.
  3. Increment `verify.iteration`.
  4. Return to Step 5 (IMPLEMENT) — the core implement command will detect the new unchecked fix tasks and execute them, then the automatic post-implementation validate gate runs again before verify retries.
- If conditions not met:
  - Set `verify.status: "failed"`.
  - Continue to Step 7 (Validate) which will report the failures.

### 6.4 Update State

```json
"verify": {
  "status": "pending | running | healthy | degraded | failed | healing | complete",
  "iteration": N,
  "max_iterations": N,
  "verdict": "healthy | degraded | failed | startup_failed",
  "completed_at": "<ISO-timestamp> or null",
  "error": "string or null",
  "checks": {
    "startup": { "status": "pass|fail", "command": "...", "ready_after_seconds": N },
    "log_analysis": { "errors": N, "warnings": N, "error_patterns": ["..."] },
    "endpoints": [{ "url": "...", "method": "GET", "status": 200, "result": "pass|warn|fail" }],
    "process": { "running": true }
  },
  "diagnosis": [{ "issue": "...", "severity": "critical|major|minor", "root_cause": "...", "related_task": "T{NNN}", "suggested_fix": "..." }],
  "fix_tasks_created_total": N,
  "iterations_used": N,
  "results_log": "<path>"
}
```

### 6.5 Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AUTOMATION PHASE 6/7: VERIFY (Runtime Health + Self-Heal) ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Verdict:           {HEALTHY / DEGRADED / FAILED}
Iteration:         {N} / {max}
Startup:           {command} ({ready/failed in} {seconds}s)
Endpoints Checked: {N} ({N} passed)
Log Errors:        {N}
Self-Heal:         {N} fix tasks generated, {N} iterations used
Results Log:       {path}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Step 7: VALIDATE (Built-In Final Pass)

Run a final validation after verify finishes, or immediately after implement when verify is not configured. This final pass re-runs validate so post-verify checks are included in the terminal pipeline result.

### 7.1 Validate Artifacts Exist

| Artifact   | Required | Phase   |
| ---------- | -------- | ------- |
| `spec.md`  | Yes      | Specify |
| `plan.md`  | Yes      | Plan    |
| `tasks.md` | Yes      | Tasks   |

Optional artifacts (warn if expected but missing):

- `data-model.md` — Expected if feature involves data
- `contracts/` — Expected if feature has external interfaces
- `research.md` — Expected if plan had NEEDS CLARIFICATION items
- `checklists/requirements.md` — Expected after specify

### 7.2 Validate Test Coverage and Self-Validation in Tasks

Re-run the validation from Step 4.4 and confirm:

- Unit test tasks exist for implementation tasks
- Integration test tasks exist for integration-point tasks
- Self-validation tasks exist for implementation tasks
- No implementation task is missing its corresponding test or self-validation
- Every self-validation task specifies a technique and success criteria

### 7.3 Validate Implementation Results (if implement phase ran)

If the implement phase completed (state shows `implement.status: "complete"`):

- All tasks in `tasks.md` are marked `[X]` or `[x]`
- Self-validation results log exists and all checks passed
- Test suite passed
- No remaining `- [ ] T{NNN}` tasks

### 7.4 Update State

```json
"validate": {
  "status": "complete",
  "completed_at": "<ISO-timestamp>",
  "artifacts_valid": true,
  "test_coverage_valid": true,
  "warnings": []
}
```

---

## Final Pipeline Report

```
╔═══════════════════════════════════════════════════════════════════╗
║               SPEC KIT AUTOPILOT — PIPELINE COMPLETE             ║
╠═══════════════════════════════════════════════════════════════════╣
║                                                                   ║
║  Feature:    {name}                                               ║
║  Directory:  {path}                                               ║
║  Pipeline:   {pipeline-id}                                        ║
║                                                                   ║
║  Phase 1 — Specify:    ✓ COMPLETE   ({duration})                 ║
║  Phase 2 — Clarify:    ✓ COMPLETE   ({N} questions auto-answered)║
║  Phase 3 — Plan:       ✓ COMPLETE   ({N} artifacts)              ║
║  Phase 4 — Tasks:      ✓ COMPLETE   ({N} tasks)                  ║
║  Phase 5 — Implement:  ✓ COMPLETE   ({N}/{N} tasks, {N} passed)  ║
║  Phase 6 — Verify:     ✓ HEALTHY    ({N} iterations, {N} checks) ║
║  Validation:           ✓ PASSED                                  ║
║                                                                   ║
║  Test Coverage:                                                   ║
║    Unit Tests:          {N} tasks (target: ≥80%)                  ║
║    Integration Tests:   {N} tasks                                ║
║    Self-Validation:     {N} tasks (every feature self-verifies)   ║
║                                                                   ║
║  Artifacts:                                                       ║
║    {spec.md}                                                      ║
║    {plan.md}                                                      ║
║    {tasks.md}                                                     ║
║    {validation-results.log}                                       ║
║    {additional artifacts...}                                      ║
║                                                                   ║
║  Next Steps:                                                      ║
║    → /speckit.autopilot.validate  Re-validate test coverage      ║
║    → /speckit.autopilot.status    View pipeline status anytime   ║
║    → /speckit.analyze             Check cross-artifact consistency║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
```

---

## Error Handling

### Phase Failure

1. Update `autopilot-state.json` with `"status": "failed"` and the error message
2. Report which phase failed, what succeeded before it, and the specific error
3. Recovery options:
   - `/speckit.autopilot.run` — Resume from failed phase (state file preserved)
   - `/speckit.{phase}` — Run the specific failed phase manually
   - Delete `autopilot-state.json` to restart from scratch

### Partial Failure

If a phase partially completes (e.g., spec written but validation failed):

- The state file records the partial completion
- Re-running will detect partial state and retry the phase
- Artifacts from the partial run are preserved (not deleted)

---

## State File Reference

**Location**: `FEATURE_DIR/autopilot-state.json`

**Full schema**:

```json
{
	"pipeline_id": "string — autopilot-YYYYMMDD-HHMMSS",
	"feature_directory": "string — relative path to feature dir",
	"started_at": "ISO 8601 timestamp",
	"last_updated_at": "ISO 8601 timestamp",
	"phases": {
		"specify": {
			"status": "pending | running | complete | failed",
			"completed_at": "ISO 8601 or null",
			"error": "string or null",
			"spec_file": "string or null",
			"clarifications_auto_resolved": "number"
		},
		"clarify": {
			"status": "pending | running | complete | failed",
			"completed_at": "ISO 8601 or null",
			"error": "string or null",
			"questions_answered": "number",
			"categories_addressed": ["string"]
		},
		"plan": {
			"status": "pending | running | complete | failed",
			"completed_at": "ISO 8601 or null",
			"error": "string or null",
			"artifacts": ["string"],
			"test_framework": "string or null"
		},
		"tasks": {
			"status": "pending | running | complete | failed",
			"completed_at": "ISO 8601 or null",
			"error": "string or null",
			"total_tasks": "number",
			"unit_test_tasks": "number",
			"integration_test_tasks": "number",
			"self_validation_tasks": "number",
			"validation_passed": "boolean"
		},
		"implement": {
			"status": "pending | running | complete | failed",
			"completed_at": "ISO 8601 or null",
			"error": "string or null",
			"tasks_total": "number",
			"tasks_completed": "number",
			"tests_passed": "boolean",
			"self_validation_passed": "boolean",
			"validation_results_path": "string or null"
		},
		"verify": {
			"status": "pending | running | healthy | degraded | failed | healing | complete",
			"iteration": "number",
			"max_iterations": "number",
			"verdict": "healthy | degraded | failed | startup_failed or null",
			"completed_at": "ISO 8601 or null",
			"error": "string or null",
			"checks": {
				"startup": {
					"status": "pass|fail",
					"command": "string",
					"ready_after_seconds": "number or null"
				},
				"log_analysis": {
					"errors": "number",
					"warnings": "number",
					"error_patterns": ["string"]
				},
				"endpoints": [
					{
						"url": "string",
						"method": "string",
						"expected_status": "number",
						"actual_status": "number",
						"response_time_ms": "number",
						"result": "pass|warn|fail"
					}
				],
				"process": { "running": "boolean" }
			},
			"diagnosis": [
				{
					"issue": "string",
					"severity": "critical|major|minor",
					"affected": "string",
					"root_cause": "string",
					"related_task": "string",
					"suggested_fix": "string"
				}
			],
			"fix_tasks_created_total": "number",
			"iterations_used": "number",
			"results_log": "string or null"
		},
		"validate": {
			"status": "pending | running | complete | failed",
			"completed_at": "ISO 8601 or null",
			"error": "string or null",
			"artifacts_valid": "boolean",
			"test_coverage_valid": "boolean",
			"self_validation_valid": "boolean",
			"warnings": ["string"]
		}
	}
}
```
