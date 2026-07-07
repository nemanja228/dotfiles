#!/usr/bin/env sh
# Stopgap: one-way restore of this repo's dot_claude/ files into ~/.claude.
# Reverse of sync-claude.sh. Temporary — delete once chezmoi manages these dotfiles.
#
# Copies only files present under dot_claude/. Never deletes anything in ~/.claude:
# files that exist locally but not in the repo are left untouched. One-way only —
# never reads back from ~/.claude.
set -eu

SRC="$(cd "$(dirname "$0")" && pwd)/dot_claude"
DEST="$HOME/.claude"

# Top-level customization files.
FILES="CLAUDE.md engineering-practices.md statusline.sh settings.json keybindings.json"

# User-owned directories to walk. Each file inside is copied to the mirrored path;
# extra files already at the destination (not present in the repo) are preserved.
DIRS="hooks skills agents commands"

mkdir -p "$DEST"

for f in $FILES; do
  if [ -f "$SRC/$f" ]; then
    cp "$SRC/$f" "$DEST/$f"
    echo "restored  $f"
  else
    echo "skip      $f (absent)" >&2
  fi
done

for d in $DIRS; do
  if [ ! -d "$SRC/$d" ]; then
    echo "skip      $d/ (absent)" >&2
    continue
  fi
  count=0
  # -print0/xargs would be nicer, but a find | while read loop is portable and
  # good enough given paths under dot_claude/ don't contain newlines.
  find "$SRC/$d" -type f | while IFS= read -r src_path; do
    rel="${src_path#"$SRC"/}"
    dest_path="$DEST/$rel"
    mkdir -p "$(dirname "$dest_path")"
    cp "$src_path" "$dest_path"
    echo "restored  $rel"
  done
  count=$(find "$SRC/$d" -type f | wc -l)
  if [ "$count" -eq 0 ]; then
    echo "skip      $d/ (empty)" >&2
  fi
done

echo "Done. Review ~/.claude to confirm."
