---
name: jk-execute
description: "Use when executing an implementation plan — four modes: Deep (subagent per task, clean orchestrator), Direct (main thread, full visibility), Swarm (parallel independent tasks), Care (human checkpoints)."
---

# Deep Execute

**Announce at start:** "I'm using the jk-execute skill to execute the plan."

Execute an implementation plan using one of four execution topologies. Each mode uses per-task review (spec compliance + code quality) and ends with jk-prove-it.

**Wisdom vs Memory — two different persistence systems:**

| | Wisdom | Memory |
|---|--------|--------|
| **Scope** | This plan execution only | Cross-session, long-lived |
| **Audience** | Subagents executing later tasks in this plan | Future you, working on this project next month |
| **Content** | Conventions discovered, gotchas hit, commands that worked, patterns to follow | Project decisions, user preferences, architectural constraints, domain knowledge |
| **Path** | `.jk-work/<plan-slug>/wisdom.md` (derived from plan filename) | Auto memory system (`~/.claude/projects/.../memory/`) |
| **Lifecycle** | Created during execution, archived with plan docs when done | Persists indefinitely |
| **Example** | "This codebase uses vitest not jest" / "Import from ./types not ./index" | "User prefers Swarm mode" / "Imports are highest-risk — always verify target client" |

**Wisdom** compounds across tasks — task 5 benefits from what task 1 learned. It's transient to the execution.

**Memory checkpoints** (save to auto memory, not wisdom):
- **Before presenting the plan** — last chance before the user might `/clear`. Save project decisions, user preferences, constraints from the planning conversation.
- **After all tasks complete, before jk-prove-it** — promote any wisdom that's broadly useful to memory (e.g., "this project's test runner is X" is worth remembering). Leave execution-specific gotchas in wisdom.
- **After jk-prove-it completes** — save verification learnings, anything about the codebase worth knowing next time.

**After execution completes**, archive the wisdom file alongside the plan: copy `.jk-work/<plan-slug>/wisdom.md` to `docs/plans/<plan-slug>-wisdom.md` and commit. This preserves execution context with the plan for reference.

> **REQUIRED SUB-SKILL:** Use jk-skills:jk-philosophy

If you cannot load jk-skills:jk-philosophy, STOP and tell the user the plugin is misconfigured.

## Model Selection

Choose `haiku`, `sonnet`, or `opus` for subagents based on what the task demands:

| Signal | Haiku | Sonnet | Opus |
|--------|-------|--------|------|
| **Reasoning** | None — mechanical, no judgment | Some — following patterns, clear criteria | Deep — novel design, ambiguous tradeoffs |
| **Risk** | Zero — output is trivially verifiable | Low — reviewer can catch it, easily re-run | High — wrong answer cascades, hard to detect |
| **Task type** | File listing, formatting, grep-and-summarize | Exploration, convention checking, focused review | Design, root-cause analysis, adversarial review |

**In this skill:**
- **Implementers** → `opus` by default. `sonnet` only for truly straightforward tasks (clear spec, known patterns, no judgment calls)
- **Per-task reviewers** (spec compliance, code quality) → `sonnet` — narrow scope, clear criteria
- **Round table reviewers** → `sonnet` for generic reviewers (already specified), specialized agents use their own model
- **Haiku** → mechanical subtasks only: generating boilerplate, formatting, file scaffolding

**Default:** Lean towards heavier models — this plugin values correctness over token cost. Use `opus` unless the task is clearly mechanical. `sonnet` for focused work with clear criteria. `haiku` only for truly mechanical subtasks (file listing, formatting, boilerplate).

## Plan File Discovery

1. If a path is provided as argument, use it
2. If no path, list recent `*-plan.md` and `*-design.md` files in `docs/plans/` and ask the user to pick
3. If no plan files found, STOP and tell the user to create one first (use jk-skills:jk-plan)

## Execution Modes

### Deep — Subagent Per Task

Sequential execution where each task is dispatched to a subagent. The main thread orchestrates: reading results, extracting wisdom, dispatching reviewers, managing the task list. The dirty work happens in subagents, keeping orchestrator context clean for high-quality coordination.

**Best for:** Most plans. Tightly coupled tasks, refactoring, architectural changes. The orchestrator retains full context across all tasks without burning tokens on implementation details.

### Direct — Main Thread

Sequential execution where all work happens in the main conversation thread. No subagents for implementation — you do the work directly. The user sees every file read, every edit, every test run in real time.

**Best for:** Risky or uncertain work where the user wants full visibility. Tasks expected to be problematic, unfamiliar codebases, or situations where you expect to need user input mid-task. Different from Care mode — Direct has no prescribed pauses, it just keeps the work visible.

### Swarm — Parallel Independent

Multiple subagents working simultaneously on independent tasks in the same worktree. Maximum speed, but requires strict discipline — agents are modifying files in a shared workspace.

**Best for:** 3+ tasks that touch completely independent files (add tests to 5 modules, update 8 configs, implement 6 unrelated endpoints). For plans with fewer than 3 independent tasks, suggest Deep instead — Swarm adds overhead for no benefit.

### Care — Brain + Human

Sequential like Deep (subagent per task), but pauses at meaningful phase boundaries for human review. The user stays in the loop with structured checkpoints.

**Best for:** High-stakes changes (auth, data migration, billing), learning a new codebase, or when the user explicitly wants to review progress before continuing.

---

## Mode Selection

If the user specified a mode, use it. If not, analyze the plan and recommend one.

**Recommendation heuristics** (in priority order):
1. **Swarm** if there are 3+ tasks AND most tasks touch completely independent files (no shared files or sequential dependencies)
2. **Direct** if the plan touches risky areas, the user seems uncertain, or tasks are expected to be problematic
3. **Care** if the plan is high-stakes or the user is learning the codebase
4. **Deep** as the default — cleanest orchestration, good for most work

**When presenting the choice**, include your analysis:

```
Choose execution mode:

1. Deep    — Subagent per task, sequential. Orchestrator stays clean, reviews between tasks.
             Good default for most plans.
2. Direct  — Main thread, sequential. You see everything in real time. No subagents for implementation.
             Best when you want full visibility or expect trouble.
3. Swarm   — Parallel subagents on independent files. Maximum speed, atomic commits.
             Best for N independent tasks touching separate files.
4. Care    — Subagent per task with human checkpoints. Structured pauses between phases.
             Best for high-stakes work or when you want to review progress.

Recommended: [mode] — [one-line reason with specifics about the plan]
```

If recommending Swarm, include the proposed wave/phase breakdown showing which tasks run in parallel and which must be serialized. If recommending Deep or Direct, explain why the tasks are too coupled for Swarm.

---

## Setup (All Modes)

1. Read the plan file
2. Extract all tasks with full text (provide text to subagents — do not make them read the file)
3. **Check for outstanding context.** Is anything from the conversation not captured in the plan files? Decisions, design choices, context that only exists in the conversation.
4. **Determine execution mode.** If the user specified a mode, use it. Otherwise, analyze the plan and recommend one (see Mode Selection above). If recommending Swarm, work out the wave breakdown.
5. **Save to memory.** Before presenting, save any important context from the planning conversation that would be useful in future sessions — user preferences, project decisions, constraints learned. This is the last chance before the user might `/clear`.
6. **Present the plan to the user** using `EnterPlanMode`.

   <HARD-GATE>
   Write a FRESH presentation to the plan mode tool. Do NOT edit the plan doc file on disk. Do NOT copy-paste from the plan doc. The plan doc is an agent-facing reference — detailed, verbose, exact code. The presentation is a separate artifact you write from scratch for a human audience.

   No interface definitions, no full API endpoint tables, no exact code snippets, no test case lists.
   </HARD-GATE>

   The plan mode UI shows the **bottom** first. Structure accordingly:

   **Top (main content — user scrolls up to read):**
   Skimmable. Bullets, short tables, and brief elaboration — not essays or walls of text. Cover:
   - What the plan accomplishes
   - How it's done (approach, architecture, key patterns)
   - Key decisions made during planning — surface these explicitly so the user can catch anything they've had second thoughts about since the interview
   - Task list: one line per task (number + short name)
   - Waves (Swarm only): which tasks run together
   - Verification: the commands to run

   Think dashboard, not document. The user should be able to scan it in 30 seconds and understand what's happening.

   **Bottom (what the user sees first — self-contained, target ~10-15 lines):**
   - Literal `## TL;DR: [plan title]` heading, then 4-6 sentences covering: what gets built, the approach/architecture at a high level, how many tasks, which mode and why, key decisions worth flagging. Scale to plan complexity — simple plans get a few sentences, complex plans can have several short paragraphs with bullets. Prefer bullets over prose. Give the user enough to catch problems without scrolling up.
   - **Mode**: recommendation + one-line reasoning
   - **Context note**: Based on step 3's analysis, tell the user whether they can safely `/clear`. Only recommend clearing if you have verified that ALL conversation context needed for execution is captured in the plan docs on disk. If there is ANY uncaptured context (decisions, constraints, clarifications from the interview that didn't make it into the docs), say so and recommend against clearing. Do not say "you can clear" as a default — earn it by checking.

   Then `ExitPlanMode`. One decision point.

6. Create task list
7. Record `BASE_SHA` (current HEAD before any implementation)
8. Derive `<plan-slug>` from the plan filename (e.g., `2026-03-20-mcp-safety` from `2026-03-20-mcp-safety.md`). Create `.jk-work/<plan-slug>/` directory.

## Hard Directive (Deep, Direct, and Swarm)

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

1. **Dispatch implementer subagent** with full task text + context + accumulated wisdom. Construct exactly what they need — never pass session history or context they don't need.
2. **Handle implementer status:**
   - **DONE** → proceed to review (step 3)
   - **DONE_WITH_CONCERNS** → read concerns. If about correctness/scope, address before review. If observational ("this file is getting large"), note and proceed.
   - **NEEDS_CONTEXT** → provide the missing context and re-dispatch
   - **BLOCKED** → assess the blocker:
     1. Context problem → provide more context, re-dispatch
     2. Task too hard for the model → re-dispatch with `opus`
     3. Task too large → break into smaller pieces
     4. Plan itself is wrong → escalate to the user
   - **Never** ignore an escalation or force the same agent to retry without changes
3. **Dispatch spec compliance reviewer** — does code match the plan?
4. If spec fails → implementer fixes → re-review (max 3 cycles)
5. **Dispatch code quality reviewer** — is the code clean?
6. If quality fails → implementer fixes → re-review (max 3 cycles)
7. **Extract wisdom** from this task and append to `.jk-work/<plan-slug>/wisdom.md`:
   - **Plan diversions**: anything the implementer did differently from the plan — changed approach, skipped a step, added something unplanned, discovered the plan was wrong
   - **Plan revisions**: if the plan needs updating for future tasks based on what was learned
   - Conventions discovered
   - Gotchas hit
   - Commands that worked
   - Patterns to follow
   - Mistakes to avoid

   Each wisdom entry must include: `[Task N | agent: <mode/model> | <timestamp>]` header for traceability.
8. Mark task complete

### Wisdom Accumulation

Each task's implementer receives all accumulated wisdom from previous tasks. This compounds — later tasks benefit from everything learned earlier.

Write wisdom to `.jk-work/<plan-slug>/wisdom.md` after each task. Read it before dispatching the next implementer.

### Round Table

After ALL tasks are complete, launch reviewers in parallel on the full diff (`git diff {BASE_SHA}..HEAD`):

| Reviewer | Type | Focus |
|----------|------|-------|
| **Spec Compliance** | general-purpose | Does the complete implementation match the plan holistically? |
| **Code Quality** | general-purpose | Cross-cutting quality: consistency, duplication, naming coherence |
| **Security** | general-purpose | Full attack surface: input validation, auth, secrets, injection |
| **Convention Compliance** | general-purpose | Project CLAUDE.md adherence across all changes |
| **Integration** | general-purpose | Do all pieces work together? Will this break existing code? |
| **Error Handling** | `silent-failure-hunter` agent | Silent failures, swallowed errors, inadequate fallbacks |
| **Test Coverage** | `test-analyzer` agent | Behavioral test gaps, criticality-rated |
| **Documentation** | `doc-analyzer` agent | Doc accuracy, staleness, AI-generated drift |

**Generic reviewers:** Type `general-purpose`, model `sonnet`, read-only tools.
**Specialized agents:** Use the named agent definitions directly.

**Confidence Scoring:**

Each reviewer must score every issue 0-100 for **confidence that it's a real issue** (not severity):
- **0-25**: False positive, pre-existing, or linter territory — not a real issue
- **26-50**: Probably not real, but worth a second look
- **51-100**: Real issue — fix it. Code is free, refactoring is always worth it.

**Triage:**
1. Issues ≥51 confidence → fix. All real issues get fixed, regardless of severity.
2. Issues 26-50 → quick second look. Fix if real, discard if false positive.
3. Issues <26 → discard (false positives).
4. Max 2 round table cycles. After that, remaining issues go to the user.

### Finish

> **REQUIRED SUB-SKILL:** Use jk-skills:jk-prove-it

---

## Direct Mode

### Per-Task Execution

For each task, execute directly in the main thread — no implementer subagent:

1. Read relevant files and understand the task context
2. Implement with TDD: write failing test, implement, verify pass
3. Commit your work
4. Self-review: completeness, quality, discipline, testing
5. **Dispatch spec compliance reviewer** (subagent) — does code match the plan?
6. If spec fails → fix directly → re-review (max 3 cycles)
7. **Dispatch code quality reviewer** (subagent) — is the code clean?
8. If quality fails → fix directly → re-review (max 3 cycles)
9. **Extract wisdom** and append to `.jk-work/<plan-slug>/wisdom.md`
10. Mark task complete

Reviewers still run as subagents — the point of Direct mode is that *implementation* happens in the main thread, not that everything does.

### Wisdom Accumulation

Same as Deep mode. Write wisdom after each task, read before starting the next.

### Round Table

Same as Deep mode.

### Finish

> **REQUIRED SUB-SKILL:** Use jk-skills:jk-prove-it

---

## Swarm Mode

### Critical: Shared Worktree Safety

<HARD-GATE>
Swarm agents work in the SAME worktree simultaneously. Every agent MUST be briefed on this situation in their prompt. The rules are non-negotiable:

1. **Atomic commits only.** Each agent commits with a single `git add <specific-files> && git commit` command. NEVER `git add .` or `git add -A` — this will commit another agent's in-progress work.
2. **NEVER stash.** `git stash` in a shared worktree will capture another agent's changes. Forbidden.
3. **NEVER reset.** `git reset`, `git checkout .`, `git restore .` will destroy another agent's work. Forbidden.
4. **NEVER rebase.** Rewriting history while other agents are committing will cause chaos. Forbidden.
5. **Own your files.** Only modify files assigned to your task. If you discover you need to touch a file assigned to another task, STOP and report the conflict to the orchestrator.
6. **Wait if needed.** If your task depends on another agent's output (e.g., a shared type definition), wait for that agent to finish. Use `inotifywait` on the expected file, or poll with short sleeps (5s intervals, max 2 minutes), or simply report the dependency to the orchestrator.
</HARD-GATE>

### Wave Planning

Before dispatching, organize tasks into waves of parallel work:

1. **Identify file ownership** — for each task, list every file it will create or modify
2. **Check for overlaps** — if two tasks touch the same file, they CANNOT be in the same wave
3. **Check for dependencies** — if task B needs task A's output, B goes in a later wave
4. **Group into waves** — tasks in the same wave run in parallel, waves run sequentially

Present the wave plan to the user during mode selection:

```
Wave 1 (parallel): Task 1 (src/auth/), Task 3 (src/billing/), Task 5 (tests/e2e/)
Wave 2 (parallel): Task 2 (src/api/ — depends on Task 1), Task 4 (src/billing/reports/ — depends on Task 3)
Wave 3 (sequential): Task 6 (integration — touches files from waves 1-2)
```

### Per-Wave Dispatch

For each wave:

1. Dispatch all wave's implementer subagents simultaneously
2. Each agent gets:
   - Full task text + context
   - **Explicit list of files they own** (and may modify)
   - **The shared worktree safety rules** (copy the HARD-GATE above into the prompt)
   - Any existing wisdom files from `.jk-work/`
3. Wait for all agents in the wave to complete
4. Run per-task review for each completed task (spec + quality)
5. Merge wisdom files, proceed to next wave

### Per-Agent Wisdom

Each agent writes its learnings to `.jk-work/<plan-slug>/wisdom-task-N.md` (where N is the task number). No shared file — no race conditions.

Later waves read all existing `.jk-work/<plan-slug>/wisdom-task-*.md` files before beginning.

### Per-Task Review

After each implementer completes:
1. Dispatch spec compliance reviewer
2. If spec fails → dispatch fix subagent → re-review
3. Dispatch code quality reviewer
4. If quality fails → dispatch fix subagent → re-review

### Coordinator

After all waves complete:
1. Merge all `.jk-work/<plan-slug>/wisdom-task-*.md` files into `.jk-work/<plan-slug>/wisdom.md`
2. Report completion status for all tasks
3. Report any failures or issues

**No round table in Swarm mode** — there's no single coherent diff to review when work happened across waves.

### Finish

> **REQUIRED SUB-SKILL:** Use jk-skills:jk-prove-it

---

## Care Mode

### Per-Task Execution

Same as Deep mode: subagent per task, sequential, per-task review pipeline, wisdom accumulation in `.jk-work/<plan-slug>/wisdom.md`.

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

**All implementer prompts** (both standard and swarm) must include the Plan Context and Escalation & Report sections below.

### Shared: Plan Context (include in all implementer prompts)

Give each implementer situational awareness without dumping the full plan. The orchestrator constructs this section from the plan:

```
## Plan Context
**Goal:** [one-sentence goal from plan header]
**Architecture:** [2-3 sentences: key components, how they relate, tech stack]
**File structure:** [list of files being created/modified across the whole plan, with one-line purpose each]
**Your task:** Task N of M
**Before you:** [what tasks already completed and what they produced — or "first task"]
**After you:** [what tasks come next and what they need from you — or "last task"]
**Cross-task conventions:** [naming patterns, shared types, import conventions discovered so far]
```

This is NOT the full plan text — it's a summary the orchestrator writes. Keep it tight. The implementer gets full detail for their own task but only situational awareness of the rest.

### Shared: Escalation & Report (append to all implementer prompts)

```
## When You're in Over Your Head

It is always OK to stop and say "this is too hard for me." Bad work is worse than
no work. You will not be penalized for escalating.

**STOP and escalate when:**
- The task requires architectural decisions with multiple valid approaches
- You need to understand code beyond what was provided and can't find clarity
- You feel uncertain about whether your approach is correct
- The task involves restructuring existing code in ways the plan didn't anticipate
- You've been reading file after file trying to understand the system without progress

**How to escalate:** Report back with status BLOCKED or NEEDS_CONTEXT. Describe
specifically what you're stuck on, what you've tried, and what kind of help you need.
The orchestrator can provide more context, re-dispatch with a more capable model,
or break the task into smaller pieces.

## Report Format
- **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
- What you implemented (or what you attempted, if blocked)
- **Plan diversions**: anything you did differently from the plan and why. If none, say "none."
- What you tested and results
- Files changed
- Self-review findings
- Wisdom learned (conventions, gotchas, patterns discovered)

Use DONE_WITH_CONCERNS if you completed the work but have doubts about correctness.
Use BLOCKED if you cannot complete the task. Use NEEDS_CONTEXT if you need
information that wasn't provided. Never silently produce work you're unsure about.
```

### Implementer

```
You are implementing Task N: [task name]

## Task Description
[FULL TEXT of task from plan]

[INSERT: Plan Context section]

## Accumulated Wisdom
[All wisdom from previous tasks — conventions, gotchas, patterns]

## Before You Begin
If you have questions about requirements, approach, dependencies, or anything unclear — ask now.

## Your Job
1. Implement exactly what the task specifies
2. Follow TDD: write failing test first, then implement, then refactor. Use jk-skills:test-driven-development.
3. Verify implementation works
4. Commit your work
5. Self-review: completeness, quality, discipline, testing
6. If you find issues during self-review, fix them before reporting

[APPEND: Escalation & Report section]
```

### Swarm Implementer

```
You are implementing Task N: [task name]

## CRITICAL: Shared Worktree
You are ONE OF SEVERAL agents working in the SAME worktree simultaneously. Other agents are modifying other files right now. Follow these rules exactly:

- **Atomic commits only:** `git add <your-specific-files> && git commit -m "..."` — NEVER `git add .` or `git add -A`
- **NEVER stash** — `git stash` will capture other agents' changes
- **NEVER reset/restore/checkout .** — this destroys other agents' work
- **NEVER rebase** — rewriting history while others commit causes chaos
- **Only touch YOUR files:** [list of assigned files]
- **If you need a file not on your list**, STOP and report the conflict — do not modify it

## Task Description
[FULL TEXT of task from plan]

## Your Assigned Files
You may ONLY create or modify these files:
[explicit file list]

[INSERT: Plan Context section]

## Accumulated Wisdom
[All wisdom from previous tasks — conventions, gotchas, patterns]

## Dependencies
[If waiting on another agent: "Task M must finish first. Wait for [file/condition] to exist before proceeding. Use: inotifywait -e close_write [path] or poll with 5s sleeps, max 2 minutes."]

## Your Job
1. Implement exactly what the task specifies
2. Follow TDD: write failing test first, then implement, then refactor. Use jk-skills:test-driven-development.
3. Verify implementation works
4. Commit ONLY your files: `git add [your files] && git commit -m "task N: [description]"`
5. Self-review: completeness, quality, discipline, testing
6. If you find issues during self-review, fix them before reporting

[APPEND: Escalation & Report section]
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

Dispatch the code-reviewer agent using the process from jk-skills:jk-code-review. Fill the template with the current task's context.

---

## Integration

- **jk-skills:jk-plan** creates the plan this skill executes
- **jk-skills:jk-prove-it** is REQUIRED at the end of every mode
- **jk-skills:verification-before-completion** is invoked by jk-prove-it
- **jk-skills:jk-finish-branch** for merge/push decision after prove-it
- **jk-skills:jk-code-review** — per-task code quality review dispatch
- **jk-skills:test-driven-development** — subagents should follow TDD for each task
