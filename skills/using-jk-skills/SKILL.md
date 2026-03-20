---
name: using-jk-skills
description: Use when starting any conversation — establishes how to find and use skills, requiring Skill tool invocation before ANY response including clarifying questions
---

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. This is not optional. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

## How to Access Skills

**In Claude Code:** Use the `Skill` tool. When you invoke a skill, its content is loaded and presented to you — follow it directly. Never use the Read tool on skill files.

**In other environments:** Check your platform's documentation for how skills are loaded.

# Using Skills

## The Rule

**Invoke relevant or requested skills BEFORE any response or action.** Even a 1% chance a skill might apply means you should invoke the skill to check. If an invoked skill turns out to be wrong for the situation, you don't need to use it.

## Red Flags

These thoughts mean STOP — you're rationalizing:

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "I can check git/files quickly" | Files lack conversation context. Check for skills. |
| "Let me gather information first" | Skills tell you HOW to gather information. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "I remember this skill" | Skills evolve. Read current version. |
| "This doesn't count as a task" | Action = task. Check for skills. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |
| "This feels productive" | Undisciplined action wastes time. Skills prevent this. |
| "I know what that means" | Knowing the concept ≠ using the skill. Invoke it. |

## Task Routing

| User says | Start with |
|-----------|-----------|
| "Build X" / "Add feature Y" | jk-plan (or jk-brainstorm if vague) |
| "Fix bug Y" / "This is broken" | systematic-debugging |
| "What if we..." / "I'm thinking about..." | jk-brainstorm |
| "Execute this plan" / "Start building" | jk-execute |
| "I'm done" / "Is this ready?" | jk-prove-it |
| "Review this code" / "Check my work" | jk-code-review |
| "I got feedback" / review comments | jk-receive-review |
| "Let's merge" / "Ship this" | jk-finish-branch |
| "Refactor X" | jk-plan (refactoring intent) |
| "Add tests" / "Write tests for" | test-driven-development |
| "Set up a worktree" | using-git-worktrees |
| "Write a new skill" | writing-skills |
| "Step back" / "Are we on track?" / "Reflect" | jk-reflect |
| "Go light" / "Max tokens" / "Burn rate" | jk-burn-rate |
| "Remember this" / "Save this" / "What did we learn?" | jk-remember |
| "Check for redundant plugins" | jk-plugin-check |
| "Set up a conversation between agents" | jk-converse |
| "Clean up docs" / "Audit documentation" | jk-remember (deep/overhaul) |

## Skill Priority

When multiple skills could apply, use this order:

1. **Process skills first** (jk-plan, systematic-debugging) — these determine HOW to approach the task
2. **Implementation skills second** (test-driven-development, dispatching-parallel-agents) — these guide execution

## Skill Types

**Rigid** (TDD, debugging, jk-prove-it): Follow exactly. Don't adapt away discipline.

**Flexible** (patterns, philosophy): Adapt principles to context.

The skill itself tells you which.

## User Instructions

Instructions say WHAT, not HOW. "Add X" or "Fix Y" doesn't mean skip workflows.
