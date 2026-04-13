---
description: "Check the current status of the autopilot pipeline using the state file and artifact scan."
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --paths-only
  ps: scripts/powershell/check-prerequisites.ps1 -Json -PathsOnly
---

# Autopilot Pipeline Status

Reports the current status of the autopilot pipeline. Uses the state file for precise phase tracking and falls back to artifact scanning if no state file exists.

## Steps

### 1. Locate Feature Directory

Run `{SCRIPT}` from repo root. Parse JSON payload for `FEATURE_DIR`.

If the script fails, check `.specify/feature.json` for the feature directory path.

If no feature is found:

```
No active feature found.

To start a new pipeline:
  /speckit.autopilot.run <feature description>
```

Stop here.

### 2. Load Pipeline State

Read `FEATURE_DIR/autopilot-state.json` if it exists.

**If state file exists**: Use it as the primary source of truth for phase status. Continue to Step 3.

**If no state file exists**: Fall back to artifact detection (Step 2b).

#### 2b. Artifact Detection (Fallback)

Scan the feature directory for artifacts and infer phase status:

| Condition | Inferred Status |
|-----------|-----------------|
| No `spec.md` | Pipeline not started |
| `spec.md` exists, no `## Clarifications` with "Autopilot Session" | Specify done |
| `spec.md` has "Autopilot Session" clarifications | Specify + Clarify done |
| `plan.md` exists | Specify + Clarify + Plan done |
| `tasks.md` exists, some tasks `- [ ]` | Tasks done, implement not started |
| `tasks.md` exists, all tasks `- [X]` or `- [x]` | Tasks + Implement done |
| `verify-results.log` exists | Verify done |

### 3. Scan Artifacts

Regardless of state file presence, scan the feature directory for these artifacts:

| Artifact | Path | Phase |
|----------|------|-------|
| Specification | `spec.md` | Specify |
| Quality Checklist | `checklists/requirements.md` | Specify |
| Clarifications | `spec.md` → `## Clarifications` section | Clarify |
| Research | `research.md` | Plan |
| Implementation Plan | `plan.md` | Plan |
| Data Model | `data-model.md` | Plan |
| Contracts | `contracts/` | Plan |
| Quickstart | `quickstart.md` | Plan |
| Tasks | `tasks.md` | Tasks |
| Validation Results | `validation-results.log` | Implement |
| Verify Results | `verify-results.log` | Verify |
| Validation State | `autopilot-state.json` | Validate |

### 4. Parse Task Details (if tasks.md exists)

Count and classify tasks:

- **Total tasks**: All lines matching `- [ ] T{NNN}` or `- [x] T{NNN}` or `- [X] T{NNN}`
- **Completed**: Lines matching `- [x] T{NNN}` or `- [X] T{NNN}`
- **Remaining**: Lines matching `- [ ] T{NNN}`
- **Unit test tasks**: Tasks containing "unit test" (case-insensitive)
- **Integration test tasks**: Tasks containing "integration test" (case-insensitive)
- **Implementation tasks**: Tasks containing "Implement", "Create", "Build" but not "test"
- **User stories**: Unique `[US{N}]` labels found

### 5. Compute Pipeline Progress

Calculate overall progress:

```
progress = (completed_phases / total_phases) * 100
```

Where completed phases are those with `status: "complete"` in the state file (or inferred from artifacts).

### 6. Output Status Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SPEC KIT AUTOPILOT — PIPELINE STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature:    {name}
Directory:  {FEATURE_DIR}
Pipeline:   {pipeline-id from state file, or "unknown"}
Started:    {timestamp from state, or "unknown"}
Progress:   {percentage}%

┌─────────────────────────────────────────────────────────────────┐
│ Phase            │ Status       │ Details                       │
├──────────────────┼──────────────┼───────────────────────────────┤
│ 1. Specify       │ ✓ COMPLETE   │ spec.md created               │
│ 2. Clarify       │ ✓ COMPLETE   │ 4 questions auto-answered     │
│ 3. Plan          │ ✓ COMPLETE   │ 3 artifacts generated         │
│ 4. Tasks         │ ✓ COMPLETE   │ 24 tasks (6 tests)            │
│ 5. Implement     │ ✓ COMPLETE   │ 24/24 tasks, 6/6 self-val     │
│ 6. Verify        │ ✓ HEALTHY    │ 2 iterations, 5/5 endpoints   │
│ 7. Validate      │ ✓ PASSED     │ All checks pass               │
└─────────────────────────────────────────────────────────────────┘

  — OR (if incomplete) —

┌─────────────────────────────────────────────────────────────────┐
│ Phase            │ Status       │ Details                       │
├──────────────────┼──────────────┼───────────────────────────────┤
│ 1. Specify       │ ✓ COMPLETE   │ spec.md created               │
│ 2. Clarify       │ ✗ FAILED     │ Error: <message>              │
│ 3. Plan          │ ◌ PENDING    │ Not started                   │
│ 4. Tasks         │ ◌ PENDING    │ Not started                   │
│ 5. Implement     │ ◌ PENDING    │ Not started                   │
│ 6. Verify        │ ◌ PENDING    │ Not started                   │
│ 7. Validate      │ ◌ PENDING    │ Not started                   │
└─────────────────────────────────────────────────────────────────┘

Artifacts:
  {✓/✗} spec.md              {path or "missing"}
  {✓/✗} checklists/           {path or "missing"}
  {✓/✗} research.md           {path or "missing"}
  {✓/✗} plan.md               {path or "missing"}
  {✓/✗} data-model.md         {path or "missing"}
  {✓/✗} contracts/            {path or "missing"}
  {✓/✗} tasks.md              {path or "missing"}

Task Breakdown (if tasks.md exists):
  Total:              {N}
  Completed:          {N}
  Remaining:          {N}
  Unit Tests:         {N}
  Integration Tests:  {N}
  Implementation:     {N}
  User Stories:       {list}

Test Enforcement:
  Unit tests present:      {✓ YES / ✗ NO}
  Integration tests present: {✓ YES / ✗ NO}
  Validation passed:       {✓ YES / ✗ NO / — NOT RUN}

Self-Validation Results (if implement ran):
  Total checks:           {N}
  Passed:                 {N}
  Failed:                 {N}
  Results log:            {path or "not run"}

Verify & Self-Healing Results (if verify ran):
  Verdict:              {HEALTHY / DEGRADED / FAILED}
  Iterations:           {N} / {max}
  Endpoints checked:    {N} ({N} passed)
  Fix tasks generated:  {N}
  Results log:          {path or "not run"}

Next Step: {recommended command}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 7. Recommendations

Based on the current state, suggest the next action:

| Current State | Recommendation |
|---------------|----------------|
| Not started | `/speckit.autopilot.run <feature description>` |
| Specify complete, clarify failed | `/speckit.autopilot.run` (resumes from clarify) |
| Specify + Clarify done | `/speckit.autopilot.run` (resumes from plan) |
| Tasks done, implement not started | `/speckit.autopilot.run` (resumes from implement) |
| Implement in progress | `/speckit.autopilot.run` (resumes from failed task) |
| Verify failed, iterations remain | `/speckit.autopilot.run` (resumes verify self-heal loop) |
| Verify failed, max iterations reached | Manual investigation needed; check verify-results.log |
| All phases done, tasks complete | `/speckit.analyze` |
| Validation not run | `/speckit.autopilot.validate` |
| Validation failed | `/speckit.autopilot.validate` (auto-fix) |
