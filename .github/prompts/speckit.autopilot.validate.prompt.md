Validate that generated tasks have proper unit tests, integration tests, self-validation coverage, and post-implementation verification. Can be run at any time to verify task quality.

## Steps

### 1. Locate Feature Directory

Find the active feature directory using this priority:

1. Read `.specify/feature.json` for the feature directory path
2. Look for the most recently modified directory under `.specify/specs/`
3. If nothing found, report: `No active feature found.`

### 2. Check for Tasks File

Read `FEATURE_DIR/tasks.md`. If it doesn't exist:

```
No tasks.md found. Run the pipeline first to generate tasks.
```

### 3. Parse and Classify Tasks

Parse every task line (matching `- [ ] T{NNN}` or `- [x] T{NNN}` or `- [X] T{NNN}`). For each task, classify it:

| Category | Match Pattern | Examples |
|----------|---------------|---------|
| Unit Test | Contains "unit test" (case-insensitive) | "Write unit tests for UserService" |
| Integration Test | Contains "integration test" (case-insensitive) | "Write integration tests for auth flow" |
| Self-Validation | Contains "self-validation" or "self validation" (case-insensitive) | "Add self-validation for OrderService" |
| Test (Generic) | Contains "test" but not "unit" or "integration" or "self-validation" | "Run test suite" |
| Implementation | Contains "Implement", "Create", "Build", "Add", "Write" AND is NOT a test/validation task | "Implement UserService" |
| Setup/Config | Infrastructure, configuration, initialization | "Create project structure" |
| Verification | Contains "Verify", "Run", "Check", "Ensure" AND is NOT a self-validation task | "Run full test suite" |

Also extract for each task:
- Task ID (T001, T002, etc.)
- User story label ([US1], [US2], etc.) if present
- File path mentioned in the description

### 4. Validation Checks

Run these checks in order. Each check PASSES or FAILS with specific details.

#### Check 1: Implementation Tasks Have Unit Tests

For each user story with implementation tasks, verify there's at least one unit test task in the same story phase.

**Pass condition**: For every user story (US1, US2, ...) with implementation tasks, there is at least one unit test task.

**Failure detail**: List which user stories are missing unit tests.

#### Check 2: Integration Points Have Integration Tests

For each user story that involves API endpoints, database operations, external services, or middleware, verify there's at least one integration test task.

**Pass condition**: At least one integration test task exists for the overall feature.

**Failure detail**: If no integration test tasks exist at all, FAIL.

#### Check 3: TDD Ordering

For each user story, verify that unit test tasks appear before (lower task ID) their corresponding implementation tasks.

**Pass condition**: Unit test task IDs < their corresponding implementation task IDs within the same user story.

**Failure detail**: List out-of-order pairs.

#### Check 4: Test File Paths Exist

Verify each test task specifies a file path for the test file.

**Pass condition**: Every test task description includes a file path.

**Failure detail**: List test tasks missing file paths.

#### Check 5: Coverage Sweep Task

Verify the final phase includes a task to run the full test suite and check coverage.

**Pass condition**: At least one task in the final phase mentions running the full test suite or verifying coverage.

**Failure detail**: Note that the coverage sweep task is missing.

#### Check 6: Task ID Continuity

Verify task IDs are sequential with no gaps (T001, T002, T003, ...).

**Pass condition**: All task IDs form a continuous sequence.

**Failure detail**: List gaps in the sequence.

#### Check 7: Self-Validation Coverage

For each user story with implementation tasks, verify there's at least one self-validation task.

**Pass condition**: For every user story with implementation tasks, there is at least one self-validation task.

**Failure detail**: List which user stories are missing self-validation tasks.

#### Check 8: Self-Validation Technique and Success Criteria

For every self-validation task, verify it specifies:
1. A **technique** (logging, smoke, assertion, build, schema, health, dry-run, idempotency, contract, or snapshot)
2. A **validation** check (what to execute)
3. A **success criteria** (what "pass" looks like)

**Pass condition**: Every self-validation task includes all three elements.

**Failure detail**: List self-validation tasks that are missing technique, validation, or success criteria.

#### Check 9: Behavioral Guideline — Goal-Driven Tasks

Verify that implementation tasks include explicit success criteria (not just "implement X").

**Pass condition**: Every implementation task description includes a verification condition or links to a self-validation task.

**Failure detail**: List implementation tasks without success criteria.

#### Check 10: Behavioral Guideline — Simplicity (Single Responsibility)

Verify that no single task encompasses more than one distinct responsibility.

**Pass condition**: Every task describes one clear action. No task combines multiple unrelated responsibilities.

**Failure detail**: List tasks that bundle multiple responsibilities.

#### Check 11: Behavioral Guideline — Surgical (Exact File Paths)

Verify that every implementation task specifies the exact file path(s) it will modify or create.

**Pass condition**: Every implementation task includes at least one file path.

**Failure detail**: List implementation tasks without file paths.

#### Check 12: All Tasks Marked Complete (Post-Implementation)

If the implement phase has run (state file shows `implement.status: "complete"` or tasks.md has any `[X]`/`[x]` marks), verify ALL tasks are marked complete.

**Pass condition**: No `- [ ] T{NNN}` lines remain.

**Failure detail**: List the task IDs still incomplete.

**Skip condition**: Skip if no tasks have been implemented yet.

#### Check 13: Self-Validation Results (Post-Implementation)

If `FEATURE_DIR/validation-results.log` exists, verify all self-validation checks passed.

**Pass condition**: Every self-validation entry shows PASS.

**Failure detail**: List which self-validation tasks failed.

**Skip condition**: Skip if `validation-results.log` does not exist.

#### Check 14: Test Suite Pass (Post-Implementation)

If the implement phase has run, verify the test suite passed.

**Pass condition**: `implement.tests_passed` is `true` in state file, or no test failure evidence.

**Failure detail**: Report which tests failed.

**Skip condition**: Skip if implement phase not run.

#### Check 15: Verify Runtime Results (Post-Verify)

If verify phase has run (state shows `verify.status: "complete"` or `verify-results.log` exists), verify all runtime checks passed.

**Pass condition**: All endpoint checks show PASS, no log error patterns, verdict is `healthy`.

**Failure detail**: List failed endpoints, log errors, and verify verdict.

**Skip condition**: Skip if verify phase not run.

#### Check 16: Self-Heal Iterations (Post-Verify)

If verify phase ran with self-healing, verify iterations did not exceed max and final verdict is healthy.

**Pass condition**: `verify.iterations_used <= verify.max_iterations` and verdict is `healthy`.

**Failure detail**: Report max iterations reached with remaining issues.

**Skip condition**: Skip if verify not run or `verify.auto_heal` is false.

### 5. Output Validation Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AUTOPILOT VALIDATION (3-Pillar + Post-Implementation + Post-Verify)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: {name}
Tasks File: {path}

Task Breakdown:
  Total Tasks:          {N}
  Implementation:       {N}
  Unit Tests:           {N}
  Integration Tests:    {N}
  Self-Validation:      {N}
  Setup/Config:         {N}
  Verification:         {N}

Validation Results:
  {✓/✗} Check 1:  Implementation → Unit Test mapping    {PASS/FAIL}
  {✓/✗} Check 2:  Integration point coverage             {PASS/FAIL}
  {✓/✗} Check 3:  TDD ordering                           {PASS/FAIL}
  {✓/✗} Check 4:  Test file paths specified              {PASS/FAIL}
  {✓/✗} Check 5:  Coverage sweep task present            {PASS/FAIL}
  {✓/✗} Check 6:  Task ID continuity                     {PASS/FAIL}
  {✓/✗} Check 7:  Self-validation coverage               {PASS/FAIL}
  {✓/✗} Check 8:  Self-validation technique + criteria   {PASS/FAIL}
  {✓/✗} Check 9:  Goal-driven tasks (success criteria)   {PASS/FAIL}
  {✓/✗} Check 10: Simplicity (single responsibility)     {PASS/FAIL}
  {✓/✗} Check 11: Surgical (exact file paths)            {PASS/FAIL}
  {—/✓/✗} Check 12: All tasks complete                   {SKIP/PASS/FAIL}
  {—/✓/✗} Check 13: Self-validation results              {SKIP/PASS/FAIL}
  {—/✓/✗} Check 14: Test suite pass                      {SKIP/PASS/FAIL}
  {—/✓/✗} Check 15: Verify runtime results               {SKIP/PASS/FAIL}
  {—/✓/✗} Check 16: Self-heal iterations within limit    {SKIP/PASS/FAIL}

Overall: ✓ VALID / ✗ {N} ISSUES FOUND

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

For each failure, include specific details (which tasks, which stories, what's missing).

### 6. Auto-Fix (if issues found)

If the user wants to fix issues, apply these fixes:

1. **Missing unit tests (Check 1)**: Generate unit test tasks for uncovered implementation tasks. Insert before the implementation task. Re-number task IDs.

2. **Missing integration tests (Check 2)**: Generate integration test tasks for uncovered integration points. Insert after implementation tasks. Re-number.

3. **Wrong ordering (Check 3)**: Move test tasks before their implementation tasks. Re-number.

4. **Missing file paths (Check 4)**: Add test file paths based on project structure.

5. **Missing coverage sweep (Check 5)**: Add a final-phase verification task.

6. **Task ID gaps (Check 6)**: Re-number all tasks sequentially.

7. **Missing self-validation (Check 7)**: Generate self-validation tasks for uncovered implementation tasks:
   - API endpoint → smoke test + contract assertion
   - Business logic → logging + assertion
   - Database/data model → schema validation
   - Service/server → health endpoint
   - Configuration → build verification
   Include technique, validation, and success criteria. Re-number.

8. **Incomplete self-validation (Check 8)**: Fill in missing technique/validation/success criteria.

9. **Missing success criteria (Check 9)**: Append `verify:` clause to each task. Must be specific (e.g., "verify: POST /api/users returns 201 with {id, email}").

10. **Multi-responsibility tasks (Check 10)**: Split into separate tasks. Each gets its own ID, file path, and success criteria. Re-number.

11. **Missing file paths (Check 11)**: Infer from project structure in `plan.md`.

12-16. **Cannot auto-fix**: Report the issues and suggest manual investigation.

After auto-fix, re-run validation to confirm all checks pass.

### 7. Update State File

If `FEATURE_DIR/autopilot-state.json` exists, update the validate phase:

```json
"validate": {
  "status": "complete",
  "completed_at": "<ISO-timestamp>",
  "artifacts_valid": true,
  "test_coverage_valid": true,
  "warnings": []
}
```
