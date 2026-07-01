#!/usr/bin/env bash
# Organization Kit — Integration Setup
# Usage: ./setup.sh --integration <agent> [--dry-run] [--force]
# Example: ./setup.sh --integration claude
# Example: ./setup.sh --integration claude copilot cursor

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMANDS_SRC="$SCRIPT_DIR/commands"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INTEGRATIONS=()
DRY_RUN=false
FORCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --integration|-i)
      shift
      while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
        INTEGRATIONS+=("$1")
        shift
      done
      ;;
    --dry-run) DRY_RUN=true; shift ;;
    --force)   FORCE=true;   shift ;;
    --list)
      echo "Available integrations:"
      echo "  claude    — Claude Code        (.claude/commands/)"
      echo "  copilot   — GitHub Copilot     (.github/prompts/)"
      echo "  cursor    — Cursor             (.cursor/rules/)"
      echo "  windsurf  — Windsurf           (.windsurf/rules/)"
      echo "  gemini    — Gemini CLI         (.gemini/commands/)"
      echo "  zed       — Zed               (.agents/skills/)"
      echo "  kimi      — Kimi Code          (.kimi-code/skills/)  [confirmed]"
      echo "  opencode  — opencode           (.opencode/commands/) [confirmed]"
      echo "  hermes    — Hermes             (~/.hermes/skills/)   [confirmed, GLOBAL]"
      echo "  agy       — Antigravity (agy)  (.agy/skills/)        [best-effort]"
      echo "  generic   — Generic            (.ai/commands/)"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ ${#INTEGRATIONS[@]} -eq 0 ]]; then
  echo "Usage: ./setup.sh --integration <agent> [--dry-run] [--force]"
  echo "Run ./setup.sh --list to see available integrations"
  exit 1
fi

COMMANDS=(init discover spec package invoke review accept learn status health next evolve audit reconcile normalize)

copy_command() {
  local src="$1"
  local dst="$2"
  local args_var="$3"  # variable name used for $ARGUMENTS in this agent

  if [[ "$DRY_RUN" == true ]]; then
    echo "  [dry-run] would copy: $src → $dst"
    return
  fi

  mkdir -p "$(dirname "$dst")"

  if [[ -f "$dst" && "$FORCE" == false ]]; then
    echo -e "  ${YELLOW}skip${NC} (exists): $dst  (use --force to overwrite)"
    return
  fi

  # Substitute $ARGUMENTS with the agent's variable if needed
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
      local dir=".claude/commands"
      for cmd in "${COMMANDS[@]}"; do
        copy_command \
          "$COMMANDS_SRC/org.$cmd.md" \
          "$dir/org.$cmd.md" \
          '$ARGUMENTS'
      done
      echo -e "\n  Invoke with: /org.{command}"
      ;;

    copilot)
      local dir=".github/prompts"
      for cmd in "${COMMANDS[@]}"; do
        # Copilot uses {input} instead of $ARGUMENTS and needs mode: agent in frontmatter
        local src="$COMMANDS_SRC/org.$cmd.md"
        local dst="$dir/org.$cmd.prompt.md"

        if [[ "$DRY_RUN" == true ]]; then
          echo "  [dry-run] would copy: $src → $dst"
          continue
        fi

        mkdir -p "$dir"
        if [[ -f "$dst" && "$FORCE" == false ]]; then
          echo -e "  ${YELLOW}skip${NC} (exists): $dst"
          continue
        fi

        # Read source, adjust frontmatter for Copilot
        local content
        content=$(cat "$src")
        # Add 'tools' to frontmatter and replace $ARGUMENTS
        echo "$content" \
          | sed 's/---/---\nmode: agent\ntools:\n  - codebase\n  - filesystem/' \
          | sed 's/\$ARGUMENTS/{input}/g' \
          | head -1000 > "$dst" 2>/dev/null || cp "$src" "$dst"

        echo -e "  ${GREEN}✓${NC} $dst"
      done
      echo -e "\n  Use via: VS Code Copilot Chat → 📎 → select prompt"
      ;;

    cursor)
      local dir=".cursor/rules"
      for cmd in "${COMMANDS[@]}"; do
        local src="$COMMANDS_SRC/org.$cmd.md"
        local dst="$dir/org.$cmd.mdc"

        if [[ "$DRY_RUN" == true ]]; then
          echo "  [dry-run] would copy: $src → $dst"
          continue
        fi

        mkdir -p "$dir"
        if [[ -f "$dst" && "$FORCE" == false ]]; then
          echo -e "  ${YELLOW}skip${NC} (exists): $dst"
          continue
        fi

        # Add alwaysApply: false to frontmatter
        sed 's/---/---\nalwaysApply: false/' "$src" > "$dst" 2>/dev/null || cp "$src" "$dst"
        echo -e "  ${GREEN}✓${NC} $dst"
      done
      echo -e "\n  Invoke with: /org.{command}"
      ;;

    windsurf)
      local dir=".windsurf/rules"
      for cmd in "${COMMANDS[@]}"; do
        local src="$COMMANDS_SRC/org.$cmd.md"
        local dst="$dir/org.$cmd.md"

        if [[ "$DRY_RUN" == true ]]; then
          echo "  [dry-run] would copy: $src → $dst"
          continue
        fi

        mkdir -p "$dir"
        if [[ -f "$dst" && "$FORCE" == false ]]; then
          echo -e "  ${YELLOW}skip${NC} (exists): $dst"
          continue
        fi

        sed 's/---/---\ntrigger: explicit/' "$src" > "$dst" 2>/dev/null || cp "$src" "$dst"
        echo -e "  ${GREEN}✓${NC} $dst"
      done
      echo -e "\n  Invoke with: /org.{command}"
      ;;

    gemini)
      local dir=".gemini/commands"
      for cmd in "${COMMANDS[@]}"; do
        copy_command \
          "$COMMANDS_SRC/org.$cmd.md" \
          "$dir/org.$cmd.md" \
          '$ARGUMENTS'
      done
      echo -e "\n  Invoke with: /org.{command}"
      ;;

    zed)
      local dir=".agents/skills"
      for cmd in "${COMMANDS[@]}"; do
        copy_command \
          "$COMMANDS_SRC/org.$cmd.md" \
          "$dir/org.$cmd.md" \
          '$ARGUMENTS'
      done
      echo -e "\n  Invoke with: /org.{command}"
      ;;

    kimi)
      local dir=".kimi-code/skills"
      for cmd in "${COMMANDS[@]}"; do
        copy_command \
          "$COMMANDS_SRC/org.$cmd.md" \
          "$dir/org.$cmd.md" \
          '$ARGUMENTS'
      done
      echo -e "\n  Invoke with: /org.{command}"
      ;;

    opencode)
      local dir=".opencode/commands"
      for cmd in "${COMMANDS[@]}"; do
        local src="$COMMANDS_SRC/org.$cmd.md"
        local dst="$dir/org.$cmd.md"

        if [[ "$DRY_RUN" == true ]]; then
          echo "  [dry-run] would copy: $src → $dst"
          continue
        fi

        mkdir -p "$dir"
        if [[ -f "$dst" && "$FORCE" == false ]]; then
          echo -e "  ${YELLOW}skip${NC} (exists): $dst"
          continue
        fi

        # Add agent: build to frontmatter (opencode-specific)
        sed 's/---/---\nagent: build/' "$src" > "$dst" 2>/dev/null || cp "$src" "$dst"
        echo -e "  ${GREEN}✓${NC} $dst"
      done
      echo -e "\n  Invoke with: /org.{command} in the opencode TUI"
      echo -e "  Note: \$ARGUMENTS is natively supported by opencode"
      ;;

    hermes)
      # Hermes installs GLOBALLY into ~/.hermes/skills/
      local dir="${HOME}/.hermes/skills"
      echo -e "  ${YELLOW}Note: Hermes installs GLOBALLY to ${dir}/${NC}"
      echo -e "  Skills will be available in ALL your Hermes sessions.\n"
      for cmd in "${COMMANDS[@]}"; do
        copy_command \
          "$COMMANDS_SRC/org.$cmd.md" \
          "$dir/org.$cmd.md" \
          '$ARGUMENTS'
      done
      echo -e "\n  Invoke with: /org.{command} in any Hermes session"
      ;;

    agy)
      local dir=".agy/skills"
      echo -e "  ${YELLOW}Note: agy path (.agy/skills/) is best-effort — verify with your agy version.${NC}\n"
      for cmd in "${COMMANDS[@]}"; do
        copy_command \
          "$COMMANDS_SRC/org.$cmd.md" \
          "$dir/org.$cmd.md" \
          '$ARGUMENTS'
      done
      echo -e "\n  Invoke with: /org.{command}"
      echo -e "  If commands don't appear, check integrations/agy/integration.yml for path correction."
      ;;

    generic)
      local dir=".ai/commands"
      for cmd in "${COMMANDS[@]}"; do
        copy_command \
          "$COMMANDS_SRC/org.$cmd.md" \
          "$dir/org.$cmd.md" \
          '$ARGUMENTS'
      done
      echo -e "\n  Usage: paste the content of .ai/commands/org.{command}.md into your agent session"
      ;;

    *)
      echo -e "  ${RED}Unknown integration: $agent${NC}"
      echo "  Run ./setup.sh --list to see available integrations"
      return 1
      ;;
  esac
}

# Ensure .org-kit/active state directory exists
mkdir -p ".org-kit"
if [[ ! -f ".org-kit/active" ]]; then
  echo "# Active organization (set by /org.init or manually)" > ".org-kit/active"
  echo -e "${GREEN}✓${NC} Created .org-kit/active (empty — run /org.init to set)"
fi

# Install each requested integration
for integration in "${INTEGRATIONS[@]}"; do
  install_integration "$integration"
done

# Copy framework scripts so commands can run from this directory
SCRIPTS_SRC="$SCRIPT_DIR/scripts"
SCRIPTS_DST="./scripts"
if [[ "$DRY_RUN" == true ]]; then
  echo "  [dry-run] would copy: $SCRIPTS_SRC → $SCRIPTS_DST"
else
  mkdir -p "$SCRIPTS_DST"
  cp "$SCRIPTS_SRC"/*.ps1 "$SCRIPTS_DST"/ 2>/dev/null || true
  cp "$SCRIPTS_SRC"/*.psm1 "$SCRIPTS_DST"/ 2>/dev/null || true
  echo -e "${GREEN}✓${NC} Copied framework scripts to $SCRIPTS_DST"
fi

echo -e "\n${GREEN}Setup complete.${NC}"
if [[ "$DRY_RUN" == true ]]; then
  echo "(dry run — no files were modified)"
fi
