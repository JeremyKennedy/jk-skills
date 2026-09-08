# jk-skills

A five-skill companion package designed to work alongside [Superpowers](https://github.com/obra/superpowers). Superpowers owns the engineering process (planning, execution, TDD, debugging, code review); jk-skills provides philosophy, reflection, knowledge persistence, structured agent conversations, and deliberate decision interviewing.

## Skills

| Skill | What it does |
|-------|-------------|
| `jk-philosophy` | Foundational philosophy: code is free, complexity is expensive, root causes over workarounds, clean cutovers, evidence before assertions, direct communication |
| `jk-reflect` | Step back and challenge the current direction. Light reflection by default; optional deep reflection with a fresh agent for consequential decisions |
| `jk-interview` | Structured decision-tree interview for plans, decisions, and ideas; exposes assumptions before moving on |
| `jk-remember` | Route durable knowledge to agent instructions, docs/, or auto memory. Explicit invocation or end of significant work |
| `jk-converse` | Structured async conversation between two or more agent sessions over a shared JSONL file with automatic turn detection and convergence protocol |

## Source boundaries and distribution

- `skills/` contains exactly the five first-party `jk-*` skills listed above.
- `adopted-skills/` contains pinned, attributed snapshots of upstream skills. These snapshots are source-library inputs, not first-party `jk-*` skills.
- Adopted skills are explicit-only: they require an explicit invocation, use no hooks or extensions, and are not distributed through the default Pi, Codex, or Claude package paths.
- Agent Hub owns target distribution for adopted skills. Retiring direct installer paths is a later parity checkpoint; the installation paths below cover the first-party skills.

## Installation

### Claude Code (via Nix/home-manager)

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

### Claude Code Marketplace

```
/plugin marketplace add JeremyKennedy/jk-skills
/plugin install jk-skills@jk-skills
```

### Pi

```
pi install git:github.com/JeremyKennedy/jk-skills@v4.0.0
```

### Codex

```
codex plugin marketplace add JeremyKennedy/jk-skills --ref v4.0.0
codex plugin install jk-skills@jk-skills
```

### OpenCode

Uses the same Nix/home-manager installation path; the skills directory is symlinked under `~/.config/opencode/skills/`.

## Requirements

- **Superpowers v6.2.0+** — jk-skills is a companion, not a replacement. Install Superpowers separately for planning, execution, TDD, debugging, and code review.
- The five first-party `jk-*` companions are host-neutral and work in Claude Code, Pi, OpenCode, and Codex.
- Adopted snapshots are explicit-only source inputs managed by Agent Hub, not part of the default package installations above.

## v2 → v3

v3 was a breaking reduction from 20 skills, 6 agents, and a SessionStart hook to four passive companion skills. Engineering process (planning, execution, debugging, TDD, code review, verification, git worktrees, parallel dispatch, skill writing, plugin checks, branch management, burn rate) moved to Superpowers. The retained skills are original prose (not derived from upstream).

If upgrading from v2: uninstall jk-skills v2, install Superpowers v6.2.0+, then install jk-skills v3 as a companion.

## v3 → v4

v4 adds the first-party `jk-interview` skill for explicit decision-tree interviews while keeping Superpowers as the engineering-process companion.

## Validation

```
just check          # bash checks + converse Python tests
nix flake check     # Nix sandbox build
```

## Release Flow

1. Make changes, run `just check` and `nix flake check`
2. Bump version in `.claude-plugin/plugin.json`
3. Commit and push
4. Tag `v<version>` and push the tag

## License

GPL v3. See [LICENSE](LICENSE).
