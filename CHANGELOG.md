# Changelog

All notable changes to the Spec Kit Autopilot extension will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-04-12

### Added

- `speckit.implement` integrated as a standard pipeline phase — runs automatically after tasks are finalized
- Step 5 (IMPLEMENT) in run command: delegates to core `/speckit.implement`, then runs self-validation checks and logs results to `validation-results.log`
- Implement phase state tracking in `autopilot-state.json` (tasks completed/total, test results, self-validation results)
- Post-implementation validation checks (12-14): all tasks complete, self-validation results, test suite pass
- Status command updated to show implement phase, self-validation results, and post-implementation recommendations
- Architecture diagram updated to include IMPLEMENT phase

### Changed

- Default pipeline phases now include `implement`: `[specify, clarify, plan, tasks, implement]`
- Removed `pipeline.chain_implement` setting — `implement` is now a standard phase in the phases list
- Validation report now shows 14 checks (11 pre-implementation + 3 post-implementation)
- Final pipeline report includes implement phase results
- Validate step renumbered from Step 5 to Step 6 to accommodate new implement step

## [1.0.0] - 2026-04-12

### Added

- `/speckit.autopilot.run` — Orchestrates the full pipeline by delegating to core spec-kit commands
- `/speckit.autopilot.status` — Reports pipeline progress from state file and artifact scan
- `/speckit.autopilot.validate` — 11-check validation covering test coverage, self-validation, and behavioral guideline compliance with auto-fix
- `/speckit.autopilot.constitution` — Merges autopilot behavioral guidelines into the project constitution
- `/speckit.autopilot.start` — Alias for the run command
- Pipeline state file (`autopilot-state.json`) for reliable resume and status tracking
- Auto-answer mode for clarification phase using AI-recommended options
- Three-pillar task enforcement: unit tests + integration tests + self-validation
- Self-validation with 10 techniques (logging, smoke, assertion, build, schema, health, dry-run, idempotency, contract, snapshot)
- Behavioral constitution with 4 rules (think-before-code, simplicity-first, surgical-changes, goal-driven-execution)
- Behavioral checks in validation: goal-driven tasks, single-responsibility, exact file paths
- Post-generation validation that verifies test coverage was actually generated
- Auto-fix capability for missing test and self-validation tasks
- Configurable phase list (skip phases, reorder, or run subset)
- Optional `chain_implement` to auto-run implementation after tasks
- Test strategy injection into plan artifacts (additive, non-destructive)
- Configuration template with full documentation
