# Changelog

All notable changes to the Spec Kit Autopilot extension will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-04-12

### Added

- `/speckit.autopilot.run` — Orchestrates the full pipeline by delegating to core spec-kit commands
- `/speckit.autopilot.status` — Reports pipeline progress from state file and artifact scan
- `/speckit.autopilot.validate` — Validates test coverage in generated tasks with 6 checks and auto-fix
- `/speckit.autopilot.start` — Alias for the run command
- Pipeline state file (`autopilot-state.json`) for reliable resume and status tracking
- Auto-answer mode for clarification phase using AI-recommended options
- Enforced unit test generation for all implementation tasks
- Enforced integration test generation for all integration-point tasks
- Post-generation validation that verifies test coverage was actually generated
- Auto-fix capability for missing test tasks
- Configurable phase list (skip phases, reorder, or run subset)
- Optional `chain_implement` to auto-run implementation after tasks
- Test strategy injection into plan artifacts (additive, non-destructive)
- Configuration template with full documentation
