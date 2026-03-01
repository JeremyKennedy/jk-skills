---
name: jk-prove-it
description: "Ship gate: you claim you're done — prove it. Mechanical verification, self-review of your own diff, structured ship report."
---

# Prove It

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

## Step 3: Ship Report

Produce this report. Every field is mandatory. Do not skip fields. Do not say "N/A" unless it genuinely does not apply.

```markdown
## Ship Report

### What Changed
[Bullet list of changes, grouped by logical area]

### What Was Tested
[Commands run, their output, pass/fail status]

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

## The Standard

If you can't fill out every section of the ship report with confidence, you are not done.

Go back. Do more work. Then prove it again.
