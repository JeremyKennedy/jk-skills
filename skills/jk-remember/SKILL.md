---
name: jk-remember
description: "Use when the user says 'remember this', wants to persist a learning, or at the end of significant work — smart routing to CLAUDE.md, docs/, or auto memory based on what the knowledge is."
---

# Remember

**Announce at start:** "I'm using the jk-remember skill to persist what we've learned."

Intelligently persist knowledge to the right place. Not everything is worth saving, and different knowledge belongs in different places. This skill reflects on all available context — not just the last message — and routes accordingly.

## When to Use

- User explicitly says "remember this" or "save this"
- End of a significant work session (planning, debugging, building)
- After discovering something non-obvious about the project
- When the user asks "what have we learned?"

## The Three Destinations

| Destination | What belongs here | Audience | Examples |
|-------------|------------------|----------|----------|
| **CLAUDE.md** | Project conventions, commands, architecture, gotchas — things that shape how ANY agent works in this codebase | Every future session | "Tests must run with `--runInBand`" / "Auth uses JWT with HS256" |
| **docs/** | Domain knowledge, technical decisions, reference material — deeper than CLAUDE.md, organized by topic | Agents and humans who need depth | "The API paginates at 100, loop with cursor" / "We chose Postgres over SQLite because..." |
| **Auto memory** | User preferences, collaboration style, personal context — things about the PERSON, not the project | This user's future sessions only | "User prefers Swarm mode" / "User wants terse responses" |

**Decision test:** "Would a different person working on this project need to know this?"
- Yes → CLAUDE.md or docs/ (project knowledge)
- No → auto memory (user knowledge)

"Is this a one-liner or does it need context/depth?"
- One-liner → CLAUDE.md
- Needs explanation → docs/

## Process

### 1. Gather Context

Don't just look at the last message. Reflect on the full conversation:
- What was discovered during this work?
- What was surprising or non-obvious?
- What would have saved time if we'd known it at the start?
- What conventions or patterns emerged?
- What decisions were made and why?

### 2. Filter

Not everything is worth saving. Skip:
- Things obvious from reading the code
- One-off fixes unlikely to recur
- Generic best practices (not project-specific)
- Transient state (current branch, WIP status)
- Things already documented

### 3. Route

For each item worth saving, decide the destination:

**Check existing docs first.** Run `tree docs/` and read CLAUDE.md. Does a relevant file already exist?
- If CLAUDE.md already has a section for this topic → update that section
- If a doc file covers this topic → append there
- If nothing fits and it's substantial → consider a new doc file
- If nothing fits and it's a one-liner → CLAUDE.md

For CLAUDE.md updates, follow the claude-md-improver principles:
- Keep it concise — one line per concept
- Make commands copy-paste ready
- Only project-specific info, never generic advice
- Every line must earn its place in the context window

### 4. Present

Show the user what you want to save and where, with diffs:

```
## Knowledge to Persist

### CLAUDE.md
**Why:** Build command wasn't documented, caused confusion.
```diff
 ## Commands
+`just test-unit` — Run unit tests (requires Docker for DB)
```

### docs/api-patterns.md (existing file)
**Why:** Pagination pattern discovered during debugging.
```diff
+## Pagination
+The API returns max 100 items. Use `cursor` param to paginate:
+`GET /api/items?cursor=<last_id>`
```

### Auto Memory
- User prefers opus for code review agents
```

### 5. Apply

Only after user approval. Use Edit tool for CLAUDE.md and docs/, auto memory system for user preferences.

## Deciding to Save Nothing

It's valid — and often correct — to decide nothing is worth persisting. If the session was routine work with no surprises, say so:

> "I reviewed the session and don't see anything worth persisting. The work was straightforward and the relevant context is already in the code and docs."

Don't save things just because the skill was invoked.

## Integration with Other Skills

- **jk-execute** runs knowledge promotion automatically after execution — that handles the bulk of post-execution persistence
- **jk-remember** is for explicit, user-triggered persistence or mid-session saves
- **jk-reflect** pairs well — reflect first, then remember what was learned
- **claude-md-management:revise-claude-md** does session-end CLAUDE.md updates — jk-remember is broader (routes to all three destinations) and can be used mid-session
