#!/usr/bin/env sh
# Claude Code status line — POSIX sh, no jq / python / node.
# Works on macOS, Linux, and Windows (Git Bash).
# Shows: <used>/<window> <pct>% | model·effort | 5h usage | wk usage | git branch + status | dir

input=$(cat)
# single-line copy so brace/region extraction works on pretty-printed payloads too
flat=$(printf '%s' "$input" | tr '\r\n' '  ')

# --- minimal JSON readers, whitespace-tolerant ---
jstr() {
  printf '%s' "$input" \
    | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -n1 \
    | sed 's/.*:[[:space:]]*"\(.*\)"/\1/'
}
# scoped number reader — first numeric value of key $2 within blob $1
jnum_in() {
  printf '%s' "$1" \
    | grep -o "\"$2\"[[:space:]]*:[[:space:]]*[0-9.]*" | head -n1 \
    | grep -o '[0-9.]*$'
}

MODEL=$(jstr display_name);            [ -z "$MODEL" ] && MODEL="Claude"
EFFORT=$(jstr level)
DIR=$(jstr current_dir)

# --- context: read from the slice BEFORE rate_limits so used_percentage can't
#     collide with the rate-limit windows' own used_percentage fields ---
PRE=$(printf '%s' "$flat" | sed 's/"rate_limits".*//')
PCT=$(jnum_in "$PRE" used_percentage); PCT=${PCT%.*}; [ -z "$PCT" ] && PCT=0
USED=$(jnum_in "$PRE" total_input_tokens);  [ -z "$USED" ] && USED=0
WIN=$(jnum_in "$PRE" context_window_size);  [ -z "$WIN" ] && WIN=200000

# --- rate limits: 5-hour session window + 7-day (weekly) window.
#     Present only for Claude.ai Pro/Max after the first API response; each
#     window object has no nested braces, so [^}]* captures it exactly. ---
FH=$(printf '%s' "$flat" | sed -n 's/.*"five_hour"[[:space:]]*:[[:space:]]*{\([^}]*\)}.*/\1/p')
SD=$(printf '%s' "$flat" | sed -n 's/.*"seven_day"[[:space:]]*:[[:space:]]*{\([^}]*\)}.*/\1/p')
FH_PCT=$(jnum_in "$FH" used_percentage); FH_PCT=${FH_PCT%.*}
FH_RESET=$(jnum_in "$FH" resets_at);     FH_RESET=${FH_RESET%.*}
SD_PCT=$(jnum_in "$SD" used_percentage); SD_PCT=${SD_PCT%.*}
SD_RESET=$(jnum_in "$SD" resets_at);     SD_RESET=${SD_RESET%.*}

# --- format token counts like 118k ---
fmtk() { if [ "$1" -ge 1000 ]; then echo "$(( ($1 + 500) / 1000 ))k"; else echo "$1"; fi; }
USED_H=$(fmtk "$USED")
WIN_H=$(fmtk "$WIN")

# --- reset countdown: epoch -> compact "2h13m" / "43m" / "3d4h" ---
NOW=$(date +%s)
fmt_eta() {
  rem=$(( $1 - NOW )); [ "$rem" -lt 0 ] && rem=0
  d=$(( rem / 86400 )); h=$(( (rem % 86400) / 3600 )); m=$(( (rem % 3600) / 60 ))
  if   [ "$d" -gt 0 ]; then printf '%dd%dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then printf '%dh%dm' "$h" "$m"
  else printf '%dm' "$m"; fi
}

# --- colors (real ESC bytes) ---
R=$(printf '\033[0m');   DIM=$(printf '\033[2m')
GREEN=$(printf '\033[32m'); YEL=$(printf '\033[33m')
RED=$(printf '\033[31m');   CYAN=$(printf '\033[36m')
if   [ "$PCT" -ge 60 ]; then CXC=$RED
elif [ "$PCT" -ge 30 ]; then CXC=$YEL
else                         CXC=$GREEN; fi
# usage windows escalate as lockout nears: <50 green, 50-79 yellow, >=80 red
usage_color() {
  if   [ "${1:-0}" -ge 80 ]; then printf '%s' "$RED"
  elif [ "${1:-0}" -ge 50 ]; then printf '%s' "$YEL"
  else printf '%s' "$GREEN"; fi
}

# --- model + effort ---
SEG_MODEL="${CYAN}${MODEL}${R}"
[ -n "$EFFORT" ] && SEG_MODEL="${SEG_MODEL}${DIM}·${EFFORT}${R}"

# --- context ---
SEG_CTX="${CXC}${USED_H}/${WIN_H} ${PCT}%${R}"

# --- usage windows (skipped when rate_limits absent, e.g. before first response) ---
SEG_5H=""
if [ -n "$FH_PCT" ]; then
  C=$(usage_color "$FH_PCT"); ETA=""; [ -n "$FH_RESET" ] && ETA=" $(fmt_eta "$FH_RESET")"
  SEG_5H="${C}5h ${FH_PCT}%${R}${DIM}${ETA}${R}"
fi
SEG_WK=""
if [ -n "$SD_PCT" ]; then
  C=$(usage_color "$SD_PCT"); ETA=""; [ -n "$SD_RESET" ] && ETA=" $(fmt_eta "$SD_RESET")"
  SEG_WK="${C}wk ${SD_PCT}%${R}${DIM}${ETA}${R}"
fi

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

# --- assemble: context · model · 5h · wk · git · dir ---
SEP="${DIM} │ ${R}"
OUT="$SEG_CTX$SEP$SEG_MODEL"
[ -n "$SEG_5H" ]  && OUT="$OUT$SEP$SEG_5H"
[ -n "$SEG_WK" ]  && OUT="$OUT$SEP$SEG_WK"
[ -n "$SEG_GIT" ] && OUT="$OUT$SEP$SEG_GIT"
[ -n "$SEG_DIR" ] && OUT="$OUT$SEP$SEG_DIR"
printf '%s\n' "$OUT"
