---
name: jk-opencode-sessions
version: "1.0.0"
description: Use when you need to message, ping, read, or hand work to another OpenCode session on the same host instead of starting a new conversation. Covers the ocsession CLI, the session_send/session_read/session_list tools, openchamber session links, and when waiting for a reply is safe.
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

## Subagent or separate session

A bounded task whose result you need back in this conversation gets a subagent. It runs inside the
current session, reports back, and nests under it in the sidebar. You can still message it.

A new initiative with its own direction and follow-ups gets a separate session. It becomes a root
in the sidebar, and you reach it with `session_send`.

A subtask does not get a root session. Root sessions per subtask fill the sidebar with conversations
nobody revisits.

## Message protocol

Send through the OpenCode API: `session_send` inside OpenCode, `ocsession send` elsewhere.

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

## Rules that matter

- **Use `--wait` / `wait` when you need the answer.** Delivery is a steer into the target's
  queue; the target works on its own and there is no reply event to subscribe to.
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
tool. `ocsession status <id>` confirms the session exists and shows its directory before you
trust a reply.

## Auth

The CLI goes through `opencode api`, which reads the server password from
`~/.config/opencode/service.json`. The password never appears in argv, so do not hand-roll
`curl` unless you have a reason — and if you do, it is basic auth `opencode:<password>`
against `http://127.0.0.1:<port>/api/...`.
