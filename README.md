# Spec Kit Autopilot

A [spec-kit](https://github.com/github/spec-kit) extension that provides an automated pipeline for spec-driven development. One command chains through specify, clarify, plan, tasks, implement, verify, and validate — with auto-answered clarifications, enforced unit + integration test coverage, **self-validating tasks**, automatic post-implementation validation, and pipeline state tracking for reliable resume.

## What This Extension Does

Install this extension into a spec-kit project when you want one orchestrated workflow instead of manually running each phase yourself.

- `/speckit.autopilot.run` is the main entrypoint for feature delivery
- `/speckit.autopilot.status` shows where a pipeline stopped and what should happen next
- `/speckit.autopilot.validate` checks task quality, test coverage requirements, and self-validation coverage
- `/speckit.autopilot.verify` performs runtime checks after implementation
- `/speckit.autopilot.constitution` injects the autopilot behavioral rules into the project constitution
- `/speckit.autopilot.bootstrap-copilot` copies the required Copilot files into the project root `.github/` folder

The extension is intentionally an orchestrator. It delegates feature work to the core spec-kit commands and adds autopilot-specific behavior on top: clarification auto-answering, test enforcement, self-validation, runtime verification, self-healing, and resume state tracking.

## Recommended Workflow

Use this sequence in a real project:

1. Initialize your project with spec-kit.
2. Install this extension into that project.
3. If you use GitHub Copilot in VS Code, bootstrap the `.github/` Copilot assets.
4. Run `/speckit.autopilot.run <feature description>`.
5. If the run stops or you leave mid-run, use `/speckit.autopilot.status` or re-run `/speckit.autopilot.run` to resume.
6. Use `/speckit.autopilot.validate` or `/speckit.autopilot.verify` directly only when you need those phases independently.

## Features

- **One-command pipeline**: `/speckit.autopilot.run <feature description>` orchestrates the entire workflow
- **Delegates to core commands**: Orchestrates rather than re-implements — stays compatible as spec-kit evolves
- **Auto-answered clarifications**: All specification questions answered using best-practice recommendations
- **Enforced test coverage**: Every generated task includes unit tests and integration tests with post-generation validation
- **Self-validating tasks**: Every feature includes a runnable check the autopilot executes to confirm it works (logging, smoke tests, assertions, health checks, etc.)
- **Runtime verification**: Starts the built application, checks logs, hits HTTP endpoints, and validates everything is running
- **Automatic validation**: Runs `/speckit.autopilot.validate` automatically after every successful implement pass and again as the final pipeline phase
- **Self-healing loop**: When issues are found, generates fix tasks and loops back to implementation automatically (configurable max iterations)
- **Pipeline state file**: `autopilot-state.json` is created at run start as soon as the feature directory is known, then tracks exact phase status for reliable resume and status checks
- **Configurable phases**: Skip phases, reorder them, or run a subset of the pipeline
- **Validation command**: `/speckit.autopilot.validate` verifies test coverage, self-validation, and behavioral guideline compliance with auto-fix
- **Behavioral constitution**: `/speckit.autopilot.constitution` merges coding rules (think-before-code, simplicity, surgical changes, goal-driven execution) into the project constitution

## Prerequisites

- [spec-kit](https://github.com/github/spec-kit) installed (`uv tool install specify-cli`)
- A spec-kit initialized project (`/speckit.constitution` run at least once)
- An AI agent that supports spec-kit commands (Claude Code, Copilot, Cursor, etc.)

> **GitHub Copilot users**: If you want the extension to appear as project-level Copilot instructions, prompts, and custom agents in VS Code, you still need to install the extension into the project and then copy the autopilot-managed `.github/` files into the project root. The bootstrap command below handles that.

## Installation

Install this extension into the target spec-kit project first. After that, decide whether you only need the spec-kit command files or whether you also want GitHub Copilot discovery in VS Code.

### Option 1: Install from GitHub ZIP (Recommended)

```bash
cd /path/to/your/spec-kit-project
specify extension add autopilot --from https://github.com/grknylmz/github-speckit-autopilot/archive/refs/heads/main.zip
```

### Option 2: Install from Local Clone

```bash
# Clone the repository
git clone https://github.com/grknylmz/github-speckit-autopilot.git

# Install into your spec-kit project
cd /path/to/your/spec-kit-project
specify extension add --dev /path/to/github-speckit-autopilot
```

### Verify Installation

```bash
specify extension list

# Should show:
#  ✓ Spec Kit Autopilot (v1.3.0)
#     Automated pipeline orchestrating specify, clarify, plan, tasks, implement, verify, and validate
#     Commands: 6 | Hooks: 0 | Status: Enabled
```

### Confirm Commands Are Registered

```bash
ls .claude/commands/speckit.autopilot.*

# Should show:
# speckit.autopilot.run.md
# speckit.autopilot.status.md
# speckit.autopilot.validate.md
# speckit.autopilot.verify.md
# speckit.autopilot.constitution.md
# speckit.autopilot.bootstrap-copilot.md
```

### Bootstrap GitHub Copilot Files

If you use GitHub Copilot in VS Code, there is one more step. The extension installation places the managed Copilot assets under `.specify/extensions/autopilot/`, but VS Code discovers project instructions, prompts, and agents from the project root `.github/` directory.

Run one of these:

```text
/speckit.autopilot.bootstrap-copilot
```

or

```bash
./.specify/extensions/autopilot/scripts/sync-copilot-files.sh
```

This copies only the autopilot-managed files into:

- `.github/copilot-instructions.md`
- `.github/prompts/`
- `.github/agents/`

It does not modify unrelated `.github/` files.

### Confirm Copilot Files Are Installed

Then verify:

```bash
ls .github/copilot-instructions.md
ls .github/prompts/speckit.autopilot.*.prompt.md
ls .github/agents/*.agent.md

# Should show:
# .github/copilot-instructions.md
# .github/prompts/speckit.autopilot.run.prompt.md
# .github/prompts/speckit.autopilot.status.prompt.md
# .github/prompts/speckit.autopilot.validate.prompt.md
# .github/prompts/speckit.autopilot.verify.prompt.md
# .github/prompts/speckit.autopilot.constitution.prompt.md
# .github/prompts/speckit.autopilot.bootstrap-copilot.prompt.md
# .github/agents/speckit-autopilot.agent.md
# .github/agents/speckit-autopilot-bootstrap.agent.md
```

If VS Code does not show prompt files, enable this setting:

```json
{
  "chat.promptFiles": true
}
```

### Uninstall

```bash
specify extension remove autopilot
```

## Usage

### Quick Start

For a new project setup, this is the shortest reliable path:

1. Install the extension with `specify extension add autopilot --from https://github.com/grknylmz/github-speckit-autopilot/archive/refs/heads/main.zip`.
2. If you use GitHub Copilot in VS Code, run `/speckit.autopilot.bootstrap-copilot` once.
3. Open Copilot Chat or your spec-kit-compatible agent in the project.
4. Run `/speckit.autopilot.run Add user authentication with OAuth2 and JWT tokens`.
5. Re-run `/speckit.autopilot.run` with no arguments to resume if the pipeline was interrupted.

### Which Entry Point To Use

- Use `/speckit.autopilot.run` for normal feature delivery.
- Use `/speckit.autopilot.bootstrap-copilot` only for VS Code Copilot setup.
- Use `/speckit.autopilot.status` when you need to inspect resume state.
- Use `/speckit.autopilot.validate` when you want to check task quality or post-run outputs without re-running the full pipeline.
- Use `/speckit.autopilot.verify` when you want runtime checks without re-running earlier phases.

### Run the Full Pipeline

```
/speckit.autopilot.run Add user authentication with OAuth2 and JWT tokens
```

This orchestrates:

1. **Specify** — Delegates to `/speckit.specify` to generate the feature spec, auto-resolves NEEDS CLARIFICATION markers
2. **Clarify** — Delegates to `/speckit.clarify`, intercepts questions, auto-answers with recommended options
3. **Plan** — Delegates to `/speckit.plan` for research, data model, contracts
4. **Tasks** — Delegates to `/speckit.tasks` with 3-pillar enforcement: unit tests, integration tests, and self-validation (all mandatory)
5. **Implement** — Delegates to `/speckit.implement` to execute all tasks, then runs self-validation checks and logs results
6. **Validate** — Runs automatically at the end of implementation as a post-implementation gate before runtime verification
7. **Verify** — Starts the application, runs health checks (logs, HTTP endpoints, process health), diagnoses issues, and self-heals by generating fix tasks and looping back to implement
8. **Validate** — Final validation pass confirms implementation and post-verify results after the full pipeline completes

Use this command when you want the extension to follow the authoritative flow in `commands/speckit.autopilot.run.md`. Do not call the underlying core commands manually unless you intentionally want to bypass autopilot orchestration.

### Check Pipeline Status

```
/speckit.autopilot.status
```

Reads the pipeline state file and scans artifacts. Shows which phases are complete, task counts, test coverage status, and recommends the next action.

### Validate Test Coverage

```
/speckit.autopilot.validate
```

Runs 16 validation checks on `tasks.md` (11 pre-implementation + 3 post-implementation + 2 post-verify):

1. Implementation tasks have unit tests
2. Integration points have integration tests
3. TDD ordering (tests before implementation)
4. Test file paths are specified
5. Coverage sweep task exists
6. Task IDs are sequential
7. Self-validation coverage (every user story has self-validation tasks)
8. Self-validation quality (each specifies technique, validation, and success criteria)
9. Goal-driven tasks (every implementation task has explicit success criteria)
10. Simplicity (single responsibility per task, no multi-responsibility bundling)
11. Surgical (every implementation task specifies exact file paths)

Post-implementation checks: 12. All tasks marked complete (no remaining `- [ ]` tasks) 13. Self-validation results (all checks in validation-results.log passed) 14. Test suite pass (all tests passed after implementation)

Post-verify checks: 15. Verify runtime results (all endpoint checks passed, no log errors) 16. Self-heal iterations within limit (verify resolved all issues within max iterations)

Offers auto-fix for any issues found.

This command also runs automatically after each successful implement pass inside `/speckit.autopilot.run`.

### Resume a Failed Pipeline

Just re-run the same command — the state file is bootstrapped at run start and then tracks exactly where to resume:

```
/speckit.autopilot.run
```

The pipeline reads `FEATURE_DIR/autopilot-state.json` first. If that file is missing, it falls back to scanning the generated artifacts to determine the resume point.

### Use With GitHub Copilot in VS Code

After you bootstrap the project-root `.github/` files, there are two supported ways to use the extension in Copilot:

1. Select the `Spec Kit Autopilot` custom agent when you want the run, status, validate, verify, or constitution workflows.
2. Select the `Spec Kit Autopilot Bootstrap` custom agent when you want to set up Copilot files in a project.

If you prefer prompt files instead of switching agents, use the matching prompt from `.github/prompts/` for the workflow you want.

### After Autopilot

- `/speckit.autopilot.validate` — Re-run validation manually if you want an additional pass outside the automatic pipeline run
- `/speckit.autopilot.status` — View pipeline status anytime
- `/speckit.analyze` — Check for cross-artifact consistency

## Configuration

Located at `.specify/extensions/autopilot/autopilot-config.yml`.

### Phase Configuration

Control which phases run:

```yaml
pipeline:
  phases:
    - specify
    - clarify
    - plan
    - tasks
    - implement
    - verify
    - validate
```

Common configurations:

- **Full pipeline with verify**: `[specify, clarify, plan, tasks, implement, verify, validate]`
- **Plan only (no execute)**: `[specify, clarify, plan, tasks]`
- **Skip clarify**: `[specify, plan, tasks, implement, verify, validate]`
- **Re-plan only**: `[plan, tasks]`
- **Tasks only**: `[tasks]`
- **Implement only**: `[implement, validate]`
- **Implement and verify**: `[implement, verify, validate]`

### All Settings

| Setting                              | Default                                                        | Description                         |
| ------------------------------------ | -------------------------------------------------------------- | ----------------------------------- |
| `test_enforcement.unit_tests`        | `true`                                                         | Generate unit test tasks            |
| `test_enforcement.integration_tests` | `true`                                                         | Generate integration test tasks     |
| `test_enforcement.coverage_target`   | `80`                                                           | Minimum coverage percentage         |
| `test_enforcement.test_framework`    | `"auto-detect"`                                                | Test framework to use               |
| `self_validation.enabled`            | `true`                                                         | Generate self-validation tasks      |
| `self_validation.techniques`         | `[logging, smoke, ...]`                                        | Allowed validation techniques       |
| `self_validation.log_results`        | `true`                                                         | Log validation results to file      |
| `clarify.auto_answer`                | `true`                                                         | Auto-answer clarification questions |
| `clarify.use_recommended`            | `true`                                                         | Use AI-recommended option           |
| `clarify.max_auto_questions`         | `5`                                                            | Max questions to auto-answer        |
| `pipeline.phases`                    | `[specify, clarify, plan, tasks, implement, verify, validate]` | Phases to execute                   |
| `pipeline.stop_on_failure`           | `true`                                                         | Stop on any phase failure           |
| `verify.enabled`                     | `true`                                                         | Enable runtime verification phase   |
| `verify.max_iterations`              | `5`                                                            | Maximum self-heal loops             |
| `verify.startup_timeout_seconds`     | `30`                                                           | App startup timeout                 |
| `verify.health_retries`              | `3`                                                            | Health check retry count            |
| `verify.auto_heal`                   | `true`                                                         | Auto-generate fix tasks on failure  |
| `verify.endpoints`                   | `[]`                                                           | Explicit endpoints to verify        |

## Self-Validation

The core differentiator of autopilot. Every feature built through the pipeline must include a self-validation step — a runnable check the autopilot executes to confirm the feature works without any human intervention.

### Three Pillars Per Task

| Pillar                | What It Verifies                               | Who Runs It              |
| --------------------- | ---------------------------------------------- | ------------------------ |
| **Unit tests**        | Individual functions/methods work in isolation | Test runner              |
| **Integration tests** | Components work together correctly             | Test runner              |
| **Self-validation**   | The built feature actually works at runtime    | Autopilot (or developer) |

### Validation Techniques

The autopilot chooses the most appropriate technique per task:

| Technique           | Best For                        | Example                                                     |
| ------------------- | ------------------------------- | ----------------------------------------------------------- |
| **Logging**         | Data processing, business logic | Log order creation with id, total, items — check log output |
| **Smoke test**      | API endpoints, CLI commands     | `curl -f http://localhost:3000/api/health`                  |
| **Assertion**       | Calculations, transformations   | `assert(user.age >= 0)`                                     |
| **Build**           | New modules, components         | `npm run build && npm run typecheck`                        |
| **Schema**          | Data models, migrations         | `npx prisma validate && npx prisma migrate status`          |
| **Health endpoint** | Services, APIs                  | `GET /health` returns `{status: "ok"}`                      |
| **Dry-run**         | Destructive operations          | `--dry-run` flag shows what would happen                    |
| **Idempotency**     | State mutations                 | Run twice, verify identical state                           |
| **Contract**        | API integrations                | Response matches expected JSON schema                       |
| **Snapshot**        | Output generation, reports      | Compare output against golden snapshot                      |

### Self-Validation Task Format

Every self-validation task in `tasks.md` specifies three things:

```text
- [ ] T{NNN} [US{N}] Add self-validation for {Component} in {source-path}
  - Technique: {which technique}
  - Validation: {what to execute}
  - Success criteria: {what "pass" looks like}
```

## Behavioral Constitution

The autopilot automatically merges behavioral guidelines into the project constitution when the pipeline starts. These rules reduce common LLM coding mistakes and are enforced during task generation and validation.

### The 4 Rules

| Rule                      | Principle                                                         | What It Prevents             |
| ------------------------- | ----------------------------------------------------------------- | ---------------------------- |
| **Think Before Coding**   | State assumptions, surface tradeoffs, ask before assuming         | Implementing the wrong thing |
| **Simplicity First**      | Minimum code, no speculative features, no over-abstraction        | Overcomplicated solutions    |
| **Surgical Changes**      | Touch only what you must, match existing style                    | Collateral damage in diffs   |
| **Goal-Driven Execution** | Every task has explicit success criteria, verify before moving on | Tasks that can't self-verify |

### Setup Behavioral Guidelines

```
/speckit.autopilot.constitution
```

This appends the guidelines to `.specify/constitution.md` (idempotent — safe to run multiple times). The autopilot pipeline runs this automatically before the first phase.

### How Rules Apply to Tasks

- **Goal-Driven**: Every task must include success criteria — not just "implement X" but "implement X, verify: {check}"
- **Simplicity**: One responsibility per task. If a task does three things, it gets split.
- **Surgical**: Every task specifies exact file paths. No "update related files" vagueness.
- **Think First**: Ambiguous tasks include a sub-step to surface assumptions before implementing.

## Architecture

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

Key design decisions:

- **Orchestrator, not re-implementer** — Delegates to core commands, survives spec-kit updates
- **State file over file-scanning** — `autopilot-state.json` gives precise resume, no guessing
- **Post-generation validation** — Verifies test coverage was actually generated, auto-fixes gaps
- **Additive enhancements** — Test strategy injection appends to core artifacts, doesn't modify them

## Commands

| Command                                | Description                                                                |
| -------------------------------------- | -------------------------------------------------------------------------- |
| `/speckit.autopilot.run`               | Run the full pipeline                                                      |
| `/speckit.autopilot.status`            | Check pipeline progress                                                    |
| `/speckit.autopilot.validate`          | Validate test coverage, self-validation, and behavioral compliance         |
| `/speckit.autopilot.verify`            | Runtime verification: start app, check health, diagnose issues, self-heal  |
| `/speckit.autopilot.constitution`      | Merge behavioral guidelines into project constitution                      |
| `/speckit.autopilot.bootstrap-copilot` | Copy Copilot instruction and prompt files into the project root `.github/` |

## Requirements

- spec-kit >= 0.1.0
- Core commands: `speckit.specify`, `speckit.clarify`, `speckit.plan`, `speckit.tasks`, `speckit.implement`

## License

MIT

---

## GitHub Copilot Support

This repository includes built-in support for GitHub Copilot. If you clone the repository directly, the files are already present. If you install via `specify extension add`, run `/speckit.autopilot.bootstrap-copilot` in a supported agent or use the sync script to copy the Copilot files from `.specify/extensions/autopilot/.github/` into the project root `.github/`.

### How It Works

| Mechanism               | File                              | Loaded                                       |
| ----------------------- | --------------------------------- | -------------------------------------------- |
| **Custom instructions** | `.github/copilot-instructions.md` | Automatically (all Copilot environments)     |
| **Prompt files**        | `.github/prompts/*.prompt.md`     | Manual attach in Copilot Chat (VS Code only) |
| **Custom agents**       | `.github/agents/*.agent.md`       | Agent picker and agent-mode workflows        |

### Setup

**For custom instructions** (all environments): If you cloned this repository directly, no setup is needed. If you installed via `specify extension add`, first run `/speckit.autopilot.bootstrap-copilot` in a supported agent or `./.specify/extensions/autopilot/scripts/sync-copilot-files.sh`. After that, `.github/copilot-instructions.md` is automatically loaded when you work in the repository in VS Code, Visual Studio, or github.com.

**For prompt files** (VS Code only):

1. If you installed via `specify extension add`, run `/speckit.autopilot.bootstrap-copilot` in a supported agent or `./.specify/extensions/autopilot/scripts/sync-copilot-files.sh`
2. Open VS Code Settings (JSON): `Cmd+Shift+P` → "Open Workspace Settings (JSON)"
3. Add `"chat.promptFiles": true`
4. The `.github/prompts/` folder becomes available in Copilot Chat

**For custom agents** (VS Code Copilot agent mode): After bootstrap or sync, the `.github/agents/` folder contains autopilot-specific custom agents that can be selected from the agent picker.

### Usage

#### Using Custom Instructions

The behavioral rules, three-pillar enforcement, and pipeline conventions are automatically applied to all Copilot Chat interactions. No action needed.

#### Using Prompt Files

1. Open Copilot Chat in VS Code
2. Click the **Attach context** icon at the bottom of the chat
3. Click **Prompt...** and choose one of the autopilot prompts
4. Type your feature description or question
5. Submit

| Prompt File                           | Equivalent Command                     | Purpose                                                           |
| ------------------------------------- | -------------------------------------- | ----------------------------------------------------------------- |
| `speckit.autopilot.run`               | `/speckit.autopilot.run`               | Full pipeline orchestration via the extension command definitions |
| `speckit.autopilot.status`            | `/speckit.autopilot.status`            | Check pipeline progress                                           |
| `speckit.autopilot.validate`          | `/speckit.autopilot.validate`          | Validate task coverage (16 checks)                                |
| `speckit.autopilot.verify`            | `/speckit.autopilot.verify`            | Runtime verification + self-heal                                  |
| `speckit.autopilot.constitution`      | `/speckit.autopilot.constitution`      | Merge behavioral guidelines                                       |
| `speckit.autopilot.bootstrap-copilot` | `/speckit.autopilot.bootstrap-copilot` | Copy Copilot files into the project root `.github/`               |

#### Using Custom Agents

After bootstrap, these custom agents are available from `.github/agents/`:

| Agent File                             | Purpose                                                                       |
| -------------------------------------- | ----------------------------------------------------------------------------- |
| `speckit-autopilot.agent.md`           | Run the autopilot workflows by reading the authoritative files in `commands/` |
| `speckit-autopilot-bootstrap.agent.md` | Set up project-root Copilot instruction, prompt, and agent files              |

#### Using with Copilot Coding Agent

When you assign an issue to Copilot, the `copilot-instructions.md` is automatically loaded. Attach the relevant prompt file to provide structured instructions for the task.

### Feature Parity

| Feature                   | Claude Code                       | GitHub Copilot                                  |
| ------------------------- | --------------------------------- | ----------------------------------------------- |
| `Auto-loaded context`     | extension.yml + commands/         | copilot-instructions.md + commands/             |
| Slash commands            | `/speckit.autopilot.run` etc.     | Prompt files (manual attach)                    |
| Script execution          | `{SCRIPT}` placeholders           | Not supported (file reading fallback)           |
| `speckit CLI integration` | Full (delegates to core commands) | Command-backed instructions from this extension |
| State file management     | Automatic                         | Copilot follows command-backed prompt wrappers  |
| Resume support            | Built-in via state file           | Re-attach prompt (state preserved)              |
| Self-heal loop            | Automatic loop                    | Manual re-attach verify prompt                  |
| Configuration             | autopilot-config.yml              | Same file, read by Copilot                      |

### Limitations

- **No script execution**: Feature directory discovery uses file reading instead of prerequisite scripts
- **No automatic pipeline orchestration**: Each prompt is attached manually; the full run prompt covers all phases
- **Self-heal loop requires manual re-invocation**: After fix tasks are generated, re-attach the verify prompt
- **Prompt files are VS Code only**: The `.github/prompts/` directory is a VS Code Copilot feature
- **No extension manifest support**: No `requires`, `provides`, or version compatibility checks

For all autopilot prompts and custom agents, Copilot should follow the matching workflow defined in `commands/` and the autopilot-managed files under `.github/`, rather than relying on separate inline implementations. After a `specify extension add` install, sync those files from `.specify/extensions/autopilot/.github/` into the project root before using prompt entrypoints or custom agents.
