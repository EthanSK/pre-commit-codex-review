# Pre-Commit Codex Review

A [Claude Code](https://claude.ai/claude-code) skill that gates every code commit behind an automated Codex (GPT) bug-finding review via [Codex CLI](https://openai.com/codex).

Codex reads your staged diff, finds bugs, applies fixes, and Claude reviews before committing. Loop until clean. Catches the bugs you'd miss — proven across real-world audits where it found 14 bugs in a single codebase that the primary AI missed.

## How it works

```
You write code → stage changes → Codex (Codex.4) reviews in write mode
→ finds bugs + applies fixes → Claude reviews each fix → accepts/reverts
→ final read-only Codex pass confirms LGTM → commit
```

## Prerequisites

- [Claude Code](https://claude.ai/claude-code) installed
- [Codex CLI](https://openai.com/codex) installed and authenticated (`codex login` — uses your ChatGPT subscription, no API tokens needed)
- OR [OpenClaw](https://github.com/EthanSK/openclaw) configured with an OpenAI model route (fallback)

## Installation

```bash
# Clone this repo
git clone https://github.com/EthanSK/pre-commit-codex-review.git

# Copy the skill to your Claude skills directory
cp -r pre-commit-codex-review/SKILL.md ~/.claude/skills/pre-commit-codex-review/SKILL.md

# Or use the install script
bash pre-commit-codex-review/install.sh
```

After installation, Claude Code will automatically discover the skill and use it before code commits.

## What it catches

- Logic errors (wrong conditions, off-by-one, missing null checks)
- Security issues (path traversal, unsanitized input, XSS, injection)
- Race conditions (async without cancellation, stale closures, missing await)
- State management bugs (leaked refs, wrong useEffect deps)
- Data loss (silent write failures, missing error handling)
- Edge cases the author didn't test

## What it ignores

- Style preferences (semicolons, import order)
- Refactoring suggestions
- Test coverage gaps

## Configuration

The skill uses `gpt-5.4` by default. To use a different model, edit the `codex exec --model` line in `SKILL.md`.

Max review iterations: 3 (prevents infinite loops on style disagreements).

## Example

```
$ git add src/updater.ts
# Claude invokes the skill automatically before committing...

[pre-commit-codex-review] Sending diff to Codex (gpt-5.4, write mode)...
[pre-commit-codex-review] Codex found 2 issues:
  1. main.ts:1032 — quitAndInstall called without emitting 'installing' state
  2. main.ts:4331 — download handler doesn't emit 'downloading' immediately
[pre-commit-codex-review] Codex applied fixes. Reviewing...
[pre-commit-codex-review] Both fixes verified. Re-running read-only confirmation...
[pre-commit-codex-review] LGTM ✓
$ git commit -m "fix: ..."
```

## Background

Built after two Codex.4 shadow audits on [Producer Player](https://github.com/EthanSK/producer-player) (April 2026) where Codex independently found 14 real bugs that Claude had missed — including a security vulnerability (custom protocol serving arbitrary files), silent data loss on import, and a listener-accumulation bug in the auto-updater. 11 of 14 findings were shipped as fixes immediately.

The conclusion: Codex (GPT) and Claude have complementary blind spots. Running both on every commit catches more bugs than either alone.

## License

MIT
