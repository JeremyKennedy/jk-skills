---
name: jk-converse
description: Set up a structured async conversation between two or more agents via a shared JSONL file and the converse script — automatic turn detection, convergence protocol, persistent record
---

# Converse

**Announce at start:** "I'm using the jk-converse skill to set up a structured conversation with another agent."

Structured async conversation between two or more agent sessions over a shared
file, driven by the `converse` script. One agent initiates, the others respond,
the user bridges the sessions. The script handles message delivery, "what's
new since you last looked," and waiting — so agents never miscount offsets or
forget to wait.

## The Script

A single self-contained Python script (stdlib only, no dependencies) lives
alongside this skill at:

```
<skill-directory>/scripts/converse.py
```

`<skill-directory>` is the base directory the host reports when this skill is
loaded. **Resolve it to an absolute path now** — you will run it yourself and
paste it into the handoff block for the other agent. Invoke it as
`python3 /abs/path/to/converse.py <command> ...`.

Each conversation is one JSONL file. The script tracks, per participant, which
messages they have already seen — so any participant can ask "what's new?" and
get exactly the messages they haven't read yet, from anyone but themselves.

### Commands

| Command | What it does |
|---------|--------------|
| `init <file> --topic T --context C [--participants a,b]` | Create the conversation. Writes topic + context as the first record. |
| `post <file> --as NAME [--to A,B] [-m MSG \| -f FILE \| stdin] [--wait]` | Append your message, then print any messages addressed to you that arrived since you last looked. `--to` narrows recipients (default: broadcast). With `--wait`, immediately block for the next reply (one-shot turn loop — see below). |
| `wait <file> --as NAME [--timeout N]` | Block until a new message arrives, then print it. Returns **immediately** if one is already waiting. Aliases: `watch`, `listen`. |
| `read <file> --as NAME [--peek]` | Print new messages without posting (for a non-committal catch-up). `--peek` leaves them unread. |
| `last <file> --from NAME [--as VIEWER] [--body]` | Print the most recent message from a specific agent (does not touch read cursors). `--as` restricts to messages that viewer may see; `--body` prints just the message text. |
| `log <file> [--as VIEWER]` | Render the full transcript as readable markdown. `--as` renders only what that viewer may see. |

Key behaviors:

- **`post` always reports new messages.** After appending, it tells you e.g.
  `2 new messages:` followed by their content — anything the other agent said
  while you were composing. If nothing is new, it says so.
- **`wait` never blocks on a message that already arrived.** It checks first,
  and only sleeps if there is genuinely nothing new. This eliminates the classic
  failure of waiting forever on a reply that is already in the file.
- **`wait` without `--timeout` waits indefinitely.** With `--timeout N` it exits
  with status `2` after `N` seconds if nothing new arrived.
- Bodies may be passed with `-m`, read from a file with `-f PATH`, or piped on
  stdin (use stdin for long multi-line messages).
- **Messages broadcast to everyone by default.** `--to a,b` sends a *directed*
  message that only those agents (and the sender) can see — `read`, `wait`,
  `post`, `last --as`, and `log --as` all filter to what each agent is allowed
  to see. Prefer broadcasting; narrow only when the info genuinely needn't be
  shared (e.g. a worker reporting status just to its parent).

> **Do not chain `read … && wait …`.** `read` marks the backlog seen and
> advances your cursor, so the following `wait` has nothing pending and blocks —
> you've drained messages you should be *responding to* and then sat idle. Just
> use `wait`: it returns the pending backlog immediately if there is one (and
> only blocks when there's genuinely nothing to act on). The loop is
> **`wait` → act → `post --wait` → act → …**, never drain-then-block.

## Roles

Exactly the same three-party contract as before — the script just replaces the
manual bookkeeping.

### You (the initiating agent)

1. **Resolve the script path** and pick conversation + participant names.
2. **`init`** the conversation file with topic and context.
3. **`post`** your opening position.
4. **Give the user a copy-pasteable handoff block** for the other session.
5. **`wait`** for the response (this is your turn-ending action).
6. **Read, `post` your reply, `wait` again.** Repeat until convergence.

### The user

Bridges the sessions. They paste your handoff block into the other agent's
session. They do not mediate content.

### The other agent

In a separate session, without this skill loaded. It gets everything it needs
from the handoff block: the script path, the file path, its participant name,
and the command patterns. It `read`s, `post`s, and `wait`s just like you.

## Step 1: Initialize

Choose an absolute path for the conversation file (project root or `/tmp/`) and
names for the participants (e.g. `agent-1` / `agent-2`, or descriptive roles
like `proposer` / `reviewer`). Then:

```bash
python3 /abs/path/converse.py init /abs/conversation.jsonl \
  --topic "Scope of the widget refactor" \
  --context "Deciding whether to extract WidgetStore. Key files: src/widget/*. The user wants minimal surface area." \
  --participants agent-1,agent-2
```

Put enough in `--context` that the other agent can participate cold — it has
not seen your conversation history.

## Step 2: Post Your Opening

```bash
python3 /abs/path/converse.py post /abs/conversation.jsonl --as agent-1 \
  -m "I propose extracting WidgetStore into its own module. Two questions: (1) keep the existing name? (2) move the cache too, or leave it inline?"
```

For longer openings, pipe on stdin:

```bash
python3 /abs/path/converse.py post /abs/conversation.jsonl --as agent-1 -f - <<'EOF'
My analysis ...
multiple paragraphs ...
EOF
```

## Step 3: Give the User the Handoff Block

Give the user a single copy-pasteable block for the other session. Fill in the
real absolute paths and names. The other agent needs nothing else.

````
Paste this into the other agent session:

```
You are joining an async agent conversation driven by a script. You are "agent-2".

The conversation file: /abs/conversation.jsonl
The script:           python3 /abs/path/converse.py

1. See what's been said:
     python3 /abs/path/converse.py read /abs/conversation.jsonl --as agent-2
   (or `log` for the full transcript)

2. Post your response (it will also report anything new since you looked):
     python3 /abs/path/converse.py post /abs/conversation.jsonl --as agent-2 -f - <<'EOF'
     <your response>
     EOF

3. Wait for the reply — ALWAYS end your turn with this, it blocks until I respond:
     python3 /abs/path/converse.py wait /abs/conversation.jsonl --as agent-2
   Run it as the final action of your turn. When it returns, it prints the new
   message(s); read them, then post your reply and wait again.

Protocol for your messages:
- State positions explicitly: "I agree with X" / "I disagree because Y".
- Number your points when responding to multiple items.
- End with specific questions or a clear ask.

Convergence: we iterate until we agree. When satisfied, post a message that
ends with "I confirm this exact scope:" followed by a numbered list. I will do
the same. Stop after mutual confirmation.
```
````

In synchronous harnesses, run `wait` as the **final foreground action of the
turn** so control returns to you when the message arrives. In harnesses with
real async/background execution, you may run `wait` in the background and be
notified on completion. Either way, the rule is the same: after you `post`, you
`wait`.

## Turn Loop

Use the combined `post --wait` so each turn is one call — say your piece, then
listen for the reply:

```
1. (act on the messages you just received)
2. post --wait  your reply      (appends, then blocks for the next message)
3. read the printed reply, go to 1
```

To enter the loop (or when you have nothing to say yet), start with a bare
`wait` — it returns the current backlog immediately if there is one, otherwise
blocks for the next message. Then act and switch to `post --wait`.

You cannot "forget to wait" without ending your turn silently — make `wait` or
`post --wait` the last thing you do every turn until convergence. Never
`read … && wait …` (that drains the backlog, then blocks instead of letting you
respond to it).

## Convergence

Conversations must converge. The pattern:

1. **Opening**: State your position, ask specific questions.
2. **Response**: Answer each question directly, raise new concerns.
3. **Synthesis**: Propose a unified position, enumerate exact scope.
4. **Confirmation**: Both agents post a message ending with
   "I confirm this exact scope:" followed by a numbered list.

Stop when all participants have confirmed. Don't iterate after agreement.

Most conversations converge in 2–4 rounds. If you're past 4 rounds without
agreement, stop waiting and escalate to the user.

## Conversation Quality

- **Be specific, not diplomatic.** "I disagree because X" not "perhaps we could
  consider..."
- **Push back on over-engineering.** If the other agent proposes unnecessary
  complexity, say so.
- **Ground arguments in the codebase.** Reference file paths, line numbers,
  existing patterns.
- **Respect the user's stated preferences.** If the user already rejected an
  approach, don't re-propose it.

## More Than Two Agents

Participants are arbitrary names — pass more than two to `--participants` and
hand each additional session its own handoff block with its own `--as NAME`.
Every participant's "what's new" is tracked independently, so a third agent
joining mid-conversation still sees everything it hasn't read. For a panel,
designate one participant to call convergence once all have confirmed.

For a **parent/worker hierarchy**, workers can broadcast shared findings to all
but report routine status with `--to parent` so they don't spam siblings — the
parent sees every worker's directed reports, workers only see broadcasts and
messages addressed to them. Default to broadcasting; reach for `--to` only when
the information genuinely doesn't need sharing.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Ending your turn without `wait` | Make `wait` the final action of every turn until convergence. |
| Re-reading the whole file to find "what's new" | `post`/`read`/`wait` already print exactly what you haven't seen. |
| Hardcoding a wrong script path | Resolve `<skill-directory>/scripts/converse.py` to an absolute path once, reuse it. |
| Handoff block missing the script or file path | The other agent has no skill loaded — give it the full command patterns. |
| Messages too long and unfocused | Lead with your position, then supporting evidence. |
| No explicit questions at the end | Every message should drive toward a decision. |
| Agreeing too easily to avoid conflict | If you disagree, say why. False consensus wastes time. |
| No explicit confirmation of final scope | End with a numbered list all agents confirm verbatim. |
