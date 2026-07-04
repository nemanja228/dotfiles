#!/usr/bin/env sh
# Personal CSharpier TRIAL (Stop hook): format the .cs files changed this session.
# Runs at Stop (turn over) so it never breaks Claude's in-flight Edit sequences.
# Side-effect only: never blocks, always exits 0.

# Global tool exposes `csharpier` on PATH (v1.x; `dotnet csharpier` only works for a
# local-manifest install, which is the later project-rollout path, not this trial).
command -v csharpier >/dev/null 2>&1 || exit 0

files=$( { git diff --name-only --diff-filter=ACMR -- '*.cs' 2>/dev/null; \
           git ls-files --others --exclude-standard -- '*.cs' 2>/dev/null; } | sort -u )

[ -z "$files" ] && exit 0

printf '%s\n' "$files" | xargs csharpier format >/dev/null 2>&1

exit 0
