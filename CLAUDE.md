# CLAUDE.md

Claude Code plugin marketplace: planning, execution, TDD, debugging, and code review skills.

## Architecture

Flat marketplace+plugin repo. Repo root is both the marketplace and the plugin.

- `.claude-plugin/` — Marketplace + plugin manifests
- `skills/` — Each subdirectory has a `SKILL.md` with YAML frontmatter (`name:`, `description:`)
- `agents/` — Agent definitions
- `hooks/` — SessionStart hook (injects `using-jk-skills` into conversation)
- `scripts/check.sh` — Validation (run via `just check` or `nix flake check`)

## Dual Distribution

1. **Claude Code marketplace**: Users install via `/plugin marketplace add`
2. **Nix flake**: `nixosModules.default` configures `programs.claude-code.*`

Pick one, not both (duplicates otherwise).

## Commands

- `just check` — Run validation
- `just build` — Validate structure (aliases check)
- `just dev` — Development info
- `nix flake check` — Nix-wrapped validation

## Skill Conventions

### Frontmatter

Every `SKILL.md` must have:
```yaml
---
name: skill-name
description: What this skill does
---
```

### Sub-Skill References

Reference other skills via:
```markdown
> **REQUIRED SUB-SKILL:** Use jk-skills:<skill-name>
```

Include failure gate text: "If you cannot load jk-skills:<name>, STOP and tell the user the plugin is misconfigured."

### Provenance

Cherry-picked skills include a provenance comment:
```html
<!-- Derived from superpowers v4.2.0: <original-skill-name> -->
```

### Philosophy Alignment

All skills should embody the development philosophy: code is free, expand scope relentlessly, refactor always, ask more questions, TDD when building features, envision the ideal end state. See `skills/jk-philosophy/SKILL.md`.

## Adding a Skill

1. Create `skills/<name>/SKILL.md` with frontmatter
2. Add reference files in `skills/<name>/references/` if needed
3. Add skill name to `skillNames` list in `flake.nix`
4. Run `just check`

## Releasing

Claude Code caches plugins locally. Users only get updates when the `version` in `.claude-plugin/plugin.json` changes — same version = skip, even if code changed.

**Release flow:**
1. Make changes, `just check`
2. Bump `version` in `.claude-plugin/plugin.json` (semver: patch for fixes, minor for new/changed skills, major for breaking changes)
3. Commit and push: `git push` (GitHub mirror is synced automatically)

Nix flake users get updates on next `flake lock --update-input jk-skills`. Marketplace users get updates via `/plugin update` or auto-update (disabled by default for third-party marketplaces).

## Commits

Use conventional commits: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`.
