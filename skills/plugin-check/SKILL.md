---
name: plugin-check
description: "Use when a user installs jk-skills or asks about plugin conflicts — checks for installed plugins that jk-skills supersedes and recommends uninstalling them."
---

# Plugin Check

**Announce at start:** "I'm using the plugin-check skill to look for redundant plugins."

Check for installed plugins that jk-skills supersedes. jk-skills absorbs and improves on several upstream plugins — running both wastes context and causes skill conflicts.

## How to Check

Read `~/.claude/plugins/installed_plugins.json` and check for the plugins listed below.

## Superseded Plugins

| Installed plugin | jk-skills replacement | Why it's redundant |
|-----------------|----------------------|-------------------|
| `superpowers@*` | jk-plan, jk-execute, jk-brainstorm, jk-code-review, systematic-debugging, test-driven-development, dispatching-parallel-agents, writing-skills, jk-finish-branch, using-git-worktrees, jk-receive-review, verification-before-completion | jk-skills absorbed all superpowers skills and added execution modes, review panels, model selection, and heavyweight planning. Running both causes duplicate/conflicting skill triggers. |
| `feature-dev@*` | jk-plan (Phase 1 + Phase 4), jk-execute | code-explorer and code-architect agents absorbed into jk-plan. Feature workflow superseded by jk-plan + jk-execute. |
| `pr-review-toolkit@*` | jk-execute (round table), jk-code-review | silent-failure-hunter, test-analyzer, and doc-analyzer agents absorbed. Confidence scoring adopted in jk-execute. |
| `code-review@*` | jk-code-review | jk-code-review dispatches code-reviewer with the same pattern plus integration with jk-execute's per-task review pipeline. |
| `code-simplifier@*` | simplify (repo-local skill) | Overlapping purpose — simplify reviews changed code for reuse, quality, and efficiency. |
| `claude-md-management@*` | jk-remember, jk-execute (knowledge promotion) | jk-remember routes knowledge to CLAUDE.md, docs/, or memory. jk-execute's knowledge promotion updates CLAUDE.md and docs/ after execution. The revise-claude-md command is subsumed by jk-remember's broader routing. |

## Complementary Plugins (keep these)

These plugins provide capabilities jk-skills does NOT cover. Do not recommend uninstalling:

- `context7@*` — library documentation lookup
- `playwright@*` — browser automation
- `frontend-design@*` — UI/component design
- `commit-commands@*` — git commit/PR workflow
- `hookify@*` — hook management
- `*-lsp@*` — language server plugins
- `telegram@*` — messaging channel

## Output Format

```
## Plugin Check

### Redundant (recommend uninstall)
- **superpowers** — fully absorbed into jk-skills (planning, execution, debugging, TDD, code review). Uninstall: `/plugin uninstall superpowers@claude-plugins-official`
- **feature-dev** — superseded by jk-plan. Uninstall: `/plugin uninstall feature-dev@claude-plugins-official`

### No conflicts
- context7, playwright, commit-commands — complementary, keep them.

### Summary
You have N plugin(s) that jk-skills supersedes. Uninstalling them will reduce context bloat and prevent conflicting skill triggers.
```

If no redundant plugins are found, say so and move on.
