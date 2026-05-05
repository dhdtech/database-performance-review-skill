#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/dhdtech/database-performance-review-skill.git"
SKILL_NAME="dba-review"

# --- helpers ---
bold()  { printf '\033[1m%s\033[0m' "$1"; }
green() { printf '\033[32m%s\033[0m' "$1"; }
cyan()  { printf '\033[36m%s\033[0m' "$1"; }
dim()   { printf '\033[2m%s\033[0m' "$1"; }

big_red_banner() {
  printf '\n'
  printf '\033[41m\033[1m                                                                  \033[0m\n'
  printf '\033[41m\033[1m  !!  CLOSE AND REOPEN YOUR CLI TOOL BEFORE USING THE SKILL  !!  \033[0m\n'
  printf '\033[41m\033[1m                                                                  \033[0m\n'
  printf '\n'
  printf '%s\n' "$(dim "Claude Code needs a restart to discover new skill directories.")"
  printf '%s\n' "$(dim "Copilot CLI users: run /skills reload instead.")"
  printf '%s\n' "$(dim "Gemini CLI / Codex users: restart your terminal session.")"
  printf '\n'
}

# --- platform table ---
# 1=Claude Code  2=Copilot CLI  3=Gemini CLI  4=Codex
label_for() {
  case "$1" in
    1) printf 'Claude Code' ;;
    2) printf 'Copilot CLI' ;;
    3) printf 'Gemini CLI'  ;;
    4) printf 'Codex'       ;;
  esac
}
dir_for() {
  case "$1" in
    1) printf '%s/.claude/skills/%s'  "$HOME" "$SKILL_NAME" ;;
    2) printf '%s/.copilot/skills/%s' "$HOME" "$SKILL_NAME" ;;
    3) printf '%s/.gemini/skills/%s'  "$HOME" "$SKILL_NAME" ;;
    4) printf '%s/.codex/skills/%s'   "$HOME" "$SKILL_NAME" ;;
  esac
}

# --- welcome ---
clear
printf '\n'
printf '  %s — %s\n' "$(bold "Database Performance Review")" "$(dim "installer")"
printf '  %s\n' "$(dim "https://github.com/dhdtech/database-performance-review-skill")"
printf '\n'
printf '  %s\n' "$(dim "This script clones the skill into the correct directory for each")"
printf '  %s\n' "$(dim "platform you select. Pick one, pick a few, or grab them all.")"
printf '\n'

# --- show all platforms ---
printf '  %s\n' "$(bold "Which platform(s)?")"
printf '\n'
for p in 1 2 3 4; do
  printf '    %s  %s  %s\n' \
    "$(green "[$p]")" \
    "$(bold "$(label_for "$p")")" \
    "$(dim "→ $(dir_for "$p")")"
done
printf '    %s  %s\n' "$(green "[a]")" "$(bold "All of the above")"
printf '\n'

read -r -p '  Enter number(s) or "a": ' CHOICE < /dev/tty

# --- resolve selection ---
SELECTED=""
case "$CHOICE" in
  a|A|all|ALL)
    SELECTED="1 2 3 4"
    ;;
  *)
    for num in $CHOICE; do
      case "$num" in
        1|2|3|4) SELECTED="$SELECTED $num" ;;
      esac
    done
    ;;
esac

SELECTED="${SELECTED# }"

if [[ -z "$SELECTED" ]]; then
  printf '\n  %s\n' "$(bold "No valid platform selected. Exiting.")"
  exit 1
fi

# --- install ---
printf '\n'
for p in $SELECTED; do
  DEST="$(dir_for "$p")"
  LABEL="$(label_for "$p")"

  if [[ -d "$DEST" ]]; then
    printf '  %s  %s %s\n' "$(dim "⊘")" "$LABEL" "$(dim "already installed at $DEST")"
    continue
  fi

  mkdir -p "${DEST%/*}"
  printf '  %s  %s %s' "$(cyan "↓")" "$LABEL" "$(dim "installing...")"
  if git clone --quiet "$REPO" "$DEST" 2>/dev/null; then
    printf '\r  %s  %s %s\n' "$(green "✓")" "$LABEL" "$(dim "→ $DEST")"
  else
    printf '\r  %s  %s %s\n' "$(bold "✗")" "$LABEL" "$(dim "failed — check git is installed and you have disk space")"
  fi
done

big_red_banner
