---
name: jk-execute
description: "Execute a plan in Deep, Swarm, or Care mode. Three execution topologies: one brain, many brains, or brain + human."
---

# Deep Execute

Execute an implementation plan using one of three execution topologies. Each mode uses per-task review (spec compliance + code quality) and ends with jk-prove-it.

> **REQUIRED SUB-SKILL:** Use jk-skills:jk-philosophy

If you cannot load jk-skills:jk-philosophy, STOP and tell the user the plugin is misconfigured.

## Plan File Discovery

1. If a path is provided as argument, use it
2. If no path, list recent `*-plan.md` and `*-design.md` files in `docs/plans/` and ask the user to pick
3. If no plan files found, STOP and tell the user to create one first (use jk-skills:jk-plan)

## Execution Modes

### Deep — One Brain

Single orchestrator, sequential, full context. Best for tightly coupled tasks, refactoring, architectural changes where context matters.

### Swarm — Many Brains

Parallel dispatch, independent tasks. Best for many independent tasks (add tests to 5 modules, update 8 configs, bulk changes). For plans with fewer than 3 tasks, suggest Deep instead — Swarm adds overhead for no benefit.

### Care — Brain + Human

Sequential like Deep, but pauses at meaningful phase boundaries for human review. Best for unfamiliar codebases, high-stakes changes, learning.

---

## Mode Selection

If the user specified a mode, use it. If not, analyze the plan and recommend one:

**Recommendation heuristics** (in priority order):
1. **Swarm** if there are 3+ tasks AND most tasks are independent (no shared files or sequential dependencies)
2. **Care** if the plan touches unfamiliar patterns, involves high-risk changes (auth, data migration, billing), or the user seems uncertain
3. **Deep** as the default — it's the safest and most thorough option

Present with your recommendation marked. Example if recommending Deep:

```
Choose execution mode:
1. Deep  — One brain, sequential, full context. Round table at end. No human pauses. (Recommended — tasks are tightly coupled)
2. Swarm — Many brains, parallel dispatch. Per-task review. Maximum speed.
3. Care  — Brain + human. Checkpoints with "what to check" guidance. You stay in the loop.
```

Include a one-line reason for the recommendation (e.g., "tasks share state", "8 independent modules", "unfamiliar codebase").

---

## Setup (All Modes)

1. Read the plan file
2. Extract all tasks with full text (provide text to subagents — do not make them read the file)
3. Create task list
4. Record `BASE_SHA` (current HEAD before any implementation)
5. Create `.jk-work/` directory if it doesn't exist

## Hard Directive (Deep and Swarm)

<HARD-GATE>
Do NOT stop, pause, or ask "should I continue?" between tasks. Execute ALL tasks until every one is complete or you hit a blocker you cannot resolve. The only acceptable reasons to stop mid-execution are:

- A test fails after 3 fix attempts
- A reviewer finds a Critical issue that contradicts the plan itself
- You need information only the user can provide

"I'm running low on context" is NOT a reason to stop — use `/clear` and resume.
</HARD-GATE>

---

## Deep Mode

### Per-Task Execution

For each task:

1. **Dispatch implementer subagent** with full task text + context + accumulated wisdom
2. Answer any questions the implementer has (before AND during work)
3. Implementer implements with TDD, commits, self-reviews
4. **Dispatch spec compliance reviewer** — does code match the plan?
5. If spec fails → implementer fixes → re-review (max 3 cycles)
6. **Dispatch code quality reviewer** — is the code clean?
7. If quality fails → implementer fixes → re-review (max 3 cycles)
8. **Extract wisdom** from this task and append to `.jk-work/wisdom.md`:
   - Conventions discovered
   - Gotchas hit
   - Commands that worked
   - Patterns to follow
   - Mistakes to avoid
9. Mark task complete

### Wisdom Accumulation

Each task's implementer receives all accumulated wisdom from previous tasks. This compounds — later tasks benefit from everything learned earlier.

Write wisdom to `.jk-work/wisdom.md` after each task. Read it before dispatching the next implementer.

### Round Table

After ALL tasks are complete, launch 6 parallel reviewers on the full diff (`git diff {BASE_SHA}..HEAD`):

| Reviewer | Focus |
|----------|-------|
| **Spec Compliance** | Does the complete implementation match the plan holistically? |
| **Code Quality** | Cross-cutting quality: consistency, duplication, naming coherence |
| **Security** | Full attack surface: input validation, auth, secrets, injection |
| **Test Coverage** | End-to-end test sufficiency, integration gaps, edge cases |
| **Convention Compliance** | Project CLAUDE.md adherence across all changes |
| **Integration** | Do all pieces work together? Will this break existing code? |

**All reviewers:** Type `general-purpose`, model `sonnet`, read-only tools.

**Triage:**
1. Critical/Important → fix, re-run only failed reviewers
2. Minor → fix if trivial, note otherwise
3. Max 2 round table cycles. After that, remaining issues go to the user.

### Finish

> **REQUIRED SUB-SKILL:** Use jk-skills:jk-prove-it

---

## Swarm Mode

### Pre-Dispatch Check

Before dispatching any agents, verify no two tasks touch the same files. For each task, identify the files it will modify.

- If overlap found: serialize overlapping tasks or merge them into one
- If no overlap: proceed with parallel dispatch

### Parallel Dispatch

Dispatch implementer subagents for all independent tasks simultaneously. Each gets:
- Full task text + context
- Any existing wisdom files from `.jk-work/`

### Per-Agent Wisdom

Each agent writes its learnings to `.jk-work/wisdom-task-N.md` (where N is the task number). No shared file — no race conditions.

Later-starting agents should read all existing `wisdom-task-*.md` files before beginning.

### Per-Task Review

After each implementer completes:
1. Dispatch spec compliance reviewer
2. If spec fails → dispatch fix subagent → re-review
3. Dispatch code quality reviewer
4. If quality fails → dispatch fix subagent → re-review

### Coordinator

After all tasks complete:
1. Merge all `wisdom-task-*.md` files into `.jk-work/wisdom.md`
2. Report completion status for all tasks
3. Report any failures or issues

**No round table in Swarm mode** — there's no single coherent diff to review when work happened in parallel.

### Finish

> **REQUIRED SUB-SKILL:** Use jk-skills:jk-prove-it

---

## Care Mode

### Per-Task Execution

Same as Deep mode: sequential, per-task review pipeline, wisdom accumulation in `.jk-work/wisdom.md`.

### Human Checkpoints

Pause at meaningful phase boundaries — not after every task, but after logical groups. At each checkpoint, present:

```markdown
## Checkpoint: [Phase Name]

### What Was Done
[Bullet list of completed tasks]

### What to Check
[Specific files to eyeball, behaviors to test, edge cases to try]

### Wisdom So Far
[Key learnings from execution]

### What Comes Next
[Preview of remaining tasks]
```

Wait for the user's response before continuing. If they have feedback, apply it.

### Round Table

Offered at the final checkpoint — the user can accept or skip.

Same panel as Deep mode if accepted.

### Finish

> **REQUIRED SUB-SKILL:** Use jk-skills:jk-prove-it

---

## Subagent Prompt Templates

### Implementer

```
You are implementing Task N: [task name]

## Task Description
[FULL TEXT of task from plan]

## Context
[Where this fits, dependencies, architectural context]

## Accumulated Wisdom
[All wisdom from previous tasks — conventions, gotchas, patterns]

## Before You Begin
If you have questions about requirements, approach, dependencies, or anything unclear — ask now.

## Your Job
1. Implement exactly what the task specifies
2. Write tests (TDD if task requires it)
3. Verify implementation works
4. Commit your work
5. Self-review: completeness, quality, discipline, testing
6. If you find issues during self-review, fix them before reporting

## Report Format
- What you implemented
- What you tested and results
- Files changed
- Self-review findings
- Wisdom learned (conventions, gotchas, patterns discovered)
```

### Spec Compliance Reviewer

```
You are reviewing whether an implementation matches its specification.

## What Was Requested
[FULL TEXT of task requirements]

## CRITICAL: Do Not Trust the Implementer's Report
Verify everything independently by reading the actual code.

Check for:
- Missing requirements (skipped or missed)
- Extra/unneeded work (over-engineering, unrequested features)
- Misunderstandings (wrong interpretation of requirements)

Report: ✅ Spec compliant OR ❌ Issues found [with file:line references]
```

### Code Quality Reviewer

```
Review the implementation for code quality.

Dispatch using the code-reviewer agent

Check: clean code, proper testing, naming, patterns, maintainability.
Report: Strengths, Issues (Critical/Important/Minor), Assessment.
```

---

## Integration

- **jk-skills:jk-plan** creates the plan this skill executes
- **jk-skills:jk-prove-it** is REQUIRED at the end of every mode
- **jk-skills:verification-before-completion** is invoked by jk-prove-it
- **jk-skills:finishing-a-development-branch** for merge/push decision after prove-it
- **jk-skills:test-driven-development** — subagents should follow TDD for each task
