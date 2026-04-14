Bootstrap GitHub Copilot support for this project using this extension's command definitions.

## Source of Truth

1. Read `commands/speckit.autopilot.bootstrap-copilot.md` and follow it as the authoritative workflow.
2. Use the installed extension files under `.specify/extensions/autopilot/.github/` as the source for the project root `.github/` files.
3. Do not re-implement bootstrap logic inline in this prompt.
4. If this prompt and any file in `commands/` differ, the `commands/` file wins.

## User Input

Apply any user-requested scope only where `commands/speckit.autopilot.bootstrap-copilot.md` permits.