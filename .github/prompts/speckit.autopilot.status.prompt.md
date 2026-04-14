Check the current status of the autopilot pipeline using this extension's command definitions.

## Source of Truth

1. Read `commands/speckit.autopilot.status.md` and follow it as the authoritative workflow.
2. If it references other autopilot commands, use the matching files in `commands/` as the source of truth.
3. Do not re-implement status logic inline in this prompt.
4. If this prompt and any file in `commands/` differ, the `commands/` file wins.

## User Input

If the user includes additional context, apply it only where `commands/speckit.autopilot.status.md` allows.
