Validate autopilot outputs using this extension's command definitions.

## Source of Truth

1. Read `commands/speckit.autopilot.validate.md` and follow it as the authoritative workflow.
2. If it references other autopilot commands or shared artifacts, use the matching files in `commands/` as the source of truth.
3. Do not re-implement validation logic inline in this prompt.
4. If this prompt and any file in `commands/` differ, the `commands/` file wins.

## User Input

Use any user-supplied scope or follow-up only if it is compatible with `commands/speckit.autopilot.validate.md`.
