---
name: jk-burn-rate
description: "Use when the user wants to set token spending level for the session — controls model selection and parallelism across all skills."
---

# Burn Rate

**Announce at start:** "I'm setting the burn rate for this session."

Session-level setting that controls how aggressively skills spend tokens. Affects model selection, number of subagents, review depth, and parallelism across all jk-skills.

## Levels

| Level | Models | Parallelism | When |
|-------|--------|-------------|------|
| **Max** | Opus for everything. Haiku only for file listing. | Maximum — parallelize aggressively, full review panels, deep audits. | End of usage period, complex critical work, "go all out" |
| **Standard** | Opus for reasoning and orchestration. Sonnet for focused work (reviews, implementation of clear specs). | Normal — parallelize where it helps, scale review to task complexity. | Default. Good balance. |
| **Light** | Sonnet for most work. Opus only when reasoning genuinely demands it. Haiku for mechanical tasks. | Conservative — fewer parallel agents, skip optional reviews for trivial tasks. | Budget-conscious, simple work, early in usage period. |

## How to Set

User says it directly: "burn rate max", "go light", "standard tokens". Or infer from context — "it's the end of my billing cycle, let's clean up docs" implies max.

If the user hasn't set it and you're about to do expensive work (deep remember, full review panel, swarm execution), ask:

> "This will use a lot of tokens. Max / standard / light?"

## How Skills Use It

Burn rate affects everything — model selection, effort, thoroughness, personality.

**Models:**
- **Max**: upgrade sonnet→opus broadly
- **Standard**: follow per-skill defaults
- **Light**: downgrade opus→sonnet where reasoning doesn't strictly demand it

**Effort and behavior:**
- **Max**: explore more alternatives, ask more questions, deeper reviews, more thorough testing, expand scope aggressively. Agents should be ambitious and perfectionist.
- **Standard**: balanced. Follow skill guidance as written.
- **Light**: be efficient. Skip optional reviews for trivial tasks, fewer interview questions when the answer is clear, shorter review panels, get to the point. Agents should be focused and pragmatic.

The burn rate is a preference, not a hard rule. If a task genuinely needs opus or deep effort even on light, do it.
