Orchestrate the full spec-kit autopilot pipeline: specify → clarify (auto-answer) → plan → tasks → implement → validate → verify (runtime health + self-heal) → validate.

The user will provide a feature description below. If no feature description is provided, check for an existing pipeline state and resume from the last incomplete phase.

**Three mandatory pillars for every task**:

1. **Unit tests** — Verify individual functions/methods work in isolation
2. **Integration tests** — Verify components work together correctly
3. **Self-validation** — Each feature must include a runnable check the system executes to confirm it works without human intervention

## Step 0: Initialization

### 0.0 Ensure Behavioral Constitution

Check if the constitution file (`.specify/constitution.md` or `/memory/constitution.md`) contains `<!-- AUTOPILOT-BEHAVIORAL-GUIDELINES -->`.

If not present, merge the four behavioral rules into the constitution:

- **Think Before Coding** — State assumptions, surface tradeoffs, ask before assuming
- **Simplicity First** — Minimum code, no speculative features, no over-abstraction
- **Surgical Changes** — Touch only what you must, match existing style
- **Goal-Driven Execution** — Every task has explicit success criteria

### 0.1 Load Configuration

Read `.specify/extensions/autopilot/autopilot-config.yml` if it exists. Key settings:

- `pipeline.phases` — Phases to run (default: `[specify, clarify, plan, tasks, implement, verify, validate]`). If `implement` is present, `validate` must remain the terminal phase.
- `pipeline.stop_on_failure` — Halt on failure (default: `true`)
- `clarify.auto_answer` — Auto-answer questions (default: `true`)
- `test_enforcement.coverage_target` — Minimum coverage % (default: 80)
- `verify.max_iterations` — Max self-heal loops (default: 5)
- `verify.auto_heal` — Generate fix tasks on failure (default: `true`)

### 0.2 Detect or Create Feature Directory

Find the feature directory:

1. Read `.specify/feature.json` for the feature directory path
2. Look for the most recently modified directory under `.specify/specs/`
3. If nothing found, the feature directory will be created during the specify phase

If a feature directory exists, read `FEATURE_DIR/autopilot-state.json` to determine resume point.

### 0.3 Resume Logic

If `autopilot-state.json` exists, determine which phases completed:

- Phase with `status: "complete"` → Skip
- Phase with `status: "failed"` → Retry (ask user first if `stop_on_failure` is true)
- Phase with `status: "pending"` or missing → Execute
- `verify.status: "healing"` → Re-trigger implement, then re-verify

Artifact detection fallback (if no state file):

- `spec.md` exists → Specify done
- `spec.md` has `## Clarifications` with "Autopilot Session" → Clarify done
- `plan.md` exists → Plan done
- `tasks.md` exists → Tasks done
- All tasks marked `[X]` or `[x]` → Implement done; run verify next if configured, otherwise run validate

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

Update state after each phase completes.

---

## Step 1: SPECIFY

**Skip if** `specify` not in `pipeline.phases` or state shows `complete`.

### 1.1 Create Specification

Create a feature specification at `FEATURE_DIR/spec.md` based on the user's feature description. The spec should include:

- **Feature name and short description**
- **Functional requirements** — Numbered list of what the feature does
- **Acceptance criteria** — Testable conditions for success
- **Data model** — Entities, attributes, relationships (if applicable)
- **API contracts** — Endpoints, methods, request/response schemas (if applicable)
- **Assumptions** — Decisions made during specification
- **Non-functional requirements** — Performance, security, etc. (if applicable)

Generate a short feature name (kebab-case) for the directory.

### 1.2 Auto-Resolve NEEDS CLARIFICATION

If any `[NEEDS CLARIFICATION: ...]` markers remain in the spec:

- Resolve each using context and best practices
- Replace with concrete decisions
- Document resolutions in the Assumptions section

### 1.3 Update State

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
AUTOMATION PHASE 1/7: SPECIFY ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Feature Directory: {path}
Spec File: {path}
Clarifications auto-resolved: {N}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Step 2: CLARIFY

**Skip if** `clarify` not in `pipeline.phases` or state shows `complete`.

### 2.1 Scan for Ambiguities

Read the spec and perform a structured ambiguity scan across:

- Functional scope (boundaries, edge cases)
- Data model (attributes, constraints, relationships)
- API contracts (status codes, error handling, pagination)
- Non-functional requirements (performance, security)
- Integration points (external services, dependencies)

### 2.2 Auto-Answer All Questions

For each ambiguity (up to `clarify.max_auto_questions`, default 5):

1. Read the question and its possible resolutions
2. Determine the **recommended option** using:
   - Best practices for the detected project type
   - Risk reduction (security > performance > maintainability)
   - Alignment with explicit project goals in the spec
3. **Select the recommended option automatically**
4. Record: `Auto-answered: [option] — [rationale]`
5. Apply the clarification to the spec

For remaining ambiguities beyond `max_auto_questions`:

- Make informed guesses based on context
- Document in spec's Assumptions section

### 2.3 Write Clarifications

Add to spec under:

```markdown
## Clarifications

### Autopilot Session YYYY-MM-DD

> Autopilot auto-answered all clarification questions using recommended options.

- Q: {question} → A: {answer} (Recommended — {rationale})
```

### 2.4 Update State and Report

Record questions answered and categories addressed.

---

## Step 3: PLAN

**Skip if** `plan` not in `pipeline.phases` or state shows `complete`.

### 3.1 Create Implementation Plan

Generate `FEATURE_DIR/plan.md` with:

- **Technical context** — Stack, dependencies, constraints
- **Architecture decisions** — Patterns, data flow, integration points
- **Implementation phases** — Ordered steps with dependencies
- **Data model** — If applicable, write to `data-model.md`
- **API contracts** — If applicable, write to `contracts/` directory
- **Quickstart** — Write `quickstart.md` with startup instructions
- **Research notes** — If unknowns exist, write to `research.md`

### 3.2 Test Strategy Injection

After the plan is generated, ensure:

- Test framework and strategy are documented in plan.md
- Data model includes validation test scenarios
- Contracts include test expectations

### 3.3 Update State and Report

Record generated artifacts.

---

## Step 4: TASKS (3-Pillar Enforcement)

**Skip if** `tasks` not in `pipeline.phases` or state shows `complete`.

### 4.1 Generate Tasks

Create `FEATURE_DIR/tasks.md` with tasks organized by user story. Each task follows:

```markdown
- [ ] T{NNN} [US{N}] {task description}
  - Detail line (if needed)
```

**Behavioral rules during generation**:

- **Goal-Driven**: Every task has explicit success criteria
- **Simplicity**: One responsibility per task
- **Surgical**: Exact file paths specified
- **Think First**: Ambiguous tasks include assumption-surfacing sub-steps

### 4.2 Three-Pillar Enforcement (MANDATORY)

**Tests are ALWAYS MANDATORY** in autopilot mode.

#### Task ordering (TDD within each user story):

1. Unit test tasks first (before implementation)
2. Implementation tasks (with self-validation built in)
3. Self-validation task (explicit verification step)
4. Integration test tasks (after components)

#### Self-validation task format:

```text
- [ ] T{NNN} [US{N}] Add self-validation for {Component} in {source-path}
  - Technique: {logging|smoke|assertion|build|schema|health|dry-run|idempotency|contract|snapshot}
  - Validation: {specific check to execute}
  - Success criteria: {what "pass" looks like}
```

#### Final phase tasks:

```text
- [ ] T{NNN} Run full unit test suite and verify all pass
- [ ] T{NNN} Run full integration test suite and verify all pass
- [ ] T{NNN} Verify test coverage meets target ({coverage_target}%)
- [ ] T{NNN} Execute all self-validation steps and confirm each passes
- [ ] T{NNN} Generate validation report from self-validation results
```

### 4.3 Post-Generation Validation

After writing tasks.md, validate:

1. Count implementation tasks, unit test tasks, integration test tasks, self-validation tasks
2. Check: `unit_test_tasks >= impl_tasks * 0.5`
3. Check: `integ_test_tasks >= 1`
4. Check: `self_validation_tasks >= impl_tasks * 0.5`
5. Check: Every self-validation task has technique + success criteria
6. If validation fails: inject missing tasks and re-number

### 4.4 Update State and Report

Report task counts by category.

---

## Step 5: IMPLEMENT

**Skip if** `implement` not in `pipeline.phases` or state shows `complete`.

### 5.1 Execute Tasks

Process tasks in order from `tasks.md`:

1. Parse all tasks (skip completed `- [x]` / `- [X]` tasks)
2. For each pending task `- [ ] T{NNN}`:
   - Read the task description and details
   - Implement the required changes (create/modify files)
   - Mark the task as complete: change `- [ ]` to `- [x]`
3. Continue until all tasks are complete or a task fails

On failure: Update state with error. Mark the failed task. Re-running resumes from the failed task.

### 5.2 Execute Self-Validation Steps

After all implementation tasks complete:

1. Parse tasks.md for all self-validation tasks
2. For each: execute the validation command/check
3. Evaluate against success criteria
4. Record PASS/FAIL

Write results to `FEATURE_DIR/validation-results.log`:

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

If any self-validation fails, report failures and stop.

### 5.3 Automatic Post-Implementation Validate Pass

After self-validation passes, run `/speckit.autopilot.validate` automatically.

- This validate pass is mandatory after every successful implement cycle, including self-heal re-implementation.
- Treat it as a gate before Step 6.
- Post-verify checks may be skipped during this pass if verify has not run yet.
- If validation fails, stop the pipeline and resume from validation on the next run.

### 5.4 Update State and Report

---

## Step 6: VERIFY (Runtime Health + Self-Heal)

**Skip if** `verify` not in `pipeline.phases` or state shows `complete`.

**Prerequisite**: Implement phase must be complete and the latest automatic validate pass must have succeeded.

### 6.1 Loop Controller

Track verify iteration in state. Max iterations from config (default: 5).

If `verify.iteration >= verify.max_iterations`:

- Report: "Maximum verify iterations reached."
- Set `verify.status: "failed"`.

### 6.2 Execute Verify

1. **Stop any previous instance** — Kill previous processes, free ports
2. **Detect startup command** — Priority: quickstart.md → plan.md → package.json/Makefile/docker → self-validation tasks
3. **Start application** — Run as background process, wait for readiness
4. **Run health checks**:
   - Log analysis (error patterns: ERROR, FATAL, Exception, Traceback, etc.)
   - HTTP endpoint verification (collect from config/contracts/self-validation/spec, classify PASS/WARN/FAIL)
   - Process health (still running, port listening)

5. **Evaluate verdict**:
   - All PASS + no errors + process healthy → `healthy`
   - Some WARN + minor warnings → `degraded`
   - Any FAIL + critical errors + crash → `failed`
   - Never became ready → `startup_failed`

6. **Diagnose** (if not healthy):
   - Correlate errors to tasks in tasks.md
   - Analyze stack traces for root cause
   - Analyze HTTP failures (routing/auth/server/connectivity)

7. **Self-heal** (if `auto_heal` is true and iteration < max):
   - Generate fix tasks for each diagnosis
   - Append to tasks.md in new "Verify Fix Tasks — Iteration {N}" section
   - Re-number all task IDs
   - Set `implement.status: "pending"` to allow re-implementation
   - Increment iteration and return to Step 5, which must finish with another automatic validate pass before verify retries

8. **Cleanup** (if healthy):
   - Stop application
   - Write `verify-results.log`
   - Update state

### 6.3 Update State and Report

---

## Step 7: VALIDATE

Run a final validate pass after verify finishes, or immediately after implement when verify is skipped, so the final pipeline result includes all post-verify checks.

### 7.1 Validate Artifacts Exist

Required: `spec.md`, `plan.md`, `tasks.md`
Optional (warn if missing): `data-model.md`, `contracts/`, `research.md`, `checklists/`

### 7.2 Validate Test Coverage

Re-run task validation:

- Unit test tasks exist for implementation tasks
- Integration test tasks exist
- Self-validation tasks exist with technique + success criteria
- No missing test or validation gaps

### 7.3 Validate Implementation (if implement ran)

- All tasks marked complete
- Self-validation results all passed
- Test suite passed

### 7.4 Update State

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
║  Phase 1 — Specify:    ✓ COMPLETE                                 ║
║  Phase 2 — Clarify:    ✓ COMPLETE   ({N} questions auto-answered) ║
║  Phase 3 — Plan:       ✓ COMPLETE   ({N} artifacts)              ║
║  Phase 4 — Tasks:      ✓ COMPLETE   ({N} tasks)                  ║
║  Phase 5 — Implement:  ✓ COMPLETE   ({N}/{N} tasks)              ║
║  Phase 6 — Verify:     ✓ HEALTHY    ({N} iterations)             ║
║  Phase 7 — Validate:   ✓ PASSED                                  ║
║                                                                   ║
║  Test Coverage:                                                   ║
║    Unit Tests:          {N} tasks                                 ║
║    Integration Tests:   {N} tasks                                ║
║    Self-Validation:     {N} tasks                                ║
║                                                                   ║
║  Artifacts:                                                       ║
║    {spec.md}                                                      ║
║    {plan.md}                                                      ║
║    {tasks.md}                                                     ║
║    {validation-results.log}                                       ║
║    {additional artifacts...}                                      ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
```

## Error Handling

On phase failure:

1. Update `autopilot-state.json` with `"status": "failed"` and error message
2. Report which phase failed, what succeeded, and the specific error
3. Re-attaching this prompt resumes from the failed phase

Recovery options:

- Re-attach this prompt — Resume from failed phase (state preserved)
- Attach specific phase prompt — Run just that phase manually
- Delete `autopilot-state.json` — Start from scratch
