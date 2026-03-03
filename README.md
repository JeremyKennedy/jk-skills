# jk-skills

Heavy-duty planning, execution, and development skills for Claude Code. Supersedes [superpowers](https://github.com/obra/superpowers).

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

### Original Skills

| Skill | Description |
|-------|-------------|
| `jk-philosophy` | Development philosophy directives: code is free, expand scope, refactor always |
| `jk-plan` | Heavy-weight planning: research, interview, design, review panel, implementation plan |
| `jk-execute` | Execute plans in Deep, Swarm, or Care mode |
| `jk-brainstorm` | Lightweight ideation: bounce ideas before committing to formal planning |
| `jk-prove-it` | Ship gate: mechanical verification + self-review + ship report |

### Execution Modes

| Mode | Topology | Best For |
|------|----------|----------|
| **Deep** | One brain — sequential, full context | Tightly coupled tasks, refactoring, architecture |
| **Swarm** | Many brains — parallel dispatch | Independent tasks, bulk changes |
| **Care** | Brain + human — checkpoints | Unfamiliar codebases, high-stakes changes |

Usage: `/jk-execute deep`, `/jk-execute swarm`, `/jk-execute care`

### Cherry-Picked Skills (from superpowers)

| Skill | Description |
|-------|-------------|
| `systematic-debugging` | Root cause investigation before fixes |
| `test-driven-development` | TDD workflow, no exceptions |
| `verification-before-completion` | Evidence before claims |
| `jk-receive-review` | Challenge assumptions, verify independently |
| `jk-code-review` | Code review dispatch template |
| `jk-finish-branch` | Branch analysis + merge/push/PR decision |
| `using-git-worktrees` | Isolated workspace setup |
| `dispatching-parallel-agents` | Parallel subagent coordination |
| `writing-skills` | Skill authoring with philosophy alignment |

### Maintenance (repo-local, not shipped with plugin)

| Skill | Description |
|-------|-------------|
| `upstream-audit` | Check tracked upstream plugin repos for changes and evaluate diffs |

Lives in `.claude/skills/` — available when working in this repo but not distributed to users.

### Meta-Skill

| Skill | Description |
|-------|-------------|
| `using-jk-skills` | Auto-loaded via SessionStart hook. Teaches skill discovery and invocation. |

## Agents

| Agent | Source | Description |
|-------|--------|-------------|
| `code-reviewer` | superpowers | Review completed work against plan and coding standards |
| `silent-failure-hunter` | pr-review-toolkit | Audit error handling for silent failures and swallowed errors |
| `test-analyzer` | pr-review-toolkit | Behavioral test coverage analysis with criticality ratings |
| `doc-analyzer` | pr-review-toolkit | Documentation accuracy, staleness, and AI-generated drift detection |

## Philosophy

See [docs/philosophy.md](docs/philosophy.md) for the full development philosophy.

TL;DR: Code is free, expand scope relentlessly, refactor always, ask more questions, TDD when building features, envision the ideal end state.

## Validation

```bash
just check        # Run validation
nix flake check   # Nix-wrapped validation
```

## License

GPL v3. See [LICENSE](LICENSE).

Cherry-picked skills are derived from [superpowers](https://github.com/obra/superpowers) (MIT, Jesse Vincent). See [ATTRIBUTION.md](ATTRIBUTION.md).
