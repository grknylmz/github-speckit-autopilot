Verify the built application by starting it, checking logs, hitting endpoints, and diagnosing issues. Self-heals by generating fix tasks that can be re-implemented.

## Steps

### 1. Load Context

Find the active feature directory:

1. Read `.specify/feature.json` for the feature directory path
2. Look for the most recently modified directory under `.specify/specs/`
3. If nothing found, report: `No active feature found.`

Read `FEATURE_DIR/autopilot-state.json` for current verify state (iteration count, previous checks, diagnosis).

Read `autopilot-config.yml` (at `.specify/extensions/autopilot/autopilot-config.yml`) for verify settings:

| Setting | Default | Purpose |
|---------|---------|---------|
| `verify.max_iterations` | 5 | Maximum self-heal loops |
| `verify.startup_timeout_seconds` | 30 | Seconds to wait for app startup |
| `verify.health_retries` | 3 | Health endpoint check retries |
| `verify.auto_heal` | true | Generate fix tasks on failure |
| `verify.endpoints` | [] | Explicit endpoints (overrides auto-detection) |

### 2. Stop Any Previous Instance

Before starting a new verification cycle, ensure no previous instance is running:

1. Check for processes from a previous verify iteration (from state file or matching startup command pattern)
2. Kill any found processes: `kill {PID}` or `pkill -f "{startup-command-pattern}"`
3. Wait 2 seconds for graceful shutdown
4. Verify port(s) are free

### 3. Detect Startup Commands

Determine how to start the application. Follow this priority:

**3a. Quickstart** — Read `FEATURE_DIR/quickstart.md`. Extract startup commands from fenced code blocks (look for: `npm start`, `npm run dev`, `python manage.py runserver`, `go run`, `docker compose up`, `make serve`, `cargo run`, etc.).

**3b. Plan** — If no quickstart, read `FEATURE_DIR/plan.md`. Look for "Quickstart", "Getting Started", or "Running" sections.

**3c. Project conventions** — Inspect the project root:
- `package.json` → `scripts.start` or `scripts.dev`
- `Makefile` → `serve`, `run`, `start` targets
- `docker-compose.yml` or `Dockerfile` → `docker compose up`
- `pyproject.toml` → script entries
- `Cargo.toml` → binary targets

**3d. Self-validation tasks** — Read tasks.md for smoke/health technique tasks containing URLs that imply how the app runs.

**3e. Detection failure** — If no startup command found:

```
Could not detect application startup command.

Options:
  1. Add a quickstart.md with startup instructions to the feature directory
  2. Configure startup command in autopilot-config.yml under verify.startup_command
  3. Start the application manually and re-attach this prompt
```

Stop here. Set `verify.status: "failed"`.

### 4. Start the Application

1. Execute the detected startup command as a background process
2. Record the PID
3. Wait up to `startup_timeout_seconds` for readiness

**Readiness detection** (in priority order):

a. If a health endpoint exists, poll it:
   ```bash
   for i in $(seq 1 {health_retries}); do
     curl -sf http://localhost:{port}/health && break
     sleep {startup_timeout_seconds / health_retries}
   done
   ```

b. If no health endpoint, check if process is running and port is listening:
   ```bash
   lsof -i :{port} || curl -sf http://localhost:{port}
   ```

c. If neither applies, wait the full timeout and check if process is alive.

**If startup fails**: Capture stdout/stderr. Set `verify.checks.startup.status: "fail"`. Proceed to Step 6 (Diagnose).

**If startup succeeds**: Record command used and time to ready. Proceed to Step 5 (Health Checks).

### 5. Run Health Checks

#### 5a. Log Analysis

Read application logs:
- Stdout/stderr captured during startup
- Log files at conventional paths: `logs/`, `*.log`, `var/log/`

**Error patterns** to detect (case-insensitive):
- `ERROR`, `FATAL`, `CRITICAL`, `PANIC`
- `Exception`, `Traceback`, `Stack trace`, `Segmentation fault`
- `ECONNREFUSED`, `ENOMEM`, `ETIMEOUT`
- `Unhandled`, `Uncaught`
- `failed to`, `cannot`, `unable to`

**Positive patterns** to confirm:
- `listening on port`, `server started`, `ready`, `connected to`
- `migration completed`, `database connected`

#### 5b. HTTP Endpoint Verification

Collect endpoints to test. Priority:

1. **Explicit config** — `verify.endpoints` from config (if non-empty, use only these)
2. **Contracts** — Read `FEATURE_DIR/contracts/` for endpoint definitions
3. **Self-validation tasks** — Parse tasks.md for smoke/health/contract technique URLs
4. **Plan/Spec** — Read plan.md or spec.md for API endpoints
5. **Default health endpoints** — Try: `/health`, `/healthz`, `/ready`, `/status`, `/api/health`

For each endpoint, make an HTTP request:
- Record: HTTP status code, response body (truncated to 500 chars), response time
- Classify: **PASS** (2xx matching expectations), **WARN** (3xx or unexpected 2xx), **FAIL** (4xx/5xx/timeout/connection refused)

#### 5c. Process Health

- Verify process is still running (`kill -0 {PID}`)
- Check if port is still listening
- Best-effort: check memory usage

### 6. Evaluate Results

Aggregate all checks into a verdict:

| Condition | Verdict |
|-----------|---------|
| All endpoints PASS, no error log patterns, process healthy | `healthy` |
| Some endpoints WARN, minor log warnings, process healthy | `degraded` |
| Any endpoint FAIL, critical log errors, process crashed | `failed` |
| Startup itself failed (process never became ready) | `startup_failed` |

### 7. Diagnose Issues

If verdict is NOT `healthy`:

#### 7a. Correlate Errors to Tasks
For each error, match file path/module/component against tasks in tasks.md.

#### 7b. Analyze Stack Traces
Extract failing file, line number, function name. Determine root cause.

#### 7c. Analyze HTTP Failures
For each failed endpoint: routing (404), auth (401/403), server error (500), connectivity.

#### 7d. Synthesize Diagnosis
For each distinct issue:

```
Issue {N}: {short-title}
  Severity: {critical|major|minor}
  Affected: {endpoint/log/error detail}
  Root cause: {analysis}
  Related task: T{NNN} — {task description}
  Suggested fix: {what needs to change, in which file}
```

### 8. Self-Heal (Generate Fix Tasks)

If `verify.auto_heal` is `true` and iteration < `max_iterations`:

#### 8a. Generate Fix Tasks

For each diagnosis:

```text
- [ ] T{NNN} [FIX-{iteration}] Fix {issue-title} in {file-path}
  - Root cause: {diagnosis root cause}
  - Fix: {specific change needed}
  - Verify: {how to confirm the fix works}
```

#### 8b. Append to tasks.md

Add a new section:

```markdown
## Verify Fix Tasks — Iteration {N}

_Generated by verify phase after runtime verification failures._

{fix tasks}
```

#### 8c. Re-number Tasks

Ensure all task IDs remain sequential (T001, T002, ..., T{last}).

#### 8d. Update State

Update `autopilot-state.json` verify phase:
- `status: "healing"`
- Increment iteration count
- Record diagnosis and fix task IDs

#### 8e. Stop Application and Report

1. Stop the running application
2. Report that fix tasks were generated
3. User should re-implement fix tasks (attach speckit.autopilot.run prompt with phases: `[implement, verify]`)

**If iteration count has reached max**: Do NOT generate fix tasks. Report remaining issues. Set `verify.status: "failed"`.

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
  Fix tasks generated: {N}
============================================================
```

#### 9c. Update State

Update `autopilot-state.json`:
- `verify.status: "complete"`
- `verify.verdict: "healthy"`
- Record all check results

#### 9d. Phase Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
VERIFY (Runtime Health + Self-Heal) ✓
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
