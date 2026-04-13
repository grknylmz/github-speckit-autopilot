# Changelog

All notable changes to the Spec Kit Autopilot extension will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2026-04-13

### Added

- GitHub Copilot support via `.github/copilot-instructions.md` — auto-loaded behavioral rules and pipeline context for all Copilot environments
- `.github/prompts/speckit.autopilot.run.prompt.md` — Full pipeline orchestration as a Copilot prompt file
- `.github/prompts/speckit.autopilot.status.prompt.md` — Pipeline status check as a Copilot prompt file
- `.github/prompts/speckit.autopilot.validate.prompt.md` — 16-check validation as a Copilot prompt file
- `.github/prompts/speckit.autopilot.verify.prompt.md` — Runtime verification and self-heal as a Copilot prompt file
- `.github/prompts/speckit.autopilot.constitution.prompt.md` — Behavioral guidelines merge as a Copilot prompt file
- README section: "GitHub Copilot Support" with setup instructions, feature parity table, and limitations

### Changed

- Removed `.github/` from `.gitignore` so Copilot files can be committed
- Prerequisites section updated with note for Copilot users

## [1.2.0] - 2026-04-13

### Added

- `speckit.autopilot.verify` command — Starts the built application, captures logs, hits HTTP endpoints, runs health checks, and validates everything is running
- Step 6 (VERIFY) in run command: runtime verification with self-healing loop (verify → diagnose → fix → re-implement → re-verify)
- Self-healing loop: diagnose issues, generate fix tasks in tasks.md, re-implement, and re-verify (configurable max iterations, default: 5)
- Startup command detection from quickstart.md, plan.md, project conventions, and self-validation tasks
- HTTP endpoint verification using contracts, self-validation tasks, and explicit configuration
- Log analysis with error pattern detection (ERROR, FATAL, stack traces, connection failures)
- Structured diagnosis correlating runtime errors to implementation tasks
- Fix task generation in new "Verify Fix Tasks" sections in tasks.md
- Verify state tracking in autopilot-state.json (iteration count, verdict, check results, diagnosis)
- `verify-results.log` artifact with detailed check results
- New configuration section: `verify` with max_iterations, startup_timeout_seconds, health_retries, auto_heal, endpoints
- Post-verify validation checks (15-16): verify runtime results, self-heal iterations within limit
- Status command updated to show verify phase, self-healing results, and verify-related recommendations

### Changed

- Default pipeline phases now include `verify`: `[specify, clarify, plan, tasks, implement, verify]`
- Validate step renumbered from Step 6 to Step 7 to accommodate new verify step
- Architecture diagram updated to include VERIFY phase with loop-back arrow to IMPLEMENT
- Final pipeline report includes verify phase results
- Validation report now shows 16 checks (11 pre-implementation + 3 post-implementation + 2 post-verify)

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
