Merge autopilot behavioral guidelines using this extension's command definitions.

## Source of Truth

1. Read `commands/speckit.autopilot.constitution.md` and follow it as the authoritative workflow.
2. If it references other autopilot commands or shared artifacts, use the matching files in `commands/` as the source of truth.
3. Do not re-implement constitution logic inline in this prompt.
4. If this prompt and any file in `commands/` differ, the `commands/` file wins.

## User Input

Apply any user-requested scope or refresh behavior only where `commands/speckit.autopilot.constitution.md` permits.
