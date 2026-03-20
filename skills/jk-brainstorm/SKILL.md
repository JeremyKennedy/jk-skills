---
name: jk-brainstorm
description: "Use when exploring ideas before committing to a direction — lightweight conversational ideation, no code, no design docs."
---

<!-- Derived from superpowers v4.3.1: brainstorming, visual companion from v5.0.5 -->

# Brainstorm

**Announce at start:** "I'm using the jk-brainstorm skill — let's explore ideas."

Collaborative ideation mode. Chat, explore, refine ideas. No structure, no gates, no design docs. This is the "let's think about this" phase before you decide whether something needs full planning (jk-plan) or can just be built.

## When to Use

- Vague idea, not sure what to build yet
- Multiple approaches, want to explore tradeoffs
- Need to think out loud before committing to a direction
- "What if we..." / "How would you approach..." / "I'm thinking about..."

## When NOT to Use

- You already know what to build → use jk-plan or just start
- You have a clear bug → use systematic-debugging
- You're ready to execute → use jk-execute

## How It Works

**Be conversational.** This is a dialogue, not a process.

1. **Understand context** — Quickly scan relevant code, docs, recent commits. Build a mental model.
2. **Ask questions** — One at a time. Multiple choice when possible. Follow the user's energy.
3. **Explore approaches** — When you have enough context, propose 2-3 approaches with tradeoffs. Lead with your recommendation.
4. **Iterate** — The user will push back, refine, redirect. Go with it. Ask follow-ups. Probe edge cases.
5. **Crystallize** — When an approach solidifies, summarize it clearly: what we're building, how, and why.

## Visual Companion

When upcoming questions involve visual content (mockups, layouts, diagrams), offer the browser companion:

> "Some of what we're working on might be easier to show visually in a browser — mockups, diagrams, layout comparisons. Want to try it? (Requires opening a local URL)"

**This offer must be its own message.** Don't combine it with other questions. If they decline, continue text-only.

After acceptance, decide **per question** whether to use the browser or terminal. The test: would the user understand this better by **seeing** it than reading it? Use the browser for visual content (wireframes, layout comparisons, architecture diagrams). Use the terminal for text content (requirements, tradeoffs, scope decisions).

See `references/visual-companion.md` for the full setup, CSS classes, and interaction loop.

## Rules

- **One question per message.** Don't overwhelm.
- **Follow energy.** If the user digs into a topic, go deeper. Don't redirect to your agenda.
- **Challenge quick answers to complex questions.** "Whatever you think" is not an answer to an architectural decision — push back with tradeoffs.
- **No implementation.** Don't write code, create files, or scaffold anything. Ideas only.
- **No design docs.** This isn't jk-plan. If the idea needs formal planning, suggest transitioning to jk-plan at the end.

## Ending a Brainstorm

When ideas have crystallized, offer the next step:

```
We've landed on [summary]. Want to:
1. Start building (simple enough to just go)
2. Plan it formally (/jk-plan)
3. Keep exploring
```

Don't push toward planning unless the idea is complex enough to warrant it. Simple ideas can go straight to implementation.
