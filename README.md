# jk-skills

Heavy-duty planning, execution, and development skills for Claude Code.

### Supersedes

If you have any of these installed, **uninstall them** — jk-skills absorbs their functionality:

- [superpowers](https://github.com/obra/superpowers) — all 10 skills + code-reviewer agent absorbed
- [pr-review-toolkit](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/pr-review-toolkit) — all 3 review agents absorbed (silent-failure-hunter, test-analyzer, doc-analyzer)
- [feature-dev](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/feature-dev) — code-explorer and code-architect agents absorbed into jk-plan

**Compatible with** (can run alongside jk-skills):
- [code-review](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-review) — PR-specific automated review (not absorbed, you don't review others' PRs)

## Installation

### Option A: Claude Code Plugin Marketplace

```
/plugin marketplace add JeremyKennedy/jk-skills
/plugin install jk-skills@jk-skills
```

### Option B: Nix Flake (NixOS / home-manager)

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

## Skills

### jk- Skills (owned, customized)

| Skill | Description |
|-------|-------------|
| `jk-philosophy` | Foundational development philosophy: scope expansion, relentless refactoring, aggressive productivity |
| `jk-plan` | Deep interview, parallel codebase research, adversarial review panel, implementation plan |
| `jk-execute` | Execute plans in Deep, Swarm, or Care mode with mandatory TDD and code review |
| `jk-brainstorm` | Lightweight conversational ideation — no code, no design docs |
| `jk-prove-it` | Ship gate: mechanical verification, self-review, liveness check, ship report |
| `jk-code-review` | Dispatch code-reviewer agent to catch issues early (automatic in jk-execute, manual for ad-hoc) |
| `jk-receive-review` | Receive code review feedback with technical rigor — challenge assumptions, verify independently |
| `jk-finish-branch` | Analyze branch state (long-lived, feature, PR, trunk), present merge/push/PR/cleanup options |

### Execution Modes

| Mode | Topology | Best For |
|------|----------|----------|
| **Deep** | One brain — sequential, full context | Tightly coupled tasks, refactoring, architecture |
| **Swarm** | Many brains — parallel dispatch | Independent tasks, bulk changes |
| **Care** | Brain + human — checkpoints | Unfamiliar codebases, high-stakes changes |

Usage: `/jk-execute deep`, `/jk-execute swarm`, `/jk-execute care`

### Adopted Skills (from superpowers, unmodified)

| Skill | Description |
|-------|-------------|
| `systematic-debugging` | Root cause investigation before proposing fixes |
| `test-driven-development` | TDD workflow: write failing test, implement, refactor |
| `verification-before-completion` | Evidence before claims — run verification, confirm output |
| `using-git-worktrees` | Isolated workspace setup with safety verification |
| `dispatching-parallel-agents` | Parallel subagent coordination for independent tasks |
| `writing-skills` | Skill authoring and verification before deployment |

### Meta-Skill

| Skill | Description |
|-------|-------------|
| `using-jk-skills` | Auto-loaded via SessionStart hook. Skill discovery and invocation routing. |

### Maintenance (repo-local, not shipped with plugin)

| Skill | Description |
|-------|-------------|
| `upstream-audit` | Check tracked upstream plugin repos for changes and evaluate diffs |

Lives in `.claude/skills/` — available when working in this repo but not distributed to users.

## Agents

| Agent | Source | Description |
|-------|--------|-------------|
| `code-reviewer` | superpowers | Review completed work against plan and coding standards |
| `code-explorer` | feature-dev | Deep codebase analysis — trace execution paths, map architecture layers |
| `code-architect` | feature-dev | Design feature architectures with implementation blueprints |
| `silent-failure-hunter` | pr-review-toolkit | Audit error handling for silent failures and swallowed errors |
| `test-analyzer` | pr-review-toolkit | Behavioral test coverage analysis |
| `doc-analyzer` | pr-review-toolkit | Documentation accuracy, staleness, and AI-generated drift detection |

## Philosophy

Invoke via `/jk-philosophy`. Full text in [docs/philosophy.md](docs/philosophy.md).

TL;DR: Code is free, expand scope relentlessly, refactor always, ask more questions, TDD when building features, envision the ideal end state.

## Validation

```bash
just check        # Run validation
nix flake check   # Nix-wrapped validation
```

## License

GPL v3. See [LICENSE](LICENSE).

Derived works from [superpowers](https://github.com/obra/superpowers) (MIT, Jesse Vincent) and [claude-plugins-official](https://github.com/anthropics/claude-plugins-official) (Apache 2.0, Anthropic). See [ATTRIBUTION.md](ATTRIBUTION.md).
