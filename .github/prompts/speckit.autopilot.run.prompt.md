Run the Spec Kit Autopilot pipeline using this extension's command definitions.

## Source of Truth

1. Read `commands/speckit.autopilot.run.md` and follow it as the authoritative workflow.
2. If that workflow delegates to companion autopilot commands, read the matching files in `commands/` and follow those definitions.
3. Do not re-implement the pipeline inline in this prompt.
4. If this prompt and any file in `commands/` differ, the `commands/` file wins.
5. Use `/speckit.autopilot.run` as the only autopilot pipeline entrypoint. Do not use or suggest `/speckit.autopilot.start`.

## User Input

Use the user's feature description if one is provided.
If no feature description is provided, follow the resume behavior defined in `commands/speckit.autopilot.run.md`.
