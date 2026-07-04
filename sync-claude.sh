#!/usr/bin/env sh
# Stopgap: one-way sync of customized ~/.claude files into this repo's dot_claude/.
# Temporary — delete once chezmoi manages these dotfiles.
#
# Copies only an explicit whitelist (FILES + DIRS) so new secrets/caches in ~/.claude
# can never leak into the repo. One-way only: never writes back to ~/.claude, and the
# rm -rf below only ever targets paths under the script-owned dot_claude/.
set -eu

SRC="$HOME/.claude"
DEST="$(cd "$(dirname "$0")" && pwd)/dot_claude"

# Top-level customization files.
FILES="CLAUDE.md engineering-practices.md statusline.sh settings.json keybindings.json"

# Fully user-owned directories, mirrored whole (new files inside picked up automatically).
DIRS="hooks skills agents commands"

for f in $FILES; do
  if [ -f "$SRC/$f" ]; then
    cp "$SRC/$f" "$DEST/$f"
    echo "synced  $f"
  else
    echo "skip    $f (absent)" >&2
  fi
done

for d in $DIRS; do
  if [ -d "$SRC/$d" ] && [ -n "$(ls -A "$SRC/$d" 2>/dev/null)" ]; then
    rm -rf "$DEST/$d"
    cp -r "$SRC/$d" "$DEST/$d"
    echo "synced  $d/ (dir)"
  else
    echo "skip    $d/ (absent or empty)" >&2
  fi
done

echo "Done. Review 'git status' / 'git diff' before committing."
