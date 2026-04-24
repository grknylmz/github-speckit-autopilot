#!/usr/bin/env sh

set -eu

extension_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_dir="$extension_root/.github"
target_dir="$(pwd)/.github"

if [ ! -d "$source_dir" ]; then
  echo "Source .github directory not found: $source_dir" >&2
  exit 1
fi

required_files="
copilot-instructions.md
prompts/speckit.autopilot.run.prompt.md
prompts/speckit.autopilot.status.prompt.md
prompts/speckit.autopilot.validate.prompt.md
prompts/speckit.autopilot.verify.prompt.md
prompts/speckit.autopilot.constitution.prompt.md
prompts/speckit.autopilot.bootstrap-copilot.prompt.md
agents/speckit-autopilot.agent.md
agents/speckit-autopilot-bootstrap.agent.md
"

missing=0
for file in $required_files; do
  if [ ! -f "$source_dir/$file" ]; then
    echo "Missing Copilot source file: $source_dir/$file" >&2
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  exit 1
fi

mkdir -p "$target_dir/prompts" "$target_dir/agents"

for file in $required_files; do
  case "$file" in
    copilot-instructions.md)
      cp "$source_dir/$file" "$target_dir/$file"
      ;;
    prompts/*)
      cp "$source_dir/$file" "$target_dir/prompts/"
      ;;
    agents/*)
      cp "$source_dir/$file" "$target_dir/agents/"
      ;;
  esac
done

for generated_file in "$target_dir"/agents/speckit.autopilot.*.md; do
  if [ -e "$generated_file" ]; then
    rm "$generated_file"
  fi
done

echo "Copied Copilot files to $target_dir"
