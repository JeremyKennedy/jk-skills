---
name: jk-remember
description: "Use when the user says 'remember this', wants to persist a learning, or at the end of significant work — reflects on how to make things better for future sessions, routes knowledge to CLAUDE.md, docs/, or auto memory."
---

# Remember

**Announce at start:** "I'm using the jk-remember skill to reflect on what we've learned."

Step back and reflect on how to make future sessions better. Persist knowledge to the right place, fix stale documentation, flag process improvements. Can be invoked mid-session with specific context, or on a blank session for a general audit.

## When to Use

- User says "remember this" or "save this"
- End of a significant work session
- After discovering something non-obvious
- On a blank session: general documentation audit and improvement
- When invoked by jk-execute at persistence checkpoints

## The Three Destinations

| Destination | What belongs here | Examples |
|-------------|------------------|----------|
| **CLAUDE.md** | Conventions, commands, gotchas, references to docs/. Every line costs context window, but multi-line entries and sections are fine when justified. | `just test-unit` requires Docker / See docs/api.md for pagination patterns |
| **docs/** | Domain knowledge, decisions, reference material. Can be long and detailed, organized by topic. | API pagination patterns / why we chose Postgres / deployment quirks |
| **Auto memory** | User preferences, collaboration style — about the person, not the project | User prefers Swarm mode / wants terse responses |

**Routing test:** Would a different person working on this project need this?
- Yes → CLAUDE.md or docs/
- No → auto memory

Does it need depth or is a line enough?
- One-liner or reference → CLAUDE.md
- Needs explanation → docs/

### CLAUDE.md Rules

CLAUDE.md is part of every prompt. Not off-limits, but every addition should be justified.

**Belongs:** project-specific conventions, commands, gotchas, doc references, things where a wrong assumption causes real problems, things not derivable from the code.

**Doesn't belong:** generic advice, things obvious from the code or `just --list`, deep explanations better in docs/, anything already covered.

Use judgment. A three-line gotcha section is fine. A page of API docs is not — put that in docs/ and reference it.

## Depth

jk-remember scales from a quick checkpoint to a full documentation audit. Match the depth to the situation.

**Quick** — invoked by jk-execute at a persistence checkpoint, or user wants to save one specific thing. Skim conversation context, route the obvious stuff, done in under a minute. No subagents.

**Standard** — end of a work session. Reflect on the full conversation, check CLAUDE.md and docs/ for staleness, present changes. A few minutes.

**Deep** — user explicitly wants a thorough review, or it's the end of a major effort. Dispatch subagents to audit CLAUDE.md quality, review docs/ coverage, check for stale commands, scan recent git history. Can take a while.

**Background execution:** Standard and deep modes can run as background tasks when they shouldn't block the main work. If invoked from jk-plan or jk-execute at a checkpoint, dispatch the doc review work in the background and continue with execution. Present results when the background task completes. Quick mode is fast enough to run inline.

**How to decide:** Use judgment based on the scope of work. A small bugfix might warrant quick. A complex multi-file execution might warrant standard or even deep. If you're unsure, ask:

> "How thorough do you want me to be? Quick save of what we learned, standard review of docs, or deep audit of all project documentation?"

## Process

### 1. Gather Context

**If mid-session** — reflect on the full conversation:
- What context was missing at the start that would have made this work faster?
- What was surprising or non-obvious?
- What conventions or patterns emerged?
- What decisions were made and why?

**If blank session** — audit the project's documentation health:
- Read CLAUDE.md. Is anything stale, wrong, or missing?
- Run `tree docs/`. Is knowledge organized well? Any obvious gaps?
- Check recent git history. Were there recent changes that should be documented?
- Look for red flags: commands that would fail, references to deleted files, outdated paths, TODOs never completed, generic advice that wastes context window.

**In either case**, also check:
- Did any tool calls fail during this session? Each failed tool call is a signal:
  - Missing documentation (command wasn't documented, path was wrong)
  - Missing tooling (a better CLI command or API would prevent this class of failure)
  - Stale docs (documented command no longer works)

  Surface these to the user — sometimes the fix is better docs, sometimes it's a better tool or script.

### 2. Filter

Skip:
- Things obvious from the code
- One-off fixes unlikely to recur
- Generic best practices
- Transient state
- Things already well-documented

Saving nothing is a valid outcome. Don't save things just because the skill was invoked.

### 3. Route

**Check existing structure first.** Run `tree docs/` and read CLAUDE.md.

For docs/ updates: read the target file and **integrate the learning into the existing structure.** If the document would benefit from reorganization, rewrite the relevant sections. The goal is a coherent document, not an append log.

For CLAUDE.md updates: find the right section. Add concise, justified content.

For new doc files: only if the topic is substantial and doesn't fit in an existing file.

### 4. Present

Show the user what you want to change and where, with diffs and reasoning:

```
### CLAUDE.md
**Why:** Missing convention caused a debugging detour.
 ## Testing
+`just test-unit` — requires Docker running (DB tests hit real Postgres)

### docs/api-patterns.md (rewritten section)
**Why:** Pagination pattern undocumented.
[Show the integrated section]

### Auto Memory
- User prefers opus for code review agents

### Process Suggestions
- Tool call `just deploy-staging` failed — command doesn't exist.
  Consider adding a deploy script or documenting the actual deploy process.
```

### 5. Apply

Only after user approval.
