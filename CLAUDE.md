# CLAUDE.md

A five-skill Superpowers companion. No hooks, agents, or process orchestration — Superpowers owns that layer.

## Architecture

- `.claude-plugin/` — Marketplace + plugin manifests
- `.codex-plugin/` — Codex plugin manifest
- `.agents/plugins/` — Codex marketplace manifest
- `package.json` — Pi package manifest
- `skills/` — Exactly five first-party `jk-*` skills
- `adopted-skills/` — Pinned, attributed upstream skill snapshots
- `tests/` — Python tests (converse round-trip, inventory, neutrality)
- `scripts/check.sh` — Validation (run via `just check` or `nix flake check`)

### Source boundaries and distribution

- `skills/` is the first-party source area and must retain the exact five-skill inventory.
- `adopted-skills/` is a source-library area for pinned, attributed upstream snapshots; adopted skills are explicit-only and contain no hooks or extensions.
- Adopted skills are distributed by Agent Hub, not through the default Pi, Codex, or Claude package paths. Agent Hub owns target distribution; direct installer retirement is a later parity checkpoint.

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
Adopted skills additionally require `disable-model-invocation: true` in the first 20 lines of `SKILL.md` and `allow_implicit_invocation: false` in `agents/openai.yaml`.

### Host-neutral skill text

Shipped skills must be host-neutral: no Claude-only tool names, no personal names, no provider-specific model IDs, no literal sub-skill paths, no unsupported timeout/model frontmatter.

### Instruction budgets

- `jk-philosophy` body: ≤250 whitespace-delimited words
- Combined five `SKILL.md` bodies: ≤2,500 words
- Enforced by `scripts/check.sh`

## Adding a first-party skill

1. Create `skills/<name>/SKILL.md` with frontmatter
2. Add to `skillNames` in `flake.nix`
3. Update `scripts/check.sh` budget limits
4. Run `just check`

Adopted upstream snapshots belong under `adopted-skills/` and are distributed by Agent Hub; do not add them to the first-party package manifests or target paths.

## Releasing

1. Make changes, `just check`
2. Bump `version` in `.claude-plugin/plugin.json`
3. Commit and push
4. Tag `v<version>` and push the tag

Every commit that changes shipped content MUST include a version bump. Semver: patch for fixes, minor for new skills, major for breaking changes.

## Commits

Conventional commits: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`.
