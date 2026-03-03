---
name: jk-code-review
description: Use when completing tasks, implementing major features, or before merging — dispatches code-reviewer agent to catch issues early
---
<!-- Derived from superpowers v4.2.0: requesting-code-review -->

# Code Review

**Announce at start:** "I'm using the jk-code-review skill to dispatch a code review."

Dispatch the `code-reviewer` agent to catch issues before they cascade. This is the canonical review dispatch — jk-execute invokes this skill for per-task code quality reviews.

**Core principle:** Review early, review often.

## When to Request Review

**Automatic (via jk-execute):**
- Per-task code quality review during Deep/Swarm/Care execution

**Manual:**
- After completing major feature (ad-hoc development)
- Before merge to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

## How to Request

**1. Get git SHAs:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**2. Dispatch code-reviewer subagent:**

Dispatch the `code-reviewer` agent as a subagent, filling the template at `references/code-reviewer.md`

**Placeholders:**
- `{WHAT_WAS_IMPLEMENTED}` - What you just built
- `{PLAN_OR_REQUIREMENTS}` - What it should do
- `{BASE_SHA}` - Starting commit
- `{HEAD_SHA}` - Ending commit
- `{DESCRIPTION}` - Brief summary

**3. Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back if reviewer is wrong (with reasoning)

## Example

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code-reviewer agent]
  WHAT_WAS_IMPLEMENTED: Verification and repair functions for conversation index
  PLAN_OR_REQUIREMENTS: Task 2 from docs/plans/deployment-plan.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to proceed

You: [Fix progress indicators]
[Continue to Task 3]
```

## Integration

**jk-execute** invokes this skill automatically for per-task code quality reviews. You do NOT need to separately invoke jk-code-review during jk-execute.

**Ad-hoc development:** Invoke this skill manually whenever you want a code review outside of jk-execute.

## Red Flags

**Never:**
- Skip review because "it's simple"
- Ignore Critical issues
- Proceed with unfixed Important issues
- Argue with valid technical feedback

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See template at: jk-code-review/references/code-reviewer.md
