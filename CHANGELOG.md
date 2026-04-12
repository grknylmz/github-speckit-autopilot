# Changelog

All notable changes to the Spec Kit Autopilot extension will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-04-12

### Added

- `/speckit.autopilot.run` command — full automated pipeline (specify → clarify → plan → tasks)
- `/speckit.autopilot.status` command — check pipeline progress and artifact status
- Auto-answer mode for clarification phase using AI-recommended options
- Enforced unit test generation for all implementation tasks
- Enforced integration test generation for all integration-point tasks
- Resume support — re-running detects existing artifacts and skips completed phases
- Configurable test enforcement, clarification behavior, and pipeline settings
- Configuration template (`config-template.yml`)
