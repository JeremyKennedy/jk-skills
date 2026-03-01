# jk-skills

Heavy-duty planning, execution, and development skills for Claude Code. Supersedes [superpowers](https://github.com/obra/superpowers).

## Installation

### Option A: Claude Code Plugin Marketplace

```
/plugin marketplace add jeremyk/jk-skills
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
imports = [ inputs.jk-skills.homeManagerModules.default ];
programs.jk-skills.enable = true;
```

**Pick one, not both.** Using both creates duplicate skills.

## Skills

### Original Skills

| Skill | Command | Description |
|-------|---------|-------------|
| `jk-philosophy` | `/jk-philosophy` | Development philosophy directives: code is free, expand scope, refactor always |
| `jk-deep-plan` | `/jk-plan` | Heavy-weight planning: research, interview, design, review panel, implementation plan |
| `jk-deep-execute` | `/jk-execute` | Execute plans in Deep, Swarm, or Care mode |
| `jk-prove-it` | — | Ship gate: mechanical verification + self-review + ship report |

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
| `receiving-code-review` | Challenge assumptions, verify independently |
| `requesting-code-review` | Code review dispatch template |
| `finishing-a-development-branch` | Merge/push decision (default: direct push) |
| `using-git-worktrees` | Isolated workspace setup |
| `dispatching-parallel-agents` | Parallel subagent coordination |
| `writing-skills` | Skill authoring with philosophy alignment |

### Meta-Skill

| Skill | Description |
|-------|-------------|
| `using-jk-skills` | Auto-loaded via SessionStart hook. Teaches skill discovery and invocation. |

## Agent

| Agent | Description |
|-------|-------------|
| `code-reviewer` | Review completed work against plan and coding standards |

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
