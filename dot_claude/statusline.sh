#!/usr/bin/env sh
# Claude Code status line — POSIX sh, no jq / python / node.
# Works on macOS, Linux, and Windows (Git Bash).
# Shows: model·effort | <used>/<window> <pct>% | git branch + status | dir

input=$(cat)

# --- minimal JSON readers (string + number), whitespace-tolerant ---
jstr() {
  printf '%s' "$input" \
    | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -n1 \
    | sed 's/.*:[[:space:]]*"\(.*\)"/\1/'
}
jnum() {
  printf '%s' "$input" \
    | grep -o "\"$1\"[[:space:]]*:[[:space:]]*[0-9.]*" | head -n1 \
    | grep -o '[0-9.]*$'
}

MODEL=$(jstr display_name);            [ -z "$MODEL" ] && MODEL="Claude"
EFFORT=$(jstr level)
PCT=$(jnum used_percentage); PCT=${PCT%.*}; [ -z "$PCT" ] && PCT=0
USED=$(jnum total_input_tokens);       [ -z "$USED" ] && USED=0
WIN=$(jnum context_window_size);       [ -z "$WIN" ] && WIN=200000
DIR=$(jstr current_dir)

# --- format token counts like 118k ---
fmtk() { if [ "$1" -ge 1000 ]; then echo "$(( ($1 + 500) / 1000 ))k"; else echo "$1"; fi; }
USED_H=$(fmtk "$USED")
WIN_H=$(fmtk "$WIN")

# --- colors (real ESC bytes) ---
R=$(printf '\033[0m');   DIM=$(printf '\033[2m')
GREEN=$(printf '\033[32m'); YEL=$(printf '\033[33m')
RED=$(printf '\033[31m');   CYAN=$(printf '\033[36m')
if   [ "$PCT" -ge 60 ]; then CXC=$RED
elif [ "$PCT" -ge 30 ]; then CXC=$YEL
else                         CXC=$GREEN; fi

# --- model + effort ---
SEG_MODEL="${CYAN}${MODEL}${R}"
[ -n "$EFFORT" ] && SEG_MODEL="${SEG_MODEL}${DIM}·${EFFORT}${R}"

# --- context ---
SEG_CTX="${CXC}${USED_H}/${WIN_H} ${PCT}%${R}"

# --- git (direct calls; silent if git missing or not a repo) ---
SEG_GIT=""
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BR=$(git branch --show-current 2>/dev/null)
  [ -z "$BR" ] && BR=$(git rev-parse --short HEAD 2>/dev/null)

  ST=$(git status --porcelain 2>/dev/null)
  STAGED=$(printf '%s\n'   "$ST" | grep -c '^[MADRC]')
  MODIFIED=$(printf '%s\n' "$ST" | grep -c '^.[MD]')
  UNTRACKED=$(printf '%s\n' "$ST" | grep -c '^??')

  AB=$(git rev-list --left-right --count '@{u}...HEAD' 2>/dev/null)
  BEHIND=$(printf '%s' "$AB" | awk '{print $1}')
  AHEAD=$(printf '%s'  "$AB" | awk '{print $2}')

  DIRTY=""
  [ "${STAGED:-0}" -gt 0 ]    && DIRTY="${DIRTY} ${GREEN}+${STAGED}${R}"
  [ "${MODIFIED:-0}" -gt 0 ]  && DIRTY="${DIRTY} ${YEL}~${MODIFIED}${R}"
  [ "${UNTRACKED:-0}" -gt 0 ] && DIRTY="${DIRTY} ${DIM}?${UNTRACKED}${R}"
  SYNC=""
  [ -n "$AHEAD" ]  && [ "$AHEAD"  -gt 0 ] && SYNC="${SYNC} ${CYAN}↑${AHEAD}${R}"
  [ -n "$BEHIND" ] && [ "$BEHIND" -gt 0 ] && SYNC="${SYNC} ${RED}↓${BEHIND}${R}"

  SEG_GIT="${R}⎇ ${BR}${SYNC}${DIRTY}"
fi

# --- directory basename (handles / and \) ---
SEG_DIR=""
[ -n "$DIR" ] && SEG_DIR="${DIM}${DIR##*[/\\]}${R}"

# --- assemble ---
SEP="${DIM} │ ${R}"
OUT="$SEG_MODEL$SEP$SEG_CTX"
[ -n "$SEG_GIT" ] && OUT="$OUT$SEP$SEG_GIT"
[ -n "$SEG_DIR" ] && OUT="$OUT$SEP$SEG_DIR"
printf '%s\n' "$OUT"
