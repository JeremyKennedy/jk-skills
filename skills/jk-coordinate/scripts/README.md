# Collector

`collect` gathers recent activity for a coordination home in one digest: local
git, agent sessions, Forgejo, and Azure DevOps. The morning run and `/open`,
`/eod` and `/focus` use it to see what changed.

It is read-only toward every external system: `git log`/`status`, read-only
SQLite opens, Forgejo GETs, and the read-only `caipas-bridge boards search` and
Review Exchange `prs` commands. It never prompts. A failing source becomes a
line in `warnings` and the rest of the digest still arrives.

The collector is generic: every host, project and repo list comes from the
`collector.json` beside the coordination state. Nothing here names a machine.

## Usage

```bash
C=<home>/scripts/collect
$C --since 1d                    # short human summary
$C --since 2d --json             # full machine digest
$C --since "2026-11-09 08:00" --json
$C --only git,sessions
$C --skip ado
$C --config ~/dev/deadlock/oracle/docs/coordination/collector.json
```

Time values: `90m`, `12h`, `2d`, `1w`, `today`, `yesterday`, `now`, an ISO date
or datetime, or epoch seconds. The window is half-open, `[since, until)`.

## Config

`collector.json` lives in the coordination home. Shape:

```json
{
  "instance": "personal",
  "repo_roots": ["~/dev"],
  "git_author": null,
  "forgejo": {
    "base_url": "https://git.jeremyk.net/api/v1",
    "token_file": "/run/agenix/agent_navi_forgejo_token",
    "repos": ["jeremy/docs", "jeremy/jk-skills"]
  },
  "ado": null,
  "sessions": {
    "opencode_db": "~/.local/share/opencode/opencode.db",
    "omp_db": "~/.omp/agent/history.db",
    "claude_dir": "~/.claude/projects"
  },
  "caps": {"git_repos": 40, "commits_per_repo": 15, "sessions": 40, "forgejo_items": 60}
}
```

- `git_author`: null means each repo's own `user.email`. Set it when the
  coordination identity differs from the repo identity.
- `forgejo.repos` is an allowlist; there is no global scan. `token_file` is read
  only for the request; the token is never printed.
- `ado` is for deadlock only: `bridge` is the `caipas-bridge` launcher, and
  `repos` limits the Review Exchange pull list to those Bridge aliases (`app`,
  `kube`). Boards search is project-scoped, so it runs once, not per repo.
  `review_exchange` holds the service-account URL, username and app-password
  file. The Review Exchange client is downloaded to
  `~/.cache/jk-coordinate/review_exchange.py` and refreshed weekly, because an
  old copy sends the retired bearer token.
- `sessions` paths default to the standard XDG locations when omitted.

## Output

`--json` top level: `instance`, `home`, `generated_at`, `window`, `git`,
`sessions` (`opencode`, `omp`, `claude`), `forgejo`, `ado`, `warnings`,
`timings`, `elapsed_seconds`.

## Limits

- Forgejo's issues endpoint returns at most 50 per repo per page; the collector
  reads one page and reports the window's items, not a complete history.
- Review Exchange returns the open PRs on the authenticated actor's plate, not a
  historical window.
- `boards search --assigned-to me` returns current assigned items, capped by
  `boards_assigned_limit`.
- Session sources read only what exists locally on this host.
