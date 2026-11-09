---
name: jk-coordinate
description: "Use when asked what's open, where something stands, to focus on a project or initiative, to capture a to-do, for an end-of-day or weekly update, or when running the morning coordination run. Keeps coordination state in files (personal at ~/dev/docs/coordination, deadlock at ~/dev/deadlock/oracle/docs/coordination) so sessions stay disposable."
version: 1.1.0
metadata:
  hermes:
    category: jk
    tags: [coordination, status, todo, triage, daily]
    related_skills: [jk-interview, writing-style]
---
<!-- agent-hub: managed -->
<!-- agent-hub-kind: skill -->
<!-- agent-hub-id: opaque-bf5730d41577 -->


# Coordinate

Answer "what's open?" with a short, ranked, evidence-backed list, and keep
every project and initiative recoverable from files. Sessions are disposable;
the files are the memory.

## Resolve the home

The coordination home depends on what the session is about:

- A session working in `~/dev/deadlock` (or its worktrees) uses
  `~/dev/deadlock/oracle/docs/coordination`.
- Everything else uses `~/dev/docs/coordination`.

The home's `README.md` is authoritative: it holds that instance's rules, item
types, ranking, sources, write scope and workflow specifics. Read it at the
start of every coordination session. If it and this skill disagree, the README
wins.

## State

Each home holds the same shape:

- `NOW.md`: everything that needs the user, ranked, plus an Inbox.
- `initiatives/<slug>/STATUS.md` and `log.md` for each project or initiative.
- `templates/`: the STATUS and log formats.
- `scripts/collect` and `collector.json`: the activity collector and its
  config (see `scripts/README.md`).

The deadlock home also carries its standup briefs, current state and briefs;
follow its README and the `standup-prep` format there.

## Principles

- **Files are memory.** Save on every change: decisions, new asks, handoffs,
  results. Never leave state only in chat. When a session gets long, start a
  fresh one with `/focus`; don't compact repeatedly.
- **Evidence or nothing.** Every item has a link and a `since MM-DD` date, or
  the tag `[unverified]`. Never write "probably".
- **Coordinate; don't execute.** Read everything. Edit only coordination files
  in the active home. Dispatch investigation and execution (see Dispatch).
- **Nothing outbound without the user's OK.** Draft message, ticket, PR and
  document text; post only after approval; log the link afterwards.
- **Decisions go through the question tool,** recommendation first, with the
  trade-off in one line.
- **Short in chat, detailed in files.** The user rarely reads the docs; the
  chat answer is what they see.

## What's open (`/open`)

1. Read `NOW.md`. If its "Updated" time is more than 2 hours old, or a refresh
   is asked for, run the home's collector for the window since then and fold
   the changes into the touched STATUS files and `NOW.md`.
2. Reply in at most 10 lines: time-sensitive items first, then what needs the
   user, ranked by the home README (stale first; decision > reply > promise >
   in progress; oldest first). One line each, with link and age.
3. End with one to three offers, such as "draft the reply?".

## Focus on one initiative (`/focus <name>`)

1. Resolve the name to `initiatives/<slug>/` (match on slug or project name).
2. Read its STATUS, the last three log entries, and the headings of the runbook
   it links.
3. Check what changed since STATUS was updated using the home's sources: git,
   Forgejo, ADO, and recent sessions.
4. Report Now, what changed, and what needs the user. Save if anything changed.
5. Stay scoped to that initiative for the rest of the session.

## Save

1. Rewrite `STATUS.md` from `templates/STATUS.md`: at most 60 lines, current
   state only, "Updated" stamp refreshed. Move overflow to the log.
2. Append a `log.md` entry from `templates/log.md`: 3 to 5 bullets with links.
3. Commit only the files you touched:
   `git -C <home repo> add -- <paths> && git -C <home repo> commit -m "coord(<slug>): <what>" -- <paths>`.
   Never `git commit -a`: other sessions keep uncommitted work in these repos.
4. Only `/open`, `/todo` (Inbox only) and the morning run write `NOW.md`.

## Capture a to-do (`/todo <text>`)

File it into the matching STATUS (under Needs you, or Next) with today's date
and "source: the user". If it's unclear where it belongs, add it to the
`NOW.md` Inbox. Save.

## Dispatch

- **Bounded work** (investigate, check, draft): a subagent. Give it full
  context, its exact write scope, and read-only rules otherwise. Save its
  result.
- **Long or hands-on work** (PR fixes, migrations, imports): a separate Build
  session the user can open in OpenChamber:

  ```bash
  sid=$(opencode api post /api/session --data '{"title":"<Name>: <task>","agent":"build","location":{"directory":"<abs path>"}}' | jq -r '.data.id')
  opencode api post "/api/session/$sid/prompt" --data "$(jq -n --arg t "<brief>" '{text:$t}')"
  ```

  The brief must stand alone: goal, links, constraints, what "done" means, and
  "append a log.md entry to <home>/initiatives/<slug>/log.md when your work
  changes its state". Record the session ID under In progress in STATUS.
- Never start imports, applies, deployments or production writes yourself.
  Those need an explicit go inside the Build session.

## Closing

Propose closing with evidence, and always state the **last touch** (anyone's
most recent activity, and the user's own) with dates and links. Ask with the
question tool (multi-select). On confirmation, rewrite STATUS from
`templates/STATUS-closed.md`, log it, commit.

## End of day (`/eod`)

Run the home's collector since the morning run. Fold changes into logs and
STATUS. Reply with Done and Still owed, and update `NOW.md`.

## Weekly update (`/weekly`)

Write `<home>/reports/<date>-weekly.md` and give the path. Open with a version
that needs no context, separate Done from What's next, and put ticket or PR
references at the end of each point.

## Morning run (`/morning`, and the unattended weekday job)

1. Run the home's collector since the previous morning run (default one day).
2. For each touched initiative: append a "since last look" log entry and update
   STATUS.
3. Rewrite `NOW.md`: time-sensitive first, ranking per the README, stale items
   escalated.
4. Cleanup: commit leftover coordination edits (only coordination files), flag
   any STATUS over 60 lines or off-template, and check that every item has a
   link and a date.
5. Push the home repo: `git -C <home repo> push origin main`. Use the exact
   repo path in the command so the permission rule matches; do not chain it
   behind other commands.
6. Deadlock: follow its README's standup procedure and refresh the current
   state.
7. Finish with a summary of at most 10 lines. It's what the user reads first.
