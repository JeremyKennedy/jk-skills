---
name: jk-burn-rate
description: "Use when the user wants to set token spending level for the session — controls model selection and parallelism across all skills. Does NOT weaken skill discipline."
---

# Burn Rate

**Announce at start:** "I'm setting the burn rate for this session."

Session-level setting that controls how aggressively skills spend tokens. Affects model selection, parallelism, and ambition on discretionary work.

<HARD-GATE>
Burn rate is an optimization knob, NOT an escape hatch. It NEVER weakens core skill discipline. Required reviews still happen. Hard gates still apply. Interview criteria still matter. The burn rate controls HOW EXPENSIVE the work is, not WHETHER the work happens.
</HARD-GATE>

## Levels

| Level | Models | Discretionary work | When |
|-------|--------|-------------------|------|
| **Max** | Opus for everything. Haiku only for file listing. | Go wide — more review agents, explore more alternatives, deeper audits, expand scope aggressively. | End of usage period, complex critical work, "go all out" |
| **Standard** | Opus for reasoning and orchestration. Sonnet for focused work. | Balanced — follow skill defaults. | Default if not set. |
| **Light** | Sonnet for most work. Opus when reasoning genuinely demands it. Haiku for mechanical tasks. | Be efficient on optional work — fewer parallel agents for discretionary tasks, leaner audits. Core reviews and gates are unchanged. | Budget-conscious, early in usage period. |

**What "light" does NOT mean:**
- Skip required reviews
- Reduce interview depth below what the task needs
- Bypass hard gates or review panels
- Lower quality standards

Light means: choose cheaper models where quality won't suffer, and be less aggressive on discretionary extras (scope expansion, optional audits, deep remember). The prescribed workflow stays intact.

## How to Set

User says it directly: "burn rate max", "go light", "standard tokens".

If the user signals they're stepping away ("going to sleep", "run this while I'm gone", "back in a few hours"), **offer** to increase burn rate — don't auto-increase. The user may still want budget-conscious work. Something like:

> "Since you're stepping away, want me to increase the burn rate? Standard (keep current), high (opus for more things), or max (burn it all)?"

If the user hasn't set a burn rate, skills follow their own model selection guidance using whatever model the user has selected in their harness. This skill only needs to be loaded when the user explicitly wants to override that default.

## How Skills Use It

When a skill is choosing models or deciding how much discretionary work to do, check whether a burn rate has been set this session:

- **Models**: max upgrades sonnet→opus broadly, light downgrades opus→sonnet for non-critical reasoning. Always use opus when the task genuinely requires it regardless of burn rate.
- **Discretionary effort**: max means more exploration, more alternatives, deeper optional audits. Light means focused and efficient on optional work. Required work is unaffected.
