---
name: jk-prove-it
description: "Use when claiming work is complete — mechanical verification, self-review of own diff, liveness check, structured ship report."
---

# Prove It

**Announce at start:** "I'm using the jk-prove-it skill to verify this work is ready to ship."

You claim you're done. Prove it.

This is not a formality. This is not a checkbox. You are about to tell a human that your work is ready to ship. If you're wrong, you waste their time and erode trust.

## When to Use

- At the end of any execution mode (Deep, Swarm, Care)
- Whenever you're about to claim "I'm done" or "this is ready"
- Before committing, pushing, or creating a PR
- When asked: "is this done?"

## Step 1: Mechanical Verification

> **REQUIRED SUB-SKILL:** Use jk-skills:verification-before-completion

If you cannot load jk-skills:verification-before-completion, STOP and tell the user the plugin is misconfigured.

Follow it completely. Run every verification command. Read every output. No shortcuts.

If verification fails, you are NOT done. Fix it. Then come back.

## Step 2: Self-Review Your Diff

Run `git diff` (or `git diff BASE_SHA..HEAD` if you have a base) and **read your own changes critically**.

You are now your own adversary. Look for:

- **Things you forgot.** Requirements you missed. Edge cases you didn't handle. Tests you didn't write.
- **Things you broke.** Did you change behavior you didn't intend to? Did you remove something that was needed?
- **Things that are ugly.** Code you know is messy but shipped anyway. Names that don't describe what they do. Abstractions that don't abstract.
- **Things that are wrong.** Logic errors. Off-by-ones. Race conditions. Null pointer paths. Security holes.
- **Things you wouldn't accept in code review.** If someone else wrote this diff and sent it to you, what would you flag?

Did you expand scope? Did you fix adjacent issues you found? If not, go back and do it — that's the philosophy.

If you find issues, fix them. Then re-run Step 1.

## Step 3: Liveness Verification

Tests passing is not enough. **Can a human see this working?**

You must demonstrate the change is alive — running, visible, behaving correctly. Not in theory. Not "tests cover it." Actually running.

### The Liveness Ladder

Try each level in order. Use the highest level you can reach:

1. **Localhost** — Start the dev server, open the page, hit the endpoint, trigger the behavior. Take a screenshot or paste the response. This is the default expectation for any UI or API change.
2. **Dev/staging** — Deploy to a non-production environment and verify there. Use this when localhost can't represent the real environment (infrastructure changes, integrations, auth flows).
3. **Production** — Deploy and verify on the real thing. Use this when dev/staging doesn't exist or the change only matters in prod context.

### What Counts as Liveness Evidence

- Screenshot of the UI showing the change
- curl/HTTP response from the endpoint
- Log output showing the new behavior firing
- CLI output demonstrating the new command/flag
- Browser console showing the expected network calls

### What Does NOT Count

- "Tests pass" — tests are not liveness
- "Build succeeds" — a build artifact sitting on disk is not alive
- "Should work when deployed" — should is not evidence
- "The code looks correct" — reading code is not running code

### When Liveness Doesn't Apply

Some changes genuinely can't be demonstrated live:

- Pure refactors with no behavior change (tests are sufficient)
- CI/CD config changes (can't run the pipeline locally)
- Documentation-only changes
- Library/dependency updates where tests cover the surface

If you believe liveness doesn't apply, you must **explicitly justify why** in the ship report. "It's a refactor" is valid. "I didn't have time" is not.

### The Hard Gate

If your change is user-facing (UI, API, CLI, behavior) and you have NOT verified it live:

**You are not done. Do not produce a ship report.**

Instead, tell the human:

> I've passed mechanical verification and self-review, but I haven't verified this is actually working live. Before I can confidently say this is done, I need to [specific action: start the dev server / deploy to dev / deploy to prod]. Want me to do that now?

This is not a risk to note. This is a blocker. You cannot ship what you haven't seen run.

## Step 4: Ship Report

Produce this report. Every field is mandatory. Do not skip fields. Do not say "N/A" unless it genuinely does not apply.

```markdown
## Ship Report

### What Changed
[Bullet list of changes, grouped by logical area]

### What Was Tested
[Commands run, their output, pass/fail status]

### Liveness
[How you verified the change is actually working. What you saw. Screenshot/output/evidence. If liveness doesn't apply, explain why.]

### Evidence
[Concrete proof: test counts, command outputs, screenshots, log snippets]

### Scope Expansion
[Adjacent issues found and fixed. If none: explain why the surrounding code was already clean.]

### Known Risks
[What could go wrong. What assumptions are you making. What wasn't tested.]

### What to Check
[Specific things the human should verify. Behaviors to test. Files to eyeball.]

### What I'm Not Sure About
[Honest uncertainty. Things that might be wrong. Decisions you made without full confidence.]
```

### Ship Report Red Flags

If your **Known Risks** section contains any of these, you are NOT done — go back and fix it:

- "Not yet deployed"
- "Haven't tested in a real environment"
- "Couldn't verify the UI"
- "Needs manual testing"
- "Should work but haven't confirmed"

These are not risks. These are incomplete work. A risk is "the migration could be slow on large datasets." A risk is NOT "nobody has looked at this running."

## The Standard

If you can't fill out every section of the ship report with confidence, you are not done.

If your liveness section is empty or says "N/A" for user-facing work, you are not done.

Go back. Do more work. Then prove it again.

## Step 5: Finish the Branch

Ship report complete. Now finish the work:

> **REQUIRED SUB-SKILL:** Use jk-skills:jk-finish-branch

If you cannot load jk-skills:jk-finish-branch, STOP and tell the user the plugin is misconfigured.
