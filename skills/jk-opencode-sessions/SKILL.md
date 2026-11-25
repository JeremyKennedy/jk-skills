---
name: jk-opencode-sessions
version: "1.1.0"
description: "Use to message, read, or hand work to another OpenCode session on the same host via ocsession, the session_* tools, or OpenChamber's openchamber tool."
---

# OpenCode Sessions

## Overview

Every OpenCode session on a host runs against that host's managed server. Any session can
message another by id, so handing work to a sibling agent, pinging an orchestrator, or reading
what another session decided does not need a new conversation.

Address a session by its `ses_...` id or by the OpenChamber link form
`openchamber://session/ses_...`. The link prefix is UI only; the id is what the server uses.

Sessions are per host. A navi id means nothing to Cedar's server and vice versa — there is no
cross-host routing, so message a Cedar session from Cedar.

`ocsession` ships wherever the composition wires Shared's `lib.mkOcsession` (navi and Cedar).
A host that runs an OpenCode server without it still has sessions; use `opencode api` there.

## CLI

```bash
ocsession list [--all]                    # roots only unless --all
ocsession status <session>                # agent, model, directory, parent
ocsession read <session> --limit 20       # newest messages, oldest first
ocsession send <session> "<text>"         # deliver without waiting
ocsession send <session> "<text>" --wait  # deliver, then print the reply
ocsession wait <session> [SECONDS]        # block until the session is idle
```

## OpenCode tools

Inside OpenCode the same capability is native — prefer the tools over shelling out:

- `session_send` — `session`, `text`, optional `wait` (seconds, 0 = fire and forget).
- `session_read` — `session`, optional `limit` (1-50).
- `session_list` — optional `all`.

Claude, Codex and Hermes have no such tools; shell out to `ocsession`.

## OpenChamber control tool

In an OpenChamber-managed session the `openchamber` tool carries the same work
as actions, and it is the better path there:

- `session.send` — `sessionId`, `prompt`, optional `agent`, `model`, `variant`,
  `returnResult`.
- `session.create` — `title`, `prompt`, optional `agent`, `model`,
  `directory`/`projectId`, `worktree`, `pullRequest`, `returnResult`.
- `session.fork`, `session.list` (`inWork`, `busy`, `query`, `withStatus`),
  `session.status`, `session.messages` (`role`, `last`, `all`),
  `session.markDone`, `session.track`.

`returnResult: true` on create/send/fork with a prompt delivers the session's
final answer back into this chat as a message when it finishes, and records you
as the sender. It replaces waiting: do not poll, sleep, or call
`session.messages` to wait for it. The agent tool refuses `wait` (CLI only);
`session.messages` returns the current messages and status without waiting.

Use the plain tools for fire-and-forget pings, and in a plain OpenCode session
where the `openchamber` tool does not exist.

## Subagent or separate session

A bounded task whose result you need back in this conversation gets a subagent. It runs inside the
current session, reports back, and nests under it in the sidebar. You can still message it.

A new initiative with its own direction and follow-ups gets a separate session. It becomes a root
in the sidebar, and you reach it with `session_send` (or `openchamber` `session.send`).

A subtask does not get a root session. Root sessions per subtask fill the sidebar with conversations
nobody revisits.

## Message protocol

Send through the OpenCode API: `session_send` inside OpenCode, `ocsession send`
elsewhere, or `openchamber` `session.send` in an OpenChamber session.

Open every message with this header:

```
From: <session title> (ses_...)
Reply needed: no, unless something breaks
How to reply: session_send to ses_...
Load skill: jk-opencode-sessions
```

`Reply needed` is free text: an acknowledgement now, a report after the task, or no reply unless
something breaks. Your id is the `ses_...` in your session context, or `ocsession list --all` beside
your title.

When you send with `returnResult` — or dispatch with `session.create` and
`returnResult` — drop the `How to reply` line. The answer comes back on its
own and the transcript links it to you. Keep the line for fire-and-forget
messages that need a reply.

## Rules that matter

- **Need the answer?** In OpenChamber set `returnResult` on the send or create; do not wait or
  poll. Elsewhere use `--wait` / `wait`: delivery is a steer into the target's queue, the
  target works on its own, and there is no reply event to subscribe to.
- **Read back after a fire-and-forget send** rather than assuming it landed.
- **The message list is capped at 50 newest-first server-side.** `read --limit` slices that
  page; older messages need paging.
- **Do not use `opencode run -s <id> "<msg>"` for messaging.** It does deliver, but it hangs
  headless with no output, so it is useless in scripts.
- **The target keeps its own agent and model.** Sending does not switch agent, change
  directory, or fork the session.
- **Never message a session that is mid-handover** unless the message is additive; a steer
  lands between its turns, not before them.

## Verification

A send returns `sent to <id> (delivery: steer)` from the CLI, or the CLI's output through the
tool. With `returnResult`, the result carries `resultDelivery: pending` (or `not-scheduled` with
the reason) — a dispatch that did not land says so, and the session keeps running. `ocsession
status <id>` confirms the session exists and shows its directory before you trust a reply.

## Auth

The CLI goes through `opencode api`, which reads the server password from
`~/.config/opencode/service.json`. The password never appears in argv, so do not hand-roll
`curl` unless you have a reason — and if you do, it is basic auth `opencode:<password>`
against `http://127.0.0.1:<port>/api/...`.
