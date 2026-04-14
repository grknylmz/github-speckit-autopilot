Verify runtime behavior using this extension's command definitions.

## Source of Truth

1. Read `commands/speckit.autopilot.verify.md` and follow it as the authoritative workflow.
2. If it references other autopilot commands or shared artifacts, use the matching files in `commands/` as the source of truth.
3. Do not re-implement verify logic inline in this prompt.
4. If this prompt and any file in `commands/` differ, the `commands/` file wins.

## User Input

Use any user-supplied runtime context only where `commands/speckit.autopilot.verify.md` allows.
