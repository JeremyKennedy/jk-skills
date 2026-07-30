# CLAUDE.md

A four-skill Superpowers companion. No hooks, agents, or process orchestration — Superpowers owns that layer.

## Architecture

- `.claude-plugin/` — Marketplace + plugin manifests
- `.codex-plugin/` — Codex plugin manifest
- `.agents/plugins/` — Codex marketplace manifest
- `package.json` — Pi package manifest
- `skills/` — Four companion skills
- `tests/` — Python tests (converse round-trip, inventory, neutrality)
- `scripts/check.sh` — Validation (run via `just check` or `nix flake check`)

## Commands

- `just check` — Run validation (bash checks + pytest)
- `just build` — Alias for check
- `just dev` — Development info
- `nix flake check` — Nix-wrapped validation

## Skill Conventions

### Frontmatter

Every `SKILL.md` must have:
```yaml
---
name: skill-name
description: Use when [trigger condition] — [what it does]
---
```

### Host-neutral skill text

Shipped skills must be host-neutral: no Claude-only tool names, no personal names, no provider-specific model IDs, no literal sub-skill paths, no unsupported timeout/model frontmatter.

### Instruction budgets

- `jk-philosophy` body: ≤250 whitespace-delimited words
- Combined four `SKILL.md` bodies: ≤2,500 words
- Enforced by `scripts/check.sh`

## Adding a Skill

1. Create `skills/<name>/SKILL.md` with frontmatter
2. Add to `skillNames` in `flake.nix`
3. Update `scripts/check.sh` budget limits
4. Run `just check`

## Releasing

1. Make changes, `just check`
2. Bump `version` in `.claude-plugin/plugin.json`
3. Commit and push
4. Tag `v<version>` and push the tag

Every commit that changes shipped content MUST include a version bump. Semver: patch for fixes, minor for new skills, major for breaking changes.

## Commits

Conventional commits: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`.
