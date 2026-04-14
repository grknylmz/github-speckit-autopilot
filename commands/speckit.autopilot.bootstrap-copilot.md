---
description: "Bootstrap GitHub Copilot support by copying the extension's Copilot instruction and prompt files into the project root .github directory."
---

# Bootstrap GitHub Copilot Support

Copies the autopilot extension's Copilot files from the installed extension directory into the current project's root `.github/` directory so VS Code Copilot can discover them.

## Steps

### 1. Locate the Installed Extension

Check for the installed extension at:

```text
.specify/extensions/autopilot/
```

If that directory does not exist, report:

```text
Autopilot extension not found at .specify/extensions/autopilot/

Install it first:
  specify extension add autopilot --from https://github.com/grknylmz/github-speckit-autopilot/archive/refs/heads/main.zip
```

Stop here.

### 2. Locate the Copilot Source Files

Use the extension-managed files in:

```text
.specify/extensions/autopilot/.github/
```

Required source files:

- `.specify/extensions/autopilot/.github/copilot-instructions.md`
- `.specify/extensions/autopilot/.github/prompts/speckit.autopilot.run.prompt.md`
- `.specify/extensions/autopilot/.github/prompts/speckit.autopilot.status.prompt.md`
- `.specify/extensions/autopilot/.github/prompts/speckit.autopilot.validate.prompt.md`
- `.specify/extensions/autopilot/.github/prompts/speckit.autopilot.verify.prompt.md`
- `.specify/extensions/autopilot/.github/prompts/speckit.autopilot.constitution.prompt.md`
- `.specify/extensions/autopilot/.github/prompts/speckit.autopilot.bootstrap-copilot.prompt.md`

If any are missing, report which ones are missing and stop.

### 3. Copy Files Into the Project Root

Ensure these directories exist at the project root:

- `.github/`
- `.github/prompts/`

Then copy the autopilot-managed files into the project root:

- `.github/copilot-instructions.md`
- `.github/prompts/speckit.autopilot.run.prompt.md`
- `.github/prompts/speckit.autopilot.status.prompt.md`
- `.github/prompts/speckit.autopilot.validate.prompt.md`
- `.github/prompts/speckit.autopilot.verify.prompt.md`
- `.github/prompts/speckit.autopilot.constitution.prompt.md`
- `.github/prompts/speckit.autopilot.bootstrap-copilot.prompt.md`

Rules:

- Overwrite only these autopilot-managed files.
- Do not modify unrelated files under `.github/`.
- Preserve file contents exactly.

### 4. Verify

Confirm all copied files now exist in the project root.

If VS Code prompt files are not yet enabled, remind the user to set:

```json
{
  "chat.promptFiles": true
}
```

### 5. Report

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AUTOPILOT COPILOT BOOTSTRAP COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Copied Files:
  ✓ .github/copilot-instructions.md
  ✓ .github/prompts/speckit.autopilot.run.prompt.md
  ✓ .github/prompts/speckit.autopilot.status.prompt.md
  ✓ .github/prompts/speckit.autopilot.validate.prompt.md
  ✓ .github/prompts/speckit.autopilot.verify.prompt.md
  ✓ .github/prompts/speckit.autopilot.constitution.prompt.md
  ✓ .github/prompts/speckit.autopilot.bootstrap-copilot.prompt.md

Next:
  1. Enable `chat.promptFiles` in VS Code if needed
  2. Open Copilot Chat and attach an autopilot prompt

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```