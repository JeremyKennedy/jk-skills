# CLAUDE.md

Claude Code plugin marketplace: planning, execution, TDD, debugging, and code review skills.

## Architecture

Flat marketplace+plugin repo. Repo root is both the marketplace and the plugin.

- `.claude-plugin/` — Marketplace + plugin manifests
- `skills/` — Plugin skills (shipped to users). Each subdirectory has a `SKILL.md` with YAML frontmatter (`name:`, `description:`)
- `.claude/skills/` — Repo-local skills (maintenance tools, not shipped). Same format as `skills/`.
- `agents/` — Agent definitions
- `hooks/` — SessionStart hook (injects `using-jk-skills` into conversation)
- `upstream/` — Upstream tracking registry
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
description: Use when [trigger condition] — [what it does]
---
```

Descriptions must start with "Use when" to clearly indicate when the skill applies.

### Announcements

All user-facing skills must include after the `# Title`:
```markdown
**Announce at start:** "I'm using the <skill-name> skill to [action]."
```

Exceptions: jk-philosophy (foundational reference) and using-jk-skills (meta-skill injected by hook).

### Sub-Skill References

Reference other skills via:
```markdown
> **REQUIRED SUB-SKILL:** Use jk-skills:<skill-name>
```

### Provenance

Cherry-picked skills include a provenance comment:
```html
<!-- Derived from superpowers v4.2.0: <original-skill-name> -->
```

### Philosophy Alignment

All skills should embody the development philosophy: code is free, expand scope relentlessly, refactor always, ask more questions, TDD when building features, envision the ideal end state. See `skills/jk-philosophy/SKILL.md`.

### Autonomy by Default

Skills should run autonomously — ending a turn to wait for user input is a **conscious decision**, not an accident. This plugin is designed for heavyweight autonomous work.

**When blocking is appropriate:** interview questions, user approval gates (plan presentation, doc updates), Care mode checkpoints, decisions only the user can make.

**When blocking is NOT appropriate:** between tasks in Deep/Swarm mode (use the hard directive), between phases that don't need user input, for informational updates that could be a non-blocking message.

If a skill must block, be explicit about it: tell the user what you're waiting for and why. Never silently end a turn.

## Adding a Skill

1. Create `skills/<name>/SKILL.md` with frontmatter
2. Add reference files in `skills/<name>/references/` if needed
3. Add skill name to `skillNames` list in `flake.nix`
4. Run `just check`

## Adding an Agent

1. Create `agents/<name>.md` with YAML frontmatter (`name:`, `description:`, `model: inherit`)
2. Add provenance comment if derived from upstream (`<!-- Derived from ... -->`)
3. Register in `flake.nix` under `programs.claude-code.agents`
4. Update `upstream/registry.json` absorbed list if applicable
5. Run `just check`

### Agent Output Format

All review agents must use a consistent per-issue format:
1. **Location**: file:line
2. **Severity**: Critical / Important / Minor
3. **Confidence**: 0-100 (is this a real issue, not a false positive?)
4. **Issue**: What's wrong
5. **Recommendation**: Specific fix

## Releasing

Claude Code caches plugins locally. Users only get updates when the `version` in `.claude-plugin/plugin.json` changes — same version = skip, even if code changed.

**Version bump is MANDATORY.** Every commit that changes shipped content (`skills/`, `agents/`, `hooks/`, `.claude-plugin/`) MUST include a version bump in `.claude-plugin/plugin.json`. Semver: patch for fixes, minor for new/changed skills, major for breaking changes. If you're about to commit and haven't bumped the version, bump it now.

Changes to repo-local files (`.claude/skills/`, `scripts/`, `CLAUDE.md`, `docs/`, `upstream/`) do NOT require a version bump.

**Release flow:**
1. Make changes, `just check`
2. Bump `version` in `.claude-plugin/plugin.json` (see above)
3. Commit and push: `git push` (GitHub mirror is synced automatically)

Nix flake users get updates on next `flake lock --update-input jk-skills`. Marketplace users get updates via `/plugin update` or auto-update (disabled by default for third-party marketplaces).

## Commits

Use conventional commits: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`.
