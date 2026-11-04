---
name: jk-coordinate
description: "Use when Jeremy asks what's open, where something stands, to focus on a client or initiative, to capture a to-do, for an end-of-day or weekly update, or when running the morning coordination run. Keeps coordination state in ~/dev/docs (NOW.md, STATUS.md, log.md) so sessions stay disposable."
---

# Coordinate

Answer "what's open?" with a short, ranked, evidence-backed list, and keep
every client and initiative recoverable from files. Sessions are disposable;
the files are the memory.

## Where state lives

The coordination home is `~/dev/docs`. Read `~/dev/docs/coordination/README.md`
at the start of every coordination session: it holds the rules, item types,
ranking, link formats and this machine's sources. If it and this skill
disagree, the README wins.

- `NOW.md`: everything that needs Jeremy, ranked, plus an Inbox.
- `clients/<slug>/STATUS.md` and `log.md`; `initiatives/<slug>/STATUS.md` and `log.md`.
- `coordination/templates/`: the STATUS, closed-STATUS and log formats.
- `coordination/collector/`: the activity collector (see its README).
- `coordination/sweeps/<date>/`: evidence from sweeps.
- `pr-registry/`: per-PR detail; `refresh.ts` syncs its automatic fields.

## Principles

- **Files are memory.** Save on every change: decisions, new asks, handoffs,
  results. Never leave state only in chat. When a session gets long, start a
  fresh one with `/focus`; don't compact repeatedly.
- **Evidence or nothing.** Every item has a link and a `since MM-DD` date, or
  the tag `[unverified]`. Never write "probably".
- **Coordinate; don't execute.** Read everything. Edit only coordination files
  in `~/dev/docs`. Dispatch investigation and execution (see Dispatch).
- **Nothing outbound without Jeremy's OK.** Draft Slack, Shortcut, PR and
  canvas text; post only after he approves; log the link afterwards.
- **Decisions go through the question tool,** recommendation first, with the
  trade-off in one line.
- **Short in chat, detailed in files.** Jeremy rarely reads the docs; the chat
  answer is what he sees.

## What's open (`/open`)

1. Read `NOW.md`. If its "Updated" time is more than 2 hours old, or Jeremy
   asks for a refresh, run the collector for the window since then and fold
   the changes into the touched STATUS files and `NOW.md`.
2. Reply in at most 10 lines: time-sensitive items first, then what needs
   Jeremy, ranked by the README (stale first; decision > reply > promise >
   in progress; oldest first). One line each, with link and age.
3. End with one to three offers, such as "draft the reply to Brian?".

## Focus on one initiative (`/focus <name>`)

1. Resolve the name to `clients/<slug>/` or `initiatives/<slug>/` (match on
   slug, client name or channel).
2. Read its STATUS, the last three log entries, and the headings of the
   runbook it links.
3. Check what changed since STATUS was updated: the client's Slack channel,
   its Shortcut stories or epic, its PRs, the latest Conductor run, and recent
   sessions about it.
4. Report Now, what changed, and what needs Jeremy. Save if anything changed.
5. Stay scoped to that initiative for the rest of the session.

## Save

1. Rewrite `STATUS.md` from `templates/STATUS.md`: at most 60 lines, current
   state only, "Updated" stamp refreshed. Move overflow to the log.
2. Append a `log.md` entry from `templates/log.md`: 3 to 5 bullets with links.
3. Commit only the files you touched:
   `git -C ~/dev/docs add -- <paths> && git -C ~/dev/docs commit -m "coord(<slug>): <what>" -- <paths>`.
   Never `git commit -a`: other sessions keep uncommitted work in this repo.
4. Only `/open`, `/todo` (Inbox only) and the morning run write `NOW.md`.

## Capture a to-do (`/todo <text>`)

File it into the matching STATUS (under Needs you, or Next) with today's date
and "source: Jeremy". If it's unclear where it belongs, add it to the
`NOW.md` Inbox. Save.

## Dispatch

- **Bounded work** (investigate, check, draft): a subagent. Give it full
  context, its exact write scope, and read-only rules otherwise. Save its
  result.
- **Long or hands-on work** (PR fixes, walkers, imports): a separate Build
  session that Jeremy can open in OpenChamber:

  ```bash
  sid=$(opencode api post /api/session --data '{"title":"<Name>: <task>","agent":"build","location":{"directory":"/Users/jeremy/dev"}}' | jq -r '.data.id')
  opencode api post "/api/session/$sid/prompt" --data "$(jq -n --arg t "<brief>" '{text:$t}')"
  ```

  The brief must stand alone: goal, links, constraints, what "done" means,
  and "append a log.md entry to clients/<slug>/log.md when your work changes
  its state". Record the session ID under In progress in STATUS.
- Never start imports, applies, deployments or production writes yourself.
  Those need Jeremy's explicit go inside the Build session.

## Closing

Propose closing with evidence, and always state the **last touch** (anyone's
most recent activity, and Jeremy's own) with dates and links. Ask with the
question tool (multi-select). On confirmation, rewrite STATUS from
`templates/STATUS-closed.md`, log it, commit.

## End of day (`/eod`)

Run the collector since the morning run. Fold changes into logs and STATUS.
Reply with Done and Still owed, and update `NOW.md`.

## Weekly update (`/weekly`)

The Monday canvas draft is the weekly report. Until the canvas integration
exists, write `~/dev/docs/coordination/reports/<date>-weekly.md`. Jeremy's
format: open with a version that needs no context ("Tricon reported some
issues; we've resolved most of them"), separate Done from What's next, put
Shortcut numbers at the end of each point, order clients BJ, Tricon, Colson,
BLG, then the rest, and give him the file path.

## Morning run (`/morning`, and the 8:00 weekday job)

1. Run the collector since the previous morning run (default one day).
2. Refresh the PR registry: `bun ~/dev/docs/pr-registry/refresh.ts`, then
   commit `pr-registry/registry.json`.
3. For each touched client or initiative: append a "since last look" log
   entry and update STATUS.
4. Rewrite `NOW.md`: time-sensitive first, ranking per the README, stale
   items escalated.
5. Cleanup: commit leftover coordination edits (only coordination files),
   flag any STATUS over 60 lines or off-template, and check that every item
   has a link and a date.
6. Push: `git -C /Users/jeremy/dev/docs push origin main`.
7. Mondays: draft the canvas update for Jeremy's approval. Never write to it
   without his OK.
8. Finish with a summary of at most 10 lines. It's what Jeremy reads first in
   OpenChamber.
