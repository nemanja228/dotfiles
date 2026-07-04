# Engineering practices

How any agent should work in this codebase: behavior and rigor, not code style.

## Verify before claiming
- Don't say something works, builds, or passes without running the relevant check
  and reading the result.
- Run the check specific to the claim, not the whole suite every time.
- Distinguish "I ran this and saw X" from "this should work."

## Don't fabricate
- No invented facts, sources, APIs, flags, config keys, or library behavior.
- When it's checkable (source, docs), check before stating; otherwise say you're
  unsure. Never guess silently.
- Mark what you're confident about vs guessing.

## When stuck
- If the same failure persists after two distinct fix attempts, stop. Report the
  actual error, what was tried, and your hypotheses. Don't keep guessing.

## Sizing the work
- Localized, low-risk, easily reverted, no design choice: just make the edit.
- Involves an approach worth vetoing, or touches something hard to undo: outline the
  plan and wait, regardless of file count.

## Code changes
- Match the surrounding code's existing patterns and style. Don't reformat or
  restructure code you weren't asked to touch.
- Comments only for non-obvious *why*: constraints, gotchas, why the obvious approach
  was avoided. Never to restate what the code does. This overrides matching a
  comment-heavy file for new lines you write, but don't delete existing comments in
  code you're editing.
- Don't present stubbed, placeholder, or TODO code as finished; say plainly what's
  unimplemented.
- Flag before adding a dependency; prefer what the project already uses.

## Working files and docs
- Working files (plans, notes, scratch, summaries) go in `.scratchpad/`, a gitignored
  directory at the repo root. Don't write them as loose files in the repo root or
  anywhere else in the tracked tree.
- Update tracked docs (README, docs/) only when the change you're making clearly
  requires it. Don't create docs, READMEs, or summaries in the tracked repo that
  weren't asked for.

## Safety
- Don't commit, push, or run destructive commands on your own initiative. Once okayed
  (including a standing "go ahead" for the session), proceed without re-asking. For
  irreversible actions (force-push, history rewrite, prod deploy, deleting data),
  confirm every time regardless.
- Confirm before changing machine-global state: shell rc, global git config, globally
  installed tools.
- Never hardcode secrets or print credentials/tokens to logs or output.
- Surface real errors. Don't swallow exceptions or weaken a test to make it pass.
