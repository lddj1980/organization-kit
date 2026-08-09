#!/usr/bin/env bash
# Organization Kit - native OpenClaude skill installer

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
COMMANDS_SRC="$ROOT_DIR/commands"
TARGET_PATH="$(pwd)"
GLOBAL=false
DRY_RUN=false
FORCE=false

COMMANDS=(init discover spec package invoke review accept learn status health next evolve audit reconcile normalize)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET_PATH="$2"
      shift 2
      ;;
    --global)
      GLOBAL=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --force)
      FORCE=true
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

convert_to_openclaude_skill() {
  local src="$1"
  local skill_name="$2"
  python3 - "$src" "$skill_name" <<'PY'
from pathlib import Path
import re
import sys

src = Path(sys.argv[1])
skill_name = sys.argv[2]
raw = src.read_text(encoding="utf-8-sig")
description = f"Organization Kit command /{skill_name}"
body = raw

m = re.match(r"\A---\s*\r?\n(?P<frontmatter>.*?)\r?\n---\s*\r?\n(?P<body>.*)\Z", raw, re.S)
if m:
    frontmatter = m.group("frontmatter")
    body = m.group("body")
    d = re.search(r"(?m)^description:\s*(?P<description>.+?)\s*$", frontmatter)
    if d:
        description = d.group("description").strip()
        if len(description) >= 2 and description[0] == description[-1] and description[0] in {'\"', "'"}:
            description = description[1:-1]

safe = description.replace("\\", "\\\\").replace('"', '\\"')
print("---")
print(f"name: {skill_name}")
print(f'description: "{safe}"')
print('argument-hint: "[arguments]"')
print("user-invocable: true")
print("---")
print()
print(body, end="" if body.endswith("\n") else "\n")
PY
}

install_skill_set() {
  local skills_root="$1"

  for cmd in "${COMMANDS[@]}"; do
    local skill_name="org.$cmd"
    local src="$COMMANDS_SRC/$skill_name.md"
    local dst_dir="$skills_root/$skill_name"
    local dst="$dst_dir/SKILL.md"

    if [[ ! -f "$src" ]]; then
      echo "Canonical command not found: $src" >&2
      exit 1
    fi

    if [[ "$DRY_RUN" == true ]]; then
      echo "  [dry-run] would create native skill: $src -> $dst"
      continue
    fi

    if [[ -f "$dst" && "$FORCE" == false ]]; then
      echo "  [skip] $dst (use --force to overwrite)"
      continue
    fi

    mkdir -p "$dst_dir"
    convert_to_openclaude_skill "$src" "$skill_name" > "$dst"
    echo "  [ok] $dst"
  done
}

PROJECT_SKILLS_ROOT="$TARGET_PATH/.openclaude/skills"
echo "Installing OpenClaude project skills to $PROJECT_SKILLS_ROOT"
install_skill_set "$PROJECT_SKILLS_ROOT"

if [[ "$GLOBAL" == true ]]; then
  CONFIG_ROOT="${OPENCLAUDE_CONFIG_DIR:-$HOME/.openclaude}"
  GLOBAL_SKILLS_ROOT="$CONFIG_ROOT/skills"
  echo "Installing OpenClaude global skills to $GLOBAL_SKILLS_ROOT"
  install_skill_set "$GLOBAL_SKILLS_ROOT"
fi

echo
echo "OpenClaude native skills installed."
echo "Invoke with: /org.{command}"
