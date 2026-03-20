---
name: jk-plan
description: "Use when starting non-trivial work — deep interview, codebase research, adversarial review panel, implementation plan. Use jk-brainstorm for lighter ideation."
---

# Deep Plan

**Announce at start:** "I'm using the jk-plan skill for heavy-weight planning."

Heavy-weight planning that front-loads tokens into understanding before any code is written. Research, interview with hard gates, design, adversarial review panel that cycles until diminishing returns, then implementation plan.

For small/quick changes, skip this skill — use jk-skills:jk-brainstorm or just start building.

> **REQUIRED SUB-SKILL:** Use jk-skills:jk-philosophy


**The philosophy governs every phase of planning.** Code is free, expand scope relentlessly, refactor always, envision the ideal end state. During the interview, push for the ambitious version. During design, don't settle for "good enough." During review, treat every real issue as worth fixing. Read the philosophy and keep it in mind — it's not just a preamble.

## Model Selection

Choose `haiku`, `sonnet`, or `opus` for subagents based on what the task demands:

| Signal | Haiku | Sonnet | Opus |
|--------|-------|--------|------|
| **Reasoning** | None — mechanical, no judgment | Some — following patterns, clear criteria | Deep — novel design, ambiguous tradeoffs |
| **Risk** | Zero — output is trivially verifiable | Low — reviewer can catch it, easily re-run | High — wrong answer cascades, hard to detect |
| **Task type** | File listing, formatting, grep-and-summarize | Exploration, convention checking, focused review | Design, root-cause analysis, adversarial review |

**In this skill:**
- **Phase 1 research agents** → `sonnet` — exploration and summarization, no design decisions
- **Phase 4 design architects** → `opus` — creative design work with real tradeoffs
- **Phase 5 review panel** → mixed per reviewer (see table below)

**Default:** Lean towards heavier models — this is heavyweight planning where getting it right matters more than token cost. Use `opus` unless the task is clearly mechanical. `sonnet` for focused work with clear criteria. `haiku` only for truly mechanical subtasks (file listing, formatting).

## Hard Gates

<HARD-GATE>
You may NOT write any implementation code, invoke any implementation skill, or transition to execution until ALL of the following are true:

1. **Codebase researched** — you have explored relevant files, patterns, and conventions
2. **Interview complete** — all 5 clearance criteria pass (see below)
3. **Intent classified** — work type confirmed with user (new feature / refactoring / bug fix / architecture)
4. **Design doc written and approved** — saved to `docs/plans/YYYY-MM-DD-<topic>-design.md`
5. **Review panel passed** — at least one cycle with no Critical/Important issues
6. **Implementation plan written** — saved to `docs/plans/YYYY-MM-DD-<topic>.md`

No exceptions. Not for "simple" tasks. Not for "obvious" changes. If it's simple, skip this skill entirely.
</HARD-GATE>

## Process

### Phase 1: Research (parallel exploration)

Before asking the user a single question, understand the landscape from multiple angles.

Launch **2-3 code-explorer agents in parallel** (model: `sonnet` — exploration, no decisions), each with a different focus. Each agent should trace through code comprehensively and return a list of 5-10 key files to read.

**Example agent focuses** (adapt to the task):

| Focus | Prompt |
|-------|--------|
| **Similar features** | "Find features similar to [X] and trace their implementation — patterns, abstractions, data flow" |
| **Architecture** | "Map the architecture and abstractions for [area] — layers, boundaries, integration points" |
| **Existing implementation** | "Analyze the current implementation of [related area] — how it works, what it depends on, what could break" |

After agents return:
- **Read all key files they identified** — build deep context, not just summaries
- Read project CLAUDE.md, docs/, and recent git history
- If external technologies are involved, research them (web search, Context7)
- Identify: what exists, what's adjacent, what conventions apply, what could break

**Output:** Mental model of the codebase. Do NOT write a research doc — internalize it and use it to ask better questions.

### Phase 2: Classify Intent

Before interviewing, classify the work type. This changes how you interview:

| Intent | Interview emphasis | Key questions |
|--------|-------------------|---------------|
| **New feature** | Discovery, patterns, boundaries | "I found pattern X in module Y — follow or deviate?" / "What's the MVP vs. full vision?" |
| **Refactoring** | Safety, preservation, migration | "What tests verify current behavior?" / "Can this be done incrementally?" / "What breaks if we're wrong?" |
| **Bug fix** | Root cause, reproduction, regression | "Can you reproduce reliably?" / "When did this last work?" / "What changed?" |
| **Architecture** | Strategic impact, longevity, scale | "Expected lifespan?" / "What's the 10x scale scenario?" / "What do we want to be easy to change later?" |

State the classification to the user and confirm before proceeding. If ambiguous (e.g., "fix this by rewriting it"), ask which lens to use.

### Phase 2.5: Scope Check

Before interviewing in detail, assess scope. If the request describes multiple independent subsystems (e.g., "build a platform with chat, file storage, billing, and analytics"), flag this immediately. Don't spend interview questions refining details of a project that needs decomposition first.

If the project is too large for a single plan, help the user decompose into sub-projects: what are the independent pieces, how do they relate, what order should they be built? Then plan the first sub-project through the normal flow. Each sub-project gets its own design → plan → implementation cycle.

### Phase 3: Interview

Interview the user until you have enough clarity to design. These criteria guide the interview — not every plan needs all five at the same depth. A focused refactor might not need a test strategy discussion if the existing tests are clear. A new feature definitely does. Use judgment, but don't skip criteria without a reason.

| # | Criterion | What "pass" means |
|---|-----------|-------------------|
| 1 | **Objective defined** | You can state the goal in one sentence and the user agrees |
| 2 | **Scope established** | Clear boundaries — what's in, what's out, what's deferred |
| 3 | **Ambiguities resolved** | No "it depends" or "we'll figure it out later" remaining |
| 4 | **Technical approach decided** | Architecture, key patterns, data flow — all settled |
| 5 | **Test strategy confirmed** | What gets tested, how, what "done" looks like |

**Interview rules:**
- One question at a time. Multiple choice when possible.
- Adapt questions to the intent classification (see above).
- Use your research to ask INFORMED questions — "I see you use X pattern in Y module, should we follow that here or is there a reason to diverge?"
- Challenge quick answers to complex questions. Probe edge cases.
- Follow the user's energy — if they elaborate, go deeper on that topic.
- Ask "what happens when X fails?" for every integration point.
- Do NOT accept "whatever you think is best" for architectural decisions. Push back with tradeoffs and force a choice.
- Stop when all 5 criteria pass. Not before. If the user says "just do it," tell them which criteria haven't passed and ask the specific question that would resolve it.

### Phase 4: Design Doc

For non-obvious architectural decisions, launch **2-3 code-architect agents in parallel** (model: `opus`) with different design philosophies. Each agent independently designs a full approach without seeing the others — this avoids anchoring bias.

| Architect | Philosophy |
|-----------|-----------|
| **Minimal** | Smallest change, maximum reuse of existing code and patterns |
| **Clean** | Best architecture, elegant abstractions, long-term maintainability |
| **Pragmatic** | Balance of speed and quality, practical tradeoffs |

After architects return:
1. Synthesize their approaches — summarize each with concrete implementation differences
2. Form your recommendation with reasoning
3. Present to user: approaches, tradeoffs, your recommendation
4. Get the user's choice before writing the design doc

Present the design in sections, scaled to complexity. Get approval after each section.

Cover: architecture, components, data flow, error handling, testing approach, file locations.

**Save to:** `docs/plans/YYYY-MM-DD-<topic>-design.md`
**Commit** the design doc.

**Audience:** The design doc is for agents. Be thorough — exact file paths, data flow, error handling, integration points. Agents will read this to understand what to build. The user participates during the interview and sees the plan presentation later; they are not expected to read the doc on disk.

### Phase 5: Review Panel

Launch 4-6 reviewer subagents **in parallel** to tear apart the design. Each reviewer is a fresh agent with no sunk cost in the plan.

**All reviewers:**
- Type: `general-purpose`
- Tools: Read, Grep, Glob (read-only)
- Must read the design doc AND the project CLAUDE.md
- Must explore relevant codebase areas
- Output: verdict (PASS/FAIL) + issues list, each with severity (Critical/Important/Minor) and a suggested fix

**The panel:**

| Reviewer | Model | Prompt focus |
|----------|-------|-------------|
| **Gaps** | `opus` | What's missing? Requirements implied but not addressed? Error cases not handled? Features mentioned but not designed? |
| **Assumptions** | `opus` | What does the plan assume that might not be true? What's fragile? What could change? What external dependencies could break? |
| **Edge Cases** | `opus` | Empty input, concurrent access, partial failure, network errors, scale (10x and 0.1x), race conditions, data corruption |
| **Conventions** | `sonnet` | Does the plan follow project CLAUDE.md? Correct file locations, naming patterns, config patterns, error handling, testing patterns? |
| **Security** | `opus` | Injection vectors, auth gaps, secret handling, unsafe defaults, OWASP top 10, supply chain concerns |
| **Simplicity** | `sonnet` | Is any part over-engineered? Could anything be done more simply? Are there unnecessary abstractions? YAGNI violations? |

Model rationale: Gaps, Assumptions, Edge Cases, and Security require deep judgment about what *could* go wrong — hard to verify if the reviewer misses something. Conventions and Simplicity have clear, checkable criteria against the CLAUDE.md and codebase.

#### Triage

After all reviewers return:

1. Collect all issues. Group by severity.
2. **Critical/Important** → present to user, discuss, update the design doc
3. **Minor** → fix if trivial, otherwise note and move on
4. **Reviewer disagreements** → use your judgment, document the decision

**When a fix contradicts a user decision:**
If the review panel flags something the user explicitly decided during the interview, do NOT silently change it. You can fix minor issues on your own, but if a fix reverses or significantly alters something the user said they wanted, you MUST either ask the user before changing it OR — if you judge it's clearly the right call — make the change but record it as a **plan diversion** that will be highlighted in the final presentation. The user will see it before approving execution.

Track all diversions from user decisions in a running list. These get surfaced in Phase 7.

#### Re-Cycle

After fixing issues, run three categories of reviewers:

1. **Failed dedicated agents** — Re-run the reviewers that found Critical/Important issues, to verify fixes.
2. **Delta agent** — A new reviewer focused on second-order effects. Prompt: "Here is the design doc diff since last cycle and a summary of what was flagged and fixed. What new issues do these changes introduce? Look for second-order effects: a fix in one area creating problems in another, shifted assumptions, new gaps, new complexity." Give it the diff AND a short summary of each fix (issue → resolution).
3. **Free agent** — A new reviewer with no assigned domain and no access to previous reviewer outputs. Prompt: "You are a fresh reviewer with no assigned domain. Review this design for any issues — correctness, completeness, consistency, elegance, anything. You are specifically valuable because the dedicated reviewers each have a narrow lens. Find what they missed." Give it only the current design doc and project CLAUDE.md. Do NOT show it previous cycle results — avoid anchoring.

Scale the re-cycle to the severity of what was found. If only one dedicated agent failed on a minor point, re-running just that agent may be enough. If major issues were found across multiple domains, the full three-category re-cycle is warranted. Use judgment.

**Stop condition:** A cycle produces no Critical/Important issues. Minor-only means the design is solid.

**Maximum:** 3 cycles. If still failing after 3, escalate to the user.

#### Evidence

Append review summary to the design doc:

```markdown
---

## Review Notes

Reviewed: YYYY-MM-DD
Cycles: N
Key decisions:
- [decision from review discussion]
- [decision from review discussion]

Issues found and resolved:
- [issue] → [resolution]

Diversions from user decisions (if any):
- [what user said] → [what changed and why]
```

### Phase 6: Implementation Plan

**File structure first.** Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in:

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- Prefer smaller, focused files over large ones. Agents reason better about code they can hold in context, and edits are more reliable when files are focused.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If a file has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition — each task should produce self-contained changes that make sense independently.

**Then write tasks:**

- Bite-sized tasks (2-5 min each)
- Exact file paths, complete code, exact commands with expected output
- TDD: write test → verify fail → implement → verify pass → commit
- Plan header with Goal / Architecture / Tech Stack

**Save to:** `docs/plans/YYYY-MM-DD-<topic>.md`
**Commit** the plan.

**Audience:** The implementation plan is for agents. Be maximally detailed — exact code, exact commands, exact expected output. Agents executing tasks will read this verbatim. The user sees a summarized version in the CC plan presentation (handled by jk-execute), not this document.

**Plan review loop:** After writing the plan, dispatch a single plan reviewer (model: `sonnet` — clear criteria, checkable against the design doc):

```
You are a plan document reviewer. Verify this plan is complete and ready for execution.

**Plan to review:** [PLAN_FILE_PATH]
**Design doc:** [DESIGN_FILE_PATH]

Check for:
| Category | What to look for |
|----------|-----------------|
| Completeness | TODOs, placeholders, missing steps, gaps between design and plan |
| Consistency | Plan contradicts design doc, steps reference non-existent files |
| Executability | Steps too vague to execute, missing verification commands, unclear expected output |
| File coverage | Design specifies files/components not covered by any task |
| Task ordering | Dependencies between tasks not reflected in ordering |

Only flag issues that would cause real problems during execution. Approve unless there are serious gaps.

Output: **Status:** Approved | Issues Found, then issues list if any.
```

If issues found → fix and re-dispatch (max 3 iterations). If the reviewer keeps failing, surface to user.

### Phase 6.5: Diversion Report

If any diversions from user decisions were recorded during the review panel (see Phase 5 Triage), present them to the user now — before handing off to execution. This is their last chance to catch changes they didn't explicitly approve.

```
### Changes from what we discussed

During the review panel, the design was adjusted in ways that differ from what you originally asked for:

- **[Topic]**: You said [X], but the review found [Y], so the design now does [Z].
- ...

These are already in the design doc. Let me know if any of these should be reverted before we proceed.
```

If there are no diversions, skip this phase. Do not present an empty report.

### Phase 7: Execution Handoff

jk-plan ends here. Save all documents to disk, verify they exist, commit them.

**Update the plan index.** Add or update an entry in `docs/plans/INDEX.md` (create if it doesn't exist):

```markdown
| Plan | Status | Date | Summary |
|------|--------|------|---------|
| [plan-name](YYYY-MM-DD-topic.md) | planned | YYYY-MM-DD | One-line summary |
```

Statuses: `planned` → `in-progress` → `complete` / `abandoned`. jk-execute updates status during execution.

**Persist learnings.** Invoke `jk-skills:jk-remember` (quick depth) — planning sessions generate project knowledge from the interview (decisions, constraints, domain context). This can run in the background while handing off to execution.

Then invoke `jk-skills:jk-execute` with the plan file path. jk-execute handles everything from here — evaluating context, choosing execution mode, presenting the plan to the user, and executing.
