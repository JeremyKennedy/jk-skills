# jk-skills

A heavyweight Claude Code plugin for planning, executing, and shipping software. It replaces several plugins with an integrated system: research → interview → design → adversarial review → implementation plan → parallel execution → verification.

This is opinionated. It expands scope aggressively, demands TDD, runs adversarial review panels, and won't let you ship without proving the work is done. If you want something lighter, this isn't it.

## What It Does

**Planning** — Before writing code, `jk-plan` runs deep codebase research with parallel explorer agents, interviews you to understand the problem, has multiple architects independently design solutions, then runs a 6-reviewer adversarial panel to tear the design apart. It cycles until no critical issues remain.

**Execution** — `jk-execute` takes the plan and runs it in one of four modes:

| Mode | How it works | Best for |
|------|-------------|----------|
| **Deep** | One orchestrator dispatches subagents per task, reviews between tasks | Most work — tightly coupled tasks, refactoring |
| **Direct** | Main thread does the work, you see everything | Risky or uncertain work where you want full visibility |
| **Swarm** | Parallel subagents on independent files simultaneously | Bulk changes, 3+ independent tasks |
| **Care** | Like Deep but pauses at meaningful checkpoints for your review | High-stakes changes, unfamiliar codebases |

**Verification** — `jk-prove-it` mechanically verifies the work before you ship. Runs tests, checks the diff, generates a ship report. No "I think it works" — evidence or it didn't happen.

**Knowledge** — `jk-remember` persists what was learned to the right place: CLAUDE.md for project conventions, docs/ for deeper knowledge, auto memory for your preferences. Runs at the end of planning and execution so knowledge compounds across sessions.

**Reflection** — `jk-reflect` steps back and challenges the current direction. Gut check first, then structured analysis. Can dispatch a fresh subagent for an unbiased perspective on complex decisions.

**Burn Rate** — `jk-burn-rate` lets you control token spending: max (opus everything, go wide), standard (balanced), or light (efficient, cheaper models where quality won't suffer). Never weakens core discipline — just controls how aggressively to spend on discretionary work.

## Installation

### Claude Code Marketplace

```
/plugin marketplace add JeremyKennedy/jk-skills
/plugin install jk-skills@jk-skills
```

### Nix Flake (NixOS / home-manager)

```nix
# flake.nix inputs:
jk-skills = {
  url = "git+https://git.jeremyk.net/jeremy/jk-skills.git";
  inputs.nixpkgs.follows = "nixpkgs";
};

# home-manager config:
imports = [ inputs.jk-skills.nixosModules.default ];
programs.jk-skills.enable = true;
```

**Pick one, not both.** Using both creates duplicate skills.

## Supersedes

If you have any of these installed, **uninstall them** — jk-skills absorbs and improves on their functionality:

- **[superpowers](https://github.com/obra/superpowers)** — all skills + code-reviewer agent
- **[feature-dev](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/feature-dev)** — code-explorer and code-architect agents
- **[pr-review-toolkit](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/pr-review-toolkit)** — silent-failure-hunter, test-analyzer, doc-analyzer agents
- **[code-review](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-review)** — jk-code-review covers this
- **[code-simplifier](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-simplifier)** — overlaps with built-in review
- **[claude-md-management](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/claude-md-management)** — jk-remember handles CLAUDE.md + docs/ + memory routing

Run `/plugin-check` to detect conflicts automatically.

## All Skills

### Core Workflow (roughly in order of use)

| Skill | What it does |
|-------|-------------|
| `jk-brainstorm` | Lightweight conversational ideation with optional visual browser companion |
| `jk-plan` | Research → interview → design → review panel → implementation plan |
| `jk-execute` | Run plans in Deep / Direct / Swarm / Care mode with TDD and code review |
| `jk-prove-it` | Mechanical verification, self-review, ship report |
| `jk-finish-branch` | Analyze branch state, present merge/push/PR/cleanup options |
| `jk-remember` | Smart knowledge routing: CLAUDE.md / docs/ / auto memory. Scales from quick save to full doc audit |

### Support Skills

| Skill | What it does |
|-------|-------------|
| `jk-reflect` | Step back, challenge assumptions, optionally dispatch fresh subagent for outside perspective |
| `jk-burn-rate` | Session-level token spending control: max / standard / light |

### Development Discipline

| Skill | What it does |
|-------|-------------|
| `systematic-debugging` | Root cause investigation before proposing fixes |
| `test-driven-development` | TDD: failing test → implement → refactor |
| `verification-before-completion` | Evidence before claims — run verification, confirm output |
| `jk-code-review` | Dispatch code-reviewer agent (automatic in jk-execute, manual for ad-hoc) |
| `jk-receive-review` | Handle code review feedback with rigor — challenge assumptions, verify independently |

### Coordination

| Skill | What it does |
|-------|-------------|
| `dispatching-parallel-agents` | Parallel subagent coordination with context isolation |
| `using-git-worktrees` | Isolated workspace setup with safety verification |
| `jk-converse` | Structured async conversation between two agents via shared markdown file |

### Meta

| Skill | What it does |
|-------|-------------|
| `using-jk-skills` | Auto-loaded via SessionStart hook. Skill discovery and routing. |
| `jk-philosophy` | Foundational philosophy: code is free, expand scope, refactor always, heavyweight autonomy |
| `plugin-check` | Detect installed plugins that jk-skills supersedes |
| `writing-skills` | Skill authoring and verification |

## Agents

| Agent | Used by | What it does |
|-------|---------|-------------|
| `code-reviewer` | jk-execute, jk-code-review | Review code against plan and standards |
| `code-explorer` | jk-plan Phase 1 | Deep codebase analysis |
| `code-architect` | jk-plan Phase 4 | Design feature architectures |
| `silent-failure-hunter` | jk-execute round table | Audit error handling for silent failures |
| `test-analyzer` | jk-execute round table | Behavioral test coverage analysis |
| `doc-analyzer` | jk-execute round table | Documentation accuracy and staleness detection |

## Philosophy

Code is free. Expand scope relentlessly. Refactor always. Ask more questions. Build on what's already known. Run autonomously — blocking must be conscious and explicit. Every task is an opportunity to leave the codebase better.

Full text: invoke `/jk-philosophy` in a session.

## License

GPL v3. See [LICENSE](LICENSE).

Derived from [superpowers](https://github.com/obra/superpowers) (MIT), [claude-plugins-official](https://github.com/anthropics/claude-plugins-official) (Apache 2.0). See [ATTRIBUTION.md](ATTRIBUTION.md).
