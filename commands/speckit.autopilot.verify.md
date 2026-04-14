---
description: 'Verify the built application by starting it, checking logs, hitting endpoints, and diagnosing issues. Self-heals by generating fix tasks and looping back to implement.'
mode: speckit.autopilot.verify
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --paths-only
  ps: scripts/powershell/check-prerequisites.ps1 -Json -PathsOnly
---

# Autopilot Verify

Starts the built application, runs health checks (logs, HTTP endpoints, process health), diagnoses issues, and self-heals by generating fix tasks that loop back to the implement phase.

## Steps

### 1. Load Context

Run `{SCRIPT}` from repo root. Parse JSON payload for `FEATURE_DIR`. If no feature is found, report:

```
No active feature found. Run /speckit.autopilot.run first.
```

Read `FEATURE_DIR/autopilot-state.json` for the current verify state (iteration count, previous checks, diagnosis).

Read `autopilot-config.yml` for verify settings:

| Setting                          | Default | Purpose                                       |
| -------------------------------- | ------- | --------------------------------------------- |
| `verify.max_iterations`          | 5       | Maximum self-heal loops                       |
| `verify.startup_timeout_seconds` | 30      | Seconds to wait for app startup               |
| `verify.health_retries`          | 3       | Health endpoint check retries                 |
| `verify.auto_heal`               | true    | Generate fix tasks on failure                 |
| `verify.endpoints`               | []      | Explicit endpoints (overrides auto-detection) |

### 2. Stop Any Previous Instance

Before starting a new verification cycle, ensure no previous instance of the application is running:

1. Check for processes from a previous verify iteration (PID from state file, or processes matching the expected startup command pattern).
2. Kill any found processes: `kill {PID}` or `pkill -f "{startup-command-pattern}"`.
3. Wait 2 seconds for graceful shutdown.
4. Verify the port(s) are free.

### 3. Detect Startup Commands

Determine how to start the application. Follow this priority sequence:

**3a. Quickstart** — Read `FEATURE_DIR/quickstart.md` if it exists. Extract startup commands from fenced code blocks (look for: `npm start`, `npm run dev`, `python manage.py runserver`, `go run`, `docker compose up`, `make serve`, `cargo run`, etc.).

**3b. Plan** — If no quickstart, read `FEATURE_DIR/plan.md`. Look for "Quickstart", "Getting Started", or "Running" sections with startup instructions.

**3c. Project conventions** — If neither yields a command, inspect the project root:

- `package.json` → `scripts.start` or `scripts.dev`
- `Makefile` → `serve`, `run`, `start` targets
- `docker-compose.yml` or `Dockerfile` → `docker compose up`
- `pyproject.toml` → script entries
- `Cargo.toml` → binary targets

**3d. Self-validation tasks** — If nothing found, read self-validation tasks from `tasks.md` (smoke/health technique tasks contain URLs that imply how the app runs). Infer the start command from endpoint URLs.

**3e. Detection failure** — If no startup command is found:

```
Could not detect application startup command.

Options:
  1. Add a quickstart.md with startup instructions to the feature directory
  2. Configure startup command in autopilot-config.yml under verify.startup_command
  3. Start the application manually and re-run verify
```

Stop here. Set `verify.status: "failed"` with error detail.

### 4. Start the Application

1. Execute the detected startup command as a background process using `&`.
2. Record the PID.
3. Wait up to `startup_timeout_seconds` for readiness.

**Readiness detection** (in order of priority):

a. If a health endpoint exists (from contracts or self-validation tasks), poll it:

```bash
for i in $(seq 1 {health_retries}); do
  curl -sf http://localhost:{port}/health && break
  sleep {startup_timeout_seconds / health_retries}
done
```

b. If no health endpoint, check if the process is running and the port is listening:

```bash
lsof -i :{port} || curl -sf http://localhost:{port}
```

c. If neither is applicable, wait the full timeout and check if the process is still alive.

**If startup fails** (process exits, port not listening after timeout):

- Capture stdout and stderr from the startup process.
- Set `verify.checks.startup.status: "fail"`.
- Record the error output in the checks.
- Proceed to Step 6 (Diagnose).

**If startup succeeds**:

- Record `verify.checks.startup.status: "pass"`, the command used, and time to ready.
- Proceed to Step 5 (Health Checks).

### 5. Run Health Checks

Execute checks and record results for each.

#### 5a. Log Analysis

Read application logs:

- Stdout/stderr captured during startup
- Log files at conventional paths: `logs/`, `*.log`, `var/log/`
- Application-specific log output (e.g., `journalctl`, Docker logs if containerized)

**Error patterns** to detect (case-insensitive):

- `ERROR`, `FATAL`, `CRITICAL`, `PANIC`
- `Exception`, `Traceback`, `Stack trace`, `Segmentation fault`
- `ECONNREFUSED`, `ENOMEM`, `ETIMEOUT`
- `Unhandled`, `Uncaught`
- `failed to`, `cannot`, `unable to`

**Positive patterns** to confirm:

- `listening on port`, `server started`, `ready`, `connected to`
- `migration completed`, `database connected`

Record:

```
verify.checks.log_analysis:
  errors: {count}
  warnings: {count}
  error_patterns: [{list of matched patterns with context}]
```

#### 5b. HTTP Endpoint Verification

Collect endpoints to test. Priority order:

1. **Explicit config** — `verify.endpoints` from config (if non-empty, use only these).
2. **Contracts** — Read `FEATURE_DIR/contracts/` directory. Each contract file defines an endpoint with method and path.
3. **Self-validation tasks** — Parse `tasks.md` for tasks using `smoke`, `health`, or `contract` techniques. Extract URLs from validation commands.
4. **Plan/Spec** — Read `plan.md` or `spec.md` for listed API endpoints.
5. **Default health endpoints** — If nothing found, try standard paths: `/health`, `/healthz`, `/ready`, `/status`, `/api/health`.

For each endpoint, make an HTTP request:

- Record: HTTP status code, response body (truncated to 500 chars), response time.
- Classify: **PASS** (2xx matching expectations), **WARN** (3xx or unexpected 2xx), **FAIL** (4xx/5xx/timeout/connection refused).

```
verify.checks.endpoints:
  - url: "/health"
    method: "GET"
    expected_status: 200
    actual_status: 200
    response_time_ms: 45
    result: "pass"
  - url: "/api/users"
    method: "POST"
    expected_status: 201
    actual_status: 500
    response_body: "{\"error\": \"Internal server error\"}"
    result: "fail"
```

#### 5c. Process Health

- Verify the application process is still running (`kill -0 {PID}`).
- Check if the port is still listening.
- Best-effort: check memory usage if available.

```
verify.checks.process:
  running: true
  port_listening: true
```

### 6. Evaluate Results

Aggregate all check results into a verdict:

| Condition                                                  | Verdict          |
| ---------------------------------------------------------- | ---------------- |
| All endpoints PASS, no error log patterns, process healthy | `healthy`        |
| Some endpoints WARN, minor log warnings, process healthy   | `degraded`       |
| Any endpoint FAIL, critical log errors, process crashed    | `failed`         |
| Startup itself failed (process never became ready)         | `startup_failed` |

### 7. Diagnose Issues

If verdict is NOT `healthy`, perform diagnosis.

#### 7a. Correlate Errors to Tasks

For each error found:

- Match the error's file path, module name, or component name against tasks in `tasks.md`.
- Identify which implementation task likely introduced the issue.

#### 7b. Analyze Stack Traces

For each stack trace:

- Extract the failing file, line number, and function name.
- Determine root cause: null reference, missing import, wrong config, type mismatch, missing dependency, etc.

#### 7c. Analyze HTTP Failures

For each failed endpoint:

- Determine category: routing (404), auth (401/403), server error (500), connectivity (connection refused/timeout).
- Cross-reference with contract definition (if available) to identify divergence.

#### 7d. Synthesize Diagnosis

For each distinct issue, produce a structured diagnosis:

```
Issue {N}: {short-title}
  Severity: {critical|major|minor}
  Affected: {endpoint/log/error detail}
  Root cause: {analysis}
  Related task: T{NNN} — {task description}
  Suggested fix: {what needs to change, in which file}
```

Record in `verify.diagnosis` array.

### 8. Self-Heal (Generate Fix Tasks)

If `verify.auto_heal` is `true` and `verify.iteration < verify.max_iterations`:

#### 8a. Generate Fix Tasks

For each diagnosis from Step 7, create a fix task:

```text
- [ ] T{NNN} [FIX-{iteration}] Fix {issue-title} in {file-path}
  - Root cause: {diagnosis root cause}
  - Fix: {specific change needed}
  - Verify: {how to confirm the fix works}
```

#### 8b. Append to tasks.md

Add fix tasks in a new section at the end of `tasks.md`:

```markdown
## Verify Fix Tasks — Iteration {N}

_Generated by verify phase after runtime verification failures._

{fix tasks}
```

#### 8c. Re-number Tasks

After appending, ensure all task IDs remain sequential (T001, T002, ..., T{last}). Renumber if needed.

#### 8d. Update State

```json
"verify": {
  "status": "healing",
  "iteration": N,
  "max_iterations": N,
  "verdict": "failed|degraded|startup_failed",
  "fix_tasks_created": N,
  "fix_task_ids": ["T{NNN}", ...],
  "checks": { ... },
  "diagnosis": [ ... ],
  "fix_tasks_created_total": N
}
```

#### 8e. Stop Application and Return

1. Stop the running application (`kill {PID}`).
2. The orchestrator (run command) detects `verify.status: "healing"` and re-triggers the implement phase for the new fix tasks.

**If iteration count has reached `verify.max_iterations`**:

- Do NOT generate fix tasks.
- Report remaining issues.
- Set `verify.status: "failed"`.
- Stop the application.
- If `pipeline.stop_on_failure` is true, halt pipeline. Otherwise continue to validate.

### 9. Cleanup and Final Report (if verdict is `healthy`)

#### 9a. Stop Application

Kill the background process. Verify port is freed.

#### 9b. Write Results Log

Write to `FEATURE_DIR/verify-results.log`:

```
Verify Results — {timestamp} — Iteration {N}
============================================================
Verdict: HEALTHY

Startup:
  Command: {command}
  Time to ready: {seconds}s

Log Analysis:
  Errors found: 0
  Warnings: {N}

Endpoint Checks:
  {method} {url} → {status} ({response_time}ms) ✓
  ...

Process Health:
  Running: yes

Self-Healing:
  Iterations: {N}
  Fix tasks generated: {N} (across all iterations)
============================================================
```

#### 9c. Update State

```json
"verify": {
  "status": "complete",
  "iteration": N,
  "max_iterations": N,
  "verdict": "healthy",
  "completed_at": "<ISO-timestamp>",
  "checks": {
    "startup": { "status": "pass", "command": "...", "ready_after_seconds": N },
    "log_analysis": { "errors": 0, "warnings": N, "error_patterns": [] },
    "endpoints": [{ "url": "...", "method": "GET", "status": 200, "response_time_ms": N, "result": "pass" }],
    "process": { "running": true }
  },
  "diagnosis": [],
  "fix_tasks_created_total": N,
  "iterations_used": N,
  "results_log": "FEATURE_DIR/verify-results.log"
}
```

#### 9d. Phase Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AUTOMATION PHASE 6/7: VERIFY (Runtime Health + Self-Heal) ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Verdict:           HEALTHY
Iterations:        {N} / {max}
Startup:           {command} (ready in {seconds}s)
Endpoints Checked: {N} ({N} passed)
Log Errors:        0
Self-Heal:         {N} fix tasks generated, {N} resolved
Results Log:       {path}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
