---
name: upstream-audit
description: Use when checking upstream plugin repos for changes since last review — evaluate diffs for relevance and report what's new
---

# Upstream Audit

**Announce at start:** "I'm using the upstream-audit skill to check for upstream changes."

Check tracked upstream repos for changes since the last review. Evaluate diffs for relevance to absorbed or watched plugins. Present a structured report.

## Registry

Read `upstream/registry.json` in the project root. Each entry has:

| Field | Purpose |
|-------|---------|
| `name` | Human-readable upstream name |
| `repo` | GitHub `owner/repo` |
| `path` | Subdirectory filter for monorepos (null = whole repo) |
| `last_checked_sha` | Last reviewed commit SHA |
| `last_checked_date` | When it was last reviewed |
| `absorbed` | What was cherry-picked (skills, agents, version) |
| `status` | `absorbed` (we forked it) or `watching` (tracking for ideas) |
| `notes` | Context about the relationship |

## Audit Process

### 1. Load Registry

Read `upstream/registry.json`. If it doesn't exist, STOP and tell the user to create one.

### 2. Check Each Upstream

For each entry, check for new commits since `last_checked_sha`:

**Whole-repo upstreams** (path is null):
```bash
gh api "repos/{repo}/compare/{last_checked_sha}...HEAD" --jq '{
  ahead_by: .ahead_by,
  commits: [.commits[] | {sha: .sha[:8], date: .commit.author.date[:10], message: .commit.message | split("\n")[0]}]
}'
```

**Monorepo upstreams** (path is set):
```bash
gh api "repos/{repo}/commits?sha=HEAD&path={path}&since={last_checked_date}T00:00:00Z" --jq '[.[] | {sha: .sha[:8], date: .commit.author.date[:10], message: .commit.message | split("\n")[0]}]'
```

If `last_checked_sha` is null (first run), fetch the last 20 commits instead.

### 3. Evaluate Changes

For each upstream with new commits:

**If status is `absorbed`:**
- Fetch the full diff for affected files: `gh api "repos/{repo}/compare/{last_checked_sha}...HEAD" --jq '.files[] | select(.filename | startswith("{path}")) | {filename, status, additions, deletions}'`
- For each changed file, check: does it correspond to a skill/agent we absorbed?
- Read the actual diff for absorbed-relevant files: `gh api "repos/{repo}/compare/{last_checked_sha}...HEAD" -q '.files[] | select(.filename | startswith("{path}")) | .patch'`
- Evaluate: bug fix we should port? New feature worth absorbing? Breaking change? Diverged too far to merge?

**If status is `watching`:**
- Summarize what changed (commit messages are usually enough)
- Flag anything that looks like a new agent, skill, or significant feature
- Note if anything addresses gaps in jk-skills

### 4. Present Report

```markdown
## Upstream Audit Report — YYYY-MM-DD

### {name} ({status})
**Repo:** {repo}
**Changes since:** {last_checked_date} ({last_checked_sha[:8]})
**New commits:** N

#### Summary
[What changed, in 2-3 sentences]

#### Relevant Changes
- [file/skill] — [what changed and why it matters]

#### Recommendation
- [ ] Port: [specific fix/feature to absorb]
- [ ] Watch: [interesting but not actionable yet]
- [ ] Skip: [irrelevant or diverged]

---
```

### 5. Update Registry

After the user reviews the report, ask if they want to mark upstreams as checked. For each confirmed upstream, update `last_checked_sha` and `last_checked_date` in the registry file.

Only update SHAs the user explicitly confirms — they may want to defer some for deeper review.

## Adding an Upstream

To track a new upstream, add an entry to `upstream/registry.json`:

```json
{
  "name": "new-plugin",
  "repo": "owner/repo",
  "path": "plugins/new-plugin",
  "last_checked_sha": null,
  "last_checked_date": null,
  "absorbed": { "skills": [], "agents": [] },
  "status": "watching",
  "notes": "Why we're tracking this"
}
```

Set `path` to null for standalone repos, or a subdirectory for monorepos.
