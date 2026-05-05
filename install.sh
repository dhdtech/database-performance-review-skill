#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/dhdtech/dba-review.git"
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
  printf '%s\n' "$(dim "Claude Code / OpenCode need a restart to discover new skill directories.")"
  printf '%s\n' "$(dim "Copilot CLI users: run /skills reload instead.")"
  printf '%s\n' "$(dim "Gemini CLI / Codex users: restart your terminal session.")"
  printf '\n'
}

# --- platform table ---
# 1=Claude Code  2=Copilot CLI  3=Gemini CLI  4=Codex  5=OpenCode
label_for() {
  case "$1" in
    1) printf 'Claude Code' ;;
    2) printf 'Copilot CLI' ;;
    3) printf 'Gemini CLI'  ;;
    4) printf 'Codex'       ;;
    5) printf 'OpenCode'    ;;
  esac
}
dir_for() {
  case "$1" in
    1) printf '%s/.claude/skills/%s'     "$HOME" "$SKILL_NAME" ;;
    2) printf '%s/.copilot/skills/%s'    "$HOME" "$SKILL_NAME" ;;
    3) printf '%s/.gemini/skills/%s'     "$HOME" "$SKILL_NAME" ;;
    4) printf '%s/.codex/skills/%s'      "$HOME" "$SKILL_NAME" ;;
    5) printf '%s/.config/opencode/skills/%s' "$HOME" "$SKILL_NAME" ;;
  esac
}

# --- welcome ---
clear
printf '\n'
printf '  %s — %s\n' "$(bold "Database Performance Review")" "$(dim "installer")"
printf '  %s\n' "$(dim "https://github.com/dhdtech/dba-review")"
printf '\n'
printf '  %s\n' "$(dim "This script installs OR updates the skill to the latest version.")"
printf '  %s\n' "$(dim "Already installed? Run it again — it will pull the latest changes.")"
printf '  %s\n' "$(dim "You'll be asked y/n for each platform — no numbers, no typos.")"
printf '\n'

# --- ask each platform ---
printf '  %s\n' "$(bold "Install for which platforms?")"
printf '  %s\n\n' "$(dim "Answer y/n for each — press Enter to accept the default.")"
SELECTED=""
for p in 1 2 3 4 5; do
  DEST="$(dir_for "$p")"
  if [[ -d "$DEST" ]]; then
    HINT="$(dim "(already installed — will replace)")"
  else
    HINT="$(dim "→ $DEST")"
  fi
  while true; do
    printf '    %s  %s\n      %s' \
      "$(bold "$(label_for "$p")")" \
      "$HINT" \
      "$(dim "Install? [Y/n]: ")"
    read -r ANS < /dev/tty
    case "${ANS:-y}" in
      y|Y|yes|YES) SELECTED="$SELECTED $p"; break ;;
      n|N|no|NO) break ;;
      *) printf '      %s\n' "$(dim "Please answer y or n")" ;;
    esac
  done
done

SELECTED="${SELECTED# }"

if [[ -z "$SELECTED" ]]; then
  printf '\n  %s\n' "$(bold "No platforms selected. Exiting.")"
  exit 0
fi

printf '\n  %s %s\n\n' "$(green "✓")" "$(bold "Installing for:") $(for p in $SELECTED; do printf '%s  ' "$(label_for "$p")"; done)"

# --- install ---
printf '\n'
for p in $SELECTED; do
  DEST="$(dir_for "$p")"
  LABEL="$(label_for "$p")"

  if [[ -d "$DEST" ]]; then
    printf '  %s  %s %s' "$(cyan "↓")" "$LABEL" "$(dim "replacing...")"
    rm -rf "$DEST"
  else
    printf '  %s  %s %s' "$(cyan "↓")" "$LABEL" "$(dim "installing...")"
  fi

  mkdir -p "$DEST"
  if git clone --quiet "$REPO" "$DEST" 2>/dev/null; then
    rm -rf "$DEST/.git"
    printf '\r  %s  %s %s\n' "$(green "✓")" "$LABEL" "$(dim "→ $DEST")"
  else
    printf '\r  %s  %s %s\n' "$(bold "✗")" "$LABEL" "$(dim "failed — check git is installed and you have disk space")"
  fi
done

big_red_banner
