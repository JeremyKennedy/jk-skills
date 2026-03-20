---
name: jk-remember
description: "Use when the user says 'remember this', wants to persist a learning, or at the end of significant work — smart routing to CLAUDE.md, docs/, or auto memory based on what the knowledge is."
---

# Remember

**Announce at start:** "I'm using the jk-remember skill to persist what we've learned."

Persist knowledge to the right place. Not everything is worth saving, and different knowledge belongs in different places. Reflects on all available context — not just the last message.

## When to Use

- User explicitly says "remember this" or "save this"
- End of a significant work session
- After discovering something non-obvious about the project
- When the user asks "what have we learned?"

## The Three Destinations

| Destination | What belongs here | Bar | Examples |
|-------------|------------------|-----|----------|
| **CLAUDE.md** | Commands, conventions, gotchas that shape how every agent works in this codebase. Every line costs context window. | **Highest.** Must be concise, project-specific, actionable, and not derivable from the code. Would a wrong assumption here cause real damage? Then it earns a line. | `just test-unit` requires Docker / Auth: JWT with HS256 |
| **docs/** | Domain knowledge, technical decisions, reference material. Can be long, detailed, organized by topic. | **Medium.** Worth writing if it would save a future agent or human significant time. | API pagination patterns / why we chose Postgres / deployment quirks |
| **Auto memory** | User preferences, collaboration style — things about the person, not the project | **Low.** Save freely. Private, no context window cost. | User prefers Swarm mode / wants terse responses |

**Decision test:** "Would a different person working on this project need to know this?"
- Yes → CLAUDE.md or docs/
- No → auto memory

"Does this earn a line in every future session's context window?"
- Yes, and it's concise → CLAUDE.md
- It needs explanation or depth → docs/

### CLAUDE.md Rules

CLAUDE.md is part of every prompt — every line has a context window cost. But it's not off-limits. Multi-line entries, references to docs/, even short sections are fine when justified.

**What belongs in CLAUDE.md:**
- Project-specific conventions, commands, gotchas
- References to docs/ files as an index ("see docs/api.md for API patterns")
- Anything where a wrong assumption would cause real problems
- Things not derivable from reading the code

**What doesn't:**
- Generic advice ("write tests", "use meaningful names")
- Things obvious from the code or `just --list`
- Deep explanations better suited to docs/
- Anything already covered

Use judgment. A three-line section about a critical gotcha is fine. A page of API documentation is not — put that in docs/ and add a one-line reference in CLAUDE.md.

## Process

### 1. Gather Context

Reflect on the full conversation:
- What context was missing at the start that would have made this work faster or better?
- What was surprising or non-obvious?
- What conventions or patterns emerged?
- What decisions were made and why?
- Are any documented commands, paths, or conventions now stale because of this work?

### 2. Filter

Skip:
- Things obvious from reading the code
- One-off fixes unlikely to recur
- Generic best practices
- Transient state
- Things already documented

### 3. Route

**Check existing structure first.** Run `tree docs/` and read CLAUDE.md.

For docs/ updates: **read the target file and integrate the learning into the existing structure.** Don't just stick it at the end. If the document would benefit from reorganization to accommodate the new knowledge, rewrite the relevant sections. The goal is a coherent document, not an append log.

For CLAUDE.md updates: find the right section, add a single concise line. If no section fits, consider whether it really belongs in CLAUDE.md.

For new doc files: only if the topic is substantial enough to warrant one and doesn't fit in an existing file.

### 4. Present

Show the user what you want to save and where, with diffs and reasoning:

```
### CLAUDE.md
**Why:** Missing convention caused a 10-minute debugging detour.
 ## Testing
+`just test-unit` — requires Docker running (DB tests hit real Postgres)

### docs/api-patterns.md (update)
**Why:** Pagination pattern not documented, discovered during debugging.
[Show the rewritten section, not just an append]

### Auto Memory
- User prefers opus for code review agents
```

### 5. Apply

Only after user approval.

## Deciding to Save Nothing

Valid and often correct. If the work was routine with no surprises, say so and move on. Don't save things just because the skill was invoked.
