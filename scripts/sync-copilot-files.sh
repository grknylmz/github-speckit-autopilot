#!/usr/bin/env sh

set -eu

extension_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_dir="$extension_root/.github"
target_dir="$(pwd)/.github"

if [ ! -d "$source_dir" ]; then
  echo "Source .github directory not found: $source_dir" >&2
  exit 1
fi

mkdir -p "$target_dir/prompts" "$target_dir/agents"

cp "$source_dir/copilot-instructions.md" "$target_dir/copilot-instructions.md"
cp "$source_dir/prompts/"*.prompt.md "$target_dir/prompts/"
cp "$source_dir/agents/"*.agent.md "$target_dir/agents/"

echo "Copied Copilot files to $target_dir"