#!/usr/bin/env bash
# Validates every skill in a plugin and packages each one as a ZIP that
# claude.ai accepts (the skill folder is the root of the archive).
#
# Usage: scripts/package-skills.sh <plugin-dir> <out-dir>

set -euo pipefail

fail() {
  echo "error: $1" >&2
  exit 1
}

read_frontmatter_name() {
  local skill_file="$1"
  awk '
    NR == 1 && $0 == "---" { inside = 1; next }
    inside && $0 == "---" { exit }
    inside && /^name:/ { sub(/^name:[[:space:]]*/, ""); print; exit }
  ' "$skill_file"
}

validate_skill() {
  local skill_dir="$1"
  local folder_name
  folder_name="$(basename "$skill_dir")"
  local skill_file="$skill_dir/SKILL.md"

  if [ ! -f "$skill_file" ]; then
    fail "$skill_dir has no SKILL.md"
  fi

  local declared_name
  declared_name="$(read_frontmatter_name "$skill_file")"

  if [ -z "$declared_name" ]; then
    fail "$skill_file has no name in its frontmatter"
  fi

  if [ "$declared_name" != "$folder_name" ]; then
    fail "$skill_file declares name '$declared_name' but its folder is '$folder_name'"
  fi

  if ! grep -q '^description:' "$skill_file"; then
    fail "$skill_file has no description in its frontmatter"
  fi
}

package_skill() {
  local skill_dir="$1"
  local out_dir="$2"
  local folder_name
  folder_name="$(basename "$skill_dir")"
  local parent_dir
  parent_dir="$(dirname "$skill_dir")"

  rm -f "$out_dir/$folder_name.zip"
  (cd "$parent_dir" && zip -rq "$out_dir/$folder_name.zip" "$folder_name" -x '*.DS_Store')
  echo "packaged $out_dir/$folder_name.zip"
}

main() {
  local plugin_dir="${1:-}"
  local out_dir="${2:-}"

  if [ -z "$plugin_dir" ] || [ -z "$out_dir" ]; then
    fail "usage: package-skills.sh <plugin-dir> <out-dir>"
  fi

  if [ ! -d "$plugin_dir/skills" ]; then
    fail "$plugin_dir has no skills folder"
  fi

  mkdir -p "$out_dir"
  out_dir="$(cd "$out_dir" && pwd)"

  local skill_dir
  for skill_dir in "$plugin_dir"/skills/*/; do
    skill_dir="${skill_dir%/}"
    validate_skill "$skill_dir"
    package_skill "$skill_dir" "$out_dir"
  done
}

main "$@"
