---
name: jk-remember
description: "Use when the user says 'remember this', wants to persist a learning, or at the end of significant work — routes knowledge to agent instructions, docs/, or auto memory"
---

# Remember

Persist what was learned so future sessions benefit. Route knowledge to the right place, fix stale documentation, flag process improvements.

## When to Use

- User says "remember this" or "save this"
- End of significant work
- After discovering something non-obvious that future sessions would need

## The Three Destinations

| Destination | What belongs here |
|---|---|
| **Agent instructions** | Conventions, commands, gotchas, doc references — things where a wrong assumption causes real problems |
| **docs/** | Domain knowledge, decisions, reference material — needs depth or explanation |
| **Auto memory** | User preferences, collaboration style — about the person, not the project |

**Routing test**: Would a different developer need this? Yes → agent instructions or docs/. No → auto memory.

**Depth test**: One-liner or reference → agent instructions. Needs explanation → docs/.

## Process

### Gather
Reflect on the session: what was missing at the start? What was surprising? What decisions were made and why? Check agent instructions and docs/ for staleness. Check for tool failures that signal missing documentation.

### Filter
Skip: things obvious from code, one-off fixes, generic advice, transient state, things already documented. Saving nothing is valid.

### Route
Integrate into existing structure — never append blindly. For docs/, rewrite the relevant section. For agent instructions, find the right section and add concise, justified content. New files only when the topic is substantial and doesn't fit existing structure.

### Present and Apply
Show what changed with reasoning, then apply after user approval.
