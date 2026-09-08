---
name: jk-interview
description: "Use when the user explicitly asks for an interview, stress test, or challenge about a plan, decision, or idea — run a structured decision-tree interview."
---

# Interview

Make load-bearing decisions explicit before action.

## Trigger

Use only explicit interview, stress-test, or challenge requests, not routine clarification.

## Build the tree

1. Restate the goal and desired outcome.
2. Track settled decisions, open decisions, and their dependencies.
3. Find the **frontier**: open decisions whose prerequisites are settled.
4. Find environmental facts with tools; ask the user for decisions and preferences.

Do not ask downstream questions while upstream decisions remain open.

## Ask rounds

Ask every current frontier question in one round, with a recommendation and trade-off:

```text
❓ Q1 — <question>: <why it matters>

➡️ Recommendation: <answer and trade-off>
```

Apply the answers, discard ruled-out branches, calculate the next frontier, and never repeat settled questions. If an answer changes an earlier decision, surface the consequence and rebuild the frontier.

## Assumption checkpoint

When the remaining questions are refinements rather than blockers, pause and make stopping visible:

```text
I think we're at a good place to stop.

If we move on, I will assume:
- <assumption>
- <assumption>

I recommend stopping because <reason>.

If we continued, the next frontier would be:
1. **Top question:** <highest-leverage question>
2. <next question>
3. <next question>

Does that track match your intent?

- **Move on** — accept the assumptions and synthesize.
- **Continue** — ask the displayed frontier.
- **Correct** — revise an assumption or recommendation first.
```

Show actual next questions, mark the highest-leverage one, and explain why stopping is reasonable. Do not implement after **Move on**; synthesize first. After **Correct**, update the tree. The user may stop at any time.

## Synthesize

Summarize the goal, decisions, assumptions, risks, deferred questions, and next action in the conversation. Do not write files, create tickets, invoke another skill, or implement automatically.
