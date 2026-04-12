---
description: "Check the current status of the autopilot pipeline — which phases are complete and what artifacts exist."
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --paths-only
  ps: scripts/powershell/check-prerequisites.ps1 -Json -PathsOnly
---

# Autopilot Pipeline Status

Check the current status of an autopilot pipeline run for the active feature.

## Steps

1. Run `{SCRIPT}` from repo root to get project paths. Parse JSON payload:
   - `FEATURE_DIR`
   - `FEATURE_SPEC`
   - If JSON parsing fails, check `.specify/feature.json` for the feature directory path.

2. **Detect Feature Directory**: If no feature directory is found:
   ```
   No active feature found. Run /speckit.autopilot.run with a feature description to start the pipeline.
   ```
   Stop here.

3. **Scan for Artifacts**: Check the feature directory for these files:

   | Artifact | File Path | Phase |
   |----------|-----------|-------|
   | Specification | `spec.md` | Phase 1: Specify |
   | Quality Checklist | `checklists/requirements.md` | Phase 1: Specify |
   | Clarifications | `spec.md` (## Clarifications section) | Phase 2: Clarify |
   | Research | `research.md` | Phase 3: Plan |
   | Implementation Plan | `plan.md` | Phase 3: Plan |
   | Data Model | `data-model.md` | Phase 3: Plan |
   | Contracts | `contracts/` directory | Phase 3: Plan |
   | Quickstart | `quickstart.md` | Phase 3: Plan |
   | Tasks | `tasks.md` | Phase 4: Tasks |

4. **Read Task Details** (if `tasks.md` exists):
   - Count total tasks: lines matching `- [ ]` or `- [x]` or `- [X]`
   - Count completed tasks: lines matching `- [x]` or `- [X]`
   - Count remaining tasks: lines matching `- [ ]`
   - Count unit test tasks: tasks containing "unit test" (case-insensitive)
   - Count integration test tasks: tasks containing "integration test" (case-insensitive)

5. **Determine Pipeline Phase**:

   | Condition | Current Phase |
   |-----------|---------------|
   | No `spec.md` | Not Started |
   | `spec.md` exists, no Clarifications section | Phase 1 Complete (ready for clarify) |
   | Clarifications section exists, no `plan.md` | Phase 2 Complete (ready for plan) |
   | `plan.md` exists, no `tasks.md` | Phase 3 Complete (ready for tasks) |
   | `tasks.md` exists, incomplete tasks | Phase 4 Complete (ready for implement) |
   | `tasks.md` exists, all tasks complete | Pipeline Complete |

6. **Output Status Report**:

   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   SPEC KIT AUTOPILOT — PIPELINE STATUS
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Feature: {feature-name}
   Directory: {feature-directory}

   Phase 1 — Specify:      {✓ COMPLETE / — NOT STARTED}
     spec.md:              {exists / missing}
     checklist:            {exists / missing}

   Phase 2 — Clarify:      {✓ COMPLETE / — NOT STARTED}
     clarifications:       {N questions answered / none}

   Phase 3 — Plan:         {✓ COMPLETE / — NOT STARTED}
     plan.md:              {exists / missing}
     research.md:          {exists / missing / not needed}
     data-model.md:        {exists / missing / not needed}
     contracts/:           {exists / missing / not needed}

   Phase 4 — Tasks:        {✓ COMPLETE / — NOT STARTED}
     tasks.md:             {exists / missing}
     total tasks:          {N}
     completed:            {N}
     remaining:            {N}

   Test Enforcement:
     unit test tasks:      {N}
     integration test tasks: {N}

   Current State: {phase description}
   Next Step: {suggested command}

   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```

7. **Suggestions**: Based on current state, recommend:
   - If not started: `/speckit.autopilot.run <feature description>`
   - If partially complete: `/speckit.autopilot.run` (will resume from current phase)
   - If tasks exist with remaining work: `/speckit.implement`
   - If all tasks complete: `/speckit.analyze`
