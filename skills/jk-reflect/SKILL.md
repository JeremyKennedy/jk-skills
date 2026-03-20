---
name: jk-reflect
description: "Use when needing to step back from the current work — gain objectivity, challenge assumptions, evaluate approach. Can dispatch a subagent for a fresh perspective on complex topics."
---

# Reflect

**Announce at start:** "I'm using the jk-reflect skill to step back and think clearly."

Pause. Challenge assumptions. Evaluate whether the current direction is right.

## When to Use

- You've lost sight of the original goal
- A decision feels wrong but you can't articulate why
- The user asks you to step back or reconsider
- You're about to commit to a direction and want a sanity check
- Something is more complex than expected
- You want to challenge the emerging direction in a brainstorm or plan

## How It Works

### Light Reflection (default)

Two phases — gut check first, then analysis.

**Phase 1: Gut Reaction (immediate)**

Before you think carefully, give the user your raw instinct in 1-2 sentences. What's your honest first impression of where things stand? Don't hedge, don't qualify. "I think we're off track because..." or "This feels solid, we're on the right path." The user needs a quick signal before the deeper analysis.

**Phase 2: Structured Analysis (take your time)**

Now step back properly:

1. **What are we trying to accomplish?** Restate the original goal. Has it drifted? Are we still solving the right problem?
2. **How did we get here?** Trace the key decisions. Which ones were deliberate? Which were accidental or expedient?
3. **What approach are we taking?** Summarize the current direction and ask: is this still the best path given what we now know?
4. **What assumptions are we making?** List them explicitly — especially ones that haven't been verified.
5. **What are we NOT considering?** Alternatives dismissed too quickly, edge cases ignored, risks unexamined.
6. **If we started over knowing what we know now, would we do the same thing?** If no, what would change?
7. **Do we need to re-plan?** If things have gone significantly off course, say so clearly. A course correction now is cheaper than continuing down the wrong path.

**Be critical. Push back.** The whole point of reflection is to challenge the current direction, not validate it. If you find yourself saying "everything looks good" on a complex topic, you're probably not looking hard enough. Find the weak point — there always is one.

### Deep Reflection (for complex/high-stakes topics)

When the topic is complex enough that your own biases might cloud judgment, dispatch a **fresh subagent** (model: `opus`) with no sunk cost in the current approach:

```
You are a fresh set of eyes reviewing an approach in progress. You have NO investment in the current direction — your job is to be honestly critical.

## Context
[What we're building and why]

## Current Approach
[What's been decided/built so far]

## Key Decisions Made
[List the major choices and their reasoning]

## What I Want You To Challenge
[Specific areas of uncertainty, or "everything"]

## Your Job
1. Are the goals right? Is this solving the real problem?
2. Is the approach sound? Are there simpler/better alternatives?
3. What assumptions are being made that might not hold?
4. What's being overlooked or underweighted?
5. If you were starting fresh, what would you do differently?

Be constructive but honest. "This looks fine" is a valid answer if it's true.
Output your assessment, then a clear recommendation: stay the course, adjust, or rethink.
```

Use deep reflection when:
- The decision has significant consequences (architecture, scope, approach)
- You've been going back and forth and can't settle
- The user explicitly asks for an outside perspective
- You suspect confirmation bias in your own reasoning

### After Reflecting

Present findings to the user with a clear recommendation:

```
## Reflection

[What I found — honest assessment]

### Recommendation
[Stay the course / Adjust X / Rethink Y]

### Why
[Brief reasoning]
```

Then return to the work — or change direction based on the reflection.

## Rules

- **Be honest, not diplomatic.** The point of reflection is truth, not comfort.
- **Don't reflect for the sake of it.** If the answer is "we're on track," say so and move on.
- **Don't use reflection to procrastinate.** Reflect, decide, act.
- **The user can always override.** Reflection is advisory, not a gate.
