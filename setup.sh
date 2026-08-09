#!/usr/bin/env bash
# Organization Kit — Integration Setup
# Usage: ./setup.sh --integration <agent> [--dry-run] [--force] [--global]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMANDS_SRC="$SCRIPT_DIR/commands"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INTEGRATIONS=()
DRY_RUN=false
FORCE=false
GLOBAL=false
TARGET_PATH="$(pwd)"

while [[ $# -gt 0 ]]; do
  case $1 in
    --integration|-i)
      shift
      while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
        INTEGRATIONS+=("$1")
        shift
      done
      ;;
    --target)
      TARGET_PATH="$2"
      shift 2
      ;;
    --dry-run) DRY_RUN=true; shift ;;
    --force)   FORCE=true;   shift ;;
    --global)  GLOBAL=true;  shift ;;
    --list)
      echo "Available integrations:"
      echo "  claude     — Claude Code        (.claude/commands/)"
      echo "  copilot    — GitHub Copilot     (.github/prompts/)"
      echo "  cursor     — Cursor             (.cursor/rules/)"
      echo "  windsurf   — Windsurf           (.windsurf/rules/)"
      echo "  gemini     — Gemini CLI         (.gemini/commands/)"
      echo "  zed        — Zed                (.agents/skills/)"
      echo "  kimi       — Kimi Code          (.kimi-code/skills/)  [confirmed]"
      echo "  opencode   — opencode           (.opencode/commands/) [confirmed]"
      echo "  openclaude — OpenClaude         (.openclaude/skills/<command>/SKILL.md) [native]"
      echo "               --global → ~/.openclaude/skills/ (or OPENCLAUDE_CONFIG_DIR/skills)"
      echo "  hermes     — Hermes             (~/.hermes/skills/)   [confirmed, GLOBAL]"
      echo "  agy        — Antigravity (agy)  (.agy/skills/)        [best-effort]"
      echo "  generic    — Generic            (.ai/commands/)"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ ${#INTEGRATIONS[@]} -eq 0 ]]; then
  echo "Usage: ./setup.sh --integration <agent> [--dry-run] [--force] [--target <path>]"
  echo "Run ./setup.sh --list to see available integrations"
  exit 1
fi

COMMANDS=(init discover spec package invoke review accept learn status health next evolve audit reconcile normalize)

resolve_destination() {
  local rel="$1"
  printf '%s/%s' "$TARGET_PATH" "$rel"
}

copy_command() {
  local src="$1"
  local dst="$2"
  local args_var="$3"

  if [[ "$DRY_RUN" == true ]]; then
    echo "  [dry-run] would copy: $src → $dst"
    return
  fi

  mkdir -p "$(dirname "$dst")"

  if [[ -f "$dst" && "$FORCE" == false ]]; then
    echo -e "  ${YELLOW}skip${NC} (exists): $dst  (use --force to overwrite)"
    return
  fi

  if [[ "$args_var" != '$ARGUMENTS' ]]; then
    sed "s/\\\$ARGUMENTS/$args_var/g" "$src" > "$dst"
  else
    cp "$src" "$dst"
  fi

  echo -e "  ${GREEN}✓${NC} $dst"
}

install_integration() {
  local agent="$1"
  echo -e "\n${BLUE}Installing: $agent${NC}"

  case $agent in
    claude)
      local dir
      dir="$(resolve_destination '.claude/commands')"
      for cmd in "${COMMANDS[@]}"; do
        copy_command "$COMMANDS_SRC/org.$cmd.md" "$dir/org.$cmd.md" '$ARGUMENTS'
      done
      echo -e "\n  Invoke with: /org.{command}"
      ;;

    copilot)
      local dir
      dir="$(resolve_destination '.github/prompts')"
      for cmd in "${COMMANDS[@]}"; do
        local src="$COMMANDS_SRC/org.$cmd.md"
        local dst="$dir/org.$cmd.prompt.md"
        if [[ "$DRY_RUN" == true ]]; then echo "  [dry-run] would copy: $src → $dst"; continue; fi
        mkdir -p "$dir"
        if [[ -f "$dst" && "$FORCE" == false ]]; then echo -e "  ${YELLOW}skip${NC} (exists): $dst"; continue; fi
        sed '0,/---/s//---\nmode: agent\ntools:\n  - codebase\n  - filesystem/' "$src" | sed 's/\$ARGUMENTS/{input}/g' > "$dst"
        echo -e "  ${GREEN}✓${NC} $dst"
      done
      ;;

    cursor)
      local dir
      dir="$(resolve_destination '.cursor/rules')"
      for cmd in "${COMMANDS[@]}"; do
        local src="$COMMANDS_SRC/org.$cmd.md"
        local dst="$dir/org.$cmd.mdc"
        if [[ "$DRY_RUN" == true ]]; then echo "  [dry-run] would copy: $src → $dst"; continue; fi
        mkdir -p "$dir"
        if [[ -f "$dst" && "$FORCE" == false ]]; then echo -e "  ${YELLOW}skip${NC} (exists): $dst"; continue; fi
        sed '0,/---/s//---\nalwaysApply: false/' "$src" > "$dst"
        echo -e "  ${GREEN}✓${NC} $dst"
      done
      ;;

    windsurf)
      local dir
      dir="$(resolve_destination '.windsurf/rules')"
      for cmd in "${COMMANDS[@]}"; do
        local src="$COMMANDS_SRC/org.$cmd.md"
        local dst="$dir/org.$cmd.md"
        if [[ "$DRY_RUN" == true ]]; then echo "  [dry-run] would copy: $src → $dst"; continue; fi
        mkdir -p "$dir"
        if [[ -f "$dst" && "$FORCE" == false ]]; then echo -e "  ${YELLOW}skip${NC} (exists): $dst"; continue; fi
        sed '0,/---/s//---\ntrigger: explicit/' "$src" > "$dst"
        echo -e "  ${GREEN}✓${NC} $dst"
      done
      ;;

    gemini)
      local dir
      dir="$(resolve_destination '.gemini/commands')"
      for cmd in "${COMMANDS[@]}"; do copy_command "$COMMANDS_SRC/org.$cmd.md" "$dir/org.$cmd.md" '$ARGUMENTS'; done
      ;;

    zed)
      local dir
      dir="$(resolve_destination '.agents/skills')"
      for cmd in "${COMMANDS[@]}"; do copy_command "$COMMANDS_SRC/org.$cmd.md" "$dir/org.$cmd.md" '$ARGUMENTS'; done
      ;;

    kimi)
      local dir
      dir="$(resolve_destination '.kimi-code/skills')"
      for cmd in "${COMMANDS[@]}"; do copy_command "$COMMANDS_SRC/org.$cmd.md" "$dir/org.$cmd.md" '$ARGUMENTS'; done
      ;;

    opencode)
      local dir
      dir="$(resolve_destination '.opencode/commands')"
      for cmd in "${COMMANDS[@]}"; do
        local src="$COMMANDS_SRC/org.$cmd.md"
        local dst="$dir/org.$cmd.md"
        if [[ "$DRY_RUN" == true ]]; then echo "  [dry-run] would copy: $src → $dst"; continue; fi
        mkdir -p "$dir"
        if [[ -f "$dst" && "$FORCE" == false ]]; then echo -e "  ${YELLOW}skip${NC} (exists): $dst"; continue; fi
        sed '0,/---/s//---\nagent: build/' "$src" > "$dst"
        echo -e "  ${GREEN}✓${NC} $dst"
      done
      ;;

    openclaude)
      local installer="$SCRIPT_DIR/adapters/integrations/openclaude/install.sh"
      if [[ ! -f "$installer" ]]; then echo "OpenClaude native adapter not found: $installer" >&2; return 1; fi
      local args=(--target "$TARGET_PATH")
      [[ "$DRY_RUN" == true ]] && args+=(--dry-run)
      [[ "$FORCE" == true ]] && args+=(--force)
      [[ "$GLOBAL" == true ]] && args+=(--global)
      bash "$installer" "${args[@]}"
      ;;

    hermes)
      local dir="${HOME}/.hermes/skills"
      for cmd in "${COMMANDS[@]}"; do copy_command "$COMMANDS_SRC/org.$cmd.md" "$dir/org.$cmd.md" '$ARGUMENTS'; done
      ;;

    agy)
      local dir
      dir="$(resolve_destination '.agy/skills')"
      for cmd in "${COMMANDS[@]}"; do copy_command "$COMMANDS_SRC/org.$cmd.md" "$dir/org.$cmd.md" '$ARGUMENTS'; done
      ;;

    generic)
      local dir
      dir="$(resolve_destination '.ai/commands')"
      for cmd in "${COMMANDS[@]}"; do copy_command "$COMMANDS_SRC/org.$cmd.md" "$dir/org.$cmd.md" '$ARGUMENTS'; done
      ;;

    *)
      echo -e "  ${RED}Unknown integration: $agent${NC}"
      return 1
      ;;
  esac
}

mkdir -p "$TARGET_PATH/.org-kit"
if [[ ! -f "$TARGET_PATH/.org-kit/active" ]]; then
  echo "# Active organization (set by /org.init or manually)" > "$TARGET_PATH/.org-kit/active"
  echo -e "${GREEN}✓${NC} Created $TARGET_PATH/.org-kit/active"
fi

for integration in "${INTEGRATIONS[@]}"; do install_integration "$integration"; done

SCRIPTS_SRC="$SCRIPT_DIR/scripts"
SCRIPTS_DST="$TARGET_PATH/scripts"
if [[ "$DRY_RUN" == true ]]; then
  echo "  [dry-run] would copy: $SCRIPTS_SRC → $SCRIPTS_DST"
else
  mkdir -p "$SCRIPTS_DST"
  cp "$SCRIPTS_SRC"/*.ps1 "$SCRIPTS_DST"/ 2>/dev/null || true
  cp "$SCRIPTS_SRC"/*.psm1 "$SCRIPTS_DST"/ 2>/dev/null || true
  echo -e "${GREEN}✓${NC} Copied framework scripts to $SCRIPTS_DST"
fi

echo -e "\n${GREEN}Setup complete.${NC}"
if [[ "$DRY_RUN" == true ]]; then echo "(dry run — no files were modified)"; fi
