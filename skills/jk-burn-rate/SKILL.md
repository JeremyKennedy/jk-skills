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

Skills with model selection guidance (jk-plan, jk-execute, jk-remember) should check the burn rate before choosing models. The burn rate overrides the per-skill defaults:

- **Max**: upgrade sonnet→opus where the skill would normally use sonnet for reviewers/implementers
- **Standard**: follow the skill's own model selection guidance as written
- **Light**: downgrade opus→sonnet where the task doesn't strictly require opus-level reasoning

The burn rate is a preference, not a hard rule. If a task genuinely needs opus even on light (e.g., complex architectural decision), use opus.
