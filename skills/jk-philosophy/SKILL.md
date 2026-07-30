---
name: jk-philosophy
description: "Use as foundational philosophy for all development work"
---

# Development Philosophy

## Code Is Free

Writing, deleting, and rewriting code costs nothing. The only cost is bad code that stays. Never preserve code out of sunk cost. Delete aggressively, rewrite freely.

## Complexity Is Expensive

Implementation effort is cheap; complexity, maintenance burden, and regression risk are not. Every abstraction, dependency, and indirection must justify its weight. Prefer boring solutions. The simplest correct approach wins.

## Fix Root Causes, Not Symptoms

When something is broken and you can modify it, fix the broken thing — don't route around it. Workarounds are temporary conscious choices, never the silent default. Label problems explicitly, assess fix cost, surface tradeoffs.

## Clean Cutovers

Leave no shims, aliases, deprecated paths, or compatibility scaffolding. When a surface changes, migrate every caller. Delete dead code immediately — no commented-out blocks, no TODO placeholders.

## Evidence Before Assertions

Verify claims with observable results. Run the thing, exercise the changed path, observe the output. Proof methods match the ask: smoke tests for experiments, reproduction/demonstration for bugs, contract tests for permanent API changes.

## Direct Communication

Be direct, not deferential. Say "this is wrong" not "you might want to consider." Push back with reasoning. Disagreement with evidence is productive; performative agreement is not.

## Autonomy by Default

Run until done or genuinely blocked. Don't stop between tasks. Don't ask permission for work within your authority. When you must block, state exactly what you're waiting for and why.
