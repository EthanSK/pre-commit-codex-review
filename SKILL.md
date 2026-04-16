---
name: pre-commit-codex-review
description: Before committing code changes on ANY project, run the staged diff through GPT-5 via Codex CLI (or OpenClaw fallback) for automated bug-finding and fixing. Codex writes fixes, Claude reviews. Loop until clean. Mandatory for all code commits — skip only for docs-only / config-only changes.
---

# Pre-Commit Codex Review

## Why this exists

GPT-5.4 consistently finds bugs that Claude misses — proven across two
shadow audits on Producer Player (2026-04-16) where it caught 14 real
bugs, 11 shipped immediately. This skill gates every commit behind a
GPT-5 review so those bugs never reach production.

## When to use

**Every code commit on every project.** Exceptions:
- Pure documentation changes (README, CHANGELOG, comments-only)
- Config-only changes (package.json version bumps, .gitignore, CI YAML with no logic)
- Emergency hotfixes where the user explicitly says "skip review, ship now"

## How it works

### Step 1: stage changes + generate diff

```bash
git add <files>
git diff --cached > /tmp/pre-commit-diff.patch
```

### Step 2: invoke Codex in WRITE mode (primary)

```bash
codex exec --model gpt-5.4 --sandbox write \
  "Review this project for bugs in the staged changes. Fix any concrete
   bugs you find (logic errors, security issues, race conditions, state
   management bugs, edge cases). Leave a comment at each fix site.
   If you find nothing, say 'LGTM — no issues found.'"
```

Codex explores the repo, reads the diff context, finds bugs, AND applies
fixes directly. This is faster than report-then-fix because GPT-5 can
fix while it has full context.

**Fallback — OpenClaw (if Codex isn't available):**
```bash
openclaw infer model run --model openai-codex/gpt-5.4 \
  "Review this diff for bugs... $(cat /tmp/pre-commit-diff.patch)"
```
OpenClaw is one-shot inference (can't write files), so Claude fixes manually.

### Step 3: Claude reviews Codex's changes

```bash
git diff  # see what Codex changed
```

For each change Codex made:
- **Good fix** → accept (stage it)
- **Wrong fix** → revert (`git checkout -- <file>` for that hunk)
- **Partially right** → edit to improve, then stage

Claude is the quality gate. Codex does the heavy lifting; Claude ensures
nothing ships that's wrong.

### Step 4: final confirmation pass

Run Codex one more time in READ-ONLY mode on the final staged diff:

```bash
codex exec --model gpt-5.4 --sandbox read-only \
  "Review this diff for any remaining bugs. $(cat /tmp/pre-commit-diff.patch)"
```

If LGTM → commit. If new findings → fix and re-review.

### Step 5: commit

```bash
git commit -m "..."
```

## Loop behavior

Codex finds → fixes → Claude reviews → Codex confirms. Max 3 iterations.
After 3 with no convergence, commit with a note listing remaining findings
assessed as false positives or style preferences.

## What Codex should focus on

The prompt asks for:
- Logic errors (wrong condition, off-by-one, missing null check)
- Security issues (unsanitized input, path traversal, XSS, injection)
- Race conditions (async without cancellation, stale closure, missing await)
- State management bugs (leaked refs, wrong useEffect deps, stale state)
- Data loss (writes that silently fail, missing error handling on persist)
- API contract violations (wrong types, missing fields)
- Edge cases the author likely didn't test

What it should NOT flag:
- Style preferences (semicolons, quote style, import order)
- Refactoring suggestions
- Test coverage gaps

## Prerequisites

- **Codex CLI** installed and authenticated via `codex login` (uses ChatGPT subscription, not API tokens)
- OR **OpenClaw** configured with an OpenAI model route (fallback)
- **Claude Code** (this skill runs inside Claude Code sessions)

## Installation

```bash
# Option 1: copy to your Claude skills directory
cp -r pre-commit-codex-review ~/.claude/skills/

# Option 2: use the install script
bash install.sh
```

## Performance

- Codex `exec` with write mode on a typical diff (< 500 lines): 30-60 seconds
- Large diffs (1000+ lines): 60-120 seconds
- Final read-only confirmation: 15-30 seconds
